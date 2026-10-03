import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../../shared/widgets/web_footer.dart';
import '../../applications/viewmodels/applications_providers.dart';
import '../../applications/widgets/apply_modal.dart';
import '../viewmodels/job_detail_providers.dart';
import '../viewmodels/saved_jobs_provider.dart';
import '../widgets/job_detail_sections.dart';
import '../widgets/job_summary_card.dart';
import '../widgets/save_job_helper.dart';
import '../widgets/sticky_sidebar_layout.dart';

/// pages/JobDetailPage.jsx — /viec-lam/:id (public).
class JobDetailPage extends ConsumerStatefulWidget {
  const JobDetailPage({super.key, required this.jobId});
  final String jobId;

  @override
  ConsumerState<JobDetailPage> createState() => _JobDetailPageState();
}

class _JobDetailPageState extends ConsumerState<JobDetailPage> {
  final _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  /// `navigate(-1)` with a fallback to the list for deep links.
  void _back() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRoutes.jobs);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(jobDetailProvider(widget.jobId));

    return async.when(
      loading: () =>
          const PublicLayout(child: _StateShell(child: _LoadingBox())),
      error: (e, _) => PublicLayout(
        child: _StateShell(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  border: Border.all(color: AppColors.red100),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Text(
                  Failure.from(e).message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.red600,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _BackToListButton(onPressed: () => context.go(AppRoutes.jobs)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: () =>
                    ref.invalidate(jobDetailProvider(widget.jobId)),
                icon: const Icon(Icons.refresh, size: 16),
                label: const Text('Thử lại'),
              ),
            ],
          ),
        ),
      ),
      data: (job) => job == null
          ? PublicLayout(
              child: _StateShell(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: const BoxDecoration(
                        color: AppColors.slate100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.business_center_outlined,
                        size: 28,
                        color: AppColors.inkMuted,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Không tìm thấy việc làm',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Việc làm bạn tìm không tồn tại hoặc đã bị đóng.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.inkSoft, fontSize: 14),
                    ),
                    const SizedBox(height: 24),
                    _BackToListButton(
                      onPressed: () => context.go(AppRoutes.jobs),
                    ),
                  ],
                ),
              ),
            )
          : _buildDetail(context, job),
    );
  }

  Widget _buildDetail(BuildContext context, JobModel job) {
    final saved =
        ref.watch(savedJobIdsProvider).valueOrNull?.contains(job.jobId) ??
        false;
    final applied =
        ref.watch(appliedJobIdsProvider).valueOrNull?.contains(job.jobId) ??
        false;

    final header = PageContainer(
      child: Padding(
        padding: const EdgeInsets.only(top: 24),
        child: Breadcrumb(
          items: [
            ('Trang chủ', () => context.go(AppRoutes.home)),
            ('Việc làm', () => context.go(AppRoutes.jobs)),
            (job.jobTitle, null),
          ],
        ),
      ),
    );

    // Left column exactly as the web: B1 header card, B2 skills card (when
    // tags exist), B3 content card. No company / related-jobs extras.
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobHeaderCard(job: job),
        if (job.tags.isNotEmpty) ...[
          const SizedBox(height: 16),
          JobSkillsCard(job: job),
        ],
        const SizedBox(height: 16),
        JobContentCard(job: job),
      ],
    );

    final sidebar = JobSummaryCard(
      job: job,
      applied: applied,
      saved: saved,
      onApply: () => showApplyModal(context, job),
      onToggleSave: () => handleToggleSave(context, ref, job),
      onBack: _back,
    );

    return PublicLayout(
      scrollable: false,
      scrollController: _scroll,
      child: StickySidebarLayout(
        controller: _scroll,
        header: header,
        body: body,
        sidebar: sidebar,
        footer: const WebFooter(),
        sidebarOnRight: true,
        sidebarFirstWhenStacked: false,
        sidebarFraction: 1 / 3,
        bodyPadding: const EdgeInsets.only(top: 16, bottom: 32),
      ),
    );
  }
}

/// `mx-auto max-w-2xl px-4 py-24 text-center`.
class _StateShell extends StatelessWidget {
  const _StateShell({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 672),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 96),
          child: child,
        ),
      ),
    );
  }
}

class _LoadingBox extends StatelessWidget {
  const _LoadingBox();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 3),
          ),
          SizedBox(height: 14),
          Text(
            'Đang tải chi tiết tin tuyển dụng...',
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.inkSoft),
          ),
        ],
      ),
    );
  }
}

class _BackToListButton extends StatelessWidget {
  const _BackToListButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => ElevatedButton.icon(
    onPressed: onPressed,
    icon: const Icon(Icons.arrow_back, size: 18),
    label: const Text('Quay lại danh sách'),
  );
}
