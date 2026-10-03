import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

/// GoRouter navigation helpers used across navbars/drawers/footers so the
/// Android back button always pops to the previous page instead of exiting
/// the app.
///
/// Why not just `context.go(route)`?  `go` *replaces* the whole nav stack
/// with the new route, so when the user hits the system back button the
/// stack is empty and Android drops them to the launcher. `push` instead
/// appends, keeping history intact.
///
/// [pushIfDifferent] additionally short-circuits when the active route is
/// already [route] so tapping the same menu entry twice doesn't stack a
/// duplicate copy of the current page.
extension NavCtx on BuildContext {
  /// Push [route] unless the current route already matches it. Used for
  /// drawer / navbar / footer links where "forward" navigation should
  /// preserve the back-stack.
  void pushIfDifferent(String route) {
    final router = GoRouter.of(this);
    final current = router.routeInformationProvider.value.uri.path;
    if (current == route) return;
    // Call via `router` directly to make sure we hit the GoRouter.push
    // and not any Navigator-based `push` that might shadow it.
    router.push(route);
  }
}
