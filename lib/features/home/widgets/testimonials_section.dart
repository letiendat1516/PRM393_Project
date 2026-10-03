import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// HomePage.jsx §8.9 "Câu chuyện thành công" (`id="testimonials"`, bg-canvas).
class TestimonialsSection extends StatelessWidget {
  const TestimonialsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Section(
      background: AppColors.canvas,
      verticalPadding: homeSectionPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Reveal(
            child: SectionHeading(
              eyebrow: 'Câu chuyện thành công',
              title: 'Ứng viên nói gì về JobHub',
              description:
                  'Hàng trăm nghìn ứng viên đã tìm được công việc phù hợp nhờ JobHub. Dưới đây là một vài trải nghiệm thực tế.',
            ),
          ),
          const SizedBox(height: 48),
          ResponsiveGrid(
            spacing: 24,
            children: [
              for (var i = 0; i < DemoData.testimonials.length; i++)
                Reveal(
                  delay: Duration(milliseconds: i * 70),
                  child: TestimonialCard(testimonial: DemoData.testimonials[i]),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// components/testimonial/TestimonialCard.jsx — quote glyph + star row,
/// curly-quoted testimonial, author block with 44px portrait.
class TestimonialCard extends StatelessWidget {
  const TestimonialCard({super.key, required this.testimonial});
  final Testimonial testimonial;

  @override
  Widget build(BuildContext context) {
    final t = testimonial;
    return AppCard(
      hoverLift: true,
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Icon(Icons.format_quote_rounded, size: 32, color: AppColors.secondary),
              Semantics(
                label: 'Đánh giá ${t.rating} trên 5 sao',
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    for (var i = 0; i < t.rating; i++)
                      const Padding(
                        padding: EdgeInsets.only(left: 2),
                        child: Icon(Icons.star_rounded, size: 16, color: AppColors.secondary),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Expanded(
            child: Text(
              '“${t.quote}”',
              style: const TextStyle(fontSize: 14, height: 1.75, color: AppColors.inkSoft),
            ),
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderMuted)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppColors.primary100,
                  backgroundImage: AssetImage(t.avatar),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${t.role} · ${t.company}',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
