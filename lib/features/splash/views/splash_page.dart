import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/brand.dart';
import '../../../shared/widgets/nav_items.dart';
import '../../auth/viewmodels/current_user_provider.dart';

/// Brand + spinner for 600 ms, then:
/// - first launch and no user → /onboarding
/// - signed in → NavItems.homeFor(role) (waits for users/{uid}; errors → '/')
/// - otherwise → '/'
class SplashPage extends ConsumerStatefulWidget {
  const SplashPage({super.key});

  @override
  ConsumerState<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends ConsumerState<SplashPage> with SingleTickerProviderStateMixin {
  static const _minDelay = Duration(milliseconds: 600);
  static const _authTimeout = Duration(seconds: 6);

  late final AnimationController _fade =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    final target = await _resolveTarget();
    if (!mounted) return;
    context.go(target);
  }

  Future<String> _resolveTarget() async {
    // Wait for the brand frame AND the first Firebase auth event together.
    final results = await Future.wait<Object?>([
      Future<void>.delayed(_minDelay),
      ref
          .read(authStateProvider.future)
          .timeout(_authTimeout)
          .catchError((_) => null),
    ]);
    if (!mounted) return AppRoutes.home;

    final user = results[1];
    if (user == null) {
      final prefs = ref.read(prefsServiceProvider);
      return prefs.isFirstLaunch ? AppRoutes.onboarding : AppRoutes.home;
    }

    try {
      final current = await ref.read(currentUserProvider.future).timeout(_authTimeout);
      if (!mounted) return AppRoutes.home;
      return NavItems.homeFor(current?.role);
    } catch (_) {
      return AppRoutes.home;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.canvas,
      body: Stack(
        children: [
          // Soft brand wash (hero gradient from the web landing).
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary50,
                    AppColors.canvas,
                    AppColors.secondary50.withValues(alpha: 0.6),
                  ],
                ),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: CurvedAnimation(parent: _fade, curve: Curves.easeOut),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const BrandLogo(size: 30),
                  const SizedBox(height: 10),
                  const Text(
                    'Nền tảng tuyển dụng thông minh',
                    style: TextStyle(fontSize: 13, color: AppColors.inkMuted, letterSpacing: 0.2),
                  ),
                  const SizedBox(height: 32),
                  const SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2.5, color: AppColors.primary),
                  ),
                ],
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 28,
            child: Text(
              'JobHub · PRM393',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: AppColors.inkMuted, letterSpacing: 1.2),
            ),
          ),
        ],
      ),
    );
  }
}
