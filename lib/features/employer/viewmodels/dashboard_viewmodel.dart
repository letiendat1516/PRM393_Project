import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import 'employer_providers.dart';

/// Aggregates computed client-side from the live jobs + applications streams.
class DashboardStats {
  const DashboardStats({
    required this.jobs,
    required this.applications,
    required this.openJobs,
    required this.pendingJobs,
    required this.totalApplications,
    required this.newLast7Days,
    required this.acceptanceRate,
    required this.byStatus,
    required this.recent,
    required this.applicationsByJob,
  });

  final List<JobModel> jobs;
  final List<ApplicationModel> applications;
  final int openJobs;
  final int pendingJobs;
  final int totalApplications;
  final int newLast7Days;
  /// accepted / (accepted + rejected) — null when nothing decided yet.
  final double? acceptanceRate;
  /// Only the 4 statuses exposed by the backend workflow.
  final Map<ApplicationStatus, int> byStatus;
  final List<ApplicationModel> recent;
  /// jobId → applications (for the "top jobs" list).
  final Map<String, int> applicationsByJob;

  static const chartStatuses = [
    ApplicationStatus.submitted,
    ApplicationStatus.underReview,
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  ];

  String get acceptanceRateLabel =>
      acceptanceRate == null ? '—' : '${(acceptanceRate! * 100).round()}%';

  factory DashboardStats.compute(List<JobModel> jobs, List<ApplicationModel> apps) {
    final weekAgo = DateTime.now().subtract(const Duration(days: 7));
    final byStatus = {for (final s in chartStatuses) s: 0};
    final byJob = <String, int>{};
    var newCount = 0;
    for (final a in apps) {
      if (byStatus.containsKey(a.status)) byStatus[a.status] = byStatus[a.status]! + 1;
      byJob[a.jobId] = (byJob[a.jobId] ?? 0) + 1;
      if (a.applicationDate != null && a.applicationDate!.isAfter(weekAgo)) newCount++;
    }
    final accepted = byStatus[ApplicationStatus.accepted]!;
    final rejected = byStatus[ApplicationStatus.rejected]!;
    final decided = accepted + rejected;
    final sorted = [...apps]..sort((a, b) {
        final da = a.applicationDate ?? DateTime(2000);
        final db = b.applicationDate ?? DateTime(2000);
        return db.compareTo(da);
      });
    return DashboardStats(
      jobs: jobs,
      applications: apps,
      openJobs: jobs.where((j) => j.isPublic).length,
      pendingJobs: jobs.where((j) => j.isPendingReview).length,
      totalApplications: apps.length,
      newLast7Days: newCount,
      acceptanceRate: decided == 0 ? null : accepted / decided,
      byStatus: byStatus,
      recent: sorted.take(6).toList(),
      applicationsByJob: byJob,
    );
  }

  /// Jobs ranked by applications received (top 5).
  List<(JobModel, int)> get topJobs {
    final list = [for (final j in jobs) (j, applicationsByJob[j.jobId] ?? j.applicationsCount)]
      ..sort((a, b) => b.$2.compareTo(a.$2));
    return list.take(5).toList();
  }
}

/// Combines the two streams; loading while either is loading, error if any.
final employerDashboardProvider = Provider.autoDispose<AsyncValue<DashboardStats>>((ref) {
  final jobs = ref.watch(employerJobsProvider);
  final apps = ref.watch(employerAllApplicationsProvider);
  if (jobs.hasError) return AsyncValue.error(jobs.error!, jobs.stackTrace ?? StackTrace.current);
  if (apps.hasError) return AsyncValue.error(apps.error!, apps.stackTrace ?? StackTrace.current);
  if (jobs.isLoading || apps.isLoading) return const AsyncValue.loading();
  return AsyncValue.data(
      DashboardStats.compute(jobs.valueOrNull ?? const [], apps.valueOrNull ?? const []));
});
