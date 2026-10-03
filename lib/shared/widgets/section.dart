import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

const double kContentMaxWidth = 1200;

class PageContainer extends StatelessWidget {
  const PageContainer({super.key, required this.child, this.padding});
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final horizontal = width >= 1024 ? 32.0 : (width >= 640 ? 24.0 : 16.0);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: kContentMaxWidth),
        child: Padding(
          padding: padding ??
              EdgeInsets.symmetric(horizontal: horizontal),
          child: child,
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  const Section({
    super.key,
    required this.child,
    this.background = AppColors.canvas,
    this.verticalPadding = 64,
    this.fullBleed = false,
  });
  final Widget child;
  final Color background;
  final double verticalPadding;
  final bool fullBleed;

  @override
  Widget build(BuildContext context) {
    final inner = Padding(
      padding: EdgeInsets.symmetric(vertical: verticalPadding),
      child: fullBleed ? child : PageContainer(child: child),
    );
    return Container(color: background, width: double.infinity, child: inner);
  }
}

class Eyebrow extends StatelessWidget {
  const Eyebrow({super.key, required this.label, this.icon, this.light = false});
  final String label;
  final IconData? icon;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final bg = light ? Colors.white.withValues(alpha: 0.15) : AppColors.primary50;
    final fg = light ? Colors.white : AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: fg),
            const SizedBox(width: 6),
          ],
          Text(
            label.toUpperCase(),
            style: TextStyle(
              color: fg,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class SectionHeading extends StatelessWidget {
  const SectionHeading({
    super.key,
    required this.eyebrow,
    required this.title,
    this.description,
    this.center = true,
    this.light = false,
  });
  final String eyebrow;
  final String title;
  final String? description;
  final bool center;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? Colors.white : AppColors.ink;
    final descColor = light ? Colors.white70 : AppColors.inkSoft;
    final align = center ? CrossAxisAlignment.center : CrossAxisAlignment.start;
    final textAlign = center ? TextAlign.center : TextAlign.start;
    // SectionHeading.jsx: h2 `text-3xl sm:text-[2.6rem]`, p `text-base sm:text-lg`.
    final sm = MediaQuery.sizeOf(context).width >= 640;

    return Column(
      crossAxisAlignment: align,
      children: [
        Eyebrow(label: eyebrow, light: light),
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 640),
          child: Text(
            title,
            textAlign: textAlign,
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: titleColor,
                  fontSize: sm ? 41.6 : 30,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
          ),
        ),
        if (description != null) ...[
          const SizedBox(height: 12),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: Text(
              description!,
              textAlign: textAlign,
              style: TextStyle(color: descColor, fontSize: sm ? 18 : 16, height: 1.75),
            ),
          ),
        ],
      ],
    );
  }
}

class AppChip extends StatelessWidget {
  const AppChip({
    super.key,
    required this.label,
    this.icon,
    this.selected = false,
    this.onTap,
    this.variant = AppChipVariant.neutral,
    this.compact = false,
  });
  final String label;
  final IconData? icon;
  final bool selected;
  final VoidCallback? onTap;
  final AppChipVariant variant;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    late Color bg, fg;
    switch (variant) {
      case AppChipVariant.neutral:
        bg = selected ? AppColors.primary : AppColors.slate100;
        fg = selected ? Colors.white : AppColors.inkSoft;
        break;
      case AppChipVariant.primary:
        bg = AppColors.primary50;
        fg = AppColors.primary;
        break;
      case AppChipVariant.secondary:
        bg = AppColors.secondary50;
        fg = AppColors.secondary600;
        break;
      case AppChipVariant.outline:
        bg = Colors.white;
        fg = AppColors.inkSoft;
        break;
    }

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 6),
        ],
        Text(
          label,
          style: TextStyle(
            color: fg,
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    final container = Container(
      padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: variant == AppChipVariant.outline
            ? Border.all(color: AppColors.border)
            : null,
      ),
      child: content,
    );

    if (onTap == null) return container;
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.pill),
      onTap: onTap,
      child: container,
    );
  }
}

enum AppChipVariant { neutral, primary, secondary, outline }
