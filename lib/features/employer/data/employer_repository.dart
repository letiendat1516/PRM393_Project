import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/system_config_repository.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/slug.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import 'job_form_input.dart';

/// EmployerService + JobService (employer side) port. Firestore access for the
/// employer feature lives only here.
class EmployerRepository {
  EmployerRepository(this._refs, this._configs, this._storage);

  final FirestoreRefs _refs;
  final SystemConfigRepository _configs;
  final StorageService _storage;

  static const msgForbidden = 'Bạn chỉ được quản lý tin tuyển dụng của công ty mình.';
  static const msgJobNotFound = 'Không tìm thấy tin tuyển dụng.';
  static const msgProfileNotFound = 'Không tìm thấy hồ sơ công ty.';
  static const msgReopenRejected = 'Tin tuyển dụng này đã bị từ chối, không thể mở lại.';

  // ── Company profile ───────────────────────────────────────────────────
  Stream<EmployerProfile?> watchProfile(String uid) =>
      _refs.employerProfiles().doc(uid).snapshots().map((s) => s.data());

  Future<EmployerProfile?> getProfile(String uid) async =>
      (await _refs.employerProfiles().doc(uid).get()).data();

  /// PUT /employers/me — field limits from employerValidator; '' allowed.
  Future<void> updateProfile(
    String uid, {
    required String companyName,
    required String phone,
    required String website,
    required String companyDescription,
    required String city,
    required String contactName,
    Gender? gender,
  }) async {
    final errors = <String, String>{};
    final name = companyName.trim();
    if (name.isNotEmpty && (name.length < 2 || name.length > 255)) {
      errors['companyName'] = 'Tên công ty phải từ 2 đến 255 ký tự.';
    }
    if (phone.trim().length > 20) errors['phone'] = 'Số điện thoại tối đa 20 ký tự.';
    if (website.trim().length > 255) errors['website'] = 'Website tối đa 255 ký tự.';
    if (companyDescription.length > 5000) {
      errors['companyDescription'] = 'Giới thiệu công ty tối đa 5000 ký tự.';
    }
    if (city.trim().length > 100) errors['city'] = 'Thành phố tối đa 100 ký tự.';
    if (contactName.trim().length > 255) {
      errors['contactName'] = 'Người liên hệ tối đa 255 ký tự.';
    }
    if (errors.isNotEmpty) {
      throw Failure.validation(errors.values.first, fieldErrors: errors);
    }

    final doc = _refs.db.collection(FirestoreRefs.colEmployerProfiles).doc(uid);
    final snap = await doc.get();
    if (!snap.exists) throw const Failure.notFound(msgProfileNotFound);

    final patch = <String, dynamic>{
      if (name.isNotEmpty) 'companyName': name,
      'phone': phone.trim(),
      'website': website.trim(),
      'companyDescription': companyDescription.trim(),
      'city': city.trim(),
      'contactName': contactName.trim(),
      'gender': gender?.name,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await doc.set(patch, SetOptions(merge: true));

    // Keep the denormalised employer fields on the company's jobs in sync.
    final jobs = await _refs.jobs().where('employerId', isEqualTo: uid).limit(100).get();
    if (jobs.docs.isNotEmpty) {
      final batch = _refs.db.batch();
      for (final d in jobs.docs) {
        batch.update(d.reference, {
          if (name.isNotEmpty) 'employerName': name,
          'employerCity': city.trim(),
          'employerWebsite': website.trim(),
        });
      }
      await batch.commit();
    }
  }

  /// Logo upload. Firebase Storage may be disabled — callers catch and ignore.
  Future<String> uploadLogo({
    required String uid,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final res = await _storage.uploadImage(
      folder: 'logos',
      uid: uid,
      bytes: bytes,
      fileName: fileName,
    );
    await _refs.db
        .collection(FirestoreRefs.colEmployerProfiles)
        .doc(uid)
        .set({'logoUrl': res.url, 'updatedAt': FieldValue.serverTimestamp()}, SetOptions(merge: true));
    final jobs = await _refs.jobs().where('employerId', isEqualTo: uid).limit(100).get();
    if (jobs.docs.isNotEmpty) {
      final batch = _refs.db.batch();
      for (final d in jobs.docs) {
        batch.update(d.reference, {'employerLogoUrl': res.url});
      }
      await batch.commit();
    }
    return res.url;
  }

  // ── Catalog ───────────────────────────────────────────────────────────
  Stream<List<CategoryModel>> watchCategories() => _refs
      .categories()
      .orderBy('name')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<List<SkillModel>> watchSkills() => _refs
      .skills()
      .orderBy('skillName')
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Future<int> maxSkillsPerJob() async =>
      (await _configs.getNumber(SystemConfig.keyMaxSkillsPerJob, AppConfig.defaultMaxSkillsPerJob))
          .toInt();

  /// REQUIRE_JOB_APPROVAL. The backend accepts the string form ('true') for
  /// this key regardless of the stored valueType, so parse the raw value
  /// instead of relying on SystemConfig.asBool (which requires BOOLEAN).
  Future<bool> requireJobApproval() async {
    try {
      final c = await _configs.get(SystemConfig.keyRequireJobApproval);
      if (c == null) return AppConfig.defaultRequireJobApproval;
      final v = c.configValue.trim().toLowerCase();
      if (v == 'true') return true;
      if (v == 'false') return false;
      return AppConfig.defaultRequireJobApproval;
    } catch (_) {
      return AppConfig.defaultRequireJobApproval;
    }
  }

  // ── Jobs ──────────────────────────────────────────────────────────────
  /// my-postings: every status, includeUnapproved, newest first (limit 100).
  Stream<List<JobModel>> watchMyJobs(String employerId) => _refs
      .jobs()
      .where('employerId', isEqualTo: employerId)
      .orderBy('createdAt', descending: true)
      .limit(100)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<JobModel?> watchJob(String jobId) =>
      _refs.jobs().doc(jobId).snapshots().map((s) => s.data());

  Future<JobModel> _ownedJob(String employerId, String jobId) async {
    final snap = await _refs.jobs().doc(jobId).get();
    final job = snap.data();
    if (job == null) throw const Failure.notFound(msgJobNotFound);
    if (job.employerId != employerId) throw const Failure.forbidden(msgForbidden);
    return job;
  }

  Future<JobModel> getOwnedJob(String employerId, String jobId) =>
      _ownedJob(employerId, jobId);

  /// POST /jobs — JobService.createJob parity.
  Future<JobModel> createJob({
    required String employerId,
    required JobFormInput input,
  }) async {
    final results = await Future.wait<Object>([
      _configs.getNumber(SystemConfig.keyMaxSkillsPerJob, AppConfig.defaultMaxSkillsPerJob),
      _configs.getNumber(SystemConfig.keyDefaultDeadlineDays, AppConfig.defaultDeadlineDays),
      requireJobApproval(),
    ]);
    final maxSkills = (results[0] as num).toInt();
    final deadlineDays = (results[1] as num).toInt();
    final requireApproval = results[2] as bool;

    _assertValid(
      input.validateAll(maxSkills),
      'Không thể tạo tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung sau:',
    );

    final skills = JobFormInput.normalizeSkills(input.skills);
    final deadline = input.deadline ?? DateTime.now().add(Duration(days: deadlineDays));
    final profile = await getProfile(employerId);
    final employerName =
        (profile?.companyName ?? '').trim().isEmpty ? 'Công ty chưa cập nhật' : profile!.companyName.trim();

    final batch = _refs.db.batch();
    final category = await _resolveCategory(input.categoryId, input.categoryName, batch);
    final skillRefs = await _upsertSkills(skills, batch);

    final docRef = _refs.jobs().doc();
    final location = input.location.trim();
    final city = input.city.trim().isEmpty ? location : input.city.trim();
    final job = JobModel(
      jobId: docRef.id,
      employerId: employerId,
      employerName: employerName,
      employerLogoUrl: profile?.logoUrl,
      employerCity: profile?.city,
      employerWebsite: profile?.website,
      categoryId: category?.categoryId,
      categoryName: category?.name,
      jobTitle: input.title.trim(),
      description: input.toDescription(),
      salaryMin: input.isSalaryNegotiable ? null : input.salaryMin,
      salaryMax: input.isSalaryNegotiable ? null : input.salaryMax,
      salaryCurrency: input.currency.trim().toUpperCase(),
      salaryPeriod: input.salaryPeriod,
      isSalaryNegotiable: input.isSalaryNegotiable,
      location: location,
      city: city,
      workMode: input.workMode,
      jobType: input.jobType,
      experienceLevel: input.experienceLevel,
      positionsAvailable: input.positions,
      applicationDeadline: deadline,
      status: requireApproval ? JobStatus.draft : JobStatus.open,
      isApproved: !requireApproval,
      requiredSkills: skillRefs,
      titleTokens: JobModel.tokenize(input.title.trim(), employerName),
      applicationsCount: 0,
      createdAt: DateTime.now(),
    );
    batch.set(docRef, job);
    if (category != null) {
      batch.set(
        _refs.db.collection(FirestoreRefs.colCategories).doc(category.categoryId),
        {'jobCount': FieldValue.increment(1)},
        SetOptions(merge: true),
      );
    }
    await batch.commit();
    return job;
  }

  /// PUT /jobs/:id — same validator; status / isApproved untouched.
  Future<void> updateJob({
    required String employerId,
    required String jobId,
    required JobFormInput input,
  }) async {
    final existing = await _ownedJob(employerId, jobId);
    final maxSkills = await maxSkillsPerJob();
    _assertValid(
      input.validateAll(maxSkills),
      'Không thể cập nhật tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung sau:',
    );

    final batch = _refs.db.batch();
    final category = await _resolveCategory(input.categoryId, input.categoryName, batch);
    final skillRefs = await _upsertSkills(JobFormInput.normalizeSkills(input.skills), batch);

    final location = input.location.trim();
    final city = input.city.trim().isEmpty ? location : input.city.trim();
    final patch = <String, dynamic>{
      'jobTitle': input.title.trim(),
      'categoryId': category?.categoryId ?? existing.categoryId,
      'categoryName': category?.name ?? existing.categoryName,
      'description': input.toDescription().toJson(),
      'salaryMin': input.isSalaryNegotiable ? null : input.salaryMin,
      'salaryMax': input.isSalaryNegotiable ? null : input.salaryMax,
      'salaryCurrency': input.currency.trim().toUpperCase(),
      'salaryPeriod': enumToWire(input.salaryPeriod),
      'isSalaryNegotiable': input.isSalaryNegotiable,
      'location': location,
      'city': city,
      'workMode': enumToWire(input.workMode),
      'jobType': enumToWire(input.jobType),
      'experienceLevel': enumToWire(input.experienceLevel),
      'positionsAvailable': input.positions,
      if (input.deadline != null) 'applicationDeadline': Timestamp.fromDate(input.deadline!),
      'requiredSkills': skillRefs.map((e) => e.toJson()).toList(),
      'titleTokens': JobModel.tokenize(input.title.trim(), existing.employerName),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    batch.update(_refs.jobs().doc(jobId), patch);

    final newCat = category?.categoryId;
    if (newCat != null && newCat != existing.categoryId) {
      batch.set(_refs.db.collection(FirestoreRefs.colCategories).doc(newCat),
          {'jobCount': FieldValue.increment(1)}, SetOptions(merge: true));
      if (existing.categoryId != null) {
        batch.set(_refs.db.collection(FirestoreRefs.colCategories).doc(existing.categoryId!),
            {'jobCount': FieldValue.increment(-1)}, SetOptions(merge: true));
      }
    }
    await batch.commit();
  }

  Future<void> closeJob(String employerId, String jobId) async {
    await _ownedJob(employerId, jobId);
    await _refs.jobs().doc(jobId).update({
      'status': enumToWire(JobStatus.closed),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  Future<void> reopenJob(String employerId, String jobId) async {
    final job = await _ownedJob(employerId, jobId);
    if (!job.isApproved) throw const Failure.validation(msgReopenRejected);
    await _refs.jobs().doc(jobId).update({
      'status': enumToWire(JobStatus.open),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Hard delete (JobService.deleteJob).
  Future<void> deleteJob(String employerId, String jobId) async {
    final job = await _ownedJob(employerId, jobId);
    final batch = _refs.db.batch();
    batch.delete(_refs.jobs().doc(jobId));
    if (job.categoryId != null) {
      batch.set(_refs.db.collection(FirestoreRefs.colCategories).doc(job.categoryId!),
          {'jobCount': FieldValue.increment(-1)}, SetOptions(merge: true));
    }
    await batch.commit();
  }

  // ── Applications (employer side, read-only here) ──────────────────────
  /// GET /applications/employer?jobId= — both equality filters are required:
  /// firestore.rules only lets an employer list applications whose
  /// `employerId == uid`, so a jobId-only query is rejected outright.
  /// Composite index: applications(employerId ASC, jobId ASC, applicationDate DESC).
  Stream<List<ApplicationModel>> watchJobApplicants(
    String employerId,
    String jobId, {
    int limit = 200,
  }) =>
      _refs
          .applications()
          .where('employerId', isEqualTo: employerId)
          .where('jobId', isEqualTo: jobId)
          .orderBy('applicationDate', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  Stream<List<ApplicationModel>> watchEmployerApplications(String employerId, {int limit = 200}) =>
      _refs
          .applications()
          .where('employerId', isEqualTo: employerId)
          .orderBy('applicationDate', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  // ── Internals ─────────────────────────────────────────────────────────
  void _assertValid(Map<String, String> errors, String message) {
    if (errors.isEmpty) return;
    throw Failure.validation(message, fieldErrors: errors);
  }

  /// Find by id, else case-insensitive name lookup, else create.
  Future<CategoryModel?> _resolveCategory(String? id, String name, WriteBatch batch) async {
    if (id != null && id.isNotEmpty) {
      final d = await _refs.categories().doc(id).get();
      if (d.exists) return d.data();
    }
    final n = name.trim();
    if (n.isEmpty) return null;
    final q = await _refs.categories().where('nameLower', isEqualTo: n.toLowerCase()).limit(1).get();
    if (q.docs.isNotEmpty) return q.docs.first.data();
    final doc = _refs.categories().doc();
    final created = CategoryModel(categoryId: doc.id, name: n);
    batch.set(doc, created);
    return created;
  }

  /// Upsert into skills (skillNameLower) → JobSkillRef rows
  /// (isRequired true, minExperienceYears 0, weight 1).
  Future<List<JobSkillRef>> _upsertSkills(List<String> names, WriteBatch batch) async {
    if (names.isEmpty) return const [];
    final existing = <String, SkillModel>{};
    final lowers = names.map((n) => n.toLowerCase()).toList();
    for (var i = 0; i < lowers.length; i += 30) {
      final chunk = lowers.sublist(i, i + 30 > lowers.length ? lowers.length : i + 30);
      final snap = await _refs.skills().where('skillNameLower', whereIn: chunk).get();
      for (final d in snap.docs) {
        existing[d.data().skillName.toLowerCase()] = d.data();
      }
    }
    final out = <JobSkillRef>[];
    for (final name in names) {
      final found = existing[name.toLowerCase()];
      if (found != null) {
        out.add(JobSkillRef(skillId: found.skillId, skillName: found.skillName));
      } else {
        // Deterministic id shared with ProfileRepository / AdminRepository so
        // the same skill name always maps to one skills/{id} document.
        final id = slugId('skill', name);
        batch.set(_refs.skills().doc(id), SkillModel(skillId: id, skillName: name));
        existing[name.toLowerCase()] = SkillModel(skillId: id, skillName: name);
        out.add(JobSkillRef(skillId: id, skillName: name));
      }
    }
    return out;
  }
}

final employerRepositoryProvider = Provider<EmployerRepository>(
  (ref) => EmployerRepository(
    ref.watch(firestoreRefsProvider),
    ref.watch(systemConfigRepositoryProvider),
    ref.watch(storageServiceProvider),
  ),
);
