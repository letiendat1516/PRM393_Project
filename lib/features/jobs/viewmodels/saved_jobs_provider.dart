import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/misc_models.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/saved_jobs_repository.dart';

/// Saved jobs of the signed-in seeker (empty stream for guests / other roles).
/// Stays in `AsyncLoading` while the user document itself is still loading so
/// pages do not flash their empty state on cold start.
final savedJobsStreamProvider = StreamProvider<List<SavedJob>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.isLoading) return const Stream.empty();
  final me = user.valueOrNull;
  if (me == null || !me.isJobSeeker) return Stream.value(const []);
  return ref.watch(savedJobsRepositoryProvider).watchSaved(me.uid);
});

/// Cross-feature contract: set of saved jobIds for bookmark state.
final savedJobIdsProvider = StreamProvider<Set<String>>((ref) {
  final user = ref.watch(currentUserProvider);
  if (user.isLoading) return const Stream.empty();
  final me = user.valueOrNull;
  if (me == null || !me.isJobSeeker) return Stream.value(const <String>{});
  return ref
      .watch(savedJobsRepositoryProvider)
      .watchSaved(me.uid)
      .map((list) => list.map((s) => s.jobId).toSet());
});

/// Cross-feature contract: toggles savedJobs/{seekerUid_jobId} (with a
/// jobSnapshot) for the current seeker. Throws [Failure] when the caller is a
/// guest (401) or not a job seeker (403) so views can prompt accordingly.
///
/// The decision is taken from the already-streamed [savedJobIdsProvider] set
/// (no extra `get` on a possibly missing document).
Future<void> toggleSavedJob(WidgetRef ref, JobModel job) async {
  final me = ref.read(currentUserProvider).valueOrNull;
  if (me == null) {
    throw const Failure.unauthorized('Vui lòng đăng nhập để lưu tin.');
  }
  if (me.role != UserRole.jobSeeker) {
    throw const Failure.forbidden('Chỉ tài khoản ứng viên mới có thể lưu tin.');
  }
  final repo = ref.read(savedJobsRepositoryProvider);
  final isSaved =
      ref.read(savedJobIdsProvider).valueOrNull?.contains(job.jobId) ?? false;
  if (isSaved) {
    await repo.remove(me.uid, job.jobId);
  } else {
    await repo.save(me.uid, job);
  }
}

/// Removes a saved job (SavedJobsPage swipe-to-delete).
Future<void> removeSavedJob(WidgetRef ref, String jobId) async {
  final me = ref.read(currentUserProvider).valueOrNull;
  if (me == null) {
    throw const Failure.unauthorized('Vui lòng đăng nhập để lưu tin.');
  }
  await ref.read(savedJobsRepositoryProvider).remove(me.uid, jobId);
}
