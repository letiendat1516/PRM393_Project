import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/user_model.dart';
import '../data/admin_repository.dart';
import '../data/ai_logs_repository.dart';

export '../data/admin_repository.dart' show adminRepositoryProvider, AdminCounts, SeedSummary;
export '../data/ai_logs_repository.dart' show aiLogsRepositoryProvider;

/// Live users per role (admin users page tabs).
final usersByRoleProvider = StreamProvider.family<List<UserModel>, UserRole>(
    (ref, role) => ref.watch(adminRepositoryProvider).watchUsersByRole(role));

/// Live employer profiles (verification page + company names on the users tab).
final employerProfilesProvider = StreamProvider<List<EmployerProfile>>(
    (ref) => ref.watch(adminRepositoryProvider).watchEmployerProfiles());

/// jobs DRAFT && !isApproved.
final pendingJobsProvider = StreamProvider<List<JobModel>>(
    (ref) => ref.watch(adminRepositoryProvider).watchPendingJobs());

final adminCategoriesProvider = StreamProvider<List<CategoryModel>>(
    (ref) => ref.watch(adminRepositoryProvider).watchCategories());

final adminSkillsProvider = StreamProvider<List<SkillModel>>(
    (ref) => ref.watch(adminRepositoryProvider).watchSkills());

/// aiMatchingLogs newest first, limited (100 for AiLogsPage, 200 for AiStatsPage).
final aiLogsProvider = StreamProvider.family<List<AiMatchingLog>, int>(
    (ref, limit) => ref.watch(aiLogsRepositoryProvider).watchRecent(limit: limit));

/// Dashboard counters (aggregation queries, refresh with `ref.invalidate`).
final adminCountsProvider =
    FutureProvider<AdminCounts>((ref) => ref.watch(adminRepositoryProvider).loadCounts());
