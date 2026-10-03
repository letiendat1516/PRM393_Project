import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../settings/widgets/adaptive_colors.dart';
import '../viewmodels/notifications_providers.dart';
import '../widgets/notification_navigator.dart';
import '../widgets/notification_tile.dart';
import '../widgets/notifications_summary_panel.dart';

/// Notification Center (FLUTTER_REBUILD_PLAN TVV5 #1): realtime list with
/// read/unread, "Đọc tất cả", filter tabs and navigation by type.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final all = ref.watch(notificationsStreamProvider);
    final filtered = ref.watch(filteredNotificationsProvider);
    final filter = ref.watch(notificationFilterProvider);
    final unread = ref.watch(unreadCountProvider);
    final action = ref.watch(notificationsControllerProvider);
    final isWide = MediaQuery.sizeOf(context).width >= 1024;

    ref.listen(notificationsControllerProvider, (_, next) {
      final err = next.error;
      if (err != null) {
        showFailure(context, err);
        ref.read(notificationsControllerProvider.notifier).clearError();
      }
    });

    Future<void> markAll() async {
      if (uid == null) return;
      final n = await ref.read(notificationsControllerProvider.notifier).markAllAsRead(uid);
      if (n != null && context.mounted) {
        showSuccess(context, n == 0 ? 'Không có thông báo chưa đọc.' : 'Đã đánh dấu $n thông báo là đã đọc.');
      }
    }

    Future<void> open(NotificationModel n) async {
      if (!n.isRead) {
        // Do not block navigation on the write.
        ref.read(notificationsControllerProvider.notifier).markAsRead(n.notificationId);
      }
      final route = notificationRouteFor(n.type, n.data);
      if (!context.mounted) return;
      if (route == GoRouterState.of(context).uri.path) return;
      context.push(route);
    }

    final list = filtered.when(
      loading: () => const RouteLoader(label: 'Đang tải thông báo…'),
      error: (e, _) => RouteErrorView(
        error: e,
        compact: true,
        onRetry: () => ref.invalidate(notificationsStreamProvider),
      ),
      data: (items) {
        if (items.isEmpty) {
          return EmptyState(
            icon: Icons.notifications_none,
            title: filter == NotificationFilter.unread ? 'Bạn đã đọc hết thông báo' : 'Chưa có thông báo',
            subtitle: filter == NotificationFilter.unread
                ? 'Không còn thông báo chưa đọc.'
                : 'Thông báo về hồ sơ ứng tuyển, tin tuyển dụng và hệ thống sẽ hiển thị tại đây.',
          );
        }
        return AppCard(
          padding: EdgeInsets.zero,
          color: context.surfaceColor,
          borderColor: context.borderMutedColor,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.x2l),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              itemCount: items.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) => NotificationTile(
                notification: items[i],
                onTap: () => open(items[i]),
              ),
            ),
          ),
        );
      },
    );

    final tabs = _FilterTabs(
      filter: filter,
      total: all.valueOrNull?.length ?? 0,
      unread: unread,
      onChanged: (f) => ref.read(notificationFilterProvider.notifier).state = f,
    );

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        tabs,
        const SizedBox(height: 16),
        Expanded(child: list),
      ],
    );

    return AppScaffold(
      title: 'Thông báo',
      actions: [
        if (uid != null)
          TextButton.icon(
            onPressed: unread == 0 || action.busy ? null : markAll,
            icon: action.busy
                ? const SizedBox(
                    width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.done_all, size: 18),
            label: const Text('Đọc tất cả'),
          ),
      ],
      body: isWide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 7, child: column),
                const SizedBox(width: 24),
                SizedBox(
                  width: 340,
                  child: SingleChildScrollView(
                    child: NotificationsSummaryPanel(notifications: all.valueOrNull ?? const []),
                  ),
                ),
              ],
            )
          : column,
    );
  }
}

/// "Tất cả (N)" / "Chưa đọc (N)" pill tabs.
class _FilterTabs extends StatelessWidget {
  const _FilterTabs({
    required this.filter,
    required this.total,
    required this.unread,
    required this.onChanged,
  });

  final NotificationFilter filter;
  final int total;
  final int unread;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final f in NotificationFilter.values)
          AppChip(
            label: '${f.label} (${f == NotificationFilter.unread ? unread : total})',
            selected: filter == f,
            onTap: () => onChanged(f),
          ),
      ],
    );
  }
}
