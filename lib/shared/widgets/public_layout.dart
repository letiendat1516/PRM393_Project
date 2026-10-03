import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/nav.dart';
import 'mobile_bottom_bar.dart';
import '../../features/auth/viewmodels/current_user_provider.dart';
import 'brand.dart';
import 'nav_items.dart';
import 'web_footer.dart';
import 'web_navbar.dart';

/// layouts/PublicLayout.jsx — canvas background, fixed navbar (72px),
/// scrollable main, footer. `useScrolled(8)` → navbar shadow once scrolled.
class PublicLayout extends ConsumerStatefulWidget {
  const PublicLayout({
    super.key,
    required this.child,
    this.showFooter = true,
    this.scrollable = true,
    this.scrollController,
  });

  final Widget child;
  final bool showFooter;
  /// true → wraps [child] (+ footer) in a SingleChildScrollView; false → the
  /// child manages its own scrolling (Expanded).
  final bool scrollable;
  final ScrollController? scrollController;

  @override
  ConsumerState<PublicLayout> createState() => _PublicLayoutState();
}

class _PublicLayoutState extends ConsumerState<PublicLayout> {
  late final ScrollController _controller = widget.scrollController ?? ScrollController();
  bool _scrolled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onScroll);
  }

  void _onScroll() {
    final s = _controller.hasClients && _controller.offset > 8;
    if (s != _scrolled) setState(() => _scrolled = s);
  }

  @override
  void dispose() {
    _controller.removeListener(_onScroll);
    if (widget.scrollController == null) _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final isWide = width >= kNavbarDesktopBreakpoint;

    // PublicLayout.jsx: `min-h-screen flex-col` + `main flex-1` → the footer
    // sits at the viewport bottom on short pages (404, empty states).
    //
    // Trade-off: the previous `LayoutBuilder + ConstrainedBox(minHeight) +
    // Column(spaceBetween)` pattern crashed admin pages (TileGrid's
    // nested LayoutBuilder → `hasSize` failures → blank body) and
    // `SliverFillRemaining(hasScrollBody: false)` tries to run those
    // same intrinsics speculatively → same crash. So we fall back to a
    // plain SingleChildScrollView + Column: the footer now sits right
    // under the last content widget on short pages (404 / empty states
    // no longer anchor it to the viewport bottom) but every page renders.
    final body = widget.scrollable
        ? SingleChildScrollView(
            controller: _controller,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                widget.child,
                if (widget.showFooter) const WebFooter(),
              ],
            ),
          )
        : (widget.scrollController == null
            // useScrolled(8) for pages that own their scroll view (AppScaffold):
            // pick up the inner scroll position via notifications.
            ? NotificationListener<ScrollUpdateNotification>(
                onNotification: (n) {
                  if (n.depth != 0) return false;
                  final s = n.metrics.pixels > 8;
                  if (s != _scrolled) setState(() => _scrolled = s);
                  return false;
                },
                child: widget.child,
              )
            : widget.child);

    return Scaffold(
      backgroundColor: AppColors.canvas,
      appBar: WebNavbar(scrolled: _scrolled),
      drawer: isWide ? null : const MobileDrawer(),
      bottomNavigationBar: isWide ? null : const MobileBottomBar(),
      body: body,
    );
  }
}

/// Navbar mobile menu: public links, role links, 'Đăng ký miễn phí',
/// 'Dành cho nhà tuyển dụng →', 'Đăng xuất'.
class MobileDrawer extends ConsumerWidget {
  const MobileDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // ── Profile header (big avatar + name + email + role chip) ──
            Container(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.border)),
              ),
              child: user == null
                  ? Row(children: const [BrandLogo()])
                  : Row(
                      children: [
                        CircleAvatar(
                          radius: 24,
                          backgroundColor: AppColors.primary,
                          child: Text(
                            user.initial,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.fullName,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                user.email,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.inkMuted,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.primary50,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  user.roleLabel,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
            ),

            // ── Section: Chung (public + home) ──
            _sectionHeader('Chung'),
            _tile(context, Icons.home_outlined, 'Trang chủ', AppRoutes.home,
                topLevel: true),
            for (final it in NavItems.public)
              _tile(context, it.icon ?? Icons.circle_outlined, it.label,
                  it.route),

            if (user != null) ...[
              // ── Role-grouped sections ──
              for (final section in NavItems.accountMenuGrouped(user.role)) ...[
                _sectionHeader(section.title),
                for (final it in section.items)
                  _tile(context, it.icon ?? Icons.circle_outlined, it.label,
                      it.route),
              ],
              const SizedBox(height: 8),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.logout, color: AppColors.danger),
                title: const Text('Đăng xuất',
                    style: TextStyle(color: AppColors.danger)),
                onTap: () async {
                  Navigator.of(context).pop();
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) context.go(AppRoutes.home);
                },
              ),
              const SizedBox(height: 8),
            ] else ...[
              _sectionHeader('Tài khoản'),
              _tile(context, Icons.login, 'Đăng nhập', AppRoutes.login,
                  highlight: true),
              _tile(context, Icons.person_add_alt_outlined,
                  'Đăng ký miễn phí', AppRoutes.register),
              _tile(context, Icons.business_center_outlined,
                  'Dành cho nhà tuyển dụng →', AppRoutes.registerEmployer),
              const SizedBox(height: 8),
            ],
          ],
        ),
      ),
    );
  }

  /// Uppercased + spaced section title above each nav group — gives the
  /// drawer scannable structure instead of one long flat list.
  Widget _sectionHeader(String title) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
            color: AppColors.inkMuted,
          ),
        ),
      );

  Widget _tile(BuildContext ctx, IconData icon, String label, String route,
      {bool highlight = false, bool topLevel = false}) {
    return ListTile(
      dense: true,
      leading: Icon(icon, color: highlight ? AppColors.primary : AppColors.inkSoft, size: 20),
      title: Text(label,
          style: TextStyle(
            color: highlight ? AppColors.primary : AppColors.ink,
            fontWeight: highlight ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          )),
      onTap: () {
        Navigator.of(ctx).pop(); // close drawer
        // Top-level destinations (Trang chủ) use go() so a tap always lands
        // on the tab root — clearing any `?section=` query the user picked
        // up from a nav link like "Công ty". Drill-ins use pushIfDifferent
        // so Android back pops to the previous page.
        if (topLevel) {
          ctx.go(route);
        } else {
          ctx.pushIfDifferent(route);
        }
      },
    );
  }
}
