import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodels/ai_stats_viewmodel.dart';

/// "Lượt gọi 7 ngày gần nhất" — single-series bar chart like the web
/// (`flex items-end` columns, height 140): one hue, rounded data-ends
/// anchored to the baseline, weekday labels below, tooltip
/// "{yyyy-MM-dd}: {n} lượt" on hover/tap. No Y axis, no gridlines, no
/// numeric value labels.
class CallsPerDayChart extends StatelessWidget {
  const CallsPerDayChart({super.key, required this.days, this.height = 160});

  final List<DayBucket> days;
  final double height;

  @override
  Widget build(BuildContext context) {
    final maxCount = days.fold<int>(0, (m, d) => d.count > m ? d.count : m);
    final maxY = (maxCount <= 0 ? 1 : maxCount).toDouble();

    return SizedBox(
      height: height,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          barGroups: [
            for (var i = 0; i < days.length; i++)
              BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    // web: `minHeight: 4` so an empty day still shows a sliver
                    toY: days[i].count == 0 ? maxY * 0.02 : days[i].count.toDouble(),
                    width: 18,
                    color: AppColors.primary.withValues(alpha: 0.8),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                  ),
                ],
              ),
          ],
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 22,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= days.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(days[i].weekdayLabel,
                        style: const TextStyle(fontSize: 10, color: AppColors.inkMuted)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppColors.ink,
              tooltipPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final d = days[group.x];
                return BarTooltipItem(
                  '${d.isoDate}: ${d.count} lượt',
                  const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                );
              },
            ),
          ),
        ),
        duration: const Duration(milliseconds: 250),
      ),
    );
  }
}
