import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/ai/gemini_service.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/slug.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/models/resume_model.dart';

/// Result of [ProfileRepository.createResume]: the stored doc plus whether
/// the binary could be persisted to Firebase Storage.
class ResumeUploadResult {
  const ResumeUploadResult({required this.resume, required this.fileStored});
  final ResumeModel resume;
  final bool fileStored;
}

/// JobSeekerService + ResumeService port on Firestore.
///
/// - jobSeekerProfiles/{uid}: single doc, arrays replaced wholesale.
/// - resumes/{id}: owner = jobSeekerId; exactly one isPrimary per owner.
/// - resumes/{id}/aiAnalyses/{analysisId}: append-only history; the latest is
///   also embedded in resumes/{id}.aiAnalysis (latest wins).
class ProfileRepository {
  ProfileRepository(this._refs, this._storage, this._gemini);

  final FirestoreRefs _refs;
  final StorageService _storage;
  final GeminiService _gemini;

  static const notFoundProfile = 'Không tìm thấy hồ sơ ứng viên.';
  static const notFoundResume = 'Không tìm thấy CV.';
  static const emptyResumeText = 'Không đọc được nội dung từ tệp CV.';
  static const notAnalyzed = 'CV chưa được phân tích.';

  /// NUL byte (rejected by Postgres text columns in the original backend;
  /// stripped here too so pasted text stays clean).
  static final String _nul = String.fromCharCode(0);

  // ── Profile ───────────────────────────────────────────────────────────

  Stream<JobSeekerProfile?> watchProfile(String uid) => _refs
      .jobSeekerProfiles()
      .doc(uid)
      .snapshots()
      .map((s) => s.exists ? s.data() : null);

  Future<JobSeekerProfile?> getProfile(String uid) async {
    final snap = await _refs.jobSeekerProfiles().doc(uid).get();
    return snap.exists ? snap.data() : null;
  }

