import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/resume_model.dart';

/// Single-series bar chart of what the AI extracted from the CV: number of
/// hard skills, soft skills, languages and certifications.
/// One hue (primary) because the bars share one measure; values are
/// direct-labelled above each bar so colour carries no information.
class AnalysisCategoryChart extends StatelessWidget {
  const AnalysisCategoryChart({super.key, required this.analysis});
  final AiAnalysis analysis;

  List<(String, int)> get _rows => [
        ('Kỹ năng', analysis.skills.length),
        ('Kỹ năng mềm', analysis.softSkills.length),
        ('Ngôn ngữ', analysis.languages.length),
        ('Chứng chỉ', analysis.certifications.length),
      ];

  @override
  Widget build(BuildContext context) {
    final rows = _rows;
    final maxVal = rows.fold<int>(0, (m, r) => r.$2 > m ? r.$2 : m);
    final maxY = (maxVal <= 0 ? 1 : maxVal) * 1.25 + 1;
    final interval = maxVal <= 5 ? 1.0 : (maxVal / 4).ceilToDouble();

    return SizedBox(
      height: 240,
      child: BarChart(
        BarChartData(
          maxY: maxY,
          minY: 0,
          alignment: BarChartAlignment.spaceAround,
          borderData: FlBorderData(show: false),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: interval,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: AppColors.borderMuted, strokeWidth: 1),
          ),
          titlesData: FlTitlesData(
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                interval: interval,
                getTitlesWidget: (v, meta) {
                  if (v > maxVal.toDouble() + 0.01 && v != 0) return const SizedBox.shrink();
                  return Text(v.toInt().toString(),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted));
                },
              ),
            ),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 32,
                getTitlesWidget: (v, meta) {
                  final i = v.toInt();
                  if (i < 0 || i >= rows.length) return const SizedBox.shrink();
                  return SideTitleWidget(
                    axisSide: meta.axisSide,
                    space: 8,
                    child: Text(rows[i].$1,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.inkSoft,
                            fontWeight: FontWeight.w600)),
                  );
                },
              ),
            ),
          ),
          barTouchData: BarTouchData(
            enabled: false,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => Colors.transparent,
              tooltipPadding: EdgeInsets.zero,
              tooltipMargin: 6,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                rod.toY.toInt().toString(),
                const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
            ),
          ),
          barGroups: [
            for (var i = 0; i < rows.length; i++)
              BarChartGroupData(
                x: i,
                showingTooltipIndicators: const [0],
                barRods: [
                  BarChartRodData(
                    toY: rows[i].$2.toDouble(),
                    width: 28,
                    color: AppColors.primary,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    backDrawRodData: BackgroundBarChartRodData(
                      show: true,
                      toY: maxY,
                      color: AppColors.slate50,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
