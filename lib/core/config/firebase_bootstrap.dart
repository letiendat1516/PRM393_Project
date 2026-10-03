import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../services/fcm_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

class FirebaseBootstrap {
  const FirebaseBootstrap._();

  static Future<void> initialize() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );

    if (!kIsWeb) {
      FirebaseMessaging.onBackgroundMessage(firebaseBackgroundHandler);
    }
    // Hard cap on FCM init — on iOS sideload builds without aps-environment
    // entitlement, individual messaging APIs can block forever. Flutter must
    // reach runApp() regardless; FCM features that need a token will light up
    // later via onTokenRefresh.
    try {
      await FcmService.instance
          .initialize()
          .timeout(const Duration(seconds: 3));
    } catch (e) {
      debugPrint('FCM init did not finish in time: $e');
    }
  }
}
