import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/system_config_repository.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/slug.dart' as slug;
import '../../../shared/models/catalog_models.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/models/user_model.dart';

/// Aggregated counters for the admin dashboard.
class AdminCounts {
  const AdminCounts({
    required this.jobSeekers,
    required this.employers,
    required this.admins,
    required this.jobsByStatus,
    required this.pendingJobs,
    required this.applications,
  });

  final int jobSeekers;
  final int employers;
  final int admins;
  final Map<JobStatus, int> jobsByStatus;
  final int pendingJobs;
  final int applications;

  int get totalUsers => jobSeekers + employers + admins;
  int get totalJobs => jobsByStatus.values.fold(0, (a, b) => a + b);
  int get openJobs => jobsByStatus[JobStatus.open] ?? 0;
  int get closedJobs => jobsByStatus[JobStatus.closed] ?? 0;
}

/// Port of backend AdminRepository/AdminService + the admin parts of
/// JobService (moderation, catalog) and the demo seeding helper.
class AdminRepository {
  AdminRepository(this._refs, this._configs);

  final FirestoreRefs _refs;
  final SystemConfigRepository _configs;

  // ── Users (UC-17) ─────────────────────────────────────────────────────

  /// users where role == [role]; newest first (sorted client-side so no
  /// composite index is required).
  Stream<List<UserModel>> watchUsersByRole(UserRole role) => _refs
      .users()
      .where('role', isEqualTo: userRoleToWire(role))
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) => _desc(a.createdAt, b.createdAt));
        return list;
      });

  /// PATCH /admin/users/{job-seekers|employers}/:id/status — action
  /// activate|block → isActive on users/{uid}, mirrored into the profile doc.
  Future<void> setAccountActive({
    required String uid,
    required UserRole role,
    required bool active,
  }) async {
    final userRef = _refs.users().doc(uid);
    final snap = await userRef.get();
    if (!snap.exists) throw const Failure.notFound('Không tìm thấy tài khoản.');

    final profileCol = role == UserRole.employer
        ? FirestoreRefs.colEmployerProfiles
        : FirestoreRefs.colJobSeekerProfiles;
    final batch = _refs.db.batch();
    batch.update(userRef, {
      'isActive': active,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    batch.set(
      _refs.db.collection(profileCol).doc(uid),
      {'isActive': active, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
    await batch.commit();
  }

  // ── Employers (UC-18) ─────────────────────────────────────────────────

  Stream<List<EmployerProfile>> watchEmployerProfiles() => _refs
      .employerProfiles()
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) => _desc(a.createdAt, b.createdAt));
        return list;
      });

  /// PATCH /admin/employers/:id/verification — verify|unverify sets
  /// isVerified on users + employerProfiles. Like the backend
  /// (EmployerService.setVerification) this sends NO notification.
  Future<void> setEmployerVerified({
    required String uid,
    required bool verified,
  }) async {
    final profileSnap = await _refs.employerProfiles().doc(uid).get();
    final userSnap = await _refs.users().doc(uid).get();
    if (!profileSnap.exists && !userSnap.exists) {
      throw const Failure.notFound('Không tìm thấy nhà tuyển dụng.');
    }

    final batch = _refs.db.batch();
    final patch = {
      'isVerified': verified,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    // Demo-seeded employers have no users/{uid} doc; creating one here would be
    // rejected by firestore.rules (users create = owner only), so only update.
    if (userSnap.exists) {
      batch.update(_refs.db.collection(FirestoreRefs.colUsers).doc(uid), patch);
    }
    batch.set(_refs.db.collection(FirestoreRefs.colEmployerProfiles).doc(uid),
        patch, SetOptions(merge: true));
    await batch.commit();
  }

  // ── Pending jobs (moderation) ─────────────────────────────────────────

  /// GET /jobs/admin/pending-review — DRAFT && !isApproved, newest first.
  Stream<List<JobModel>> watchPendingJobs() => _refs
      .jobs()
      .where('status', isEqualTo: enumToWire(JobStatus.draft))
      .where('isApproved', isEqualTo: false)
      .snapshots()
      .map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) => _desc(a.createdAt, b.createdAt));
        return list;
      });

  /// PATCH /jobs/:id/moderate { decision: 'Approved' | 'Rejected' }.
  ///
  /// Runs in a Firestore transaction so the job status change and the
  /// employer notification commit atomically — matches the invariant used
  /// by apply/updateStatus in [ApplicationsRepository].
  Future<void> moderateJob(JobModel job, {required bool approve}) async {
    final ref = _refs.jobs().doc(job.jobId);
    final notifRef = _refs.db
        .collection(FirestoreRefs.colNotifications)
        .doc();

    await _refs.db.runTransaction<void>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw const Failure.notFound('Không tìm thấy tin tuyển dụng.');
      }
      tx.update(ref, {
        'status': enumToWire(approve ? JobStatus.open : JobStatus.closed),
        'isApproved': approve,
        'moderatedAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      if (job.employerId.isEmpty) return;
      final notif = NotificationModel(
        notificationId: notifRef.id,
        recipientId: job.employerId,
        recipientRole: UserRole.employer,
        type: approve
            ? NotificationType.jobApproved
            : NotificationType.jobRejected,
        title: approve
            ? 'Tin tuyển dụng đã được duyệt'
            : 'Tin tuyển dụng bị từ chối',
        message: approve
            ? 'Tin tuyển dụng "${job.jobTitle}" đã được duyệt và hiển thị công khai.'
            : 'Tin tuyển dụng "${job.jobTitle}" đã bị từ chối.',
        data: {
          'jobId': job.jobId,
          'decision': approve ? 'Approved' : 'Rejected',
        },
      );
      tx.set(notifRef, notif.toJson());
    });
  }

  // ── Admin → user notifications (compose + broadcast) ─────────────────
  //
  // Three audience modes:
  //   • everyone — fan-out one doc per user (batched)
  //   • by role  — same fan-out, scoped by the users.role field
  //   • specific uid — one doc write
  //
  // Fan-out writes one notifications/{id} doc per recipient so the shared
  // `notifications` collection stays the single query path
  // (watchForUser filters by recipientId + createdAt desc). A composite
  // index on (recipientId, createdAt) already exists.

  /// Compact DTO wrapping an admin-authored notification payload so the
  /// repository doesn't take 4 positional strings every time.
  // (local record alias)

  /// Look up `users/{uid}` by email (case-insensitive). Returns null when
  /// the email isn't registered — the caller surfaces a validation error
  /// instead of blowing up on an empty audience.
  Future<UserModel?> findUserByEmail(String email) async {
    final e = email.trim().toLowerCase();
    if (e.isEmpty) return null;
    final snap = await _refs
        .users()
        .where('email', isEqualTo: e)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.data();
  }

  /// Send one notification to a single [recipient].
  Future<void> sendNotificationToUser({
    required UserModel recipient,
    required String title,
    required String message,
  }) async {
    _validateComposeInput(title: title, message: message);
    final ref = _refs.db.collection(FirestoreRefs.colNotifications).doc();
    final notif = NotificationModel(
      notificationId: ref.id,
      recipientId: recipient.uid,
      recipientRole: recipient.role,
      type: NotificationType.system,
      title: title.trim(),
      message: message.trim(),
      data: const {'source': 'admin'},
    );
    await ref.set(notif.toJson());
  }

  /// Broadcast one notification to every user (optionally scoped by
  /// [role]). Fans out one notifications/{id} doc per recipient so each
  /// user's inbox query still works without special-casing a "global"
  /// doc. Returns the number of recipients written to. Batched at the
  /// Firestore limit (500) with a 50-doc safety margin.
  Future<int> broadcastNotification({
    required String title,
    required String message,
    UserRole? role,
  }) async {
    _validateComposeInput(title: title, message: message);
    final t = title.trim();
    final m = message.trim();

    Query<UserModel> q = _refs.users();
    if (role != null) {
      q = q.where('role', isEqualTo: userRoleToWire(role));
    }
    // Also skip blocked accounts — writing to them is pointless since
    // isActive=false users are signed out on next listen.
    q = q.where('isActive', isEqualTo: true);
    final snap = await q.get();
    if (snap.docs.isEmpty) return 0;

    const batchLimit = 450;
    var written = 0;
    final notifCol = _refs.db.collection(FirestoreRefs.colNotifications);

    for (var i = 0; i < snap.docs.length; i += batchLimit) {
      final slice = snap.docs.skip(i).take(batchLimit);
      final batch = _refs.db.batch();
      for (final userDoc in slice) {
        final user = userDoc.data();
        final notifRef = notifCol.doc();
        final notif = NotificationModel(
          notificationId: notifRef.id,
          recipientId: user.uid,
          recipientRole: user.role,
          type: NotificationType.system,
          title: t,
          message: m,
          data: const {'source': 'admin', 'broadcast': true},
        );
        batch.set(notifRef, notif.toJson());
        written++;
      }
      await batch.commit();
    }
    return written;
  }

  void _validateComposeInput({required String title, required String message}) {
    if (title.trim().isEmpty) {
      throw const Failure.validation('Vui lòng nhập tiêu đề thông báo.');
    }
    if (title.trim().length > 120) {
      throw const Failure.validation('Tiêu đề không được vượt quá 120 ký tự.');
    }
    if (message.trim().isEmpty) {
      throw const Failure.validation('Vui lòng nhập nội dung thông báo.');
    }
    if (message.trim().length > 1000) {
      throw const Failure.validation('Nội dung không được vượt quá 1000 ký tự.');
    }
  }

  // ── Catalog: categories ───────────────────────────────────────────────

  Stream<List<CategoryModel>> watchCategories() =>
      _refs.categories().snapshots().map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) => compareVi(a.name, b.name));
        return list;
      });

  Future<void> createCategory(String name) async {
    final n = _validateName(name, 'Vui lòng nhập tên ngành nghề.');
    await _assertUniqueCategory(n);
    final id = slugId('cat', n);
    await _refs.categories().doc(id).set(CategoryModel(categoryId: id, name: n));
  }

  Future<void> deleteCategory(String id) async {
    if (id.isEmpty) {
      throw const Failure.validation('Không xác định được mã ngành nghề cần xoá.');
    }
    await _refs.categories().doc(id).delete();
  }

  Future<void> _assertUniqueCategory(String name) async {
    final dup = await _refs
        .categories()
        .where('nameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw Failure.conflict('Ngành nghề "$name" đã tồn tại.');
    }
  }

  // ── Catalog: skills ───────────────────────────────────────────────────

  Stream<List<SkillModel>> watchSkills() => _refs.skills().snapshots().map((s) {
        final list = s.docs.map((d) => d.data()).toList();
        list.sort((a, b) => compareVi(a.skillName, b.skillName));
        return list;
      });

  Future<void> createSkill(String name) async {
    final n = _validateName(name, 'Vui lòng nhập tên kỹ năng.');
    await _assertUniqueSkill(n);
    final id = slugId('skill', n);
    await _refs.skills().doc(id).set(SkillModel(skillId: id, skillName: n));
  }

  Future<void> deleteSkill(String id) async {
    if (id.isEmpty) {
      throw const Failure.validation('Không xác định được mã kỹ năng cần xoá.');
    }
    await _refs.skills().doc(id).delete();
  }

  Future<void> _assertUniqueSkill(String name) async {
    final dup = await _refs
        .skills()
        .where('skillNameLower', isEqualTo: name.toLowerCase())
        .limit(1)
        .get();
    if (dup.docs.isNotEmpty) {
      throw Failure.conflict('Kỹ năng "$name" đã tồn tại.');
    }
  }

  // ── Dashboard counters ────────────────────────────────────────────────

  Future<AdminCounts> loadCounts() async {
    Future<int> count(Query<Object?> q) async => (await q.count().get()).count ?? 0;

    final users = _refs.users();
    final jobs = _refs.jobs();
    final results = await Future.wait<int>([
      count(users.where('role', isEqualTo: userRoleToWire(UserRole.jobSeeker))),
      count(users.where('role', isEqualTo: userRoleToWire(UserRole.employer))),
      count(users.where('role', isEqualTo: userRoleToWire(UserRole.admin))),
      for (final s in JobStatus.values) count(jobs.where('status', isEqualTo: enumToWire(s))),
      count(jobs
          .where('status', isEqualTo: enumToWire(JobStatus.draft))
          .where('isApproved', isEqualTo: false)),
      count(_refs.applications()),
    ]);

    final byStatus = <JobStatus, int>{};
    for (var i = 0; i < JobStatus.values.length; i++) {
      byStatus[JobStatus.values[i]] = results[3 + i];
    }
    return AdminCounts(
      jobSeekers: results[0],
      employers: results[1],
      admins: results[2],
      jobsByStatus: byStatus,
      pendingJobs: results[3 + JobStatus.values.length],
      applications: results[4 + JobStatus.values.length],
    );
  }

  // ── Demo seeding (idempotent, set + merge) ────────────────────────────

  /// Writes DemoData → categories, skills, employerProfiles, jobs and the
  /// default system configurations. Safe to run repeatedly.
  Future<SeedSummary> seedDemoData() async {
    final jobs = [...DemoData.sampleJobs(), ...DemoData.featuredJobs()];

    final existingEmployers = await _existingIds(FirestoreRefs.colEmployerProfiles);
    final existingJobs = await _existingIds(FirestoreRefs.colJobs);
    final existingSkills = await _existingIds(FirestoreRefs.colSkills);

    final ops = <({DocumentReference<Map<String, dynamic>> ref, Map<String, dynamic> data})>[];

    // categories
    final categoryIds = <String, String>{};
    for (final name in DemoData.categories) {
      final id = slugId('cat', name);
      categoryIds[name.toLowerCase()] = id;
      ops.add((
        ref: _refs.db.collection(FirestoreRefs.colCategories).doc(id),
        data: {'categoryId': id, 'name': name, 'nameLower': name.toLowerCase()},
      ));
    }
    for (final j in jobs) {
      final c = j.categoryName;
      if (c != null && !categoryIds.containsKey(c.toLowerCase())) {
        final id = slugId('cat', c);
        categoryIds[c.toLowerCase()] = id;
        ops.add((
          ref: _refs.db.collection(FirestoreRefs.colCategories).doc(id),
          data: {'categoryId': id, 'name': c, 'nameLower': c.toLowerCase()},
        ));
      }
    }

    // skills (union of all job tags)
    final skillNames = <String, String>{};
    for (final j in jobs) {
      for (final t in j.tags) {
        skillNames.putIfAbsent(t.toLowerCase(), () => t);
      }
    }
    for (final name in skillNames.values) {
      final id = slugId('skill', name);
      ops.add((
        ref: _refs.db.collection(FirestoreRefs.colSkills).doc(id),
        data: {
          'skillId': id,
          'skillName': name,
          'skillNameLower': name.toLowerCase(),
          if (!existingSkills.contains(id)) 'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        },
      ));
    }

    // employers (sampleEmployers + featured job companies)
    final employers = <String, EmployerProfile>{};
    for (final e in DemoData.sampleEmployers()) {
      employers[e.id] = EmployerProfile(
        uid: e.id,
        companyName: e.name,
        city: e.city,
        industry: e.industry,
        isVerified: true,
        isActive: true,
      );
    }
    for (final j in DemoData.featuredJobs()) {
      employers.putIfAbsent(
        j.employerId,
        () => EmployerProfile(
          uid: j.employerId,
          companyName: j.employerName,
          city: j.city,
          industry: j.categoryName,
          isVerified: true,
          isActive: true,
        ),
      );
    }
    for (final e in employers.values) {
      final data = e.toJson();
      data['openPositions'] = jobs.where((j) => j.employerId == e.uid).length;
      if (existingEmployers.contains(e.uid)) data.remove('createdAt');
      ops.add((
        ref: _refs.db.collection(FirestoreRefs.colEmployerProfiles).doc(e.uid),
        data: data,
      ));
    }

    // jobs
    for (final j in jobs) {
      final data = j.toJson();
      final catId = j.categoryName == null ? null : categoryIds[j.categoryName!.toLowerCase()];
      if (catId != null) data['categoryId'] = catId;
      data['status'] = enumToWire(JobStatus.open);
      data['isApproved'] = true;
      data['titleTokens'] = JobModel.tokenize(j.jobTitle, j.employerName);
      if (existingJobs.contains(j.jobId)) data.remove('createdAt');
      ops.add((ref: _refs.db.collection(FirestoreRefs.colJobs).doc(j.jobId), data: data));
    }

    // commit in chunks (Firestore batch limit is 500 writes)
    const chunk = 400;
    for (var i = 0; i < ops.length; i += chunk) {
      final batch = _refs.db.batch();
      for (final op in ops.skip(i).take(chunk)) {
        batch.set(op.ref, op.data, SetOptions(merge: true));
      }
      await batch.commit();
    }

    await _configs.ensureDefaults();

    return SeedSummary(
      categories: categoryIds.length,
      skills: skillNames.length,
      employers: employers.length,
      jobs: jobs.length,
    );
  }

  Future<Set<String>> _existingIds(String collection) async =>
      (await _refs.db.collection(collection).get()).docs.map((d) => d.id).toSet();

  // ── helpers ───────────────────────────────────────────────────────────

  static int _desc(DateTime? a, DateTime? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return b.compareTo(a);
  }

  static String _validateName(String raw, String emptyMessage) {
    final n = raw.trim();
    if (n.isEmpty) throw Failure.validation(emptyMessage);
    if (n.length > 100) {
      throw const Failure.validation('Tên không được vượt quá 100 ký tự.');
    }
    return n;
  }

  /// Deterministic doc id from a display name ('cat', 'IT - Công nghệ') →
  /// 'cat_it-cong-nghe'.
  /// Shared deterministic catalogue id — see lib/core/utils/slug.dart.
  static String slugId(String prefix, String name) => slug.slugId(prefix, name);

  /// Vietnamese-friendly ordering (`localeCompare(..., 'vi')` approximation):
  /// diacritics-insensitive first, then exact.
  static int compareVi(String a, String b) {
    final sa = JobModel.stripDiacritics(a.toLowerCase());
    final sb = JobModel.stripDiacritics(b.toLowerCase());
    final c = sa.compareTo(sb);
    return c != 0 ? c : a.compareTo(b);
  }
}

class SeedSummary {
  const SeedSummary({
    required this.categories,
    required this.skills,
    required this.employers,
    required this.jobs,
  });
  final int categories;
  final int skills;
  final int employers;
  final int jobs;
}

final adminRepositoryProvider = Provider<AdminRepository>((ref) => AdminRepository(
      ref.watch(firestoreRefsProvider),
      ref.watch(systemConfigRepositoryProvider),
    ));
