import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/ui_primitives.dart';

/// AiLogsPage / AiStatsPage StatCard — icon tile + label + value.
/// [horizontal] = AiLogs variant (icon left), otherwise AiStats variant
/// (icon on top).
class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = AppColors.primary,
    this.horizontal = true,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool horizontal;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const labelStyle = TextStyle(fontSize: 12, color: AppColors.inkMuted);
    const valueStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink);

    if (!horizontal) {
      return AppCard(
        padding: const EdgeInsets.all(16),
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 8),
            Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      );
    }

    return AppCard(
      padding: const EdgeInsets.all(16),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.slate50,
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            alignment: Alignment.center,
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: labelStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
                Text(value, style: valueStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Responsive grid of equally sized tiles: [columnsFor] picks the column count
/// from the available width.
class TileGrid extends StatelessWidget {
  const TileGrid({
    super.key,
    required this.children,
    required this.columnsFor,
    this.gap = 12,
  });

  final List<Widget> children;
  final int Function(double width) columnsFor;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final cols = columnsFor(c.maxWidth).clamp(1, children.isEmpty ? 1 : children.length);
      final w = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: [for (final ch in children) SizedBox(width: w, child: ch)],
      );
    });
  }
}
