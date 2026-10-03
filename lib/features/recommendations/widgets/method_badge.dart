import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// RecommendedPage.jsx MethodBadge — `rounded-full px-2 py-0.5 text-[10px]
/// font-bold`; ai → primary-50/primary 'AI', sql → teal-50/teal-600 'SQL',
/// both → violet-50/violet-600 'AI + SQL'. Unknown methods fall back to the
/// ai colours and show the raw method string.
class MethodBadge extends StatelessWidget {
  const MethodBadge({super.key, required this.method});

  final String method;

  static (Color bg, Color fg, String label) styleFor(String method) => switch (method) {
        'ai' => (AppColors.primary50, AppColors.primary, 'AI'),
        'sql' => (AppColors.teal50, AppColors.teal600, 'SQL'),
        'both' => (AppColors.violet50, AppColors.violet600, 'AI + SQL'),
        _ => (AppColors.primary50, AppColors.primary, method),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = styleFor(method);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: 10, fontWeight: FontWeight.w700, height: 1.4),
      ),
    );
  }
}
