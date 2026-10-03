import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

/// ThemeData built from the Tailwind tokens (tailwind.config.js + index.css):
/// Plus Jakarta Sans, rounded-xl buttons/inputs (14px), rounded-2xl cards
/// (16px), slate borders. The web is light-only; the dark theme is the
/// mobile-plan extra (Settings → Giao diện).
class AppTheme {
  const AppTheme._();

  static TextTheme _textTheme(TextTheme base, Color color) {
    final t = GoogleFonts.plusJakartaSansTextTheme(base).apply(
      bodyColor: color,
      displayColor: color,
    );
    return t.copyWith(
      displayLarge: t.displayLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
      displayMedium: t.displayMedium?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
      headlineLarge: t.headlineLarge?.copyWith(fontWeight: FontWeight.w800, letterSpacing: -0.5, height: 1.1),
      headlineMedium: t.headlineMedium?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.3, height: 1.2),
      headlineSmall: t.headlineSmall?.copyWith(fontWeight: FontWeight.w700, letterSpacing: -0.2, height: 1.25),
      titleLarge: t.titleLarge?.copyWith(fontWeight: FontWeight.w700),
      titleMedium: t.titleMedium?.copyWith(fontWeight: FontWeight.w700),
      titleSmall: t.titleSmall?.copyWith(fontWeight: FontWeight.w600),
      bodyLarge: t.bodyLarge?.copyWith(height: 1.6),
      bodyMedium: t.bodyMedium?.copyWith(height: 1.55),
      labelLarge: t.labelLarge?.copyWith(fontWeight: FontWeight.w600),
    );
  }

  static ThemeData light() => _build(
        brightness: Brightness.light,
        canvas: AppColors.canvas,
        surface: AppColors.surface,
        ink: AppColors.ink,
        inkSoft: AppColors.inkSoft,
        inkMuted: AppColors.inkMuted,
        border: AppColors.border,
        borderMuted: AppColors.borderMuted,
        chipBg: AppColors.slate100,
      );

  static ThemeData dark() => _build(
        brightness: Brightness.dark,
        canvas: const Color(0xFF0B1220),
        surface: const Color(0xFF111A2B),
        ink: const Color(0xFFE2E8F0),
        inkSoft: const Color(0xFFCBD5E1),
        inkMuted: const Color(0xFF94A3B8),
        border: const Color(0xFF1F2A3D),
        borderMuted: const Color(0xFF18223A),
        chipBg: const Color(0xFF1B2538),
      );

  static ThemeData _build({
    required Brightness brightness,
    required Color canvas,
    required Color surface,
    required Color ink,
    required Color inkSoft,
    required Color inkMuted,
    required Color border,
    required Color borderMuted,
    required Color chipBg,
  }) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: isDark ? AppColors.primary300 : AppColors.primary,
      onPrimary: isDark ? AppColors.primary900 : Colors.white,
      secondary: AppColors.secondary,
      onSecondary: Colors.white,
      surface: surface,
      onSurface: ink,
      error: AppColors.danger,
    );
    final base = isDark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
    final text = _textTheme(base.textTheme, ink);

    OutlineInputBorder inputBorder(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      textTheme: text,
      scaffoldBackgroundColor: canvas,
      canvasColor: surface,
      cardColor: surface,
      dividerColor: borderMuted,
      splashFactory: InkRipple.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: surface,
        foregroundColor: ink,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        surfaceTintColor: surface,
        centerTitle: false,
        titleTextStyle: text.titleLarge?.copyWith(color: ink, fontWeight: FontWeight.w800),
        iconTheme: IconThemeData(color: ink),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.5),
          disabledForegroundColor: scheme.onPrimary,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(0, 48),
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: BorderSide(color: border),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          minimumSize: const Size(0, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: inkSoft,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.xl)),
          textStyle: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        hintStyle: text.bodyMedium?.copyWith(color: inkMuted),
        labelStyle: text.labelLarge?.copyWith(color: inkSoft, fontWeight: FontWeight.w500),
        floatingLabelStyle: text.labelLarge?.copyWith(color: scheme.primary, fontWeight: FontWeight.w500),
        prefixIconColor: inkMuted,
        suffixIconColor: inkMuted,
        border: inputBorder(border),
        enabledBorder: inputBorder(border),
        focusedBorder: inputBorder(scheme.primary, 1.5),
        errorBorder: inputBorder(AppColors.danger),
        focusedErrorBorder: inputBorder(AppColors.danger, 1.5),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          side: BorderSide(color: borderMuted),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: chipBg,
        selectedColor: isDark ? AppColors.primary800 : AppColors.primary50,
        disabledColor: borderMuted,
        labelStyle: text.labelLarge?.copyWith(fontSize: 12, color: inkSoft, fontWeight: FontWeight.w500),
        secondaryLabelStyle:
            text.labelLarge?.copyWith(fontSize: 12, color: scheme.primary, fontWeight: FontWeight.w600),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          side: BorderSide.none,
        ),
        side: BorderSide.none,
      ),
      dividerTheme: DividerThemeData(color: borderMuted, thickness: 1, space: 1),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          side: BorderSide(color: border),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: surface,
        surfaceTintColor: surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.x2l)),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
      ),
    );
  }
}
