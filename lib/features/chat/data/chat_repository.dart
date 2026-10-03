import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/misc_models.dart';

/// chats/{ChatThread.docIdFor(a, b)} + chats/{id}/messages (FLUTTER_REBUILD_PLAN §4).
///
/// Deterministic thread ids make "open chat with X" idempotent; the thread doc
/// carries the denormalised preview (lastMessage / unreadCounts) so the list
/// never needs to read the messages subcollection.
class ChatRepository {
  ChatRepository(this._refs, this._auth, this._storage);

  final FirestoreRefs _refs;
  final FirebaseAuth _auth;
  final StorageService _storage;

  static const messagesLimit = 200;
  static const maxMessageLength = 2000;

  /// Images above this size are rejected before upload.
  static const maxImageBytes = 5 * 1024 * 1024;

  /// Thread preview shown in the list for an image-only message.
  static const imagePreview = '📷 Ảnh';

  /// Shown when Firebase Storage rejects the upload (not enabled on the free
  /// plan / no bucket) — the chat keeps working text-only.
  static const imageUnavailableMessage = 'Tính năng gửi ảnh chưa khả dụng.';

  static const _previewLength = 200;

  User _requireUser() {
    final u = _auth.currentUser;
    if (u == null) throw const Failure.unauthorized();
    return u;
  }

  /// Creates (or refreshes) the 1-1 thread between me and [otherUid] and
  /// returns its chatId. Used by the employer review page / application
  /// detail to start a conversation about a job.
  Future<String> openChatWith({
    required String otherUid,
    required String otherName,
    String? jobId,
    String? jobTitle,
  }) async {
    final me = _requireUser();
    if (otherUid.trim().isEmpty) {
      throw const Failure.validation('Thiếu người nhận tin nhắn.');
    }
    if (otherUid == me.uid) {
      throw const Failure.validation('Không thể trò chuyện với chính mình.');
    }

    final chatId = ChatThread.docIdFor(me.uid, otherUid);
    final myName = await _resolveMyName(me);
    final cleanOther = otherName.trim().isEmpty ? 'Người dùng' : otherName.trim();

    try {
      await _refs.db.runTransaction((tx) async {
        final ref = _refs.chats().doc(chatId);
        final snap = await tx.get(ref);
        if (!snap.exists) {
          final participants = [me.uid, otherUid]..sort();
          tx.set(
            ref,
            ChatThread(
              chatId: chatId,
              participants: participants,
              participantNames: {me.uid: myName, otherUid: cleanOther},
              unreadCounts: {me.uid: 0, otherUid: 0},
              jobId: jobId,
              jobTitle: jobTitle,
            ),
          );
          return;
        }
        // Existing thread: refresh names / job context, keep ordering intact.
        // (Firebase uids never contain '.', so dotted paths are safe here.)
        tx.update(ref, <String, dynamic>{
          'participantNames.${me.uid}': myName,
          'participantNames.$otherUid': cleanOther,
          if (jobId != null && jobId.isNotEmpty) 'jobId': jobId,
          if (jobTitle != null && jobTitle.isNotEmpty) 'jobTitle': jobTitle,
        });
      });
    } catch (e) {
      throw Failure.from(e);
    }
    return chatId;
  }

  /// Threads I participate in, most recent first.
  /// Composite index: chats (participants ARRAY_CONTAINS, updatedAt DESC).
  Stream<List<ChatThread>> watchThreads(String uid) {
    return _refs
        .chats()
        .where('participants', arrayContains: uid)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((Object e) => throw Failure.from(e));
  }

  /// Single thread (null when it does not exist).
  Stream<ChatThread?> watchThread(String chatId) {
    return _refs
        .chats()
        .doc(chatId)
        .snapshots()
        .map((s) => s.exists ? s.data() : null)
        .handleError((Object e) => throw Failure.from(e));
  }

