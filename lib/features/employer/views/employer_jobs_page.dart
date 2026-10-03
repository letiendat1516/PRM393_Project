import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/employer_providers.dart';
import '../widgets/employer_guard.dart';
import '../widgets/employer_job_card.dart';
import '../widgets/employer_page_header.dart';
import '../widgets/employer_state_banners.dart';

/// pages/EmployerJobsPage.jsx — "Tin tuyển dụng của tôi".
class EmployerJobsPage extends ConsumerWidget {
  const EmployerJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmployerGuard(
      deniedTitle: 'Bạn không thể truy cập trang quản lý tin tuyển dụng',
      builder: (context, user) {
        final jobs = ref.watch(employerJobsProvider);
        final filter = ref.watch(employerJobsFilterProvider);
        final busy = ref.watch(jobActionsProvider);

        return EmployerPageShell(
          maxWidth: 1152,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmployerPageHeader(
                eyebrow: 'Quản lý tin tuyển dụng',
                title: 'Tin tuyển dụng của tôi',
                subtitle: 'Xem, đóng hoặc xoá các tin tuyển dụng do công ty của bạn đăng.',
                action: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.createJob),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Đăng tin tuyển dụng'),
                ),
              ),
              const SizedBox(height: 24),
              if (jobs.valueOrNull != null && jobs.value!.isNotEmpty) ...[
                _FilterChips(jobs: jobs.value!, selected: filter),
                const SizedBox(height: 16),
              ],
              jobs.when(
                loading: () => const StateCard(
                  text: 'Đang tải danh sách tin tuyển dụng...',
                  spinner: true,
                ),
                error: (e, _) => StateCard.error(
                  text: Failure.from(e).message,
                  action: OutlinedButton.icon(
                    onPressed: () => ref.invalidate(employerJobsProvider),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                  ),
                ),
                data: (list) {
                  if (list.isEmpty) {
                    return StateCard(
                      text: 'Công ty của bạn chưa có tin tuyển dụng nào.',
                      center: true,
                      action: ElevatedButton.icon(
                        onPressed: () => context.push(AppRoutes.createJob),
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Đăng tin mới'),
                      ),
                    );
                  }
                  final filtered = list.where(filter.matches).toList();
                  if (filtered.isEmpty) {
                    return StateCard(
                      text: 'Không có tin tuyển dụng nào ở mục "${filter.label}".',
                      center: true,
                    );
                  }
                  return Column(
                    children: [
                      for (var i = 0; i < filtered.length; i++) ...[
                        if (i > 0) const SizedBox(height: 16),
                        EmployerJobCard(
                          job: filtered[i],
                          busy: busy.contains(filtered[i].jobId),
                          onViewApplicants: () =>
                              context.push(AppRoutes.jobApplicantsOf(filtered[i].jobId)),
                          onEdit: () => context.push(AppRoutes.editJobOf(filtered[i].jobId)),
                          onClose: () => _confirmAndRun(
                            context,
                            ref,
                            message: 'Bạn có chắc muốn đóng tin tuyển dụng này không?',
                            confirmLabel: 'Đóng tin',
                            success: 'Đã đóng tin tuyển dụng.',
                            action: () => ref.read(jobActionsProvider.notifier).close(filtered[i].jobId),
                          ),
                          onReopen: () => _confirmAndRun(
                            context,
                            ref,
                            message: 'Mở lại tin tuyển dụng này để ứng viên có thể thấy & ứng tuyển?',
                            confirmLabel: 'Mở tin',
                            success: 'Đã mở lại tin tuyển dụng.',
                            action: () => ref.read(jobActionsProvider.notifier).reopen(filtered[i].jobId),
                          ),
                          onDelete: () => _confirmAndRun(
                            context,
                            ref,
                            message: 'Bạn có chắc muốn xoá tin tuyển dụng này không?',
                            confirmLabel: 'Xoá',
                            destructive: true,
                            success: 'Đã xoá tin tuyển dụng.',
                            action: () => ref.read(jobActionsProvider.notifier).delete(filtered[i].jobId),
                          ),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmAndRun(
    BuildContext context,
    WidgetRef ref, {
    required String message,
    required String confirmLabel,
    required String success,
    required Future<void> Function() action,
    bool destructive = false,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        title: const Text('Xác nhận'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: destructive
                ? ElevatedButton.styleFrom(backgroundColor: AppColors.red600)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await action();
      if (context.mounted) showSuccess(context, success);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

class _FilterChips extends ConsumerWidget {
  const _FilterChips({required this.jobs, required this.selected});
  final List<JobModel> jobs;
  final EmployerJobsFilter selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final f in EmployerJobsFilter.values) ...[
            ChoiceChip(
              label: Text('${f.label} (${jobs.where(f.matches).length})'),
              selected: selected == f,
              showCheckmark: false,
              labelStyle: TextStyle(
                color: selected == f ? AppColors.primary : AppColors.inkSoft,
                fontWeight: selected == f ? FontWeight.w700 : FontWeight.w500,
                fontSize: 12,
              ),
              onSelected: (_) => ref.read(employerJobsFilterProvider.notifier).state = f,
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
