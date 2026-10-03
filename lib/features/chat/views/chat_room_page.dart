import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../settings/widgets/adaptive_colors.dart';
import '../viewmodels/chat_providers.dart';
import '../widgets/chat_room_view.dart';
import '../widgets/chat_thread_list.dart';

/// /tin-nhan/:chatId — realtime bubbles + composer. Wide screens keep the
/// thread list on the left (same split frame as [ChatsPage]).
class ChatRoomPage extends ConsumerWidget {
  const ChatRoomPage({super.key, required this.chatId});

  final String chatId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWide = MediaQuery.sizeOf(context).width >= 1024;
    final me = ref.watch(chatMeProvider);
    final thread = ref.watch(chatThreadProvider(chatId)).valueOrNull;
    final title = (me != null && thread != null) ? thread.otherName(me) : 'Tin nhắn';

    if (isWide) {
      return AppScaffold(
        title: 'Tin nhắn',
        body: ChatSplitLayout(
          list: ChatThreadList(
            selectedChatId: chatId,
            onSelect: (id) => context.go(AppRoutes.chatRoomOf(id)),
          ),
          detail: ChatRoomView(key: ValueKey(chatId), chatId: chatId),
        ),
      );
    }

    return AppScaffold(
      title: title,
      body: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: context.surfaceColor,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: context.borderMutedColor),
          boxShadow: context.isDark ? null : AppShadows.card,
        ),
        child: ChatRoomView(key: ValueKey(chatId), chatId: chatId, showBack: true),
      ),
    );
  }
}
