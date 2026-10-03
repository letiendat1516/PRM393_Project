import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Dashboard KPI tile: label, hero value, optional hint, tinted icon badge.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.hint,
    this.tint = AppColors.primary,
    this.tintBg = AppColors.primary50,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final String? hint;
  final Color tint;
  final Color tintBg;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkMuted,
                        letterSpacing: 0.3)),
                const SizedBox(height: 8),
                Text(value,
                    style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                        height: 1.1)),
                if (hint != null) ...[
                  const SizedBox(height: 6),
                  Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: tintBg, borderRadius: BorderRadius.circular(12)),
            child: Icon(icon, size: 20, color: tint),
          ),
        ],
      ),
    );
    if (onTap == null) return card;
    return InkWell(borderRadius: BorderRadius.circular(AppRadius.x2l), onTap: onTap, child: card);
  }
}
