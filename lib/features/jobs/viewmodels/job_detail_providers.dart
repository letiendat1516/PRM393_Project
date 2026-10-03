import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/job_model.dart';
import '../data/jobs_repository.dart';

/// jobs/{id} (mock-first). `null` → not found state (missing doc, or a
/// CLOSED / unapproved job the rules hide from this viewer).
final jobDetailProvider = StreamProvider.autoDispose.family<JobModel?, String>((
  ref,
  jobId,
) {
  return ref.watch(jobsRepositoryProvider).watchJob(jobId);
});
