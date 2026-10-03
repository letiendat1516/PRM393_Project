import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/employer_repository.dart';

/// employerProfiles/{uid} of the signed-in employer (live).
final employerProfileProvider = StreamProvider.autoDispose<EmployerProfile?>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return Stream.value(null);
  return ref.watch(employerRepositoryProvider).watchProfile(me.uid);
});

/// GET /jobs/my-postings — every status, newest first.
final employerJobsProvider = StreamProvider.autoDispose<List<JobModel>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return Stream.value(const []);
  return ref.watch(employerRepositoryProvider).watchMyJobs(me.uid);
});

/// Single job document (edit page / applicants page header).
final employerJobProvider =
    StreamProvider.autoDispose.family<JobModel?, String>((ref, jobId) {
  return ref.watch(employerRepositoryProvider).watchJob(jobId);
});

/// applications where employerId == me && jobId == id
/// (GET /applications/employer?jobId=). The employerId filter is what lets
/// firestore.rules authorise the list query.
final jobApplicantsProvider =
    StreamProvider.autoDispose.family<List<ApplicationModel>, String>((ref, jobId) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return Stream.value(const []);
  return ref.watch(employerRepositoryProvider).watchJobApplicants(me.uid, jobId);
});

/// Every application addressed to the signed-in employer (dashboard stats).
final employerAllApplicationsProvider =
    StreamProvider.autoDispose<List<ApplicationModel>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null) return Stream.value(const []);
  return ref.watch(employerRepositoryProvider).watchEmployerApplications(me.uid);
});

/// Catalog (GET /jobs/categories, GET /jobs/skills).
final jobCategoriesProvider = StreamProvider.autoDispose<List<CategoryModel>>(
    (ref) => ref.watch(employerRepositoryProvider).watchCategories());

final jobSkillsProvider = StreamProvider.autoDispose<List<SkillModel>>(
    (ref) => ref.watch(employerRepositoryProvider).watchSkills());

/// MAX_SKILLS_PER_JOB (fallback 30).
final maxSkillsPerJobProvider = FutureProvider.autoDispose<int>(
    (ref) => ref.watch(employerRepositoryProvider).maxSkillsPerJob());

/// REQUIRE_JOB_APPROVAL (fallback true).
final requireJobApprovalProvider = FutureProvider.autoDispose<bool>(
    (ref) => ref.watch(employerRepositoryProvider).requireJobApproval());

/// Filter chips on EmployerJobsPage.
enum EmployerJobsFilter { all, open, pending, closed, rejected }

extension EmployerJobsFilterLabel on EmployerJobsFilter {
  String get label => switch (this) {
        EmployerJobsFilter.all => 'Tất cả',
        EmployerJobsFilter.open => 'Đang hiển thị',
        EmployerJobsFilter.pending => 'Chờ duyệt',
        EmployerJobsFilter.closed => 'Đã đóng',
        EmployerJobsFilter.rejected => 'Bị từ chối',
      };

  bool matches(JobModel j) => switch (this) {
        EmployerJobsFilter.all => true,
        EmployerJobsFilter.open => j.isPublic,
        EmployerJobsFilter.pending => j.isPendingReview,
        EmployerJobsFilter.closed => j.status == JobStatus.closed && j.isApproved,
        EmployerJobsFilter.rejected => j.isRejected,
      };
}

final employerJobsFilterProvider =
    StateProvider.autoDispose<EmployerJobsFilter>((_) => EmployerJobsFilter.all);

/// Close / reopen / delete with per-job busy tracking. Throws [Failure].
class JobActionsNotifier extends StateNotifier<Set<String>> {
  JobActionsNotifier(this._ref) : super(const {});
  final Ref _ref;

  bool isBusy(String jobId) => state.contains(jobId);

  Future<void> _run(String jobId, Future<void> Function(EmployerRepository repo, String uid) fn) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) throw const Failure.unauthorized();
    state = {...state, jobId};
    try {
      await fn(_ref.read(employerRepositoryProvider), me.uid);
    } catch (e) {
      throw Failure.from(e);
    } finally {
      if (mounted) state = {...state}..remove(jobId);
    }
  }

  Future<void> close(String jobId) => _run(jobId, (r, uid) => r.closeJob(uid, jobId));
  Future<void> reopen(String jobId) => _run(jobId, (r, uid) => r.reopenJob(uid, jobId));
  Future<void> delete(String jobId) => _run(jobId, (r, uid) => r.deleteJob(uid, jobId));
}

final jobActionsProvider = StateNotifierProvider.autoDispose<JobActionsNotifier, Set<String>>(
    (ref) => JobActionsNotifier(ref));
