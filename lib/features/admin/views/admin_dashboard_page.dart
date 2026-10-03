import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../viewmodels/admin_dashboard_viewmodel.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_page_shell.dart';
import '../widgets/stat_card.dart';

/// Mobile-only admin dashboard (/admin): counters, quick links to every admin
/// page and the 'Seed dữ liệu demo' action.
class AdminDashboardPage extends ConsumerWidget {
  const AdminDashboardPage({super.key});

  static const _links = [
    _QuickLink('Quản lý người dùng', 'Khóa / kích hoạt tài khoản ứng viên và nhà tuyển dụng.',
        Icons.people_outline, AppRoutes.adminUsers),
    _QuickLink('Quản lý nhà tuyển dụng', 'Xác minh thông tin doanh nghiệp.',
        Icons.business_outlined, AppRoutes.adminEmployers),
    _QuickLink('Duyệt tin tuyển dụng', 'Duyệt hoặc từ chối tin đang chờ.',
        Icons.fact_check_outlined, AppRoutes.adminPendingJobs),
    _QuickLink('Quản lý ngành nghề và kỹ năng', 'Thêm hoặc xoá ngành nghề, kỹ năng.',
        Icons.category_outlined, AppRoutes.adminCatalog),
    _QuickLink('Cấu hình hệ thống', 'Quy tắc dùng chung của hệ thống JobHub.',
        Icons.settings_outlined, AppRoutes.adminSystemConfig),
    _QuickLink('Thống kê AI Logs', 'Hiệu năng, token, xu hướng 7 ngày, Gemini API key.',
        Icons.bar_chart_outlined, AppRoutes.adminAiStats),
    _QuickLink('AI Prompt Logs', 'Prompt / response từng lượt gọi AI.',
        Icons.auto_awesome_outlined, AppRoutes.adminAiLogs),
    _QuickLink('Hồ sơ ứng tuyển', 'Toàn bộ hồ sơ ứng tuyển trên hệ thống.',
        Icons.inbox_outlined, AppRoutes.employerApplications),
  ];

