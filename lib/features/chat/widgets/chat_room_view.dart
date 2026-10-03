import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/misc_models.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../settings/widgets/adaptive_colors.dart';
import '../viewmodels/chat_providers.dart';
import 'chat_avatar.dart';
import 'message_bubble.dart';

/// Header + realtime message list + composer for one thread. Used by
/// [ChatRoomPage] on phones and as the detail pane of the wide layout.
class ChatRoomView extends ConsumerStatefulWidget {
  const ChatRoomView({super.key, required this.chatId, this.showBack = false});

  final String chatId;

  /// Shows a back arrow in the header (phone layout).
  final bool showBack;

  @override
  ConsumerState<ChatRoomView> createState() => _ChatRoomViewState();
}

class _ChatRoomViewState extends ConsumerState<ChatRoomView> {
  final _scroll = ScrollController();
  final _input = TextEditingController();
  final _focus = FocusNode();
  int _lastCount = -1;
  bool _canSend = false;
  bool _picking = false;

  @override
  void initState() {
    super.initState();
    _input.addListener(() {
      final v = _input.text.trim().isNotEmpty;
      if (v != _canSend) setState(() => _canSend = v);
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _scrollToBottom({bool animate = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final max = _scroll.position.maxScrollExtent;
      if (animate) {
        _scroll.animateTo(max, duration: const Duration(milliseconds: 220), curve: Curves.easeOut);
      } else {
        _scroll.jumpTo(max);
      }
    });
  }

  Future<void> _send() async {
    final text = _input.text;
    if (text.trim().isEmpty) return;
    _input.clear();
    final ok = await ref.read(chatRoomControllerProvider(widget.chatId).notifier).send(text);
    if (!mounted) return;
    if (!ok) {
      _input.text = text; // keep what the user typed
    } else {
      _scrollToBottom();
    }
    _focus.requestFocus();
  }

  /// "Gửi ảnh" (FLUTTER_REBUILD_PLAN TVV5 #2): pick an image with file_picker
  /// (works on mobile + web via bytes), upload through StorageService and send
  /// it as an image message. Whatever is typed in the composer becomes the
  /// caption. Failures (Storage not enabled, oversize, unreadable file) are
  /// toasted via the controller's error state — never thrown into the UI.
  Future<void> _pickImage() async {
    if (_picking) return;
    setState(() => _picking = true);
    FilePickerResult? result;
    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.image,
        allowMultiple: false,
        withData: true,
        dialogTitle: 'Chọn ảnh để gửi',
      );
    } catch (_) {
      if (mounted) {
        showFailure(context, const Failure('Không mở được thư viện ảnh.', code: 'PICKER'));
      }
      result = null;
    } finally {
      if (mounted) setState(() => _picking = false);
    }
    if (!mounted || result == null || result.files.isEmpty) return;

    final file = result.files.single;
    final bytes = file.bytes;
    if (bytes == null || bytes.isEmpty) {
      showFailure(context, const Failure.validation('Không đọc được tệp ảnh.'));
      return;
    }

    final caption = _input.text;
    final ok = await ref
        .read(chatRoomControllerProvider(widget.chatId).notifier)
        .sendImage(bytes, file.name, caption: caption);
    if (!mounted) return;
    if (ok) {
      _input.clear();
      _scrollToBottom();
    }
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final me = ref.watch(chatMeProvider);
    final thread = ref.watch(chatThreadProvider(widget.chatId));
    final messages = ref.watch(chatMessagesProvider(widget.chatId));
    final room = ref.watch(chatRoomControllerProvider(widget.chatId));

    ref.listen(chatRoomControllerProvider(widget.chatId), (_, next) {
      final err = next.error;
      if (err != null) {
        showFailure(context, err);
        ref.read(chatRoomControllerProvider(widget.chatId).notifier).clearError();
      }
    });

    // Reset my unread counter whenever the thread shows unread for me.
    ref.listen(chatThreadProvider(widget.chatId), (_, next) {
      final t = next.valueOrNull;
      if (me != null && t != null && (t.unreadCounts[me] ?? 0) > 0) {
        ref.read(chatRoomControllerProvider(widget.chatId).notifier).markRead();
      }
    });

    // Auto-scroll when new messages arrive.
    final count = messages.valueOrNull?.length ?? -1;
    if (count >= 0 && count != _lastCount) {
      final first = _lastCount == -1;
      _lastCount = count;
      _scrollToBottom(animate: !first);
    }

    if (me == null) {
      return const Center(child: RouteLoader());
    }

    return thread.when(
      loading: () => const RouteLoader(label: 'Đang mở cuộc trò chuyện…'),
      error: (e, _) => RouteErrorView(
        error: e,
        compact: true,
        onRetry: () => ref.invalidate(chatThreadProvider(widget.chatId)),
      ),
      data: (t) {
        if (t == null) {
          return EmptyState(
            icon: Icons.chat_bubble_outline,
            title: 'Không tìm thấy cuộc trò chuyện',
            subtitle: 'Cuộc trò chuyện này không tồn tại hoặc bạn không có quyền truy cập.',
            action: OutlinedButton(
              onPressed: () => context.go(AppRoutes.chats),
              child: const Text('Về danh sách tin nhắn'),
            ),
          );
        }
        if (!t.participants.contains(me)) {
          return const EmptyState(
            icon: Icons.lock_outline,
            title: 'Bạn không có quyền xem cuộc trò chuyện này',
          );
        }
        final busy = room.sending || _picking;
        return Column(
          children: [
            _Header(thread: t, me: me, showBack: widget.showBack),
            const Divider(height: 1),
            Expanded(
              child: messages.when(
                loading: () => const RouteLoader(),
                error: (e, _) => RouteErrorView(
                  error: e,
                  compact: true,
                  onRetry: () => ref.invalidate(chatMessagesProvider(widget.chatId)),
                ),
                data: (list) => list.isEmpty
                    ? const EmptyState(
                        icon: Icons.waving_hand_outlined,
                        title: 'Chưa có tin nhắn',
                        subtitle: 'Hãy gửi lời chào để bắt đầu cuộc trò chuyện.',
                      )
                    : _MessageList(messages: list, me: me, controller: _scroll),
              ),
            ),
            const Divider(height: 1),
            _Composer(
              controller: _input,
              focusNode: _focus,
              sending: room.sending,
              canSend: _canSend && !busy,
              canAttach: !busy,
              onSend: _send,
              onAttach: _pickImage,
            ),
          ],
        );
      },
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.thread, required this.me, required this.showBack});
  final ChatThread thread;
  final String me;
  final bool showBack;

