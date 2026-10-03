import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// `<label class="text-sm font-semibold">` wrapper: label text above the
/// input, optional red asterisk (`text-red-500`).
class FieldLabel extends StatelessWidget {
  const FieldLabel({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.hint,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.ink,
            ),
            children: [
              if (required)
                const TextSpan(
                  text: ' *',
                  style: TextStyle(color: AppColors.red600),
                ),
            ],
          ),
        ),
        if (hint != null) ...[
          const SizedBox(height: 2),
          Text(hint!,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

enum BannerTone { success, error, warning, primary }

/// `rounded-xl p-3 text-sm` tinted banners used across ResumePage
/// (emerald success, red error, amber warning, primary info).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.tone,
    this.text,
    this.child,
    this.padding = const EdgeInsets.all(12),
    this.bordered = false,
  }) : assert(text != null || child != null);

  final BannerTone tone;
  final String? text;
  final Widget? child;
  final EdgeInsetsGeometry padding;
  final bool bordered;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, border) = switch (tone) {
      BannerTone.success => (
          AppColors.emerald50,
          AppColors.emerald700,
          AppColors.emerald100
        ),
      BannerTone.error => (AppColors.red50, AppColors.red700, AppColors.red100),
      BannerTone.warning => (
          AppColors.amber50,
          AppColors.amber700,
          AppColors.amber200
        ),
      BannerTone.primary => (
          AppColors.primary50,
          AppColors.primary,
          AppColors.primary100
        ),
    };
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: bordered ? Border.all(color: border) : null,
      ),
      child: DefaultTextStyle(
        style: TextStyle(fontSize: 14, color: fg, height: 1.5),
        child: child ?? Text(text!),
      ),
    );
  }
}

/// `animate-spin rounded-full border-2 border-primary border-t-transparent`.
class MiniSpinner extends StatelessWidget {
  const MiniSpinner({super.key, this.size = 14, this.color = AppColors.primary});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(strokeWidth: 2, color: color),
      );
}

/// Small rounded pill (`rounded-full px-3 py-1 text-xs font-semibold`).
class Pill extends StatelessWidget {
  const Pill({
    super.key,
    required this.label,
    required this.bg,
    required this.fg,
    this.icon,
    this.compact = false,
  });

  final String label;
  final Color bg;
  final Color fg;
  final IconData? icon;
  /// `px-2 py-0.5 text-[11px] font-medium` chip variant.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: compact ? 11 : 12,
              fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

/// `btn-secondary px-3 py-2` — compact outlined button used in CV rows.
class SmallSecondaryButton extends StatelessWidget {
  const SmallSecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.foreground,
    this.tooltip,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget? icon;
  final Color? foreground;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: foreground ?? AppColors.ink,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        minimumSize: const Size(0, 36),
        textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[icon!, const SizedBox(width: 6)],
          Text(label),
        ],
      ),
    );
    if (tooltip == null) return btn;
    return Tooltip(message: tooltip!, child: btn);
  }
}

/// Section card heading: title (18px bold) + optional helper line.
class CardHeading extends StatelessWidget {
  const CardHeading({super.key, required this.title, this.subtitle, this.trailing});
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink)),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!,
                    style: const TextStyle(
                        fontSize: 14, color: AppColors.inkSoft, height: 1.5)),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}
