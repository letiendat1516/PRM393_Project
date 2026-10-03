import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../shared/models/job_model.dart';
import '../data/home_repository.dart';

/// Live featured jobs (Firestore public jobs topped up with demo data).
final featuredJobsProvider = StreamProvider.autoDispose<List<JobModel>>(
  (ref) => ref.watch(homeRepositoryProvider).watchFeaturedJobs(),
);

/// Verified employers for the "Top companies" grid (demo fallback).
final topCompaniesProvider = StreamProvider.autoDispose<List<TopCompanyItem>>(
  (ref) => ref.watch(homeRepositoryProvider).watchTopCompanies(),
);

/// Selected chip of the featured-jobs category row (`AppConfig.homeCategoryChips`).
final featuredCategoryProvider =
    StateProvider.autoDispose<String>((_) => AppConfig.homeCategoryChips.first);

/// Featured jobs filtered client-side by the selected category chip.
final filteredFeaturedJobsProvider = Provider.autoDispose<AsyncValue<List<JobModel>>>((ref) {
  final category = ref.watch(featuredCategoryProvider);
  return ref
      .watch(featuredJobsProvider)
      .whenData((jobs) => HomeCategoryFilter.apply(jobs, category));
});

/// Maps the homepage chips onto `categoryName` / title keywords.
class HomeCategoryFilter {
  const HomeCategoryFilter._();

  static const Map<String, List<String>> _keywords = {
    'Công nghệ thông tin': ['công nghệ', 'it -', 'it–', 'devops', 'phần mềm', 'developer', 'lập trình', 'kỹ sư'],
    'Kinh doanh': ['kinh doanh', 'sales'],
    'Marketing': ['marketing', 'content'],
    'Tài chính – Kế toán': ['kế toán', 'tài chính', 'ngân hàng', 'tín dụng'],
    'Nhân sự': ['nhân sự'],
  };

  static bool matches(JobModel job, String category) {
    if (category == AppConfig.homeCategoryChips.first) return true;
    final keys = _keywords[category];
    if (keys == null) return true;
    final cat = (job.categoryName ?? '').toLowerCase();
    final title = job.jobTitle.toLowerCase();
    if (category == 'Công nghệ thông tin' && cat.startsWith('it')) return true;
    return keys.any((k) => cat.contains(k) || title.contains(k));
  }

  static List<JobModel> apply(List<JobModel> jobs, String category) =>
      jobs.where((j) => matches(j, category)).toList();
}