  @override
  Widget build(BuildContext context) {
    final name = thread.otherName(me);
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
      child: Row(
        children: [
          if (showBack)
            IconButton(
              tooltip: 'Quay lại',
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go(AppRoutes.chats);
                }
              },
            )
          else
            const SizedBox(width: 8),
          ChatAvatar(name: name, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: context.inkColor)),
                if ((thread.jobTitle ?? '').isNotEmpty)
                  Text(thread.jobTitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: context.inkMutedColor)),
              ],
            ),
          ),
          if ((thread.jobId ?? '').isNotEmpty)
            TextButton.icon(
              onPressed: () => context.push(AppRoutes.jobDetailOf(thread.jobId!)),
              icon: const Icon(Icons.work_outline, size: 16),
              label: const Text('Xem tin'),
            ),
        ],
      ),
    );
  }
}

class _MessageList extends StatelessWidget {
  const _MessageList({required this.messages, required this.me, required this.controller});
  final List<ChatMessage> messages;
  final String me;
  final ScrollController controller;

  static bool _sameDay(DateTime? a, DateTime? b) =>
      a != null && b != null && a.year == b.year && a.month == b.month && a.day == b.day;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      controller: controller,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      itemCount: messages.length,
      itemBuilder: (_, i) {
        final m = messages[i];
        final prev = i > 0 ? messages[i - 1] : null;
        final next = i < messages.length - 1 ? messages[i + 1] : null;
        final newDay = prev == null || !_sameDay(prev.createdAt, m.createdAt);
        // Collapse the timestamp when the same sender continues within 2 min.
        final grouped = next != null &&
            next.senderId == m.senderId &&
            next.createdAt != null &&
            m.createdAt != null &&
            next.createdAt!.difference(m.createdAt!).inMinutes < 2;

        return Padding(
          padding: EdgeInsets.only(bottom: grouped ? 4 : 10),
          child: Column(
            children: [
              if (newDay && m.createdAt != null) DaySeparator(day: m.createdAt!),
              MessageBubble(message: m, mine: m.senderId == me, showTime: !grouped),
            ],
          ),
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer({
    required this.controller,
    required this.focusNode,
    required this.sending,
    required this.canSend,
    required this.canAttach,
    required this.onSend,
    required this.onAttach,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool sending;
  final bool canSend;
  final bool canAttach;
  final VoidCallback onSend;
  final VoidCallback onAttach;

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.x3l),
          borderSide: BorderSide(color: c, width: w),
        );

    return Container(
      color: context.surfaceColor,
      padding: const EdgeInsets.fromLTRB(6, 10, 12, 12),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton(
                tooltip: 'Gửi ảnh',
                onPressed: canAttach ? onAttach : null,
                color: context.inkMutedColor,
                icon: const Icon(Icons.image_outlined, size: 22),
              ),
            ),
            const SizedBox(width: 2),
            Expanded(
              child: TextField(
                controller: controller,
                focusNode: focusNode,
                minLines: 1,
                maxLines: 4,
                textInputAction: TextInputAction.send,
                textCapitalization: TextCapitalization.sentences,
                onSubmitted: (_) => canSend ? onSend() : null,
                decoration: InputDecoration(
                  hintText: 'Nhập tin nhắn…',
                  fillColor: context.canvasColor,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: border(context.borderColor),
                  enabledBorder: border(context.borderColor),
                  focusedBorder: border(context.accentColor, 1.5),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 46,
              height: 46,
              child: IconButton.filled(
                tooltip: 'Gửi',
                onPressed: canSend ? onSend : null,
                style: IconButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.35),
                  foregroundColor: Colors.white,
                ),
                icon: sending
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send_rounded, size: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
