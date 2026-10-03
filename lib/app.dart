import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_config.dart';
import 'core/providers.dart';
import 'core/router/app_router.dart';
import 'core/router/routes.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/enums.dart';
import 'features/auth/viewmodels/current_user_provider.dart';
import 'features/notifications/widgets/notification_navigator.dart';
import 'features/settings/viewmodels/settings_viewmodel.dart';

final rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

class JobHubApp extends ConsumerWidget {
  const JobHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final settings = ref.watch(settingsProvider);

    // Account blocking semantics (authMiddleware.requireActivePrincipal):
    // when users/{uid}.isActive flips to false, sign out immediately.
    ref.listen(currentUserProvider, (prev, next) async {
      final user = next.valueOrNull;
      if (user == null) {
        // requireActivePrincipal: users/{uid} deleted while signed in → 401
        // 'Tài khoản không còn tồn tại.' and the token is cleared. A null right
        // after registration (doc not yet written) has no cached principal, so
        // only act when we previously knew this account.
        final prefs = ref.read(prefsServiceProvider);
        final uid = ref.read(authStateProvider).valueOrNull?.uid;
        // "We knew this account": either the previous emission was this
        // principal, or the cached principal (cold start, no Firestore
        // persistence) carries the same uid. Registration-in-flight keeps the
        // provider loading (authBootstrappingProvider), so it never lands here.
        final cachedUid = prefs.cachedUser?['uid'] as String?;
        final knewAccount = prev?.valueOrNull?.uid == uid || cachedUid == uid;
        if (!next.isLoading && !next.hasError && uid != null && knewAccount) {
          await prefs.setCachedUser(null);
          await ref.read(authServiceProvider).signOut();
          rootScaffoldMessengerKey.currentState?.showSnackBar(
            const SnackBar(content: Text('Tài khoản không còn tồn tại.')),
          );
          router.go(AppRoutes.login);
        }
        return;
      }
      if (!user.isActive) {
        await ref.read(authServiceProvider).signOut();
        rootScaffoldMessengerKey.currentState?.showSnackBar(
          const SnackBar(content: Text('Tài khoản đã bị vô hiệu hóa.')),
        );
        router.go(AppRoutes.login);
        return;
      }
      final prefs = ref.read(prefsServiceProvider);
      prefs.setLastRole(userRoleToWire(user.role));
      prefs.setCachedUser({
        'uid': user.uid,
        'email': user.email,
        'fullName': user.fullName,
        'role': userRoleToWire(user.role),
        'isActive': user.isActive,
        'isVerified': user.isVerified,
      });
    });

    return MaterialApp.router(
      title: 'JobHub',
      debugShowCheckedModeBanner: false,
      scaffoldMessengerKey: rootScaffoldMessengerKey,
      themeMode: settings.themeMode,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      locale: Locale(settings.locale),
      supportedLocales: [for (final l in AppConfig.supportedLocales) Locale(l)],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      routerConfig: router,
      // Push-notification deep links + FCM token sync (notifications feature).
      builder: (context, child) => NotificationNavigator(child: child ?? const SizedBox.shrink()),
    );
  }
}
