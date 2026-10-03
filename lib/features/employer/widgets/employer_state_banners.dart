import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

enum StateCardTone { neutral, error, success }

/// The web "state banners": rounded-2xl border bg-white p-6 text-slate-500
/// (loading / empty), red-50 (error) and green-50 (success) variants.
class StateCard extends StatelessWidget {
  const StateCard({
    super.key,
    required this.text,
    this.tone = StateCardTone.neutral,
    this.center = false,
    this.spinner = false,
    this.action,
  });

  const StateCard.error({super.key, required this.text, this.action})
      : tone = StateCardTone.error,
        center = false,
        spinner = false;

  const StateCard.success({super.key, required this.text, this.action})
      : tone = StateCardTone.success,
        center = false,
        spinner = false;

  final String text;
  final StateCardTone tone;
  final bool center;
  final bool spinner;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      StateCardTone.neutral => (AppColors.surface, AppColors.border, AppColors.inkMuted),
      StateCardTone.error => (AppColors.red50, AppColors.red100, AppColors.red600),
      StateCardTone.success => (AppColors.emerald50, AppColors.emerald100, AppColors.emerald700),
    };
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(center ? 32 : 20),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: Column(
        crossAxisAlignment: center ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
            children: [
              if (spinner) ...[
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: fg),
                ),
                const SizedBox(width: 12),
              ],
              Flexible(
                child: Text(
                  text,
                  textAlign: center ? TextAlign.center : TextAlign.start,
                  style: TextStyle(color: fg, fontSize: 14, height: 1.5),
                ),
              ),
            ],
          ),
          if (action != null) ...[const SizedBox(height: 16), action!],
        ],
      ),
    );
  }
}

/// CreateJobPage error banner: bold title, message, bulleted reasons.
class ReasonsErrorBanner extends StatelessWidget {
  const ReasonsErrorBanner({
    super.key,
    required this.title,
    required this.message,
    this.reasons = const [],
    this.onClose,
  });

  final String title;
  final String message;
  final List<String> reasons;
  final VoidCallback? onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.red100),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline, color: AppColors.red700, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.red700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(color: AppColors.red700, fontSize: 13, height: 1.5)),
                if (reasons.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  for (final r in reasons)
                    Padding(
                      padding: const EdgeInsets.only(left: 6, bottom: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('•  ',
                              style: TextStyle(color: AppColors.red700, fontSize: 13)),
                          Expanded(
                            child: Text(r,
                                style: const TextStyle(
                                    color: AppColors.red700, fontSize: 13, height: 1.5)),
                          ),
                        ],
                      ),
                    ),
                ],
              ],
            ),
          ),
          if (onClose != null)
            IconButton(
              tooltip: 'Đóng',
              onPressed: onClose,
              icon: const Icon(Icons.close, size: 18, color: AppColors.red700),
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}
