import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/models/user_model.dart';

/// GET /applications/apply-context/:jobId — everything ApplyModal needs to
/// decide whether the seeker may apply (ApplicationService.getApplyContext).
class ApplyContext {
  const ApplyContext({
    required this.profile,
    required this.resumes,
    required this.job,
    required this.alreadyApplied,
  });

  final JobSeekerProfile profile;

  /// Ordered isPrimary DESC, uploadDate DESC (backend ordering).
  final List<ResumeModel> resumes;
  final JobModel job;
  final bool alreadyApplied;

  /// Resume used when none is explicitly selected: primary else first.
  ResumeModel? get defaultResume => resumes.isEmpty ? null : resumes.first;

  ResumeModel? resumeById(String? id) {
    if (id == null) return defaultResume;
    for (final r in resumes) {
      if (r.resumeId == id) return r;
    }
    return defaultResume;
  }
}

/// `['full_name', 'headline', 'city'].filter((key) => !profile[key])` —
/// ApplyModal.jsx:39-40 and ApplicationService.js:35 both surface the raw
/// snake_case keys ('Hồ sơ còn thiếu: full_name, headline, city.').
/// Derived from [JobSeekerProfile.missingRequiredFields] so the model stays
/// the single source of truth for *which* fields are required.
List<String> missingProfileKeys(JobSeekerProfile profile) {
  const keyOf = <String, String>{
    'họ tên': 'full_name',
    'chức danh': 'headline',
    'thành phố': 'city',
  };
  return [for (final f in profile.missingRequiredFields) keyOf[f] ?? f];
}

/// Firestore access for the application module (ApplicationService.js parity).
class ApplicationsRepository {
  ApplicationsRepository(this._refs);
  final FirestoreRefs _refs;

  static const notFoundMessage = 'Không tìm thấy hồ sơ ứng tuyển.';
  static const jobNotFoundMessage = 'Không tìm thấy công việc.';

  // ── Reads ────────────────────────────────────────────────────────────

  /// `null` when the job is missing OR not readable by this user (closed /
  /// unapproved jobs are denied by firestore.rules) — callers answer the web
  /// 404 'Không tìm thấy công việc.' instead of a permissions message.
  Future<JobModel?> getJob(String jobId) async {
    try {
      final snap = await _refs.jobs().doc(jobId).get();
      return snap.data();
    } catch (e) {
      final f = Failure.from(e);
      if (f.code == 'FORBIDDEN' || f.code == 'NOT_FOUND') return null;
      throw f;
    }
  }

  Future<JobSeekerProfile?> getProfile(String uid) async {
    final snap = await _refs.jobSeekerProfiles().doc(uid).get();
    return snap.data();
  }

  /// Resumes of a seeker ordered isPrimary DESC, uploadDate DESC.
  Future<List<ResumeModel>> getResumes(String uid, {String? primaryResumeId}) async {
    final snap = await _refs.resumes().where('jobSeekerId', isEqualTo: uid).get();
    final list = snap.docs.map((d) => d.data()).toList();
    bool isPrimary(ResumeModel r) => r.isPrimary || r.resumeId == primaryResumeId;
    list.sort((a, b) {
      final p = (isPrimary(b) ? 1 : 0) - (isPrimary(a) ? 1 : 0);
      if (p != 0) return p;
      final da = a.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      final db = b.uploadDate ?? DateTime.fromMillisecondsSinceEpoch(0);
      return db.compareTo(da);
    });
    return list;
  }

  /// ApplicationRepository.findDuplicate — a filtered query (two equality
  /// filters, no composite index) rather than a doc-get, so the `list` rule
  /// (jobSeekerId == uid) authorises it even before the doc exists.
  Future<bool> hasApplied(String seekerUid, String jobId) async {
    final snap = await _refs
        .applications()
        .where('jobSeekerId', isEqualTo: seekerUid)
        .where('jobId', isEqualTo: jobId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  /// ApplicationService.getApplyContext: profile + resumes + job + duplicate.
  Future<ApplyContext> getApplyContext({
    required String seekerUid,
    required String jobId,
  }) async {
    final results = await Future.wait<Object?>([
      getProfile(seekerUid),
      getJob(jobId),
      hasApplied(seekerUid, jobId),
    ]);
    final profile = results[0] as JobSeekerProfile?;
    final job = results[1] as JobModel?;
    final applied = results[2] as bool;
    if (profile == null) {
      throw const Failure.notFound('Không tìm thấy hồ sơ ứng viên.');
    }
    if (job == null) throw const Failure.notFound(jobNotFoundMessage);
    final resumes = await getResumes(seekerUid, primaryResumeId: profile.primaryResumeId);
    return ApplyContext(
      profile: profile,
      resumes: resumes,
      job: job,
      alreadyApplied: applied,
    );
  }

  /// Live set of jobIds the seeker has applied to (JobListItem `applied`).
  Stream<Set<String>> watchAppliedJobIds(String seekerUid) => _refs
      .applications()
      .where('jobSeekerId', isEqualTo: seekerUid)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data().jobId).toSet());

