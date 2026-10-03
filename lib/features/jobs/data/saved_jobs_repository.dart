import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/misc_models.dart';

/// savedJobs/{jobSeekerId_jobId} — table saved_job. Each doc embeds a
/// `jobSnapshot` so the saved list renders without N extra reads.
class SavedJobsRepository {
  SavedJobsRepository(this._refs);
  final FirestoreRefs _refs;

  /// Newest saved first. Needs composite index savedJobs(jobSeekerId asc,
  /// savedAt desc).
  Stream<List<SavedJob>> watchSaved(String seekerUid) => _refs
      .savedJobs()
      .where('jobSeekerId', isEqualTo: seekerUid)
      .orderBy('savedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map((d) => d.data()).toList())
      .handleError((Object e) => throw Failure.from(e));

  Future<bool> isSaved(String seekerUid, String jobId) async {
    try {
      final snap = await _refs
          .savedJobs()
          .doc(SavedJob.docIdFor(seekerUid, jobId))
          .get();
      return snap.exists;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> save(String seekerUid, JobModel job) async {
    try {
      await _refs
          .savedJobs()
          .doc(SavedJob.docIdFor(seekerUid, job.jobId))
          .set(
            SavedJob(
              jobSeekerId: seekerUid,
              jobId: job.jobId,
              jobSnapshot: snapshotOf(job),
            ),
          );
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> remove(String seekerUid, String jobId) async {
    try {
      await _refs.savedJobs().doc(SavedJob.docIdFor(seekerUid, jobId)).delete();
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Plain-data copy of [JobModel.toJson] (no FieldValue sentinels) that
  /// round-trips through [JobModel.fromJson].
  static Map<String, dynamic> snapshotOf(JobModel job) {
    final m = job.toJson()
      ..remove('updatedAt')
      ..remove('createdAt');
    if (job.createdAt != null) {
      m['createdAt'] = Timestamp.fromDate(job.createdAt!);
    }
    if (job.updatedAt != null) {
      m['updatedAt'] = Timestamp.fromDate(job.updatedAt!);
    }
    return m;
  }

  static JobModel jobFromSaved(SavedJob s) {
    if (s.jobSnapshot.isEmpty) {
      return JobModel(
        jobId: s.jobId,
        employerId: '',
        employerName: 'Công ty chưa cập nhật',
        jobTitle: 'Tin tuyển dụng chưa có tiêu đề',
      );
    }
    return JobModel.fromJson({...s.jobSnapshot, 'jobId': s.jobId});
  }
}

final savedJobsRepositoryProvider = Provider<SavedJobsRepository>(
  (ref) => SavedJobsRepository(ref.watch(firestoreRefsProvider)),
);
