import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/config/firebase_bootstrap.dart';
import 'core/services/prefs_service.dart';
import 'core/theme/app_colors.dart';
import 'shared/widgets/ui_primitives.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _installErrorBoundary();
  await _initPrefs();
  try {
    await FirebaseBootstrap.initialize();
  } catch (e) {
    debugPrint('Firebase init failed (did you run `flutterfire configure`?): $e');
  }

  runApp(const ProviderScope(child: JobHubApp()));
}

/// SharedPreferences must be ready before the first frame. On Android a debug
/// `flutter run` sync can race with the FCM background engine and the platform
/// channel briefly answers MissingPluginException — retry, then fall back to an
/// in-memory store so the app still boots instead of staying on a blank window.
Future<void> _initPrefs() async {
  for (var attempt = 0; attempt < 4; attempt++) {
    try {
      await PrefsService.init();
      return;
    } on MissingPluginException catch (e) {
      debugPrint('SharedPreferences not ready (attempt ${attempt + 1}): $e');
      await Future<void>.delayed(Duration(milliseconds: 250 * (attempt + 1)));
    }
  }
  debugPrint('SharedPreferences unavailable — using in-memory preferences for this session.');
  // Last resort only (plugin channel never came up): in-memory store so the
  // app boots; settings made in this session are simply not persisted.
  // ignore: invalid_use_of_visible_for_testing_member
  SharedPreferences.setMockInitialValues(<String, Object>{});
  await PrefsService.init();
}

/// components/ErrorBoundary.jsx — any uncaught build/layout error renders the
/// 'Đã xảy ra lỗi / Trang này gặp sự cố / Tải lại trang' fallback instead of
/// Flutter's red (debug) / grey (release) box. Errors are still logged.
void _installErrorBoundary() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    debugPrint('[ErrorBoundary] ${details.exceptionAsString()}');
  };
  ErrorWidget.builder = (details) => Material(
        color: AppColors.canvas,
        child: RouteErrorView(
          error: kDebugMode ? details.exception : null,
          onRetry: () => WidgetsBinding.instance.reassembleApplication(),
        ),
      );
}
