import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Brightness-aware design tokens for the mobile-only screens (Notification
/// Center, Chat, Settings) so Settings → Giao diện → "Tối" repaints tiles,
/// bubbles, composer and cards live (FLUTTER_REBUILD_PLAN TVV5 #3).
///
/// Light mode returns the exact Tailwind tokens the web uses (`AppColors`);
/// dark mode derives the same roles from the active `ThemeData`
/// (`AppTheme.dark()`): surface / onSurface / dividerColor / chip background,
/// with the soft/muted ink tones blended from onSurface onto the surface.
/// Brand accents (primary / secondary / danger) are intentionally untouched.
extension AdaptiveColors on BuildContext {
  ThemeData get _theme => Theme.of(this);

  bool get isDark => _theme.brightness == Brightness.dark;

  /// `bg-white` — cards, tiles, composer.
  Color get surfaceColor => _theme.colorScheme.surface;

  /// `bg-slate-50` — page canvas / soft wash behind inputs.
  Color get canvasColor => _theme.scaffoldBackgroundColor;

  /// `text-ink` (#0F172A).
  Color get inkColor => _theme.colorScheme.onSurface;

  /// `text-ink-soft` (#334155).
  Color get inkSoftColor => isDark ? _blend(0.82) : AppColors.inkSoft;

  /// `text-ink-muted` (#64748B).
  Color get inkMutedColor => isDark ? _blend(0.6) : AppColors.inkMuted;

  /// `border-slate-200`.
  Color get borderColor => isDark ? _blend(0.14) : AppColors.border;

  /// `border-slate-100`.
  Color get borderMutedColor => _theme.dividerColor;

  /// `bg-slate-100` — their chat bubble, neutral chips.
  Color get chipColor =>
      _theme.chipTheme.backgroundColor ?? (isDark ? _blend(0.08) : AppColors.slate100);

  /// `bg-primary-50` wash — unread rows, selected thread, icon tiles.
  Color get primaryWashColor =>
      isDark ? AppColors.primary.withValues(alpha: 0.28) : AppColors.primary50;

  /// `border-primary-100`.
  Color get primaryWashBorderColor =>
      isDark ? AppColors.primary.withValues(alpha: 0.45) : AppColors.primary100;

  /// Brand accent for *text/icons* on the current surface: exact primary in
  /// light mode, primary-300 in dark mode (see `AppTheme._build`).
  Color get accentColor => _theme.colorScheme.primary;

  Color _blend(double alpha) => Color.alphaBlend(
        _theme.colorScheme.onSurface.withValues(alpha: alpha),
        _theme.colorScheme.surface,
      );
}
