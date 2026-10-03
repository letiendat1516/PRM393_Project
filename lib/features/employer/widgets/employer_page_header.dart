import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// Eyebrow (text-sm semibold uppercase tracking-wide blue-700) + H1
/// (text-3xl bold slate-900) + subtitle (slate-500), optional right action.
class EmployerPageHeader extends StatelessWidget {
  const EmployerPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.action,
    this.eyebrowColor = AppColors.primary,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? action;
  final Color eyebrowColor;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          eyebrow.toUpperCase(),
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.1,
            color: eyebrowColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 15, color: AppColors.inkMuted, height: 1.5)),
        ],
      ],
    );
    if (action == null) return text;
    if (width < 640) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [text, const SizedBox(height: 16), action!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: text),
        const SizedBox(width: 16),
        action!,
      ],
    );
  }
}
