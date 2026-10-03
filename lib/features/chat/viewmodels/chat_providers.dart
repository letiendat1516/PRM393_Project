import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/misc_models.dart';
import '../data/chat_repository.dart';

/// Current auth uid (null when signed out).
final chatMeProvider = Provider<String?>((ref) => ref.watch(authStateProvider).valueOrNull?.uid);

/// My conversations, most recent first.
final chatThreadsProvider = StreamProvider.autoDispose<List<ChatThread>>((ref) {
  final uid = ref.watch(chatMeProvider);
  if (uid == null) return Stream.value(const <ChatThread>[]);
  return ref.watch(chatRepositoryProvider).watchThreads(uid);
});

/// Sum of my unread counters across threads (navbar/drawer badge).
final unreadChatsCountProvider = Provider.autoDispose<int>((ref) {
  final uid = ref.watch(chatMeProvider);
  if (uid == null) return 0;
  final threads = ref.watch(chatThreadsProvider).valueOrNull ?? const [];
  return threads.fold<int>(0, (sum, t) => sum + (t.unreadCounts[uid] ?? 0));
});

final chatThreadProvider = StreamProvider.autoDispose.family<ChatThread?, String>(
  (ref, chatId) => ref.watch(chatRepositoryProvider).watchThread(chatId),
);

final chatMessagesProvider = StreamProvider.autoDispose.family<List<ChatMessage>, String>(
  (ref, chatId) => ref.watch(chatRepositoryProvider).watchMessages(chatId),
);

/// Send / mark-read actions for one room.
class ChatRoomState {
  const ChatRoomState({this.sending = false, this.error});
  final bool sending;
  final Failure? error;

  ChatRoomState copyWith({bool? sending, Failure? error, bool clearError = false}) =>
      ChatRoomState(
        sending: sending ?? this.sending,
        error: clearError ? null : (error ?? this.error),
      );
}

class ChatRoomController extends StateNotifier<ChatRoomState> {
  ChatRoomController(this._repo, this.chatId) : super(const ChatRoomState());

  final ChatRepository _repo;
  final String chatId;

  /// Returns true when the message was written.
  Future<bool> send(String text) async {
    if (text.trim().isEmpty || state.sending) return false;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repo.sendMessage(chatId, text);
      state = state.copyWith(sending: false);
      return true;
    } catch (e) {
      state = state.copyWith(sending: false, error: Failure.from(e));
      return false;
    }
  }

  /// Uploads the picked image and sends it (with an optional [caption]).
  /// Returns true when the message was written; upload failures (Storage not
  /// enabled) end up in [ChatRoomState.error] for the view to toast.
  Future<bool> sendImage(Uint8List bytes, String fileName, {String caption = ''}) async {
    if (state.sending) return false;
    state = state.copyWith(sending: true, clearError: true);
    try {
      await _repo.sendImage(chatId, bytes: bytes, fileName: fileName, caption: caption);
      state = state.copyWith(sending: false);
      return true;
    } catch (e) {
      state = state.copyWith(sending: false, error: Failure.from(e));
      return false;
    }
  }

  Future<void> markRead() async {
    try {
      await _repo.markRead(chatId);
    } catch (_) {
      // Best effort — the counter is cosmetic.
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final chatRoomControllerProvider =
    StateNotifierProvider.autoDispose.family<ChatRoomController, ChatRoomState, String>(
  (ref, chatId) => ChatRoomController(ref.watch(chatRepositoryProvider), chatId),
);
