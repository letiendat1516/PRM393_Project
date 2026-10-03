import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/app_icons.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// HomePage.jsx §8.5 "Vì sao chọn JobHub" (`id="why-jobhub"`, bg-white):
/// centred heading + 1 → 2 → 3 column grid of FeatureCards.
class WhyJobHubSection extends StatelessWidget {
  const WhyJobHubSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Section(
      background: AppColors.surface,
      verticalPadding: homeSectionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(
            child: SectionHeading(
              eyebrow: 'Vì sao chọn JobHub',
              title: 'Mọi thứ bạn cần cho một hành trình nghề nghiệp thành công',
              description:
                  'JobHub kết hợp công nghệ AI và mạng lưới doanh nghiệp rộng lớn để mang đến trải nghiệm tìm việc nhanh chóng, chính xác và đáng tin cậy.',
            ),
          ),
          const SizedBox(height: 48),
          ResponsiveGrid(
            spacing: 20,
            children: [
              for (var i = 0; i < DemoData.features.length; i++)
                Reveal(
                  delay: Duration(milliseconds: i * 60),
                  child: FeatureCard(feature: DemoData.features[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// components/feature/FeatureCard.jsx — icon tile (primary-50 → primary on
/// hover), bold title, soft body; lifts on hover.
class FeatureCard extends StatefulWidget {
  const FeatureCard({super.key, required this.feature});
  final FeatureItem feature;

  @override
  State<FeatureCard> createState() => _FeatureCardState();
}

class _FeatureCardState extends State<FeatureCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(24),
        transform: Matrix4.translationValues(0, _hover ? -4 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: _hover ? AppColors.primary100 : AppColors.borderMuted),
          boxShadow: _hover ? AppShadows.elevated : AppShadows.card,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: _hover ? AppColors.primary : AppColors.primary50,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Icon(
                AppIcons.of(widget.feature.icon),
                size: 24,
                color: _hover ? Colors.white : AppColors.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              widget.feature.title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            Text(
              widget.feature.description,
              style: const TextStyle(fontSize: 14, height: 1.75, color: AppColors.inkSoft),
            ),
          ],
        ),
      ),
    );
  }
}
