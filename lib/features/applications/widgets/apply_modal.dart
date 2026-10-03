import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/job_model.dart';
import '../viewmodels/apply_viewmodel.dart';
import 'applications_common.dart';
import 'apply_context_sections.dart';

/// components/job/ApplyModal.jsx — opens as a centered dialog (max-w-xl) on
/// wide screens and as a full-height bottom sheet on phones. Resolves when
/// the modal is closed.
Future<void> showApplyModal(BuildContext context, JobModel job) {
  final width = MediaQuery.sizeOf(context).width;
  if (width < kBpSm) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.x2l)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.92,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (_, controller) => ApplyModalContent(job: job, scrollController: controller),
        ),
      ),
    );
  }
  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.4),
    builder: (_) => Dialog(
      backgroundColor: AppColors.surface,
      insetPadding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
      alignment: Alignment.topCenter,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 576),
        child: ApplyModalContent(job: job),
      ),
    ),
  );
}

/// Dialog body: header (title/company/location/close), form sections,
/// error/success blocks, footer buttons 'Đóng' / 'Xác nhận ứng tuyển'.
class ApplyModalContent extends ConsumerWidget {
  const ApplyModalContent({super.key, required this.job, this.scrollController});
  final JobModel job;
  final ScrollController? scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(applyViewModelProvider(job.jobId));
    final vm = ref.read(applyViewModelProvider(job.jobId).notifier);
    void close() => Navigator.of(context).maybePop();

    final submitLabel = state.phase == ApplyPhase.submitting ? 'Đang gửi...' : 'Xác nhận ứng tuyển';
    final submitEnabled = state.canSubmit &&
        state.phase != ApplyPhase.submitting &&
        state.phase != ApplyPhase.success;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(job: job, onClose: close),
        Flexible(
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (state.blocker != ApplyBlocker.none) ...[
                  ApplyBlockerBanner(blocker: state.blocker, onNavigate: close),
                  const SizedBox(height: 20),
                ],
                if (state.phase == ApplyPhase.validating) ...[
                  const Text(
                    'Đang kiểm tra hồ sơ và CV...',
                    style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 20),
                ],
                if (state.context != null) ...[
                  ApplyProfileSection(profile: state.context!.profile),
                  const SizedBox(height: 20),
                  ApplyResumeSection(resume: state.resume, onNavigate: close),
                  const SizedBox(height: 20),
                  ApplyWarnings(state: state),
                  CoverLetterField(value: state.coverLetter, onChanged: vm.setCoverLetter),
                  const SizedBox(height: 20),
                ],
                if (state.error != null) ...[
                  RedBanner(message: state.error!, padding: 12),
                  if (state.context == null) ...[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton(onPressed: vm.retry, child: const Text('Thử lại')),
                    ),
                  ],
                  const SizedBox(height: 20),
                ],
                if (state.phase == ApplyPhase.success) ...[
                  ApplySuccessBlock(onNavigate: close),
                  const SizedBox(height: 20),
                ],
              ],
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.border)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(onPressed: close, child: const Text('Đóng')),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: submitEnabled ? () => vm.submit() : null,
                child: Text(submitLabel),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.job, required this.onClose});
  final JobModel job;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final location = (job.location ?? '').trim().isNotEmpty ? job.location!.trim() : job.city;
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ứng tuyển công việc',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
                ),
                const SizedBox(height: 4),
                Text(job.jobTitle, style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                Text(
                  '${job.employerName} · $location',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            tooltip: 'Đóng',
            icon: const Icon(Icons.close, size: 20, color: AppColors.inkMuted),
          ),
        ],
      ),
    );
  }
}
