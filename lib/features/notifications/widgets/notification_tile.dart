import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/notification_model.dart';
import '../../settings/widgets/adaptive_colors.dart';
import 'notification_type_meta.dart';

/// One row of the Notification Center: type icon, title, message, relative
/// time and the unread dot. Unread rows get a primary-50 wash.
class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key, required this.notification, this.onTap});

  final NotificationModel notification;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final n = notification;
    final (bg, fg) = n.type.tintOf(context);
    final unread = !n.isRead;
    final unreadWash = context.isDark
        ? AppColors.primary.withValues(alpha: 0.18)
        : AppColors.primary50.withValues(alpha: 0.55);

    return Material(
      color: unread ? unreadWash : context.surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: bg,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Icon(n.type.icon, size: 20, color: fg),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread ? FontWeight.w700 : FontWeight.w600,
                              color: context.inkColor,
                              height: 1.35,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.relative(n.createdAt),
                          style: TextStyle(fontSize: 11, color: context.inkMutedColor),
                        ),
                      ],
                    ),
                    if (n.message.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        n.message,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.5,
                          color: unread ? context.inkSoftColor : context.inkMutedColor,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: bg,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        n.type.label,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: fg),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: unread
                    ? Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: context.accentColor,
                          shape: BoxShape.circle,
                        ),
                      )
                    : const SizedBox(width: 9, height: 9),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
