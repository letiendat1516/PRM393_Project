import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../settings/widgets/adaptive_colors.dart';
import '../viewmodels/chat_providers.dart';
import '../widgets/chat_thread_list.dart';

/// Conversation list (FLUTTER_REBUILD_PLAN TVV5 #2). On wide screens the
/// right pane invites the user to pick a thread; picking one navigates to
/// /tin-nhan/:chatId which renders the same split layout with the room.
class ChatsPage extends ConsumerWidget {
  const ChatsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final unread = ref.watch(unreadChatsCountProvider);

    void open(String chatId) {
      if (isWide) {
        context.go(AppRoutes.chatRoomOf(chatId));
      } else {
        context.push(AppRoutes.chatRoomOf(chatId));
      }
    }

    final list = ChatThreadList(onSelect: open);

    return AppScaffold(
      title: 'Tin nhắn',
      actions: [
        if (unread > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: context.primaryWashColor,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              '$unread chưa đọc',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w700, color: context.accentColor),
            ),
          ),
      ],
      body: isWide
          ? ChatSplitLayout(
              list: list,
              detail: const _PickThreadPlaceholder(),
            )
          : list,
    );
  }
}

class _PickThreadPlaceholder extends StatelessWidget {
  const _PickThreadPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: context.primaryWashColor, shape: BoxShape.circle),
            child: Icon(Icons.forum_outlined, size: 32, color: context.accentColor),
          ),
          const SizedBox(height: 16),
          Text('Chọn một cuộc trò chuyện',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: context.inkColor)),
          const SizedBox(height: 6),
          Text(
            'Tin nhắn giữa bạn và đối phương sẽ hiển thị tại đây.',
            style: TextStyle(fontSize: 13, color: context.inkMutedColor),
          ),
        ],
      ),
    );
  }
}
