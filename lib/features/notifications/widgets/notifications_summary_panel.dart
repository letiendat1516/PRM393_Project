import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../shared/models/notification_model.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../settings/widgets/adaptive_colors.dart';
import 'notification_type_meta.dart';

/// Right column on wide layouts: totals + breakdown by type + link to the
/// notification settings.
class NotificationsSummaryPanel extends StatelessWidget {
  const NotificationsSummaryPanel({super.key, required this.notifications});

  final List<NotificationModel> notifications;

  @override
  Widget build(BuildContext context) {
    final unread = notifications.where((n) => !n.isRead).length;
    final byType = <NotificationType, int>{};
    for (final n in notifications) {
      byType.update(n.type, (v) => v + 1, ifAbsent: () => 1);
    }
    final types = byType.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
    final titleStyle =
        TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.inkColor);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          color: context.surfaceColor,
          borderColor: context.borderMutedColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Tổng quan', style: titleStyle),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _Stat(label: 'Tất cả', value: notifications.length)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _Stat(label: 'Chưa đọc', value: unread, accent: unread > 0),
                  ),
                ],
              ),
              if (types.isNotEmpty) ...[
                const SizedBox(height: 18),
                Text('Theo loại',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: context.inkMutedColor,
                        letterSpacing: 0.4)),
                const SizedBox(height: 8),
                for (final e in types) _TypeRow(type: e.key, count: e.value),
              ],
            ],
          ),
        ),
        const SizedBox(height: 16),
        AppCard(
          color: context.surfaceColor,
          borderColor: context.borderMutedColor,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Cài đặt thông báo', style: titleStyle),
              const SizedBox(height: 6),
              Text(
                'Bật/tắt thông báo đẩy và chọn loại thông báo bạn muốn nhận.',
                style: TextStyle(fontSize: 13, color: context.inkSoftColor, height: 1.5),
              ),
              const SizedBox(height: 14),
              OutlinedButton.icon(
                onPressed: () => context.go(AppRoutes.settings),
                icon: const Icon(Icons.settings_outlined, size: 18),
                label: const Text('Mở cài đặt'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.label, required this.value, this.accent = false});
  final String label;
  final int value;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: accent ? context.primaryWashColor : context.canvasColor,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
            color: accent ? context.primaryWashBorderColor : context.borderMutedColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$value',
              style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: accent ? context.accentColor : context.inkColor,
                  height: 1.1)),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(fontSize: 12, color: context.inkMutedColor)),
        ],
      ),
    );
  }
}

class _TypeRow extends StatelessWidget {
  const _TypeRow({required this.type, required this.count});
  final NotificationType type;
  final int count;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = type.tintOf(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
            child: Icon(type.icon, size: 15, color: fg),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(type.label,
                style: TextStyle(
                    fontSize: 13, color: context.inkSoftColor, fontWeight: FontWeight.w500)),
          ),
          Text('$count',
              style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700, color: context.inkColor)),
        ],
      ),
    );
  }
}
