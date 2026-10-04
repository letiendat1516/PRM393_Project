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
      // Paint the full AppScaffold content with the theme surface so the
      // page reads as ONE uniform white sheet from the title down to the
      // bottom edge, instead of showing a white title → grey Scaffold
      // canvas → white card sandwich (the "vẫn còn màu xám" complaint
      // on the settings screen). Cards keep their own border + shadow
      // for visual separation.
      child: ColoredBox(
        color: theme.colorScheme.surface,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
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
      ),
    );
  }
}
