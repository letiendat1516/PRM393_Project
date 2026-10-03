import 'package:flutter/material.dart';

import 'public_layout.dart';
import 'section.dart';

/// Backwards-compat wrapper over [PublicLayout]: keeps existing callers that
/// pass a `title`, body, actions and FAB working while routing them through
/// the web-style navbar + drawer.
class AppScaffold extends StatelessWidget {
  const AppScaffold({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.floatingActionButton,
    this.showDrawer = true,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showDrawer;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PublicLayout(
      scrollable: false,
      showFooter: false,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(
                bottom: BorderSide(color: theme.dividerColor),
              ),
            ),
            child: PageContainer(
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ),
                  ...?actions,
                ],
              ),
            ),
          ),
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: PageContainer(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 20),
                    child: body,
                  ),
                ),
                if (floatingActionButton != null)
                  Positioned(
                    right: 24,
                    bottom: 24,
                    child: floatingActionButton!,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
