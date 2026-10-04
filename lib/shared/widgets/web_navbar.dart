import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/nav.dart';
import '../../features/auth/viewmodels/current_user_provider.dart';
import '../../features/notifications/viewmodels/notifications_providers.dart';
import '../models/user_model.dart';
import 'brand.dart';
import 'nav_items.dart';
import 'section.dart';

const double kNavbarHeight = 72;

/// Navbar.jsx switches to the desktop layout at Tailwind `md` (768px).
const double kNavbarDesktopBreakpoint = 768;

/// components/navbar/Navbar.jsx — fixed 72px bar: brand, public links, guest
/// CTAs ('Đăng nhập' / 'Đăng ký' / 'Dành cho NTD') or the account menu with
/// avatar initial + role chip.
class WebNavbar extends ConsumerWidget implements PreferredSizeWidget {
  const WebNavbar({super.key, this.scrolled = false});
  final bool scrolled;

  @override
  Size get preferredSize => const Size.fromHeight(kNavbarHeight);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= kNavbarDesktopBreakpoint;
    final user = ref.watch(currentUserProvider).valueOrNull;

    return Material(
      color: Colors.transparent,
      // Scaffold allocates (preferredSize.height + MediaQuery.padding.top)
      // for the AppBar slot — on iPhones that's 72 + ~59 = 131px. The nav
      // decoration needs to cover the entire slot (including the status-bar
      // strip) so the surface colour reaches up under the notch, so the
      // AnimatedContainer sits OUTSIDE SafeArea. SafeArea then pushes the
      // actual Row (logo + links + icons) down by the status-bar inset,
      // leaving a full 72px for content. The old layout put SafeArea inside
      // the fixed-72px container, which squashed the content strip to ~13px
      // on iPhone and clipped the logo out of view.
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: AppColors.surface.withValues(alpha: scrolled ? 0.97 : 0.92),
          border: const Border(bottom: BorderSide(color: AppColors.border)),
          boxShadow: scrolled ? AppShadows.soft : null,
        ),
        child: SafeArea(
          bottom: false,
          child: SizedBox(
            height: kNavbarHeight,
            child: PageContainer(
              padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 16),
              child: Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => context.go(AppRoutes.home),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(vertical: 8),
                      child: BrandLogo(),
                    ),
                  ),
                  const SizedBox(width: 20),
                  if (isWide)
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final it in NavItems.public)
                              _NavLink(item: it),
                          ],
                        ),
                      ),
                    )
                  else
                    const Spacer(),
                  const SizedBox(width: 12),
                  // Quick-jump to the jobs search page from anywhere —
                  // visible for guest and signed-in users, on wide and
                  // narrow viewports (fulfils "có thêm kính lúp để đi đâu
                  // cũng có thể search được job"). Preserves whatever ?q
                  // the user had before by just going to /viec-lam fresh.
                  IconButton(
                    tooltip: 'Tìm việc làm',
                    onPressed: () => context.pushIfDifferent(AppRoutes.jobs),
                    icon: const Icon(Icons.search, color: AppColors.inkSoft),
                  ),
                  if (user == null)
                    _GuestActions(isWide: isWide)
                  else if (isWide)
                    _AccountMenu(user: user, isWide: isWide)
                  else
                    const _NotificationBell(),
                  if (!isWide)
                    Builder(
                      builder: (ctx) => IconButton(
                        tooltip: 'Menu',
                        icon: const Icon(Icons.menu, color: AppColors.ink),
                        onPressed: () => Scaffold.of(ctx).openDrawer(),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _GuestActions extends StatelessWidget {
  const _GuestActions({required this.isWide});
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    if (!isWide) {
      return ElevatedButton(
        onPressed: () => context.pushIfDifferent(AppRoutes.login),
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          minimumSize: const Size(0, 40),
        ),
        child: const Text('Đăng nhập'),
      );
    }
    // Navbar.jsx order: 'Đăng nhập' (secondary) · 'Đăng ký' (primary) · 'Dành cho NTD' (ghost).
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        OutlinedButton(
          onPressed: () => context.pushIfDifferent(AppRoutes.login),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Đăng nhập'),
        ),
        const SizedBox(width: 8),
        ElevatedButton(
          onPressed: () => context.pushIfDifferent(AppRoutes.register),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            minimumSize: const Size(0, 44),
          ),
          child: const Text('Đăng ký'),
        ),
        const SizedBox(width: 4),
        TextButton(
          onPressed: () => context.pushIfDifferent(AppRoutes.registerEmployer),
          child: const Text('Dành cho NTD'),
        ),
      ],
    );
  }
}

