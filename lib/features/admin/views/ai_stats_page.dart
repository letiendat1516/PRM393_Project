import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/catalog_models.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/admin_providers.dart';
import '../viewmodels/ai_stats_viewmodel.dart';
import '../widgets/admin_page_shell.dart';
import '../widgets/ai_stats_cards.dart';
import '../widgets/calls_per_day_chart.dart';
import '../widgets/ai_providers_panel.dart';
import '../widgets/gemini_key_panel.dart';
import '../widgets/stat_card.dart';

/// Thống kê AI Logs (/admin/ai-stats) — aggregates over the last 200 logs.
/// Order (AiStatsPage.jsx): breadcrumb → header → API key panel (always) →
/// loading / error / empty / stat tiles + 4 cards.
class AiStatsPage extends ConsumerWidget {
  const AiStatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(aiStatsProvider);
    final configs = ref.watch(systemConfigsProvider);
    final width = MediaQuery.sizeOf(context).width;
    final lg = width >= kAdminLgBreakpoint;

    SystemConfig? storedKey;
    String? deepseekKey;
    String? zaiKey;
    String? providerOrder;
    for (final c in configs.valueOrNull ?? const <SystemConfig>[]) {
      if (c.configKey == SystemConfig.keyGeminiApiKey) storedKey = c;
      if (c.configKey == SystemConfig.keyDeepseekApiKey) {
        deepseekKey = c.configValue;
      }
      if (c.configKey == SystemConfig.keyZaiApiKey) zaiKey = c.configValue;
      if (c.configKey == SystemConfig.keyAiProviderOrder) {
        providerOrder = c.configValue;
      }
    }

    return AdminPageShell(
      children: [
        Breadcrumb(items: [
          ('Trang chủ', () => context.go(AppRoutes.home)),
          ('Admin', () => context.go(AppRoutes.adminDashboard)),
          ('AI Statistics', null),
        ]),
        const SizedBox(height: 16),
        AdminPageHeader(
          title: 'Thống kê AI Logs',
          titleIcon: Icons.trending_up,
          subtitle: 'Phân tích hiệu năng Gemini AI — tổng quan, xu hướng, tối ưu prompt.',
          trailing: OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.adminAiLogs),
            icon: const Icon(Icons.description_outlined, size: 16),
            label: const Text('Xem logs chi tiết'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ),
        const SizedBox(height: 24),
        // API key manager — rendered above the loading/error/empty/data chain
        GeminiKeyPanel(stored: storedKey),
        const SizedBox(height: 16),
        AiProvidersPanel(
          deepseekKey: deepseekKey,
          zaiKey: zaiKey,
          providerOrder: providerOrder,
        ),
        const SizedBox(height: 24),
        ...stats.when(
          loading: () => const [
            _StateCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Đang tải...', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
          error: (e, _) => [
            _StateCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.close, size: 32, color: AppColors.red600),
                  const SizedBox(height: 12),
                  const Text('Không tải được logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  Text(Failure.from(e).message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(aiLogsProvider(AppConfig.aiStatsLogLimit)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ],
          data: (s) => s.isEmpty
              ? const [
                  _StateCard(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.auto_awesome, size: 32, color: AppColors.inkMuted),
                        SizedBox(height: 12),
                        Text('Chưa có dữ liệu',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                        SizedBox(height: 4),
                        Text('Hãy dùng AI Matching để tạo logs trước.',
                            style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                      ],
                    ),
                  ),
                ]
              : [
                  TileGrid(
                    columnsFor: (w) => w >= 1024 ? 6 : (w >= 640 ? 3 : 2),
                    children: [
                      StatCard(
                          label: 'Tổng lượt gọi',
                          value: '${s.total}',
                          icon: Icons.auto_awesome,
                          horizontal: false),
                      StatCard(
                        label: 'Success rate',
                        value: '${s.successRate}%',
                        icon: Icons.check_circle_outline,
                        color: AppColors.green600,
                        horizontal: false,
                      ),
                      StatCard(
                          label: 'Avg time',
                          value: '${s.avgTimeMs}ms',
                          icon: Icons.schedule_outlined,
                          horizontal: false),
                      StatCard(
                        label: 'Max time',
                        value: '${s.maxTimeMs}ms',
                        icon: Icons.bolt,
                        color: AppColors.amber700,
                        horizontal: false,
                      ),
                      StatCard(
                          label: 'Total tokens',
                          value: Formatters.number(s.totalTokens),
                          icon: Icons.description_outlined,
                          horizontal: false),
                      // `$${estCost}` — (tokensIn/1e6*0.27 + tokensOut/1e6*1.1).toFixed(4)
                      StatCard(
                        label: 'Est. cost',
                        value: '\$${s.estCost}',
                        icon: Icons.account_balance_wallet_outlined,
                        horizontal: false,
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _SectionGrid(lg: lg, stats: s),
                ],
        ),
      ],
    );
  }
}

/// `grid grid-cols-1 gap-6 lg:grid-cols-2` — DOM order: task, token, 7-day,
/// slowest → left column (task, 7-day), right column (token, slowest).
class _SectionGrid extends StatelessWidget {
  const _SectionGrid({required this.lg, required this.stats});
  final bool lg;
  final AiStats stats;

  @override
  Widget build(BuildContext context) {
    final task = StatsSectionCard(
      title: 'Phân tích theo task',
      child: TaskBreakdownList(byTask: stats.byTask, total: stats.total),
    );
    final tokens = StatsSectionCard(
      title: 'Token usage',
      child: TokenUsage(tokensIn: stats.tokensIn, tokensOut: stats.tokensOut),
    );
    final chart = StatsSectionCard(
      title: 'Lượt gọi 7 ngày gần nhất',
      child: CallsPerDayChart(days: stats.last7Days),
    );
    final slowest = StatsSectionCard(
      title: 'Top 5 chậm nhất (cần tối ưu prompt)',
      child: SlowestCallsList(logs: stats.slowest),
    );

    if (!lg) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          task,
          const SizedBox(height: 24),
          tokens,
          const SizedBox(height: 24),
          chart,
          const SizedBox(height: 24),
          slowest,
        ],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: Column(children: [task, const SizedBox(height: 24), chart])),
        const SizedBox(width: 24),
        Expanded(child: Column(children: [tokens, const SizedBox(height: 24), slowest])),
      ],
    );
  }
}

class _StateCard extends StatelessWidget {
  const _StateCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 72),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderMuted),
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          boxShadow: AppShadows.card,
        ),
        child: Center(child: child),
      );
}
