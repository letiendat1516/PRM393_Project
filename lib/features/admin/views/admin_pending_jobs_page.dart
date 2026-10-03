import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../viewmodels/admin_mutation_notifier.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_page_shell.dart';

/// Duyệt tin tuyển dụng (/admin/pending-jobs) — DRAFT && !isApproved queue.
///
/// Strict port of AdminPendingJobsPage.jsx: the card shows title, company •
/// location, 'Trạng thái: Chờ duyệt', a 2-line description and the two
/// buttons — no link, no salary/category chips, no count pill, no toast.
class AdminPendingJobsPage extends ConsumerWidget {
  const AdminPendingJobsPage({super.key});

  Future<void> _moderate(BuildContext context, WidgetRef ref, JobModel job, bool approve) async {
    final label = approve ? 'duyệt' : 'từ chối';
    final ok = await showConfirmDialog(
      context,
      message: 'Bạn có chắc muốn $label tin tuyển dụng này không?',
      confirmLabel: approve ? 'Duyệt' : 'Từ chối',
      danger: !approve,
    );
    // the page may have been disposed (role/auth redirect) while the dialog was open
    if (!ok || !context.mounted) return;
    final repo = ref.read(adminRepositoryProvider);
    final failure = await ref.read(pendingJobsMutationProvider.notifier).run(
          job.jobId,
          () => repo.moderateJob(job, approve: approve),
          fallbackMessage: 'Không thể xử lý tin tuyển dụng.',
          silent: true,
        );
    if (failure == null || !context.mounted) return;
    // window.alert(message) → single-message dialog (the fallback is already
    // substituted by AdminMutationNotifier for unknown errors).
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        content: Text(failure.message, style: const TextStyle(height: 1.5)),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobs = ref.watch(pendingJobsProvider);
    final mutation = ref.watch(pendingJobsMutationProvider);

    return AdminPageShell(
      children: [
        const AdminPageHeader(
          eyebrow: 'Duyệt tin tuyển dụng',
          title: 'Danh sách tin chờ duyệt',
          subtitle:
              'Quản trị viên có thể duyệt hoặc từ chối các tin tuyển dụng do nhà tuyển dụng gửi lên.',
        ),
        const SizedBox(height: 24),
        ...jobs.when(
          loading: () => const [
            AdminStateCard(
              text: 'Đang tải danh sách tin chờ duyệt...',
              loading: true,
              center: false,
              padding: EdgeInsets.all(24),
            ),
          ],
          error: (e, _) => [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.red50,
                border: Border.all(color: AppColors.dangerBorder),
                borderRadius: BorderRadius.circular(AppRadius.x2l),
              ),
              child: Text(
                Failure.from(e).code == 'UNKNOWN'
                    ? 'Không thể tải danh sách tin chờ duyệt.'
                    : Failure.from(e).message,
                style: const TextStyle(color: AppColors.red600, fontSize: 14),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: OutlinedButton.icon(
                onPressed: () => ref.invalidate(pendingJobsProvider),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Tải lại'),
              ),
            ),
          ],
          data: (list) => list.isEmpty
              ? const [AdminStateCard(text: 'Không có tin tuyển dụng nào đang chờ duyệt.')]
              : [
                  for (var i = 0; i < list.length; i++) ...[
                    if (i > 0) const SizedBox(height: 16),
                    _PendingJobCard(
                      job: list[i],
                      busy: mutation.isUpdating(list[i].jobId),
                      disabled: mutation.busy,
                      onApprove: () => _moderate(context, ref, list[i], true),
                      onReject: () => _moderate(context, ref, list[i], false),
                    ),
                  ],
                ],
        ),
      ],
    );
  }
}

class _PendingJobCard extends StatelessWidget {
  const _PendingJobCard({
    required this.job,
    required this.busy,
    required this.disabled,
    required this.onApprove,
    required this.onReject,
  });

  final JobModel job;
  final bool busy;
  final bool disabled;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final md = MediaQuery.sizeOf(context).width >= kAdminMdBreakpoint;
    // getJobTitle(job) → job_title || title || 'Tin tuyển dụng chưa có tiêu đề'
    final title = job.jobTitle.trim().isEmpty ? 'Tin tuyển dụng chưa có tiêu đề' : job.jobTitle;
    final company = job.employerName.trim().isEmpty ? 'Chưa rõ công ty' : job.employerName;
    final location = (job.location ?? job.city).trim().isEmpty
        ? 'Chưa cập nhật địa điểm'
        : (job.location ?? job.city);
    final description = job.description.isEmpty
        ? (job.rawDescription ?? '').trim()
        : job.description.plainText.trim();

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 8),
        Text('$company • $location',
            style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
            children: [
              const TextSpan(text: 'Trạng thái: '),
              TextSpan(
                text: busy ? 'Đang xử lý...' : 'Chờ duyệt',
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.blue700),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Text(
          description.isEmpty ? 'Chưa có mô tả công việc.' : description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
        ),
      ],
    );

    final actions = Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ElevatedButton(
          onPressed: disabled ? null : onApprove,
          style: _btn(AppColors.green600),
          child: const Text('Duyệt'),
        ),
        ElevatedButton(
          onPressed: disabled ? null : onReject,
          style: _btn(AppColors.red600),
          child: const Text('Từ chối'),
        ),
      ],
    );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: md
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [Expanded(child: info), const SizedBox(width: 24), actions],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 16), actions],
            ),
    );
  }

  ButtonStyle _btn(Color color) => ElevatedButton.styleFrom(
        backgroundColor: color,
        disabledBackgroundColor: color.withValues(alpha: 0.5),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
        textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      );
}