  /// PUT /job-seekers/me with the full payload: scalar fields patched and the
  /// skills / workExperiences / educations arrays replaced wholesale.
  /// Also mirrors fullName / headline / city into users/{uid}.
  ///
  /// JobSeekerService.updateProfile → `JobRepository.upsertSkillsByNames`:
  /// every submitted skill name is resolved (case-insensitively) or created
  /// in the shared `skills` catalogue and the row stores its skill_id with
  /// source MANUAL. Same here: the profile is written with `skillId` set.
  Future<void> updateProfile(JobSeekerProfile profile) async {
    final batch = _refs.db.batch();
    final skills = await _upsertSkills(profile.skills, batch);
    batch.set(
      _refs.jobSeekerProfiles().doc(profile.uid),
      profile.copyWith(skills: skills),
    );
    batch.set(
      _refs.db.collection(FirestoreRefs.colUsers).doc(profile.uid),
      _userMirror(
        fullName: profile.fullName,
        headline: profile.headline,
        city: profile.city,
        phone: profile.phone,
      ),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// ResumePage form: only fullName / headline / city (merge write).
  Future<void> updateProfileBasics({
    required String uid,
    required String fullName,
    required String headline,
    required String city,
  }) async {
    final batch = _refs.db.batch();
    batch.set(
      _refs.db.collection(FirestoreRefs.colJobSeekerProfiles).doc(uid),
      {
        'uid': uid,
        'fullName': fullName,
        'headline': headline,
        'city': city,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    batch.set(
      _refs.db.collection(FirestoreRefs.colUsers).doc(uid),
      _userMirror(fullName: fullName, headline: headline, city: city),
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  Map<String, dynamic> _userMirror({
    String? fullName,
    String? headline,
    String? city,
    String? phone,
  }) =>
      {
        if ((fullName ?? '').trim().isNotEmpty) 'fullName': fullName!.trim(),
        'headline': ?headline,
        'city': ?city,
        if ((phone ?? '').trim().isNotEmpty) 'phone': phone!.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      };

  // ── Skills catalogue ──────────────────────────────────────────────────

  /// Firestore `whereIn` upper bound.
  static const _whereInChunk = 30;

  /// Deterministic catalogue id — identical to the admin seed/catalog scheme
  /// (`slugId('skill', name)`) so seeker-, employer- and admin-created
  /// entries for the same name converge on one document.
  static String skillDocId(String name) => slugId('skill', name);

  /// `upsertSkillsByNames`: blanks dropped, names unique case-insensitively,
  /// existing catalogue rows reused (by `skillNameLower`, then by slug id),
  /// the rest created in [batch]. Returns the rows with `skillId` filled and
  /// `source` forced to MANUAL like the backend's replaceSkills payload.
  Future<List<ProfileSkill>> _upsertSkills(
    List<ProfileSkill> input,
    WriteBatch batch,
  ) async {
    final seen = <String>{};
    final rows = <ProfileSkill>[];
    for (final s in input) {
      final name = s.skillName.trim();
      if (name.isEmpty || !seen.add(name.toLowerCase())) continue;
      rows.add(s);
    }
    if (rows.isEmpty) return const [];

    // 1) case-insensitive name lookup (what the SQL upsert did).
    final byLower = <String, SkillModel>{};
    final lowers = rows.map((s) => s.skillName.trim().toLowerCase()).toList();
    for (var i = 0; i < lowers.length; i += _whereInChunk) {
      final chunk = lowers.sublist(
          i, i + _whereInChunk > lowers.length ? lowers.length : i + _whereInChunk);
      final snap =
          await _refs.skills().where('skillNameLower', whereIn: chunk).get();
      for (final d in snap.docs) {
        byLower.putIfAbsent(d.data().skillName.toLowerCase(), () => d.data());
      }
    }

    // 2) slug-id lookup for the rest, so we never clobber an existing doc.
    final byId = <String, SkillModel>{};
    final missingIds = <String>[
      for (final s in rows)
        if (!byLower.containsKey(s.skillName.trim().toLowerCase()))
          skillDocId(s.skillName.trim()),
    ];
    for (var i = 0; i < missingIds.length; i += _whereInChunk) {
      final chunk = missingIds.sublist(i,
          i + _whereInChunk > missingIds.length ? missingIds.length : i + _whereInChunk);
      final snap = await _refs
          .skills()
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        byId[d.id] = d.data();
      }
    }

    final out = <ProfileSkill>[];
    for (final s in rows) {
      final name = s.skillName.trim();
      var found = byLower[name.toLowerCase()];
      if (found == null) {
        final id = skillDocId(name);
        found = byId[id];
        if (found == null) {
          found = SkillModel(skillId: id, skillName: name);
          batch.set(_refs.skills().doc(id), found);
          byId[id] = found;
        }
      }
      out.add(ProfileSkill(
        skillId: found.skillId,
        skillName: found.skillName,
        experienceYears: s.experienceYears,
        skillDetail: s.skillDetail,
        source: SkillSource.manual,
      ));
    }
    return out;
  }

  // ── Resumes ───────────────────────────────────────────────────────────

  /// All resumes of a seeker, ordered isPrimary DESC, uploadDate DESC
  /// (sorted client-side so no composite index is required).
  Stream<List<ResumeModel>> watchResumes(String uid) => _refs
      .resumes()
      .where('jobSeekerId', isEqualTo: uid)
      .snapshots()
      .map((s) => sortResumes(s.docs.map((d) => d.data()).toList()));

  Stream<ResumeModel?> watchResume(String resumeId) => _refs
      .resumes()
      .doc(resumeId)
      .snapshots()
      .map((s) => s.exists ? s.data() : null);

  static List<ResumeModel> sortResumes(List<ResumeModel> list) {
    final sorted = [...list];
    sorted.sort((a, b) {
      if (a.isPrimary != b.isPrimary) return a.isPrimary ? -1 : 1;
      final ad = a.uploadDate ?? DateTime.now();
      final bd = b.uploadDate ?? DateTime.now();
      return bd.compareTo(ad);
    });
    return sorted;
  }

  /// POST /resumes. Tries Firebase Storage for PDF bytes; when Storage is
  /// unavailable the doc is still written (metadata + rawText when known).
  Future<ResumeUploadResult> createResume({
    required String uid,
    required String title,
    required String fileName,
    required Uint8List bytes,
    String? rawText,
  }) async {
    final existing = await _refs
        .resumes()
        .where('jobSeekerId', isEqualTo: uid)
        .get();
    final makePrimary = existing.docs.isEmpty;

    final docRef = _refs.resumes().doc();
    String storagePath = '';
    String? downloadUrl;
    var fileStored = false;
    final isPdf = fileName.toLowerCase().endsWith('.pdf');
    if (isPdf) {
      try {
        final up = await _storage.uploadResume(
          uid: uid,
          resumeId: docRef.id,
          bytes: bytes,
          fileName: fileName,
        );
        storagePath = up.path;
        downloadUrl = up.url;
        fileStored = true;
      } catch (_) {
        // Firebase Storage is not enabled on this project (no Blaze plan):
        // fall back to a metadata/text-only resume document.
        fileStored = false;
      }
    } else {
      // Plain-text CVs are fully represented by rawText.
      fileStored = (rawText ?? '').trim().isNotEmpty;
    }

    final cleanText = (rawText ?? '').replaceAll(_nul, '').trim();
    final model = ResumeModel(
      resumeId: docRef.id,
      jobSeekerId: uid,
      title: title.trim().isEmpty ? _stem(fileName) : title.trim(),
      fileName: fileName,
      filePath: storagePath,
      downloadUrl: downloadUrl,
      rawText: cleanText.isEmpty ? null : cleanText,
      isPrimary: makePrimary,
      uploadDate: DateTime.now(),
    );

    final batch = _refs.db.batch();
    batch.set(docRef, model);
    if (makePrimary) {
      batch.set(
        _refs.db.collection(FirestoreRefs.colJobSeekerProfiles).doc(uid),
        {'primaryResumeId': docRef.id, 'updatedAt': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return ResumeUploadResult(resume: model, fileStored: fileStored);
  }

  static String _stem(String fileName) {
    final i = fileName.lastIndexOf('.');
    return i <= 0 ? fileName : fileName.substring(0, i);
  }

  /// PUT /resumes/:id { isPrimary: true } — clears every other primary.
  Future<void> setPrimary({required String uid, required String resumeId}) async {
    final snap =
        await _refs.resumes().where('jobSeekerId', isEqualTo: uid).get();
    if (!snap.docs.any((d) => d.id == resumeId)) {
      throw const Failure.notFound(notFoundResume);
    }
    final batch = _refs.db.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'isPrimary': d.id == resumeId});
    }
    batch.set(
      _refs.db.collection(FirestoreRefs.colJobSeekerProfiles).doc(uid),
      {'primaryResumeId': resumeId, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  /// PUT /resumes/:id { label } — rename.
  Future<void> rename({required String resumeId, required String title}) =>
      _refs.resumes().doc(resumeId).update({'title': title.trim()});

  /// Stores pasted / extracted text so the AI step has something to read.
  Future<void> saveRawText({required String resumeId, required String text}) =>
      _refs.resumes().doc(resumeId).update({
        'rawText': text.replaceAll(_nul, '').trim(),
      });

  /// Max writes per batch kept well under Firestore's 500-op ceiling.
  static const _batchChunk = 400;

  /// DELETE /resumes/:id — unlink file, delete doc (+ its aiAnalyses history,
  /// which Firestore does not cascade and whose rules need the parent to
  /// still exist), promote the next CV.
  Future<void> deleteResume({required String uid, required ResumeModel resume}) async {
    if (resume.jobSeekerId != uid) throw const Failure.notFound(notFoundResume);
    if (resume.filePath.isNotEmpty) await _storage.delete(resume.filePath);

    final others = await _refs
        .resumes()
        .where('jobSeekerId', isEqualTo: uid)
        .get()
        .then((s) => s.docs.where((d) => d.id != resume.resumeId).toList());

    // History docs: delete while the parent still exists (rules `get()` it).
    final history = await _refs.aiAnalyses(resume.resumeId).get();
    final historyRefs = history.docs.map((d) => d.reference).toList();
    while (historyRefs.length > _batchChunk) {
      final part = _refs.db.batch();
      for (final r in historyRefs.sublist(0, _batchChunk)) {
        part.delete(r);
      }
      await part.commit();
      historyRefs.removeRange(0, _batchChunk);
    }

    final batch = _refs.db.batch();
    for (final r in historyRefs) {
      batch.delete(r);
    }
    batch.delete(_refs.resumes().doc(resume.resumeId));
    final profileRef =
        _refs.db.collection(FirestoreRefs.colJobSeekerProfiles).doc(uid);
    if (resume.isPrimary) {
      if (others.isNotEmpty) {
        final next = sortResumes(others.map((d) => d.data()).toList()).first;
        batch.update(_refs.resumes().doc(next.resumeId), {'isPrimary': true});
        batch.set(
          profileRef,
          {
            'primaryResumeId': next.resumeId,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } else {
        batch.set(
          profileRef,
          {
            'primaryResumeId': FieldValue.delete(),
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
    }
    await batch.commit();
  }

  // ── AI analysis ───────────────────────────────────────────────────────

  /// POST /resumes/:id/analyze: Gemini resume_extraction → new aiAnalyses row
  /// + embedded copy on the resume doc.
  Future<AiAnalysis> analyzeResume({
    required String uid,
    required ResumeModel resume,
  }) async {
    if (resume.jobSeekerId != uid) throw const Failure.notFound(notFoundResume);
    final text = (resume.rawText ?? '').replaceAll(_nul, '').trim();
    if (text.isEmpty) {
      throw const Failure(emptyResumeText, status: 400, code: 'EMPTY_RESUME_TEXT');
    }

    final AiAnalysis extracted;
    try {
      extracted = await _gemini.extractResume(
        text,
        jobSeekerId: uid,
        resumeId: resume.resumeId,
      );
    } catch (e) {
      final f = Failure.from(e);
      // Key / HTTP problems keep their precise message; parse failures map to
      // the backend's generic 500.
      if (f.code == 'BAD_RESPONSE' || f.code == 'UNKNOWN') {
        throw const Failure(
          'Không thể phân tích CV bằng AI. Vui lòng thử lại sau.',
          status: 500,
          code: 'AI_EXTRACTION_FAILED',
        );
      }
      throw f;
    }

    final historyRef = _refs.aiAnalyses(resume.resumeId).doc();
    final analysis = AiAnalysis(
      analysisId: historyRef.id,
      resumeId: resume.resumeId,
      summary: extracted.summary,
      skills: extracted.skills,
      softSkills: extracted.softSkills,
      languages: extracted.languages,
      certifications: extracted.certifications,
      workExperience: extracted.workExperience,
      totalExperienceYears: extracted.totalExperienceYears,
      educationLevel: extracted.educationLevel,
      rawText: extracted.rawText,
      modelVersion: extracted.modelVersion,
      analyzedAt: extracted.analyzedAt ?? DateTime.now(),
    );

    final batch = _refs.db.batch();
    batch.set(historyRef, analysis);
    batch.update(_refs.resumes().doc(resume.resumeId), {
      'aiAnalysis': analysis.toJson(),
    });
    await batch.commit();
    return analysis;
  }

  /// GET /resumes/:id/analysis — latest by analyzedAt DESC.
  Stream<List<AiAnalysis>> watchAnalyses(String resumeId) => _refs
      .aiAnalyses(resumeId)
      .orderBy('analyzedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());
}

final profileRepositoryProvider = Provider<ProfileRepository>(
  (ref) => ProfileRepository(
    ref.watch(firestoreRefsProvider),
    ref.watch(storageServiceProvider),
    ref.watch(geminiServiceProvider),
  ),
);
