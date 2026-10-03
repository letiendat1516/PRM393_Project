import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/recommendation_models.dart';
import '../viewmodels/ai_stats_viewmodel.dart';

/// `section.card.p-5` with `h2.mb-4.text-base.font-bold`.
class StatsSectionCard extends StatelessWidget {
  const StatsSectionCard({super.key, required this.title, required this.child, this.trailing});
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              ?trailing,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

/// "Phân tích theo task" rows: name · "{count} lượt · {avg}ms · {tokens} tok"
/// + proportional track.
class TaskBreakdownList extends StatelessWidget {
  const TaskBreakdownList({super.key, required this.byTask, required this.total});
  final List<TaskStat> byTask;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < byTask.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          _ProgressRow(
            label: byTask[i].task,
            labelStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink),
            trailing:
                '${byTask[i].count} lượt · ${byTask[i].avgTimeMs}ms · ${Formatters.number(byTask[i].tokens)} tok',
            trailingStyle: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            fraction: total == 0 ? 0 : byTask[i].count / total,
            color: AppColors.primary,
            trackHeight: 8,
          ),
        ],
      ],
    );
  }
}

/// "Token usage": input (primary) / output (secondary) bars + the cost footer
/// "Input: $X · Output: $Y" (toFixed(4), DeepSeek per-1M pricing).
class TokenUsage extends StatelessWidget {
  const TokenUsage({super.key, required this.tokensIn, required this.tokensOut});
  final int tokensIn;
  final int tokensOut;

  @override
  Widget build(BuildContext context) {
    final total = tokensIn + tokensOut;
    int pct(int v) => total == 0 ? 0 : (v / total * 100).round();
    final costIn = (tokensIn / 1e6 * AiStats.priceInPer1M).toStringAsFixed(4);
    final costOut = (tokensOut / 1e6 * AiStats.priceOutPer1M).toStringAsFixed(4);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ProgressRow(
          label: 'Input tokens (prompt)',
          labelStyle: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
          trailing: '${Formatters.number(tokensIn)} (${pct(tokensIn)}%)',
          trailingStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
          fraction: total == 0 ? 0 : tokensIn / total,
          color: AppColors.primary,
          trackHeight: 10,
        ),
        const SizedBox(height: 16),
        _ProgressRow(
          label: 'Output tokens (response)',
          labelStyle: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
          trailing: '${Formatters.number(tokensOut)} (${pct(tokensOut)}%)',
          trailingStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
          fraction: total == 0 ? 0 : tokensOut / total,
          color: AppColors.secondary,
          trackHeight: 10,
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 12),
          decoration: const BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.borderMuted)),
          ),
          child: Text(
            'Input: \$$costIn · Output: \$$costOut',
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ),
      ],
    );
  }
}

/// "Top 5 chậm nhất (cần tối ưu prompt)".
class SlowestCallsList extends StatelessWidget {
  const SlowestCallsList({super.key, required this.logs});
  final List<AiMatchingLog> logs;

  @override
  Widget build(BuildContext context) {
    if (logs.isEmpty) {
      return const Text('Chưa có dữ liệu.', style: TextStyle(fontSize: 14, color: AppColors.inkMuted));
    }
    return Column(
      children: [
        for (var i = 0; i < logs.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(color: AppColors.amber100, shape: BoxShape.circle),
                  alignment: Alignment.center,
                  child: Text('${i + 1}',
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber700)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(logs[i].task,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      Text(
                        logs[i].createdAt == null ? '-' : Formatters.localeDateTime(logs[i].createdAt!),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 10, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${logs[i].processingTimeMs}ms',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: logs[i].processingTimeMs > 30000 ? AppColors.red600 : AppColors.amber700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _ProgressRow extends StatelessWidget {
  const _ProgressRow({
    required this.label,
    required this.labelStyle,
    required this.trailing,
    required this.trailingStyle,
    required this.fraction,
    required this.color,
    required this.trackHeight,
  });

  final String label;
  final TextStyle labelStyle;
  final String trailing;
  final TextStyle trailingStyle;
  final double fraction;
  final Color color;
  final double trackHeight;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis)),
            const SizedBox(width: 12),
            Text(trailing, style: trailingStyle),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: fraction.clamp(0, 1),
            minHeight: trackHeight,
            backgroundColor: AppColors.slate100,
            color: color,
          ),
        ),
      ],
    );
  }
}
