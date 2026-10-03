import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../settings/widgets/adaptive_colors.dart';
import '../viewmodels/chat_providers.dart';
import 'chat_thread_tile.dart';

/// Scrollable list of my conversations with loading / empty / error states.
class ChatThreadList extends ConsumerWidget {
  const ChatThreadList({super.key, this.selectedChatId, required this.onSelect});

  final String? selectedChatId;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final me = ref.watch(chatMeProvider);
    final threads = ref.watch(chatThreadsProvider);

    if (me == null) {
      return EmptyState(
        icon: Icons.lock_outline,
        title: 'Vui lòng đăng nhập để xem tin nhắn',
        action: ElevatedButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('Đăng nhập'),
        ),
      );
    }

    return threads.when(
      loading: () => const RouteLoader(label: 'Đang tải tin nhắn…'),
      error: (e, _) => RouteErrorView(
        error: e,
        compact: true,
        onRetry: () => ref.invalidate(chatThreadsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return const EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Chưa có cuộc trò chuyện nào',
            subtitle:
                'Nhà tuyển dụng và ứng viên có thể bắt đầu trò chuyện từ trang hồ sơ ứng tuyển.',
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
              itemCount: list.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final t = list[i];
                return ChatThreadTile(
                  thread: t,
                  me: me,
                  selected: t.chatId == selectedChatId,
                  onTap: () => onSelect(t.chatId),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

/// Wide (≥ 1024) master-detail frame: thread list on the left, [detail] on
/// the right.
class ChatSplitLayout extends StatelessWidget {
  const ChatSplitLayout({super.key, required this.list, required this.detail});

  final Widget list;
  final Widget detail;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(width: 360, child: list),
        const SizedBox(width: 20),
        Expanded(
          child: Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: context.surfaceColor,
              borderRadius: BorderRadius.circular(AppRadius.x2l),
              border: Border.all(color: context.borderMutedColor),
              boxShadow: context.isDark ? null : AppShadows.card,
            ),
            child: detail,
          ),
        ),
      ],
    );
  }
}
