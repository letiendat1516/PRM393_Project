import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/notification_model.dart';

/// notifications/{id} access + FCM token registration (users/{uid}.fcmTokens).
///
/// Other features (applications / admin / employer) call [create] to write a
/// notification document; the Notification Center streams them back with
/// [watchForUser].
class NotificationsRepository {
  NotificationsRepository(this._refs, this._prefs, {this.messaging});

  final FirestoreRefs _refs;
  final PrefsService _prefs;

  /// Injectable for tests; defaults to [FirebaseMessaging.instance].
  final FirebaseMessaging? messaging;

  FirebaseMessaging get _fcm => messaging ?? FirebaseMessaging.instance;

  /// Firestore batches are capped at 500 writes.
  static const _batchLimit = 450;

  /// Writes a notification for [recipientId]. `data` carries the ids used for
  /// deep-linking (applicationId, jobId, …) — see `notificationRouteFor`.
  Future<void> create({
    required String recipientId,
    required UserRole recipientRole,
    required NotificationType type,
    required String title,
    required String message,
    Map<String, dynamic> data = const {},
  }) async {
    if (recipientId.trim().isEmpty) {
      throw const Failure.validation('Thiếu người nhận thông báo.');
    }
    try {
      final doc = _refs.notifications().doc();
      await doc.set(NotificationModel(
        notificationId: doc.id,
        recipientId: recipientId,
        recipientRole: recipientRole,
        type: type,
        title: title,
        message: message,
        data: data,
      ));
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Newest 50 notifications of [uid] (live).
  /// Composite index: notifications (recipientId ASC, createdAt DESC).
  Stream<List<NotificationModel>> watchForUser(String uid, {int limit = 50}) {
    return _refs
        .notifications()
        .where('recipientId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()).toList())
        .handleError((Object e) => throw Failure.from(e));
  }

  Future<void> markAsRead(String notificationId) async {
    if (notificationId.isEmpty) return;
    try {
      await _refs.notifications().doc(notificationId).update({'isRead': true});
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Marks every unread notification of [uid] as read (chunked batches).
  Future<int> markAllAsRead(String uid) async {
    try {
      final snap = await _refs
          .notifications()
          .where('recipientId', isEqualTo: uid)
          .where('isRead', isEqualTo: false)
          .get();
      if (snap.docs.isEmpty) return 0;

      final docs = snap.docs;
      for (var i = 0; i < docs.length; i += _batchLimit) {
        final batch = _refs.db.batch();
        for (final d in docs.skip(i).take(_batchLimit)) {
          batch.update(d.reference, {'isRead': true});
        }
        await batch.commit();
      }
      return docs.length;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Fetches the device FCM token, adds it to users/{uid}.fcmTokens and caches
  /// it in SharedPreferences. Returns the token (null when unavailable, e.g.
  /// permission denied or web without a VAPID key).
  Future<String?> registerFcmToken(String uid) async {
    try {
      final token = await _fcm.getToken();
      if (token == null || token.isEmpty) return null;
      await _refs.db.collection(FirestoreRefs.colUsers).doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );
      await _prefs.setFcmToken(token);
      return token;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Removes the cached token from users/{uid}.fcmTokens (notifications turned
  /// off or sign out) and forgets it locally.
  Future<void> unregisterFcmToken(String uid) async {
    final token = _prefs.fcmToken;
    if (token == null || token.isEmpty) return;
    try {
      await _refs.db.collection(FirestoreRefs.colUsers).doc(uid).set(
        {'fcmTokens': FieldValue.arrayRemove([token])},
        SetOptions(merge: true),
      );
      await _prefs.setFcmToken(null);
    } catch (e) {
      throw Failure.from(e);
    }
  }
}

final notificationsRepositoryProvider = Provider<NotificationsRepository>(
  (ref) => NotificationsRepository(
    ref.watch(firestoreRefsProvider),
    ref.watch(prefsServiceProvider),
  ),
);
