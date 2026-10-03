import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// One onboarding slide (copy + illustration asset).
class OnboardingSlideData {
  const OnboardingSlideData({
    required this.icon,
    required this.image,
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final String image;
  final String eyebrow;
  final String title;
  final String description;
}

/// Illustration + copy. Two columns on wide screens, stacked on phones.
class OnboardingSlide extends StatelessWidget {
  const OnboardingSlide({super.key, required this.data, required this.isWide});

  final OnboardingSlideData data;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final illustration = _Illustration(data: data);
    final copy = _Copy(data: data, centered: !isWide);

    if (isWide) {
      return Row(
        children: [
          Expanded(flex: 6, child: illustration),
          const SizedBox(width: 56),
          Expanded(flex: 5, child: copy),
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 12),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: illustration,
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 440),
                  child: copy,
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Illustration extends StatelessWidget {
  const _Illustration({required this.data});
  final OnboardingSlideData data;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 4 / 3,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(AppRadius.x4l),
          boxShadow: AppShadows.card,
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              data.image,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Center(
                child: Icon(data.icon, size: 72, color: AppColors.primary300),
              ),
            ),
            // Soft brand gradient so the icon badge stays legible.
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    AppColors.primary900.withValues(alpha: 0.55),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                  boxShadow: AppShadows.soft,
                ),
                child: Icon(data.icon, color: AppColors.primary, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Copy extends StatelessWidget {
  const _Copy({required this.data, required this.centered});
  final OnboardingSlideData data;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final align = centered ? TextAlign.center : TextAlign.start;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: centered ? CrossAxisAlignment.center : CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.primary50,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            data.eyebrow.toUpperCase(),
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: AppColors.primary,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          data.title,
          textAlign: align,
          style: TextStyle(
            fontSize: centered ? 26 : 34,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
            letterSpacing: -0.6,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          data.description,
          textAlign: align,
          style: const TextStyle(
            fontSize: 15,
            color: AppColors.inkSoft,
            height: 1.65,
          ),
        ),
      ],
    );
  }
}
