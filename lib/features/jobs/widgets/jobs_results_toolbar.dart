import 'package:flutter/material.dart';

import '../../../core/config/app_config.dart';
import '../../../core/theme/app_colors.dart';
import '../viewmodels/jobs_search_viewmodel.dart';

/// Results toolbar: "Hiển thị X / Y việc làm", AI Matching button (gated to
/// 0 < filtered ≤ 100) and the sort select.
class JobsResultsToolbar extends StatelessWidget {
  const JobsResultsToolbar({
    super.key,
    required this.state,
    required this.onAiMatching,
    required this.onSortChanged,
  });

  final JobsSearchState state;
  final VoidCallback onAiMatching;
  final ValueChanged<String> onSortChanged;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final filtered = state.filtered.length;
    // When no filter is active the user cares about the full dataset size
    // (state.displayTotal is the server-reported count); with filters we
    // report the client-side count against the currently loaded chunk.
    final total = state.displayTotal;
    final enabled = state.canUseAiMatching;
    final tooltip = filtered > 100
        ? 'Lọc xuống ≤100 việc làm (hiện $filtered) để bật AI Matching'
        : 'Chấm điểm CV với AI DeepSeek';

    return Wrap(
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      runSpacing: 12,
      spacing: 12,
      children: [
        Text.rich(
          TextSpan(
            text: 'Hiển thị ',
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
            children: [
              TextSpan(
                text: '${state.pageJobs.length}',
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              TextSpan(text: ' / $total việc làm'),
            ],
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: tooltip,
              child: _AiMatchingButton(
                enabled: enabled,
                needsFilter: filtered > 100,
                scored: state.hasScores && filtered <= 100,
                onPressed: enabled ? onAiMatching : null,
              ),
            ),
            const SizedBox(width: 8),
            if (width >= 640)
              const Padding(
                padding: EdgeInsets.only(right: 8),
                child: Text(
                  'Sắp xếp:',
                  style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
                ),
              ),
            _SortSelect(
              value: state.effectiveSort,
              options: state.sortOptions,
              onChanged: onSortChanged,
            ),
          ],
        ),
      ],
    );
  }
}

class _AiMatchingButton extends StatelessWidget {
  const _AiMatchingButton({
    required this.enabled,
    required this.needsFilter,
    required this.scored,
    required this.onPressed,
  });

  final bool enabled;
  final bool needsFilter;
  final bool scored;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final fg = enabled ? Colors.white : AppColors.inkMuted;
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: Material(
        color: enabled ? AppColors.primary : Colors.transparent,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          hoverColor: enabled ? AppColors.primary700 : null,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: enabled ? null : Border.all(color: AppColors.border),
              boxShadow: enabled ? AppShadows.soft : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_awesome, size: 16, color: fg),
                const SizedBox(width: 6),
                Text(
                  'AI Matching',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: fg,
                  ),
                ),
                if (needsFilter) ...[
                  const SizedBox(width: 4),
                  _MiniPill(
                    label: 'cần ≤100',
                    bg: AppColors.amber100,
                    fg: AppColors.amber700,
                  ),
                ],
                if (scored) ...[
                  const SizedBox(width: 4),
                  const _MiniPill(
                    label: '✓',
                    bg: AppColors.green500,
                    fg: Colors.white,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.label, required this.bg, required this.fg});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(AppRadius.pill),
    ),
    child: Text(
      label,
      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: fg),
    ),
  );
}

/// `rounded-lg border border-slate-200 bg-white px-3 py-1.5 text-sm`.
class _SortSelect extends StatelessWidget {
  const _SortSelect({
    required this.value,
    required this.options,
    required this.onChanged,
  });
  final String value;
  final List<SortOption> options;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: options.any((o) => o.key == value) ? value : options.first.key,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          icon: const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.inkMuted,
          ),
          items: [
            for (final o in options)
              DropdownMenuItem(value: o.key, child: Text(o.label)),
          ],
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Active-filter chips row + trailing 'Xoá tất cả'.
class ActiveFilterChips extends StatelessWidget {
  const ActiveFilterChips({
    super.key,
    required this.filters,
    required this.onRemove,
    required this.onClearAll,
  });

  final JobsFilters filters;
  final void Function(JobFilterKey key, String value) onRemove;
  final VoidCallback onClearAll;

  @override
  Widget build(BuildContext context) {
    final items = filters.flatten();
    if (items.isEmpty) return const SizedBox.shrink();
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (final (key, value) in items)
          _ActiveChip(
            label: JobFilterOptions.labelFor(key, value),
            onRemove: () => onRemove(key, value),
          ),
        InkWell(
          onTap: onClearAll,
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 4, vertical: 4),
            child: Text(
              'Xoá tất cả',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
            ),
          ),
        ),
      ],
    );
  }
}

class _ActiveChip extends StatefulWidget {
  const _ActiveChip({required this.label, required this.onRemove});
  final String label;
  final VoidCallback onRemove;

  @override
  State<_ActiveChip> createState() => _ActiveChipState();
}

class _ActiveChipState extends State<_ActiveChip> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onRemove,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
          decoration: BoxDecoration(
            color: _hover ? AppColors.primary100 : AppColors.primary50,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(Icons.close, size: 14, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}
