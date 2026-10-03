import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/admin_providers.dart';
import '../widgets/admin_page_shell.dart';
import '../widgets/ai_log_tile.dart';
import '../widgets/stat_card.dart';

/// AI Prompt Logs (/ai-logs) — last 100 aiMatchingLogs, task filter, accordion rows.
class AiLogsPage extends ConsumerStatefulWidget {
  const AiLogsPage({super.key});

  @override
  ConsumerState<AiLogsPage> createState() => _AiLogsPageState();
}

class _AiLogsPageState extends ConsumerState<AiLogsPage> {
  String _filterTask = 'all';
  String? _expandedId;

  @override
  Widget build(BuildContext context) {
    final logsAsync = ref.watch(aiLogsProvider(AppConfig.aiLogsPageLimit));
    final logs = logsAsync.valueOrNull ?? const <AiMatchingLog>[];

    // stats always over the FULL list, never the filtered one
    final total = logs.length;
    final success = logs.where((l) => l.success).length;
    final avgTime =
        total == 0 ? 0 : (logs.fold<int>(0, (a, l) => a + l.processingTimeMs) / total).round();
    final totalTokens = logs.fold<int>(0, (a, l) => a + l.tokensIn + l.tokensOut);

    // tasks = ['all', ...new Set(logs.map(l => l.task))] — pills come from the
    // loaded data only (first-appearance order).
    final tasks = <String>['all'];
    for (final l in logs) {
      if (!tasks.contains(l.task)) tasks.add(l.task);
    }
    final filtered = _filterTask == 'all' ? logs : logs.where((l) => l.task == _filterTask).toList();

    return AdminPageShell(
      maxWidth: 1024,
      children: [
        Breadcrumb(items: [
          ('Trang chủ', () => context.go(AppRoutes.home)),
          ('AI Logs', null),
        ]),
        const SizedBox(height: 16),
        const AdminPageHeader(
          title: 'AI Prompt Logs',
          titleIcon: Icons.auto_awesome,
          subtitle:
              'Nhật ký gọi Gemini AI — ghi prompt, response, thời gian xử lý để theo dõi và cải thiện prompt.',
        ),
        const SizedBox(height: 24),
        TileGrid(
          columnsFor: (w) => w >= 640 ? 4 : 2,
          children: [
            StatCard(label: 'Tổng lượt gọi', value: '$total', icon: Icons.auto_awesome),
            StatCard(
              label: 'Thành công',
              value: '$success',
              icon: Icons.check_circle_outline,
              color: AppColors.green600,
            ),
            StatCard(label: 'TB thời gian', value: '${avgTime}ms', icon: Icons.schedule_outlined),
            StatCard(label: 'Tổng tokens', value: Formatters.number(totalTokens), icon: Icons.bolt),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 8,
          children: [
            const Text('Lọc theo task:', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
            for (final t in tasks)
              FilterPill(
                label: t == 'all' ? 'Tất cả' : t,
                selected: _filterTask == t,
                compact: true,
                onTap: () => setState(() => _filterTask = t),
              ),
          ],
        ),
        const SizedBox(height: 16),
        ...logsAsync.when(
          loading: () => const [
            _CenteredCard(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2)),
                  SizedBox(width: 12),
                  Text('Đang tải logs...', style: TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                ],
              ),
            ),
          ],
          error: (e, _) => [
            _CenteredCard(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(color: AppColors.red50, shape: BoxShape.circle),
                    alignment: Alignment.center,
                    child: const Icon(Icons.close, size: 26, color: AppColors.red600),
                  ),
                  const SizedBox(height: 12),
                  const Text('Không tải được logs',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
                  const SizedBox(height: 4),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 448),
                    child: Text(
                      Failure.from(e).message,
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Đảm bảo tài khoản admin có quyền đọc bộ sưu tập aiMatchingLogs trên Firestore.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton.icon(
                    onPressed: () => ref.invalidate(aiLogsProvider(AppConfig.aiLogsPageLimit)),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Thử lại'),
                  ),
                ],
              ),
            ),
          ],
          data: (_) => filtered.isEmpty
              ? [_EmptyLogs(onGoJobs: () => context.go(AppRoutes.jobs))]
              : [
                  for (var i = 0; i < filtered.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    AiLogTile(
                      log: filtered[i],
                      expanded: _expandedId == filtered[i].logId,
                      onToggle: () => setState(() =>
                          _expandedId = _expandedId == filtered[i].logId ? null : filtered[i].logId),
                    ),
                  ],
                ],
        ),
      ],
    );
  }
}

class _CenteredCard extends StatelessWidget {
  const _CenteredCard({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.borderMuted),
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          boxShadow: AppShadows.card,
        ),
        child: Center(child: child),
      );
}

class _EmptyLogs extends StatelessWidget {
  const _EmptyLogs({required this.onGoJobs});
  final VoidCallback onGoJobs;

  @override
  Widget build(BuildContext context) {
    return _CenteredCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(color: AppColors.slate100, shape: BoxShape.circle),
            alignment: Alignment.center,
            child: const Icon(Icons.description_outlined, size: 28, color: AppColors.inkMuted),
          ),
          const SizedBox(height: 12),
          const Text('Chưa có log nào',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Text.rich(
              TextSpan(
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
                children: [
                  const TextSpan(text: 'Hãy dùng tính năng '),
                  const TextSpan(text: 'AI Matching', style: TextStyle(fontWeight: FontWeight.w700)),
                  const TextSpan(text: ' trên trang '),
                  TextSpan(
                    text: 'Việc làm',
                    style: const TextStyle(
                        color: AppColors.primary, decoration: TextDecoration.underline),
                    recognizer: TapGestureRecognizer()..onTap = onGoJobs,
                  ),
                  const TextSpan(text: ' để tạo log.'),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}
