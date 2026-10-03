import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/dashboard_viewmodel.dart';
import '../viewmodels/employer_providers.dart';
import '../widgets/applicant_card.dart';
import '../widgets/applications_status_chart.dart';
import '../widgets/employer_guard.dart';
import '../widgets/employer_page_header.dart';
import '../widgets/employer_state_banners.dart';
import '../widgets/stat_tile.dart';

/// Mobile-plan screen: employer overview (stats, chart, recent applications,
/// quick actions). Data is live from the jobs + applications streams.
class EmployerDashboardPage extends ConsumerWidget {
  const EmployerDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmployerGuard(
      deniedTitle: 'Bạn không thể truy cập trang tổng quan nhà tuyển dụng',
      builder: (context, user) {
        final stats = ref.watch(employerDashboardProvider);
        final profile = ref.watch(employerProfileProvider).valueOrNull;
        final width = MediaQuery.sizeOf(context).width;
        final wide = width >= 1024;

        return EmployerPageShell(
          maxWidth: 1152,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              EmployerPageHeader(
                eyebrow: 'Nhà tuyển dụng',
                title: 'Tổng quan',
                subtitle: 'Theo dõi tin tuyển dụng và hồ sơ ứng tuyển của công ty bạn.',
                action: ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.createJob),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Đăng tin mới'),
                ),
              ),
              const SizedBox(height: 24),
              if (profile != null) ...[
                _CompanyStrip(profile: profile),
                const SizedBox(height: 16),
              ],
              _QuickActions(),
              const SizedBox(height: 24),
              stats.when(
                loading: () => const StateCard(text: 'Đang tải dữ liệu tổng quan...', spinner: true),
                error: (e, _) => StateCard.error(
                  text: Failure.from(e).message,
                  action: OutlinedButton.icon(
                    onPressed: () {
                      ref.invalidate(employerJobsProvider);
                      ref.invalidate(employerAllApplicationsProvider);
                    },
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Thử lại'),
                  ),
                ),
                data: (s) => Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _StatGrid(stats: s),
                    const SizedBox(height: 24),
                    if (wide)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 3, child: _ChartCard(stats: s)),
                          const SizedBox(width: 24),
                          Expanded(flex: 2, child: _RecentCard(stats: s)),
                        ],
                      )
                    else ...[
                      _ChartCard(stats: s),
                      const SizedBox(height: 16),
                      _RecentCard(stats: s),
                    ],
                    const SizedBox(height: 24),
                    _TopJobsCard(stats: s),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CompanyStrip extends StatelessWidget {
  const _CompanyStrip({required this.profile});
  final EmployerProfile profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.companyName.trim().isEmpty ? 'Công ty chưa cập nhật' : profile.companyName;
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CompanyLogoTile(name: name, logoUrl: profile.logoUrl, size: 48),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text(name,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    BoolBadge(
                      value: profile.isVerified,
                      trueLabel: 'Đã xác thực',
                      falseLabel: 'Chờ xác thực',
                      falseTone: const (AppColors.amber50, AppColors.amber700),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  [
                    if ((profile.city ?? '').isNotEmpty) profile.city!,
                    if ((profile.website ?? '').isNotEmpty) profile.website!,
                    if ((profile.contactName ?? '').isNotEmpty) 'Liên hệ: ${profile.contactName}',
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => context.push(AppRoutes.employerCompanyProfile),
            child: const Text('Hồ sơ công ty'),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    Widget btn(IconData icon, String label, String route) => OutlinedButton.icon(
          onPressed: () => context.push(route),
          icon: Icon(icon, size: 16),
          label: Text(label),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(0, 40),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        btn(Icons.list_alt_outlined, 'Quản lý tin tuyển dụng', AppRoutes.employerJobs),
        btn(Icons.inbox_outlined, 'Hồ sơ ứng tuyển', AppRoutes.employerApplications),
        btn(Icons.business_outlined, 'Hồ sơ công ty', AppRoutes.employerCompanyProfile),
        btn(Icons.chat_bubble_outline, 'Tin nhắn', AppRoutes.chats),
        btn(Icons.notifications_none, 'Thông báo', AppRoutes.notifications),
      ],
    );
  }
}

class _StatGrid extends StatelessWidget {
  const _StatGrid({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      StatTile(
        label: 'TIN ĐANG MỞ',
        value: '${stats.openJobs}',
        hint: stats.pendingJobs > 0 ? '${stats.pendingJobs} tin chờ duyệt' : '${stats.jobs.length} tin tổng cộng',
        icon: Icons.work_outline,
        onTap: () => context.push(AppRoutes.employerJobs),
      ),
      StatTile(
        label: 'TỔNG HỒ SƠ',
        value: '${stats.totalApplications}',
        hint: 'Trên tất cả tin tuyển dụng',
        icon: Icons.description_outlined,
        tint: AppColors.violet600,
        tintBg: AppColors.violet50,
        onTap: () => context.push(AppRoutes.employerApplications),
      ),
      StatTile(
        label: 'HỒ SƠ MỚI 7 NGÀY',
        value: '${stats.newLast7Days}',
        hint: 'Nộp trong tuần qua',
        icon: Icons.trending_up,
        tint: AppColors.emerald600,
        tintBg: AppColors.emerald50,
      ),
      StatTile(
        label: 'TỈ LỆ CHẤP NHẬN',
        value: stats.acceptanceRateLabel,
        hint: stats.acceptanceRate == null
            ? 'Chưa có hồ sơ được xử lý'
            : '${stats.byStatus[ApplicationStatus.accepted]} được nhận / ${stats.byStatus[ApplicationStatus.rejected]} từ chối',
        icon: Icons.check_circle_outline,
        tint: AppColors.amber700,
        tintBg: AppColors.amber50,
      ),
    ];
    return LayoutBuilder(
      builder: (context, c) {
        final cols = c.maxWidth >= 900 ? 4 : (c.maxWidth >= 480 ? 2 : 1);
        const gap = 16.0;
        final w = (c.maxWidth - gap * (cols - 1)) / cols;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [for (final t in tiles) SizedBox(width: w, child: t)],
        );
      },
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Hồ sơ theo trạng thái',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 4),
          Text('${stats.totalApplications} hồ sơ ứng tuyển',
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          const SizedBox(height: 16),
          ApplicationsStatusChart(byStatus: stats.byStatus),
        ],
      ),
    );
  }
}

