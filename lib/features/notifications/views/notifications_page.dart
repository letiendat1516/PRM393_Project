import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../viewmodels/notifications_providers.dart';
import '../widgets/notification_navigator.dart';
import '../widgets/notification_tile.dart';

/// Notification Center — TopCV-style layout:
/// AppBar with filter/mark-all actions → horizontal category pills →
/// optional "Thông báo đang tắt" banner (when the FCM toggle is off) →
/// a day-grouped list of [NotificationTile] rows.
class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uid = ref.watch(authStateProvider).valueOrNull?.uid;
    final all = ref.watch(notificationsStreamProvider);
    final filtered = ref.watch(filteredNotificationsProvider);
    final category = ref.watch(notificationCategoryProvider);
    final filter = ref.watch(notificationFilterProvider);
    final unread = ref.watch(unreadCountProvider);
    final action = ref.watch(notificationsControllerProvider);
    final fcmEnabled =
        ref.watch(settingsProvider.select((s) => s.notificationsEnabled));

    ref.listen(notificationsControllerProvider, (_, next) {
      final err = next.error;
      if (err != null) {
        showFailure(context, err);
        ref.read(notificationsControllerProvider.notifier).clearError();
      }
    });

    Future<void> markAll() async {
      if (uid == null) return;
      final n = await ref
          .read(notificationsControllerProvider.notifier)
          .markAllAsRead(uid);
      if (n != null && context.mounted) {
        showSuccess(
            context,
            n == 0
                ? 'Không có thông báo chưa đọc.'
                : 'Đã đánh dấu $n thông báo là đã đọc.');
      }
    }

    Future<void> open(NotificationModel n) async {
      if (!n.isRead) {
        ref
            .read(notificationsControllerProvider.notifier)
            .markAsRead(n.notificationId);
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
            title: filter == NotificationFilter.unread
                ? 'Bạn đã đọc hết thông báo'
                : category == NotificationCategory.all
                    ? 'Chưa có thông báo'
                    : 'Chưa có thông báo ${category.label.toLowerCase()}',
            subtitle: filter == NotificationFilter.unread
                ? 'Không còn thông báo chưa đọc.'
                : 'Thông báo mới sẽ hiển thị tại đây.',
          );
        }
        return _DayGroupedList(items: items, onTap: open);
      },
    );

    return AppScaffold(
      title: 'Thông báo',
      actions: [
        if (uid != null)
          IconButton(
            tooltip: filter == NotificationFilter.unread
                ? 'Bỏ lọc chưa đọc'
                : 'Chỉ hiện chưa đọc',
            onPressed: () => ref.read(notificationFilterProvider.notifier).state =
                filter == NotificationFilter.unread
                    ? NotificationFilter.all
                    : NotificationFilter.unread,
            icon: Icon(
              Icons.filter_list,
              color: filter == NotificationFilter.unread
                  ? AppColors.primary
                  : AppColors.inkSoft,
            ),
          ),
        if (uid != null)
          IconButton(
            tooltip: 'Đọc tất cả',
            onPressed: unread == 0 || action.busy ? null : markAll,
            icon: action.busy
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.done_all, color: AppColors.inkSoft),
          ),
      ],
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CategoryTabs(
            current: category,
            onChanged: (c) =>
                ref.read(notificationCategoryProvider.notifier).state = c,
          ),
          if (!fcmEnabled) ...[
            const SizedBox(height: 12),
            _FcmOffBanner(
              totalCount: all.valueOrNull?.length ?? 0,
              onEnable: () => ref
                  .read(settingsProvider.notifier)
                  .setNotifications(true),
            ),
          ],
          const SizedBox(height: 12),
          Expanded(child: list),
        ],
      ),
    );
  }
}

/// TopCV-style horizontal pills: Tất cả · Việc làm · Trạng thái CV · Kết
/// nối · Hệ thống. Active chip gets a primary outline + text; the rest
/// are subdued.
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.current, required this.onChanged});

  final NotificationCategory current;
  final ValueChanged<NotificationCategory> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Row(
        children: [
          for (final c in NotificationCategory.values) ...[
            _CategoryPill(
              label: c.label,
              selected: current == c,
              onTap: () => onChanged(c),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final border = selected ? AppColors.primary : AppColors.border;
    final text = selected ? AppColors.primary : AppColors.inkSoft;
    final bg = selected ? AppColors.primary50 : AppColors.surface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 1.2),
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: text,
          ),
        ),
      ),
    );
  }
}

/// Dismissible promotional card shown when the FCM toggle is off. CTA
/// routes through [SettingsViewModel.setNotifications(true)] rather than
/// jumping into system settings — the FCM registration listener picks it
/// up automatically on the next frame.
class _FcmOffBanner extends StatelessWidget {
  const _FcmOffBanner({required this.totalCount, required this.onEnable});

  final int totalCount;
  final VoidCallback onEnable;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary50,
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        border: Border.all(color: AppColors.primary100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.notifications_active_outlined,
                  color: AppColors.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Thông báo đang tắt',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      totalCount > 0
                          ? 'Bật thông báo để cập nhật trạng thái ứng tuyển và các cơ hội việc làm phù hợp.'
                          : 'Bật thông báo để nhận cập nhật ngay khi có.',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.inkSoft,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onEnable,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                elevation: 0,
              ),
              child: const Text(
                'Bật thông báo ngay',
                style:
                    TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A ListView that chunks the (newest-first) notifications by local day and
/// prepends each chunk with a muted "DD/MM/YYYY" header — the TopCV layout
/// for grouping notifications by date without a secondary scroll view.
class _DayGroupedList extends StatelessWidget {
  const _DayGroupedList({required this.items, required this.onTap});

  final List<NotificationModel> items;
  final void Function(NotificationModel) onTap;

  @override
  Widget build(BuildContext context) {
    final groups = _groupByDay(items);
    // Flatten (header + tiles) into a single children list so one scroll
    // view manages everything — simpler than nested ListViews.
    final rows = <Widget>[];
    for (var g = 0; g < groups.length; g++) {
      final group = groups[g];
      rows.add(_DayHeader(label: group.label));
      for (var i = 0; i < group.items.length; i++) {
        final n = group.items[i];
        rows.add(NotificationTile(
          notification: n,
          onTap: () => onTap(n),
        ));
        if (i < group.items.length - 1) {
          rows.add(const Divider(height: 1, indent: 72));
        }
      }
      if (g < groups.length - 1) {
        rows.add(const SizedBox(height: 16));
      }
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 24),
      children: rows,
    );
  }

  static List<_DayGroup> _groupByDay(List<NotificationModel> items) {
    final out = <_DayGroup>[];
    DateTime? lastKey;
    for (final n in items) {
      final d = n.createdAt ?? DateTime.now();
      final key = DateTime(d.year, d.month, d.day);
      if (lastKey == null || key != lastKey) {
        out.add(_DayGroup(label: _formatDay(key), items: [n]));
        lastKey = key;
      } else {
        out.last.items.add(n);
      }
    }
    return out;
  }

  static String _formatDay(DateTime day) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(day).inDays;
    if (diff == 0) return 'Hôm nay';
    if (diff == 1) return 'Hôm qua';
    final dd = day.day.toString().padLeft(2, '0');
    final mm = day.month.toString().padLeft(2, '0');
    return '$dd/$mm/${day.year}';
  }
}

class _DayGroup {
  _DayGroup({required this.label, required this.items});
  final String label;
  final List<NotificationModel> items;
}

class _DayHeader extends StatelessWidget {
  const _DayHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.inkMuted,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
}
