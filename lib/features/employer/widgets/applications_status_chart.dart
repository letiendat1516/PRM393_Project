import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../viewmodels/dashboard_viewmodel.dart';

/// Applications by status — column chart with direct value labels plus a
/// legend row (label + count) so identity never relies on colour alone.
class ApplicationsStatusChart extends StatelessWidget {
  const ApplicationsStatusChart({super.key, required this.byStatus});
  final Map<ApplicationStatus, int> byStatus;

  // Status colours (validated: all pairs CVD ΔE ≥ 8, contrast ≥ 3:1 on white
  // except amber, which is covered by the visible labels + legend).
  static Color colorOf(ApplicationStatus s) => switch (s) {
        ApplicationStatus.submitted => AppColors.blue600,
        ApplicationStatus.underReview => AppColors.amber500,
        ApplicationStatus.accepted => AppColors.emerald600,
        ApplicationStatus.rejected => AppColors.red600,
        _ => AppColors.slate400,
      };

  @override
  Widget build(BuildContext context) {
    final statuses = DashboardStats.chartStatuses;
    final total = statuses.fold<int>(0, (sum, s) => sum + (byStatus[s] ?? 0));
    final maxVal = statuses.fold<int>(0, (m, s) => (byStatus[s] ?? 0) > m ? byStatus[s]! : m);
    final maxY = maxVal == 0 ? 4.0 : (maxVal * 1.3).ceilToDouble();

    if (total == 0) {
      return const SizedBox(
        height: 200,
        child: Center(
          child: Text('Chưa có hồ sơ ứng tuyển nào để thống kê.',
              style: TextStyle(color: AppColors.inkMuted, fontSize: 13)),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 220,
          child: BarChart(
            BarChartData(
              maxY: maxY,
              minY: 0,
              alignment: BarChartAlignment.spaceAround,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: _interval(maxY),
                getDrawingHorizontalLine: (_) =>
                    const FlLine(color: AppColors.borderMuted, strokeWidth: 1),
              ),
              borderData: FlBorderData(
                show: true,
                border: const Border(bottom: BorderSide(color: AppColors.border)),
              ),
              titlesData: FlTitlesData(
                topTitles: const AxisTitles(),
                rightTitles: const AxisTitles(),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: _interval(maxY),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 11, color: AppColors.inkMuted),
                    ),
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= statuses.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          ApplicationStatusBadge.styleOf(statuses[i]).$3,
                          style: const TextStyle(fontSize: 11, color: AppColors.inkSoft),
                        ),
                      );
                    },
                  ),
                ),
              ),
              barTouchData: BarTouchData(
                enabled: true,
                touchTooltipData: BarTouchTooltipData(
                  getTooltipColor: (_) => AppColors.ink,
                  tooltipRoundedRadius: 8,
                  getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                    '${ApplicationStatusBadge.styleOf(statuses[group.x]).$3}\n',
                    const TextStyle(color: Colors.white, fontSize: 12),
                    children: [
                      TextSpan(
                        text: '${rod.toY.toInt()} hồ sơ',
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ),
              barGroups: [
                for (var i = 0; i < statuses.length; i++)
                  BarChartGroupData(
                    x: i,
                    showingTooltipIndicators: const [],
                    barRods: [
                      BarChartRodData(
                        toY: (byStatus[statuses[i]] ?? 0).toDouble(),
                        color: colorOf(statuses[i]),
                        width: 28,
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
            duration: const Duration(milliseconds: 250),
          ),
        ),
        const SizedBox(height: 12),
        // Direct labels: value above each column as a legend row (text tokens).
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            for (final s in statuses)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: colorOf(s), borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${ApplicationStatusBadge.styleOf(s).$3}: ',
                    style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                  ),
                  Text(
                    '${byStatus[s] ?? 0}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w700),
                  ),
                  if (total > 0)
                    Text(
                      ' (${((byStatus[s] ?? 0) * 100 / total).round()}%)',
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                    ),
                ],
              ),
          ],
        ),
      ],
    );
  }

  static double _interval(double maxY) {
    if (maxY <= 5) return 1;
    if (maxY <= 10) return 2;
    if (maxY <= 25) return 5;
    if (maxY <= 50) return 10;
    return (maxY / 5).ceilToDouble();
  }
}