  Future<void> _seed(BuildContext context, WidgetRef ref) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Seed dữ liệu demo',
      message:
          'Thao tác này sẽ ghi dữ liệu demo (ngành nghề, kỹ năng, nhà tuyển dụng, tin tuyển dụng và cấu hình mặc định) vào Firestore. Dữ liệu trùng id sẽ được ghi đè (merge). Tiếp tục?',
      confirmLabel: 'Seed dữ liệu',
    );
    if (!ok) return;
    final success = await ref.read(seedDemoProvider.notifier).run();
    if (!context.mounted) return;
    final s = ref.read(seedDemoProvider);
    if (success) {
      showSuccess(context, 'Đã seed dữ liệu demo thành công.');
    } else if (s.error != null) {
      showFailure(context, s.error!);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final counts = ref.watch(adminCountsProvider);
    final seed = ref.watch(seedDemoProvider);
    final user = ref.watch(currentUserProvider).valueOrNull;
    final width = MediaQuery.sizeOf(context).width;

    return AdminPageShell(
      children: [
        AdminPageHeader(
          eyebrow: 'Quản trị hệ thống',
          title: 'Tổng quan quản trị',
          subtitle: user == null
              ? 'Theo dõi số liệu hệ thống và truy cập nhanh các chức năng quản trị.'
              : 'Xin chào ${user.fullName}. Theo dõi số liệu hệ thống và truy cập nhanh các chức năng quản trị.',
          trailing: OutlinedButton.icon(
            onPressed: counts.isLoading ? null : () => ref.invalidate(adminCountsProvider),
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Làm mới'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
            ),
          ),
        ),
        const SizedBox(height: 24),
        ...counts.when(
          loading: () => const [AdminStateCard(text: 'Đang tải số liệu hệ thống...', loading: true)],
          error: (e, _) => [
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.x2l),
              ),
              child: RouteErrorView(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(adminCountsProvider),
              ),
            ),
          ],
          data: (c) => [
            const _SectionTitle('Người dùng'),
            const SizedBox(height: 12),
            TileGrid(
              columnsFor: (w) => w >= 1024 ? 4 : 2,
              children: [
                StatCard(
                    label: 'Tổng tài khoản',
                    value: Formatters.number(c.totalUsers),
                    icon: Icons.group_outlined,
                    onTap: () => context.push(AppRoutes.adminUsers)),
                StatCard(
                    label: 'Ứng viên',
                    value: Formatters.number(c.jobSeekers),
                    icon: Icons.person_outline,
                    onTap: () => context.push(AppRoutes.adminUsers)),
                StatCard(
                    label: 'Nhà tuyển dụng',
                    value: Formatters.number(c.employers),
                    icon: Icons.business_outlined,
                    color: AppColors.secondary600,
                    onTap: () => context.push(AppRoutes.adminEmployers)),
                StatCard(
                    label: 'Quản trị viên',
                    value: Formatters.number(c.admins),
                    icon: Icons.admin_panel_settings_outlined,
                    color: AppColors.violet600),
              ],
            ),
            const SizedBox(height: 24),
            const _SectionTitle('Tin tuyển dụng & hồ sơ'),
            const SizedBox(height: 12),
            TileGrid(
              columnsFor: (w) => w >= 1024 ? 4 : 2,
              children: [
                StatCard(
                    label: 'Tổng tin tuyển dụng',
                    value: Formatters.number(c.totalJobs),
                    icon: Icons.work_outline),
                StatCard(
                    label: 'Tin đang tuyển',
                    value: Formatters.number(c.openJobs),
                    icon: Icons.check_circle_outline,
                    color: AppColors.green600),
                StatCard(
                    label: 'Tin chờ duyệt',
                    value: Formatters.number(c.pendingJobs),
                    icon: Icons.pending_actions_outlined,
                    color: AppColors.amber700,
                    onTap: () => context.push(AppRoutes.adminPendingJobs)),
                StatCard(
                    label: 'Hồ sơ ứng tuyển',
                    value: Formatters.number(c.applications),
                    icon: Icons.inbox_outlined,
                    color: AppColors.blue700,
                    onTap: () => context.push(AppRoutes.employerApplications)),
              ],
            ),
            const SizedBox(height: 16),
            _JobsByStatusCard(counts: c),
          ],
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Chức năng quản trị'),
        const SizedBox(height: 12),
        TileGrid(
          columnsFor: (w) => w >= 1024 ? 4 : (w >= 640 ? 2 : 1),
          gap: 16,
          children: [
            for (final l in _links)
              AppCard(
                padding: const EdgeInsets.all(18),
                hoverLift: true,
                onTap: () => context.push(l.route),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.primary50,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      alignment: Alignment.center,
                      child: Icon(l.icon, size: 20, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l.label,
                              style: const TextStyle(
                                  fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
                          const SizedBox(height: 4),
                          Text(l.description,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.inkMuted, height: 1.4)),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, size: 18, color: AppColors.slate400),
                  ],
                ),
              ),
          ],
        ),
        const SizedBox(height: 32),
        const _SectionTitle('Dữ liệu demo'),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.x2l),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Previously a single `Flex` that flipped between horizontal
              // and vertical. The vertical variant kept the `Flexible`
              // child, and inside PublicLayout's SingleChildScrollView
              // (unbounded vertical constraints) that triggered
              // "RenderFlex children have non-zero flex but incoming
              // height constraints are unbounded" and blanked the
              // dashboard. Mobile now uses a plain Column with the Text
              // taking natural height; wide screens still use a Row with
              // Flexible so the long paragraph wraps next to the button.
              if (width >= kAdminMdBreakpoint)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      fit: FlexFit.tight,
                      child: const Text(
                        'Ghi bộ dữ liệu mẫu của trang web (18 ngành nghề, kỹ năng phổ biến, nhà tuyển dụng demo, 18 tin tuyển dụng đã duyệt) và khởi tạo cấu hình mặc định. Thao tác an toàn khi chạy lại nhiều lần.',
                        style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton.icon(
                      onPressed: seed.running ? null : () => _seed(context, ref),
                      icon: seed.running
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(seed.running ? 'Đang seed...' : 'Seed dữ liệu demo'),
                    ),
                  ],
                )
              else
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Ghi bộ dữ liệu mẫu của trang web (18 ngành nghề, kỹ năng phổ biến, nhà tuyển dụng demo, 18 tin tuyển dụng đã duyệt) và khởi tạo cấu hình mặc định. Thao tác an toàn khi chạy lại nhiều lần.',
                      style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: seed.running ? null : () => _seed(context, ref),
                      icon: seed.running
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Icon(Icons.cloud_upload_outlined, size: 18),
                      label: Text(seed.running ? 'Đang seed...' : 'Seed dữ liệu demo'),
                    ),
                  ],
                ),
              if (seed.message != null) ...[
                const SizedBox(height: 16),
                AdminSuccessBanner(
                    message: seed.message!,
                    onDismiss: () => ref.read(seedDemoProvider.notifier).dismiss()),
              ],
              if (seed.error != null) ...[
                const SizedBox(height: 16),
                AdminErrorBanner(
                    message: seed.error!,
                    onDismiss: () => ref.read(seedDemoProvider.notifier).dismiss()),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickLink {
  const _QuickLink(this.label, this.description, this.icon, this.route);
  final String label;
  final String description;
  final IconData icon;
  final String route;
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(text,
      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink));
}

class _JobsByStatusCard extends StatelessWidget {
  const _JobsByStatusCard({required this.counts});
  final AdminCounts counts;

  @override
  Widget build(BuildContext context) {
    final total = counts.totalJobs;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Tin tuyển dụng theo trạng thái',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 12),
          for (final s in JobStatus.values) ...[
            Row(
              children: [
                SizedBox(
                  width: 110,
                  child: Text(s.label,
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: total == 0 ? 0 : (counts.jobsByStatus[s] ?? 0) / total,
                      minHeight: 8,
                      backgroundColor: AppColors.slate100,
                      color: AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  width: 48,
                  child: Text(
                    Formatters.number(counts.jobsByStatus[s] ?? 0),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}
