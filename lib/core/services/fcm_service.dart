import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import 'prefs_service.dart';

/// Firebase Cloud Messaging + local notifications (teacher requirement).
/// Never throws out of [initialize] — a denied permission or a missing web
/// VAPID key must not break app start-up.
class FcmService {
  FcmService._();
  static final FcmService instance = FcmService._();

  /// Web push needs a VAPID key: `--dart-define=FCM_VAPID_KEY=...`
  /// (Firebase Console → Project settings → Cloud Messaging → Web Push certificates).
  static const String vapidKey = String.fromEnvironment('FCM_VAPID_KEY');

  final _plugin = FlutterLocalNotificationsPlugin();
  final _tapController = StreamController<Map<String, dynamic>>.broadcast();
  bool _initialized = false;
  String? _token;
  Map<String, dynamic>? _pendingTap;

  /// Emits the `data` payload of a notification the user tapped
  /// (background/terminated FCM or a foreground local notification).
  Stream<Map<String, dynamic>> get onNotificationTap => _tapController.stream;
  String? get token => _token;

  /// Returns (and clears) a tap payload that arrived before anyone listened to
  /// [onNotificationTap] — e.g. `getInitialMessage()` resolved in `main()`
  /// before the router existed. firebase_messaging consumes the initial
  /// message on first read, so it must be buffered here.
  Map<String, dynamic>? takePendingTap() {
    final p = _pendingTap;
    _pendingTap = null;
    return p;
  }

  void _emitTap(Map<String, dynamic> data) {
    if (data.isEmpty) return;
    if (_tapController.hasListener) {
      _tapController.add(data);
    } else {
      _pendingTap = data;
    }
  }

  static const channel = AndroidNotificationChannel(
    'jobhub_default',
    'JobHub notifications',
    description: 'Thông báo từ JobHub (hồ sơ ứng tuyển, tin tuyển dụng, hệ thống).',
    importance: Importance.high,
  );

  Future<void> initialize() async {
    if (_initialized) return;
    _initialized = true;
    final messaging = FirebaseMessaging.instance;

    try {
      await messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e) {
      debugPrint('FCM permission: $e');
    }

    if (!kIsWeb) {
      try {
        await _plugin.initialize(
          const InitializationSettings(
            android: AndroidInitializationSettings('@mipmap/ic_launcher'),
            iOS: DarwinInitializationSettings(),
          ),
          onDidReceiveNotificationResponse: (resp) {
            final payload = resp.payload;
            if (payload == null || payload.isEmpty) return;
            try {
              _emitTap((jsonDecode(payload) as Map).cast<String, dynamic>());
            } catch (_) {}
          },
        );
        await _plugin
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(channel);
      } catch (e) {
        debugPrint('Local notifications init: $e');
      }
    }

    FirebaseMessaging.onMessage.listen(_showForeground);
    // Single source of tap events for NotificationNavigator (background →
    // foreground taps, local-notification taps and the cold-start message).
    FirebaseMessaging.onMessageOpenedApp.listen((m) => _emitTap(Map<String, dynamic>.from(m.data)));
    try {
      final initial = await messaging.getInitialMessage();
      if (initial != null) _emitTap(Map<String, dynamic>.from(initial.data));
    } catch (_) {}

    messaging.onTokenRefresh.listen(persistToken);
    await refreshToken();
  }

  /// Fetches the token (web needs [vapidKey]) and stores it on users/{uid}.
  Future<void> refreshToken() async {
    try {
      if (kIsWeb && vapidKey.isEmpty) {
        debugPrint('FCM web: no FCM_VAPID_KEY provided — push disabled on web.');
        return;
      }
      _token = await FirebaseMessaging.instance.getToken(vapidKey: kIsWeb ? vapidKey : null);
      await persistToken(_token);
    } catch (e) {
      debugPrint('FCM token: $e');
    }
  }

  Future<void> persistToken(String? token) async {
    if (token == null || token.isEmpty) return;
    _token = token;
    try {
      await PrefsService.instance.setFcmToken(token);
      // Settings → 'Nhận thông báo đẩy' off: keep the token locally but never
      // register it on users/{uid} (onTokenRefresh would otherwise re-add it).
      if (!PrefsService.instance.notificationsEnabled) return;
    } catch (_) {}
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayUnion([token])},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('FCM persist token: $e');
    }
  }

  Future<void> removeTokenForCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    String? t = _token;
    if (t == null) {
      try {
        t = PrefsService.instance.fcmToken;
      } catch (_) {}
    }
    if (uid == null || t == null || t.isEmpty) return;
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {'fcmTokens': FieldValue.arrayRemove([t])},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<void> _showForeground(RemoteMessage msg) async {
    final n = msg.notification;
    if (n == null || kIsWeb) return;
    try {
      final prefs = PrefsService.instance;
      final type = msg.data['type']?.toString() ?? '';
      if (!prefs.notificationsEnabled || !prefs.isNotificationTypeEnabled(type)) return;
    } catch (_) {}
    await _plugin.show(
      n.hashCode,
      n.title,
      n.body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          channel.id,
          channel.name,
          channelDescription: channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: jsonEncode(msg.data),
    );
  }

  /// Shows a local notification for an in-app event (e.g. a new Firestore
  /// notification doc arrived while the app is open on mobile).
  Future<void> showLocal({required String title, required String body, Map<String, dynamic> data = const {}}) async {
    if (kIsWeb) return;
    try {
      // Mix full-millisecond timestamp with title hash so two notifications
      // posted in the same second don't share an id (the previous
      // seconds-resolution id was unique only per 1 s window).
      final id = (DateTime.now().millisecondsSinceEpoch & 0x3FFFFFFF) ^
          (title.hashCode & 0x3FFFFFFF);
      await _plugin.show(
        id,
        title,
        body,
        NotificationDetails(
          android: AndroidNotificationDetails(channel.id, channel.name,
              channelDescription: channel.description, importance: Importance.high, priority: Priority.high),
          iOS: const DarwinNotificationDetails(),
        ),
        payload: jsonEncode(data),
      );
    } catch (_) {}
  }
}
