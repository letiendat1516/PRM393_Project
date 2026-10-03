import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/sessions_provider.dart';
import '../widgets/recommendations_shell.dart';

/// /de-xuat — RecommendedPage.jsx: list of saved AI/SQL scoring sessions.
/// Public (no RoleGuard); data comes from the local session store, mirrored
/// to users/{uid}/aiSessions when signed in.
class RecommendedPage extends ConsumerWidget {
  const RecommendedPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessions = ref.watch(sessionsProvider);

    return RecommendationsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Breadcrumb(items: [
            ('Trang chủ', () => context.go(AppRoutes.home)),
            ('Đề xuất việc làm', null),
          ]),
          const SizedBox(height: 16),
          sessions.when(
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 80),
              child: RouteLoader(),
            ),
            error: (e, _) => RouteErrorView(
              error: e,
              compact: true,
              onRetry: () => ref.read(sessionsProvider.notifier).refresh(),
            ),
            data: (list) => Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(count: list.length, onClearAll: () => _confirmClear(context, ref)),
                const SizedBox(height: 24),
                if (list.isEmpty)
                  const _EmptyCard()
                else
                  for (var i = 0; i < list.length; i++) ...[
                    SessionRow(session: list[i]),
                    if (i < list.length - 1) const SizedBox(height: 12),
                  ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmClear(BuildContext context, WidgetRef ref) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Xoá toàn bộ phiên chấm điểm?'),
        content: const Text('Tất cả phiên chấm điểm đã lưu trên thiết bị này sẽ bị xoá.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Huỷ')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red600),
            child: const Text('Xoá tất cả'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(sessionsProvider.notifier).clearAll();
      if (context.mounted) showSuccess(context, 'Đã xoá toàn bộ phiên chấm điểm.');
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}

/// H1 with sparkles + conditional subtitle + 'Xoá tất cả' (only when > 0).
class _Header extends StatelessWidget {
  const _Header({required this.count, required this.onClearAll});
  final int count;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.of(context).size.width >= 640;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 28, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Đề xuất việc làm',
                      style: TextStyle(
                        fontSize: wide ? 30 : 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.2,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                count > 0
                    ? '$count phiên chấm điểm. Bấm vào phiên để xem chi tiết.'
                    : 'Các phiên chấm điểm AI/SQL sẽ xuất hiện ở đây.',
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
              ),
            ],
          ),
        ),
        if (count > 0) ...[
          const SizedBox(width: 12),
          OutlinedButton.icon(
            onPressed: onClearAll,
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              minimumSize: const Size(0, 40),
            ),
            icon: const Icon(Icons.close, size: 16),
            label: const Text('Xoá tất cả'),
          ),
        ],
      ],
    );
  }
}

/// `.card flex flex-col items-center justify-center px-6 py-20 text-center`.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 80),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(color: AppColors.primary50, shape: BoxShape.circle),
            child: const Icon(Icons.auto_awesome, size: 36, color: AppColors.primary),
          ),
          const SizedBox(height: 16),
          const Text(
            'Chưa có phiên chấm điểm nào',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 8),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: Text.rich(
              const TextSpan(children: [
                TextSpan(text: 'Truy cập trang việc làm, filter xuống ≤100 jobs, rồi bấm '),
                TextSpan(
                  text: 'AI Matching',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                TextSpan(text: ' để AI chấm điểm phù hợp. Mỗi lần chấm sẽ tạo 1 phiên lưu ở đây.'),
              ]),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => context.go(AppRoutes.jobs),
            icon: const Icon(Icons.search, size: 18),
            label: const Text('Đi tới việc làm'),
          ),
        ],
      ),
    );
  }
}

