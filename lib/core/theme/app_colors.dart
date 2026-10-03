import 'package:flutter/material.dart';

/// Design tokens from frontend/tailwind.config.js + src/index.css.
class AppColors {
  const AppColors._();

  // Brand — primary (navy) scale
  static const Color primary = Color(0xFF0F4C81);
  static const Color primary50 = Color(0xFFEFF6FC);
  static const Color primary100 = Color(0xFFD8E9F7);
  static const Color primary200 = Color(0xFFB3D2ED);
  static const Color primary300 = Color(0xFF7FAEDC);
  static const Color primary400 = Color(0xFF4A85C2);
  static const Color primary500 = Color(0xFF2B66A0);
  static const Color primary600 = Color(0xFF0F4C81);
  static const Color primary700 = Color(0xFF0C3D68);
  static const Color primary800 = Color(0xFF0A3255);
  static const Color primary900 = Color(0xFF082845);
  static const Color primaryDark = Color(0xFF0C3D68);

  // Brand — secondary (green) scale
  static const Color secondary = Color(0xFF00A86B);
  static const Color secondary50 = Color(0xFFECFDF5);
  static const Color secondary100 = Color(0xFFD1FAE5);
  static const Color secondary200 = Color(0xFFA7F3D0);
  static const Color secondary500 = Color(0xFF10B981);
  static const Color secondary600 = Color(0xFF00A86B);
  static const Color secondary700 = Color(0xFF00855A);

  // Surfaces
  static const Color canvas = Color(0xFFF8FAFC);
  static const Color surface = Color(0xFFFFFFFF);

  // Ink (text)
  static const Color ink = Color(0xFF0F172A);
  static const Color inkSoft = Color(0xFF334155);
  static const Color inkMuted = Color(0xFF64748B);

  // Borders
  static const Color border = Color(0xFFE2E8F0); // slate-200
  static const Color borderMuted = Color(0xFFF1F5F9); // slate-100

  // Slate scale
  static const Color slate50 = Color(0xFFF8FAFC);
  static const Color slate100 = Color(0xFFF1F5F9);
  static const Color slate200 = Color(0xFFE2E8F0);
  static const Color slate300 = Color(0xFFCBD5E1);
  static const Color slate400 = Color(0xFF94A3B8);
  static const Color slate500 = Color(0xFF64748B);

  // Status
  static const Color success = Color(0xFF00A86B);
  static const Color danger = Color(0xFFDC2626);
  static const Color dangerBg = Color(0xFFFEF2F2);
  static const Color dangerBorder = Color(0xFFFECACA);
  static const Color dangerText = Color(0xFFB91C1C);
  static const Color warning = Color(0xFFF59E0B);
  static const Color info = Color(0xFF2B66A0);

  // Tailwind tints used by badges / banners
  static const Color blue50 = Color(0xFFEFF6FF);
  static const Color blue100 = Color(0xFFDBEAFE);
  static const Color blue600 = Color(0xFF2563EB);
  static const Color blue700 = Color(0xFF1D4ED8);
  static const Color amber50 = Color(0xFFFFFBEB);
  static const Color amber100 = Color(0xFFFEF3C7);
  static const Color amber200 = Color(0xFFFDE68A);
  static const Color amber500 = Color(0xFFF59E0B);
  static const Color amber600 = Color(0xFFD97706);
  static const Color amber700 = Color(0xFFB45309);
  static const Color emerald50 = Color(0xFFECFDF5);
  static const Color emerald100 = Color(0xFFD1FAE5);
  static const Color emerald600 = Color(0xFF059669);
  static const Color emerald700 = Color(0xFF047857);
  static const Color green50 = Color(0xFFF0FDF4);
  static const Color green500 = Color(0xFF22C55E);
  static const Color green600 = Color(0xFF16A34A);
  static const Color green800 = Color(0xFF166534);
  static const Color red50 = Color(0xFFFEF2F2);
  static const Color red100 = Color(0xFFFEE2E2);
  static const Color red300 = Color(0xFFFCA5A5);
  static const Color red500 = Color(0xFFEF4444);
  static const Color red600 = Color(0xFFDC2626);
  static const Color red700 = Color(0xFFB91C1C);
  static const Color teal50 = Color(0xFFF0FDFA);
  static const Color teal600 = Color(0xFF0D9488);
  static const Color violet50 = Color(0xFFF5F3FF);
  static const Color violet600 = Color(0xFF7C3AED);
  static const Color purple600 = Color(0xFF9333EA);

  // Deprecated aliases (keeps older files compiling)
  static const Color muted = inkMuted;
  static const Color onSurface = ink;
}

/// jobMapper COMPANY_PALETTES: `bg-{c}-50 text-{c}-600` for
/// orange, pink, amber, red, sky, green, violet, teal, indigo, rose.
class CompanyPalette {
  const CompanyPalette._();

  static const List<(Color bg, Color fg)> colors = [
    (Color(0xFFFFF7ED), Color(0xFFEA580C)), // orange
    (Color(0xFFFDF2F8), Color(0xFFDB2777)), // pink
    (Color(0xFFFFFBEB), Color(0xFFD97706)), // amber
    (Color(0xFFFEF2F2), Color(0xFFDC2626)), // red
    (Color(0xFFF0F9FF), Color(0xFF0284C7)), // sky
    (Color(0xFFF0FDF4), Color(0xFF16A34A)), // green
    (Color(0xFFF5F3FF), Color(0xFF7C3AED)), // violet
    (Color(0xFFF0FDFA), Color(0xFF0D9488)), // teal
    (Color(0xFFEEF2FF), Color(0xFF4F46E5)), // indigo
    (Color(0xFFFFF1F2), Color(0xFFE11D48)), // rose
  ];

  static (Color bg, Color fg) at(int index) => colors[index % colors.length];

  /// Parse a Tailwind brand string from the mock data ('bg-orange-50 text-orange-600').
  static (Color bg, Color fg) fromTailwind(String? brand) {
    const names = ['orange', 'pink', 'amber', 'red', 'sky', 'green', 'violet', 'teal', 'indigo', 'rose'];
    if (brand == null) return colors[0];
    for (var i = 0; i < names.length; i++) {
      if (brand.contains(names[i])) return colors[i];
    }
    return colors[0];
  }
}

class AppShadows {
  const AppShadows._();

  static const soft = [
    BoxShadow(color: Color(0x0A0F4C81), blurRadius: 2, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x0F0F172A), blurRadius: 16, offset: Offset(0, 4)),
  ];
  static const card = [
    BoxShadow(color: Color(0x0D0F172A), blurRadius: 3, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x1F0F172A), blurRadius: 30, offset: Offset(0, 10)),
  ];
  static const elevated = [
    BoxShadow(color: Color(0x470F4C81), blurRadius: 50, offset: Offset(0, 18)),
  ];
}

class AppRadius {
  const AppRadius._();
  static const double sm = 4;
  static const double md = 8;
  static const double lg = 12;
  static const double xl = 14; // buttons & inputs
  static const double x2l = 16; // cards
  static const double x3l = 20;
  static const double x4l = 24;
  static const double pill = 9999;
}
