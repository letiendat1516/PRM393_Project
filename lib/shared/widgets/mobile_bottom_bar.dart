import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/utils/enums.dart';
import '../../features/auth/viewmodels/current_user_provider.dart';
import '../models/user_model.dart';
import 'nav_items.dart';

/// Material 3 bottom navigation bar shown on mobile (< [kNavbarDesktopBreakpoint]).
/// Three tabs — Trang chủ · Việc làm · Tài khoản — the account tab is
/// routed per role: guests go to /dang-nhap, each signed-in role goes to
/// their home-base page (seeker profile, employer / admin dashboard).
class MobileBottomBar extends ConsumerWidget {
  const MobileBottomBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    final currentPath = GoRouter.of(context)
        .routeInformationProvider
        .value
        .uri
        .path;

    final tabs = <_BottomTab>[
      const _BottomTab(
        route: AppRoutes.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        label: 'Trang chủ',
      ),
      const _BottomTab(
        route: AppRoutes.jobs,
        icon: Icons.work_outline,
        activeIcon: Icons.work,
        label: 'Việc làm',
      ),
      _BottomTab(
        route: _accountRoute(user),
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        label: 'Tài khoản',
      ),
    ];

    // Pick the deepest-matching tab so /viec-lam/<id> still lights up Việc làm.
    var activeIdx = -1;
    for (var i = 0; i < tabs.length; i++) {
      final r = tabs[i].route;
      if (currentPath == r || currentPath.startsWith('$r/')) activeIdx = i;
    }

    return NavigationBar(
      selectedIndex: activeIdx == -1 ? 0 : activeIdx,
      onDestinationSelected: (i) {
        final route = tabs[i].route;
        // Bottom-nav tabs are top-level destinations, not drill-ins: go()
        // replaces the stack so tapping a tab always lands on that tab's
        // root — including when the user drilled into a sub-page like
        // /viec-lam/<id> and then taps "Việc làm" expecting to pop back.
        // The earlier `pushIfDifferent` guard silently returned on the
        // current tab, which is what users reported as "nút không có tín
        // hiệu" when they tried re-tapping Trang chủ.
        if (currentPath == route) return;
        context.go(route);
      },
      destinations: [
        for (final t in tabs)
          NavigationDestination(
            icon: Icon(t.icon),
            selectedIcon: Icon(t.activeIcon),
            label: t.label,
          ),
      ],
    );
  }

  /// Role-aware destination for the account tab. Falls back to login for
  /// guests so the tab always lands on something meaningful.
  String _accountRoute(UserModel? user) {
    if (user == null) return AppRoutes.login;
    return NavItems.homeFor(user.role) == AppRoutes.adminUsers
        ? AppRoutes.adminDashboard
        : switch (user.role) {
            UserRole.jobSeeker => AppRoutes.resumeProfile,
            UserRole.employer => AppRoutes.employerDashboard,
            UserRole.admin => AppRoutes.adminDashboard,
          };
  }
}

class _BottomTab {
  const _BottomTab({
    required this.route,
    required this.icon,
    required this.activeIcon,
    required this.label,
  });
  final String route;
  final IconData icon;
  final IconData activeIcon;
  final String label;
}
