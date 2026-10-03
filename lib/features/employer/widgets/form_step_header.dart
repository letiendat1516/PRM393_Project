import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// 3-step indicator for CreateJobPage (tappable, compact on phones).
class FormStepHeader extends StatelessWidget {
  const FormStepHeader({
    super.key,
    required this.titles,
    required this.current,
    required this.onTap,
  });

  final List<String> titles;
  final int current;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final narrow = MediaQuery.sizeOf(context).width < 640;
    if (narrow) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Bước ${current + 1}/${titles.length}',
                  style: const TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(titles[current],
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: (current + 1) / titles.length,
              minHeight: 6,
              backgroundColor: AppColors.slate100,
              color: AppColors.primary,
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        for (var i = 0; i < titles.length; i++) ...[
          if (i > 0)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.symmetric(horizontal: 10),
                color: i <= current ? AppColors.primary : AppColors.border,
              ),
            ),
          InkWell(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            onTap: () => onTap(i),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < current
                          ? AppColors.primary
                          : i == current
                              ? AppColors.primary
                              : AppColors.surface,
                      border: Border.all(
                          color: i <= current ? AppColors.primary : AppColors.border),
                    ),
                    alignment: Alignment.center,
                    child: i < current
                        ? const Icon(Icons.check, size: 16, color: Colors.white)
                        : Text('${i + 1}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: i == current ? Colors.white : AppColors.inkMuted)),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    titles[i],
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: i == current ? FontWeight.w700 : FontWeight.w500,
                      color: i == current ? AppColors.ink : AppColors.inkMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
