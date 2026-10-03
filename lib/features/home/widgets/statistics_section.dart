import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';
import 'home_layout_helpers.dart';
import 'reveal.dart';

/// components/statistics/StatisticsSection.jsx — full-bleed `bg-primary`
/// band with blurred blobs and a 2 → 4 column grid of StatisticCards.
class StatisticsSection extends StatelessWidget {
  const StatisticsSection({super.key});

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Container(
      width: double.infinity,
      color: AppColors.primary,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            left: -64,
            top: -64,
            child: DecorBlob(color: Colors.white.withValues(alpha: 0.06), size: 256),
          ),
          Positioned(
            right: 40,
            bottom: -80,
            child: DecorBlob(color: AppColors.secondary.withValues(alpha: 0.22)),
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: wide ? 80 : 64),
            child: PageContainer(
              child: Reveal(
                child: ResponsiveGrid(
                  columnsFor: (w) => w >= 900 ? 4 : 2,
                  spacing: 32,
                  children: [
                    for (var i = 0; i < DemoData.statistics.length; i++)
                      Reveal(
                        delay: Duration(milliseconds: i * 80),
                        child: StatisticCard(stat: DemoData.statistics[i]),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// components/statistics/StatisticCard.jsx — giant white value + pale
/// `primary-100` label. The component's optional icon chip is rendered only
/// `if (icon)`, and data/stats.js entries carry no `icon`, so the live web
/// band shows value + label only.
class StatisticCard extends StatelessWidget {
  const StatisticCard({super.key, required this.stat});
  final StatItem stat;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 640;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          stat.value,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: wide ? 36 : 30,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: Colors.white,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stat.label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, color: AppColors.primary100),
        ),
      ],
    );
  }
}
