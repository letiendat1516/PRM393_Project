import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/models/resume_model.dart';
import '../data/profile_repository.dart';

/// Signed-in Firebase uid (null when logged out).
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// jobSeekerProfiles/{uid} live document (GET /job-seekers/me).
final jobSeekerProfileProvider =
    StreamProvider.autoDispose<JobSeekerProfile?>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(null);
  return ref.watch(profileRepositoryProvider).watchProfile(uid);
});

/// GET /resumes/me — ordered isPrimary DESC, uploadDate DESC.
final myResumesProvider = StreamProvider.autoDispose<List<ResumeModel>>((ref) {
  final uid = ref.watch(currentUidProvider);
  if (uid == null) return Stream.value(const []);
  return ref.watch(profileRepositoryProvider).watchResumes(uid);
});

/// Single resume doc (AI analysis screen).
final resumeProvider =
    StreamProvider.autoDispose.family<ResumeModel?, String>((ref, resumeId) {
  return ref.watch(profileRepositoryProvider).watchResume(resumeId);
});

/// Analysis history for one resume (latest first).
final resumeAnalysesProvider =
    StreamProvider.autoDispose.family<List<AiAnalysis>, String>((ref, resumeId) {
  return ref.watch(profileRepositoryProvider).watchAnalyses(resumeId);
});

/// The seeker's primary CV, if any.
final primaryResumeProvider = Provider.autoDispose<ResumeModel?>((ref) {
  final list = ref.watch(myResumesProvider).valueOrNull ?? const [];
  for (final r in list) {
    if (r.isPrimary) return r;
  }
  return list.isEmpty ? null : list.first;
});
