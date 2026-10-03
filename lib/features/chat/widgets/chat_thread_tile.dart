import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/misc_models.dart';
import '../../settings/widgets/adaptive_colors.dart';
import 'chat_avatar.dart';

/// Conversation row: avatar initial, other participant, job title, last
/// message (prefixed "Bạn: " when I sent it), relative time, unread badge.
class ChatThreadTile extends StatelessWidget {
  const ChatThreadTile({
    super.key,
    required this.thread,
    required this.me,
    this.selected = false,
    this.onTap,
  });

  final ChatThread thread;
  final String me;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final name = thread.otherName(me);
    final unread = thread.unreadCounts[me] ?? 0;
    final mineLast = thread.lastSenderId == me;
    final last = (thread.lastMessage ?? '').trim();

    return Material(
      color: selected ? context.primaryWashColor : context.surfaceColor,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ChatAvatar(name: name),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: unread > 0 ? FontWeight.w800 : FontWeight.w700,
                              color: context.inkColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          Formatters.relative(thread.updatedAt),
                          style: TextStyle(
                            fontSize: 11,
                            color: unread > 0 ? context.accentColor : context.inkMutedColor,
                            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    if ((thread.jobTitle ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Icon(Icons.work_outline, size: 12, color: context.inkMutedColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              thread.jobTitle!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 12, color: context.inkMutedColor),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            last.isEmpty ? 'Chưa có tin nhắn' : (mineLast ? 'Bạn: $last' : last),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              color: unread > 0 ? context.inkSoftColor : context.inkMutedColor,
                              fontWeight: unread > 0 ? FontWeight.w600 : FontWeight.w400,
                              fontStyle: last.isEmpty ? FontStyle.italic : FontStyle.normal,
                            ),
                          ),
                        ),
                        if (unread > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 20),
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              unread > 99 ? '99+' : '$unread',
                              style: const TextStyle(
                                  color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