class _NavLink extends StatelessWidget {
  const _NavLink({required this.item});
  final NavItem item;

  @override
  Widget build(BuildContext context) {
    // Not GoRouterState.of(): go_router does not register the errorBuilder
    // page (404) in its state registry, so that would throw inside NotFoundPage.
    final current =
        GoRouter.maybeOf(context)?.routerDelegate.currentConfiguration.uri ??
        Uri(path: '/');
    final uri = Uri.parse(item.route);
    final active =
        uri.path == current.path &&
        (uri.query.isEmpty ||
            uri.queryParameters['section'] ==
                current.queryParameters['section']) &&
        !(uri.path == '/' && uri.query.isEmpty && current.query.isNotEmpty);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: TextButton(
        onPressed: () => context.pushIfDifferent(item.route),
        style: TextButton.styleFrom(
          foregroundColor: active ? AppColors.primary : AppColors.inkSoft,
          backgroundColor: active ? AppColors.primary50 : Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          textStyle: TextStyle(
            fontSize: 14,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        child: Text(item.label),
      ),
    );
  }
}

/// Standalone notification bell for the mobile navbar. The full account
/// dropdown moves into the drawer so taps don't fight the hamburger.
class _NotificationBell extends ConsumerWidget {
  const _NotificationBell();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    return IconButton(
      tooltip: 'Thông báo',
      onPressed: () => context.pushIfDifferent(AppRoutes.notifications),
      icon: Badge(
        isLabelVisible: unread > 0,
        label: Text(unread > 99 ? '99+' : '$unread'),
        child: const Icon(Icons.notifications_none, color: AppColors.inkSoft),
      ),
    );
  }
}

class _AccountMenu extends ConsumerWidget {
  const _AccountMenu({required this.user, required this.isWide});
  final UserModel user;
  final bool isWide;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final unread = ref.watch(unreadCountProvider);
    final items = NavItems.accountMenu(user.role);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: 'Thông báo',
          onPressed: () => context.pushIfDifferent(AppRoutes.notifications),
          icon: Badge(
            isLabelVisible: unread > 0,
            label: Text(unread > 99 ? '99+' : '$unread'),
            child: const Icon(
              Icons.notifications_none,
              color: AppColors.inkSoft,
            ),
          ),
        ),
        const SizedBox(width: 4),
        PopupMenuButton<String>(
          tooltip: 'Tài khoản',
          offset: const Offset(0, 52),
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.xl),
            side: const BorderSide(color: AppColors.border),
          ),
          color: AppColors.surface,
          onSelected: (route) async {
            if (route == '__logout') {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) context.go(AppRoutes.home);
              return;
            }
            context.pushIfDifferent(route);
          },
          itemBuilder: (ctx) => [
            PopupMenuItem(
              enabled: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.fullName,
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  Text(
                    user.email,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
            const PopupMenuDivider(),
            for (final it in items)
              PopupMenuItem(
                value: it.route,
                child: Row(
                  children: [
                    Icon(
                      it.icon ?? Icons.circle_outlined,
                      size: 18,
                      color: AppColors.inkSoft,
                    ),
                    const SizedBox(width: 12),
                    Text(it.label),
                  ],
                ),
              ),
            const PopupMenuDivider(),
            const PopupMenuItem(
              value: '__logout',
              child: Row(
                children: [
                  Icon(Icons.logout, size: 18, color: AppColors.danger),
                  SizedBox(width: 12),
                  Text('Đăng xuất', style: TextStyle(color: AppColors.danger)),
                ],
              ),
            ),
          ],
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.surface,
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: AppColors.primary,
                  backgroundImage: user.photoUrl != null
                      ? NetworkImage(user.photoUrl!)
                      : null,
                  child: user.photoUrl == null
                      ? Text(
                          user.initial,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        )
                      : null,
                ),
                if (isWide) ...[
                  const SizedBox(width: 10),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 160),
                    child: Text(
                      user.fullName,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.primary50,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Text(
                      user.roleLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    size: 18,
                    color: AppColors.inkSoft,
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}