  /// All applications of a seeker, newest first (listMine without filters —
  /// status/keyword/sort/pagination are applied in the viewmodel).
  Stream<List<ApplicationModel>> watchMine(String seekerUid) => _refs
      .applications()
      .where('jobSeekerId', isEqualTo: seekerUid)
      .orderBy('applicationDate', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList());

  /// listForEmployer: `employerUid == null` ⇒ admin sees every application.
  Stream<List<ApplicationModel>> watchForEmployer(String? employerUid) {
    Query<ApplicationModel> q = _refs.applications();
    if (employerUid != null) q = q.where('employerId', isEqualTo: employerUid);
    return q
        .orderBy('applicationDate', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList());
  }

  Stream<ApplicationModel?> watchOne(String applicationId) =>
      _refs.applications().doc(applicationId).snapshots().map((s) => s.data());

  Stream<List<ApplicationStatusHistoryItem>> watchHistory(String applicationId) =>
      _refs
          .statusHistory(applicationId)
          .orderBy('changedAt')
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList());

  /// Most recent job_recommendation for (seeker, job) — deterministic doc id.
  /// Readable by the seeker owner, employers and admins (firestore.rules).
  Future<JobRecommendation?> latestRecommendation(String seekerUid, String jobId) async {
    final snap = await _refs
        .jobRecommendations()
        .doc(JobRecommendation.docIdFor(seekerUid, jobId))
        .get();
    return snap.data();
  }

  /// Best-effort read used when applying: a missing / unreadable
  /// recommendation must never block the application.
  Future<JobRecommendation?> _recommendationOrNull(String seekerUid, String jobId) async {
    try {
      return await latestRecommendation(seekerUid, jobId);
    } catch (_) {
      return null;
    }
  }

  // ── Apply ────────────────────────────────────────────────────────────

  /// Backend compares yyyy-mm-dd strings: a deadline equal to today is OK.
  static bool deadlinePassed(JobModel job) {
    final d = job.applicationDeadline;
    if (d == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return DateTime(d.year, d.month, d.day).isBefore(today);
  }

  /// ApplicationService.applyJob — ordered gates, then ONE transaction that
  /// creates the application, the genesis statusHistory row, increments
  /// jobs.applicationsCount and notifies the employer (NEW_APPLICATION).
  Future<ApplicationModel> apply({
    required UserModel seeker,
    required JobSeekerProfile profile,
    required JobModel job,
    required ResumeModel resume,
    String coverLetter = '',
  }) async {
    if (!seeker.isJobSeeker) {
      throw const Failure.forbidden('Chỉ tài khoản ứng viên mới có thể ứng tuyển.');
    }
    if (!seeker.isActive || !profile.isActive) {
      throw const Failure.forbidden('Tài khoản đã bị vô hiệu hóa.');
    }
    // Backend: `Hồ sơ chưa đầy đủ: ${missing.join(', ')}.` with raw keys.
    final missing = missingProfileKeys(profile);
    if (missing.isNotEmpty) {
      throw Failure.validation('Hồ sơ chưa đầy đủ: ${missing.join(', ')}.');
    }
    final letter = coverLetter.trim();
    if (letter.length > 5000) {
      throw const Failure.validation('Thư giới thiệu tối đa 5000 ký tự.');
    }

    final appId = ApplicationModel.docIdFor(seeker.uid, job.jobId);
    final appRef = _refs.applications().doc(appId);
    final jobRef = _refs.jobs().doc(job.jobId);
    final historyRef = _refs.statusHistory(appId).doc();
    final notifRef = _refs.db.collection(FirestoreRefs.colNotifications).doc();
    final now = DateTime.now();

    final candidateName =
        (profile.fullName ?? '').trim().isNotEmpty ? profile.fullName!.trim() : seeker.fullName;

    // Denormalise the (seeker, job) AI recommendation onto the application so
    // the employer review card ('Thông tin phù hợp') has a fallback even when
    // the live jobRecommendations read is unavailable.
    final recommendation = await _recommendationOrNull(seeker.uid, job.jobId);

    return _refs.db.runTransaction<ApplicationModel>((tx) async {
      final jobSnap = await tx.get(jobRef);
      final freshJob = jobSnap.data();
      if (freshJob == null) throw const Failure.notFound(jobNotFoundMessage);
      if (!freshJob.isPublic) {
        throw const Failure.validation('Công việc không còn nhận hồ sơ.');
      }
      if (deadlinePassed(freshJob)) {
        throw const Failure.validation('Công việc đã hết hạn ứng tuyển.');
      }
      final dup = await tx.get(appRef);
      if (dup.exists) {
        throw const Failure.conflict('Bạn đã ứng tuyển công việc này.', 'DUPLICATE_APPLICATION');
      }

      final application = ApplicationModel(
        applicationId: appId,
        jobId: freshJob.jobId,
        jobSeekerId: seeker.uid,
        employerId: freshJob.employerId,
        resumeId: resume.resumeId,
        // Web: `resume.title || resume.file_name` (MyApplicationsPage.jsx:95,164).
        resumeFileName: resume.title.trim().isNotEmpty ? resume.title.trim() : resume.fileName,
        resumeUrl: resume.downloadUrl,
        coverLetter: letter.isEmpty ? null : letter,
        applicationDate: now,
        status: ApplicationStatus.submitted,
        updatedAt: now,
        jobTitle: freshJob.jobTitle,
        companyName: freshJob.employerName,
        candidateFullName: candidateName,
        candidateHeadline: profile.headline,
        candidateCity: profile.city,
        candidateEmail: seeker.email,
        matchScore: recommendation?.matchScore,
        recommendationReason: recommendation?.recommendationReason,
      );
      final genesis = ApplicationStatusHistoryItem(
        historyId: historyRef.id,
        applicationId: appId,
        oldStatus: null,
        newStatus: ApplicationStatus.submitted,
        changedBy: seeker.uid,
        changedByRole: UserRole.jobSeeker,
        changedAt: now,
      );

      tx.set(appRef, application);
      tx.set(historyRef, genesis);
      tx.update(jobRef, {
        'applicationsCount': FieldValue.increment(1),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        notifRef,
        _notificationJson(
          NotificationModel(
            notificationId: notifRef.id,
            recipientId: freshJob.employerId,
            recipientRole: UserRole.employer,
            type: NotificationType.newApplication,
            title: 'Có ứng viên mới',
            message: '$candidateName đã ứng tuyển "${freshJob.jobTitle}".',
            data: {
              'applicationId': appId,
              'jobId': freshJob.jobId,
              'jobSeekerId': seeker.uid,
            },
          ),
        ),
      );
      return application;
    });
  }

  // ── Status transitions ───────────────────────────────────────────────

  /// PATCH /applications/employer/:id/status — optimistic concurrency +
  /// transition matrix enforced inside one transaction, which also appends
  /// the statusHistory row and notifies the candidate (APPLICATION_STATUS).
  Future<void> updateStatus({
    required String applicationId,
    required ApplicationStatus expectedCurrentStatus,
    required ApplicationStatus newStatus,
    required UserModel actor,
    String? note,
  }) async {
    if (!actor.isEmployer && !actor.isAdmin) {
      throw const Failure.forbidden('Bạn không có quyền cập nhật hồ sơ này.');
    }
    final appRef = _refs.applications().doc(applicationId);
    final historyRef = _refs.statusHistory(applicationId).doc();
    final notifRef = _refs.db.collection(FirestoreRefs.colNotifications).doc();
    final trimmedNote = (note ?? '').trim();
    final now = DateTime.now();

    await _refs.db.runTransaction<void>((tx) async {
      final snap = await tx.get(appRef);
      final app = snap.data();
      if (app == null) throw const Failure.notFound(notFoundMessage);
      if (!actor.isAdmin && app.employerId != actor.uid) {
        throw const Failure.forbidden('Bạn không có quyền cập nhật hồ sơ này.');
      }
      if (app.status != expectedCurrentStatus) {
        throw const Failure.conflict(
            'Hồ sơ đã được cập nhật. Vui lòng tải lại.', 'APPLICATION_STATUS_CONFLICT');
      }
      final allowed = ApplicationModel.transitions[app.status] ?? const [];
      if (!allowed.contains(newStatus)) {
        throw const Failure.validation('Chuyển trạng thái không hợp lệ.');
      }

      tx.update(appRef, {
        'status': enumToWire(newStatus),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      tx.set(
        historyRef,
        ApplicationStatusHistoryItem(
          historyId: historyRef.id,
          applicationId: applicationId,
          oldStatus: app.status,
          newStatus: newStatus,
          changedBy: actor.uid,
          changedByRole: actor.isAdmin ? UserRole.admin : UserRole.employer,
          changedAt: now,
          note: trimmedNote.isEmpty ? null : trimmedNote,
        ),
      );
      tx.set(
        notifRef,
        _notificationJson(
          NotificationModel(
            notificationId: notifRef.id,
            recipientId: app.jobSeekerId,
            recipientRole: UserRole.jobSeeker,
            type: NotificationType.applicationStatus,
            title: 'Hồ sơ ứng tuyển được cập nhật',
            message:
                'Hồ sơ ứng tuyển "${app.jobTitle}" đã chuyển sang trạng thái ${newStatus.label}.',
            data: {
              'applicationId': applicationId,
              'jobId': app.jobId,
              'status': enumToWire(newStatus),
            },
          ),
        ),
      );
    });
  }

  /// Converts [NotificationModel] into the Firestore map used by `tx.set`
  /// inside apply/updateStatus transactions. The legacy `recipientUid`
  /// alias was dead (no reader queried it) and has been removed.
  static Map<String, dynamic> _notificationJson(NotificationModel n) =>
      n.toJson();
}

final applicationsRepositoryProvider = Provider<ApplicationsRepository>(
  (ref) => ApplicationsRepository(ref.watch(firestoreRefsProvider)),
);
