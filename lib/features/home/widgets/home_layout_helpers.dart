import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';

/// Section.jsx vertical rhythm: `py-16 sm:py-24`.
double homeSectionPadding(BuildContext context) =>
    MediaQuery.sizeOf(context).width >= 640 ? 96 : 64;

/// Card grids `grid-cols-1 md:grid-cols-2 lg:grid-cols-3` (content width).
int homeThreeColumns(double maxWidth) => maxWidth >= 900 ? 3 : (maxWidth >= 600 ? 2 : 1);

/// Equal-height responsive grid (web cards use `h-full`): rows of
/// [columnsFor] columns, EVERY row wrapped in an IntrinsicHeight — including
/// single-column rows on phones. Cards (TopCompanies, Testimonials, Career
/// resources…) use `Expanded`/`Spacer` inside a vertical Column, which needs a
/// bounded height; inside the page's SingleChildScrollView a bare Column would
/// give them unbounded height → layout exception → blank, non-interactive page
/// (seen on Android: "Cannot hit test a render box that has never been laid out").
class ResponsiveGrid extends StatelessWidget {
  const ResponsiveGrid({
    super.key,
    required this.children,
    this.columnsFor = homeThreeColumns,
    this.spacing = 20,
    double? runSpacing,
  }) : runSpacing = runSpacing ?? spacing;

  final List<Widget> children;
  final int Function(double maxWidth) columnsFor;
  final double spacing;
  final double runSpacing;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, constraints) {
      final cols = columnsFor(constraints.maxWidth).clamp(1, 12);
      final rows = <List<Widget>>[];
      for (var i = 0; i < children.length; i += cols) {
        rows.add(children.sublist(i, (i + cols).clamp(0, children.length)));
      }
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var r = 0; r < rows.length; r++) ...[
            if (r > 0) SizedBox(height: runSpacing),
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  for (var c = 0; c < cols; c++) ...[
                    if (c > 0) SizedBox(width: spacing),
                    Expanded(
                      child: c < rows[r].length ? rows[r][c] : const SizedBox.shrink(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      );
    });
  }
}

/// Header split used by Featured Jobs / Career Resources: left-aligned
/// SectionHeading + shrink-0 `.btn-secondary` on the right (stacks on phones).
class SplitSectionHeader extends StatelessWidget {
  const SplitSectionHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.description,
    required this.actionLabel,
    required this.onAction,
  });

  final String eyebrow;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    final heading = SectionHeading(
      eyebrow: eyebrow,
      title: title,
      description: description,
      center: false,
    );
    final button = OutlinedButton(
      onPressed: onAction,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(actionLabel),
          const SizedBox(width: 8),
          const Icon(Icons.arrow_forward, size: 18),
        ],
      ),
    );
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < 640) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [heading, const SizedBox(height: 24), button],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: heading),
          const SizedBox(width: 24),
          button,
        ],
      );
    });
  }
}

/// Decorative blurred circle (`rounded-full blur-3xl`), approximated with a
/// radial gradient so it stays cheap on mobile.
class DecorBlob extends StatelessWidget {
  const DecorBlob({super.key, required this.color, this.size = 288});
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withValues(alpha: 0)],
            stops: const [0.2, 1],
          ),
        ),
      ),
    );
  }
}

/// `grid h-10 w-10 place-items-center rounded-xl` icon tile.
class IconTile extends StatelessWidget {
  const IconTile({
    super.key,
    required this.icon,
    required this.background,
    required this.foreground,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 12,
  });

  final IconData icon;
  final Color background;
  final Color foreground;
  final double size;
  final double iconSize;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: Icon(icon, size: iconSize, color: foreground),
    );
  }
}

/// Image.asset with a brand-coloured fallback when the asset is missing.
class HomeAssetImage extends StatelessWidget {
  const HomeAssetImage(this.asset, {super.key, this.fit = BoxFit.cover});
  final String asset;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      asset,
      fit: fit,
      width: double.infinity,
      height: double.infinity,
      errorBuilder: (_, _, _) => const DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.primary400, AppColors.primary700],
          ),
        ),
        child: Center(child: Icon(Icons.image_outlined, color: Colors.white54, size: 48)),
      ),
    );
  }
}