class _RecentCard extends StatelessWidget {
  const _RecentCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Hồ sơ mới nhất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.employerApplications),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (stats.recent.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text('Chưa có hồ sơ ứng tuyển nào.',
                    style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
              ),
            )
          else
            for (var i = 0; i < stats.recent.length; i++) ...[
              if (i > 0) const SizedBox(height: 8),
              ApplicantCard(
                application: stats.recent[i],
                compact: true,
                showJobTitle: true,
                onOpen: () => context.push(
                    AppRoutes.employerApplicationReviewOf(stats.recent[i].applicationId)),
              ),
            ],
        ],
      ),
    );
  }
}

class _TopJobsCard extends StatelessWidget {
  const _TopJobsCard({required this.stats});
  final DashboardStats stats;

  @override
  Widget build(BuildContext context) {
    final top = stats.topJobs;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text('Tin nhận nhiều hồ sơ nhất',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              TextButton(
                onPressed: () => context.push(AppRoutes.employerJobs),
                child: const Text('Quản lý tin'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (top.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Column(
                  children: [
                    const Text('Bạn chưa đăng tin tuyển dụng nào.',
                        style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => context.push(AppRoutes.createJob),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Đăng tin mới'),
                    ),
                  ],
                ),
              ),
            )
          else
            for (final (job, count) in top)
              InkWell(
                borderRadius: BorderRadius.circular(AppRadius.lg),
                onTap: () => context.push(AppRoutes.jobApplicantsOf(job.jobId)),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(job.jobTitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                    fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                            const SizedBox(height: 4),
                            JobStatusBadge(status: job.status, isApproved: job.isApproved),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text('$count',
                          style: const TextStyle(
                              fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink)),
                      const SizedBox(width: 4),
                      const Text('hồ sơ', style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                      const SizedBox(width: 8),
                      const Icon(Icons.chevron_right, size: 18, color: AppColors.slate400),
                    ],
                  ),
                ),
              ),
        ],
      ),
    );
  }
}
