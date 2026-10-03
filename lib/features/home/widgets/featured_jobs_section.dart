import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:jobhub_prm393/features/jobs/viewmodels/saved_jobs_provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/job_list_item.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../applications/widgets/apply_modal.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/home_repository.dart';
import '../viewmodels/home_providers.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// HomePage.jsx §8.4 "Việc làm nổi bật" (`id="featured-jobs"`, bg-canvas):
/// split header + 'Xem tất cả việc làm', category chip row and a
/// 1 → 2 → 3 column grid of JobCards fed by [filteredFeaturedJobsProvider].
class FeaturedJobsSection extends ConsumerWidget {
  const FeaturedJobsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(filteredFeaturedJobsProvider);
    final category = ref.watch(featuredCategoryProvider);

    return Section(
      background: AppColors.canvas,
      verticalPadding: homeSectionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Reveal(
            child: SplitSectionHeader(
              eyebrow: 'Việc làm nổi bật',
              title: 'Cơ hội việc làm hàng đầu dành cho bạn',
              description:
                  'Những vị trí đang được tuyển dụng gấp, được AI đánh giá phù hợp với nhiều nhóm kỹ năng khác nhau.',
              actionLabel: 'Xem tất cả việc làm',
              onAction: () => context.push(AppRoutes.jobs),
            ),
          ),
          const SizedBox(height: 32),
          Reveal(
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final chip in AppConfig.homeCategoryChips)
                  AppChip(
                    label: chip,
                    selected: chip == category,
                    variant: chip == category ? AppChipVariant.neutral : AppChipVariant.outline,
                    onTap: () => ref.read(featuredCategoryProvider.notifier).state = chip,
                  ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          jobs.when(
            skipLoadingOnReload: true,
            loading: () => const SizedBox(
              height: 240,
              child: RouteLoader(label: 'Đang tải việc làm nổi bật...'),
            ),
            error: (e, _) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AlertError(
                  message: Failure.from(e).message,
                  onRetry: () => ref.invalidate(featuredJobsProvider),
                ),
                const SizedBox(height: 20),
                _JobsGrid(
                  jobs: HomeCategoryFilter.apply(HomeRepository.mergeWithDemo(const []), category),
                ),
              ],
            ),
            data: (list) {
              if (list.isEmpty) {
                final all = category == AppConfig.homeCategoryChips.first;
                return EmptyState(
                  icon: Icons.work_outline,
                  title: all ? 'Chưa có việc làm nào được đăng.' : 'Chưa có việc làm phù hợp trong nhóm này.',
                  subtitle: all ? null : 'Thử chọn một nhóm ngành khác hoặc xem tất cả việc làm.',
                  action: all
                      ? OutlinedButton(
                          onPressed: () => context.push(AppRoutes.jobs),
                          child: const Text('Xem tất cả việc làm'),
                        )
                      : TextButton(
                          onPressed: () => ref.read(featuredCategoryProvider.notifier).state =
                              AppConfig.homeCategoryChips.first,
                          child: const Text('Tất cả'),
                        ),
                );
              }
              return _JobsGrid(jobs: list);
            },
          ),
        ],
      ),
    );
  }
}

class _JobsGrid extends ConsumerWidget {
  const _JobsGrid({required this.jobs});
  final List<JobModel> jobs;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final savedIds = ref.watch(savedJobIdsProvider).valueOrNull ?? const <String>{};
    return ResponsiveGrid(
      spacing: 20,
      children: [
        for (var i = 0; i < jobs.length; i++)
          Reveal(
            delay: Duration(milliseconds: i * 50),
            child: JobCard(
              job: jobs[i],
              saved: savedIds.contains(jobs[i].jobId),
              onToggleSave: () => _toggleSave(context, ref, jobs[i]),
              onApply: () => showApplyModal(context, jobs[i]),
            ),
          ),
      ],
    );
  }

  Future<void> _toggleSave(BuildContext context, WidgetRef ref, JobModel job) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) {
      context.push(AppRoutes.login);
      return;
    }
    if (!user.isJobSeeker) {
      showFailure(context, const Failure.forbidden('Chỉ tài khoản ứng viên mới có thể lưu việc làm.'));
      return;
    }
    try {
      await toggleSavedJob(ref, job);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}