  /// Latest [messagesLimit] messages in chronological order.
  Stream<List<ChatMessage>> watchMessages(String chatId) {
    return _refs
        .messages(chatId)
        .orderBy('createdAt')
        .limitToLast(messagesLimit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((Object e) => throw Failure.from(e));
  }

  /// Appends a message and updates the thread preview + the other side's
  /// unread counter in one transaction.
  ///
  /// `createdAt` is left null so `ChatMessage.toJson` writes
  /// `FieldValue.serverTimestamp()`: ordering never depends on device clocks
  /// and the latency-compensated snapshot renders "Đang gửi…" until the
  /// server acknowledges. [imageUrl] (optional) makes this an image message;
  /// the thread preview then becomes "📷 Ảnh" (or "📷 <caption>").
  Future<void> sendMessage(String chatId, String text, {String? imageUrl}) async {
    final me = _requireUser();
    final content = text.trim();
    final image = imageUrl?.trim();
    final hasImage = image != null && image.isNotEmpty;
    if (content.isEmpty && !hasImage) return;
    if (content.length > maxMessageLength) {
      throw const Failure.validation('Tin nhắn tối đa 2000 ký tự.');
    }

    try {
      await _refs.db.runTransaction((tx) async {
        final threadRef = _refs.chats().doc(chatId);
        final snap = await tx.get(threadRef);
        final thread = snap.data();
        if (thread == null) {
          throw const Failure.notFound('Không tìm thấy cuộc trò chuyện.');
        }
        if (!thread.participants.contains(me.uid)) {
          throw const Failure.forbidden();
        }

        final msgRef = _refs.messages(chatId).doc();
        tx.set(
          msgRef,
          ChatMessage(
            messageId: msgRef.id,
            senderId: me.uid,
            content: content,
            imageUrl: hasImage ? image : null,
            // createdAt omitted on purpose → FieldValue.serverTimestamp().
          ),
        );

        final textPreview = content.length > _previewLength
            ? '${content.substring(0, _previewLength)}…'
            : content;
        final preview = hasImage
            ? (content.isEmpty ? imagePreview : '📷 $textPreview')
            : textPreview;
        final update = <String, dynamic>{
          'lastMessage': preview,
          'lastSenderId': me.uid,
          'updatedAt': FieldValue.serverTimestamp(),
          'unreadCounts.${me.uid}': 0,
        };
        for (final other in thread.participants.where((p) => p != me.uid)) {
          update['unreadCounts.$other'] = FieldValue.increment(1);
        }
        tx.update(threadRef, update);
      });
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Uploads [bytes] to `chat-images/{chatId}/{uid}/{ts}-{fileName}` and
  /// appends an image message (optionally with a text [caption]).
  ///
  /// Firebase Storage is NOT enabled on the project's free plan, so a failed
  /// upload is surfaced as a plain [Failure] ([imageUnavailableMessage]) and
  /// never crashes the room; network errors keep their own message.
  Future<void> sendImage(
    String chatId, {
    required Uint8List bytes,
    required String fileName,
    String caption = '',
  }) async {
    final me = _requireUser();
    if (bytes.isEmpty) {
      throw const Failure.validation('Không đọc được tệp ảnh.');
    }
    if (bytes.length > maxImageBytes) {
      throw const Failure.validation('Ảnh tối đa 5MB.');
    }
    if (caption.trim().length > maxMessageLength) {
      throw const Failure.validation('Tin nhắn tối đa 2000 ký tự.');
    }

    final String url;
    try {
      final trimmed = fileName.trim();
      final safeName =
          (trimmed.isEmpty ? 'image' : trimmed).replaceAll(RegExp(r'[^\w.\-]+'), '_');
      final res = await _storage.uploadImage(
        folder: 'chat-images/$chatId',
        uid: me.uid,
        bytes: bytes,
        fileName: '${DateTime.now().millisecondsSinceEpoch}-$safeName',
      );
      url = res.url;
    } catch (e) {
      final f = Failure.from(e);
      if (f.code == 'NETWORK') throw f;
      throw const Failure(imageUnavailableMessage, status: 503, code: 'STORAGE_UNAVAILABLE');
    }

    await sendMessage(chatId, caption, imageUrl: url);
  }

  /// Resets my unread counter on [chatId].
  Future<void> markRead(String chatId) async {
    final me = _requireUser();
    try {
      await _refs.chats().doc(chatId).update(<Object, Object?>{
        FieldPath(['unreadCounts', me.uid]): 0,
      });
    } on FirebaseException catch (e) {
      // Thread vanished — nothing to mark.
      if (e.code == 'not-found') return;
      throw Failure.from(e);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<String> _resolveMyName(User me) async {
    try {
      final snap = await _refs.users().doc(me.uid).get();
      final name = snap.data()?.fullName.trim();
      if (name != null && name.isNotEmpty) return name;
    } catch (_) {}
    final display = me.displayName?.trim();
    if (display != null && display.isNotEmpty) return display;
    return me.email ?? 'Người dùng';
  }
}

final chatRepositoryProvider = Provider<ChatRepository>(
  (ref) => ChatRepository(
    ref.watch(firestoreRefsProvider),
    ref.watch(firebaseAuthProvider),
    ref.watch(storageServiceProvider),
  ),
);
