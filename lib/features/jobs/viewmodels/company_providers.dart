import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import '../data/jobs_repository.dart';

/// employerProfiles/{uid} for CompanyDetailPage (`null` → not found).
final companyProfileProvider = StreamProvider.autoDispose
    .family<EmployerProfile?, String>((ref, uid) {
      return ref.watch(jobsRepositoryProvider).watchEmployerProfile(uid);
    });

/// Public (approved + OPEN) jobs of one employer, newest first.
final companyJobsProvider = StreamProvider.autoDispose
    .family<List<JobModel>, String>((ref, uid) {
      return ref.watch(jobsRepositoryProvider).watchEmployerPublicJobs(uid);
    });
