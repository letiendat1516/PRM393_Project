import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../viewmodels/jobs_search_viewmodel.dart';

/// components/job/JobFilterSidebar.jsx — sticky card with 7 facet groups.
/// Controlled: state lives in [JobsSearchViewModel].
class JobFilterSidebar extends StatelessWidget {
  const JobFilterSidebar({
    super.key,
    required this.filters,
    required this.facets,
    required this.resultCount,
    required this.onToggle,
    required this.onReset,
  });

  final JobsFilters filters;
  final JobFacets facets;
  final int resultCount;
  final void Function(JobFilterKey key, String value) onToggle;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Sticky (bounded) → groups scroll inside the card like
        // `max-h-[calc(100vh-7rem)] overflow-y-auto`; stacked → natural height.
        final bounded = constraints.hasBoundedHeight;
        final groups = _groups();
        return Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.x2l),
            border: Border.all(color: AppColors.borderMuted),
            boxShadow: AppShadows.card,
          ),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(),
              const SizedBox(height: 4),
              Text(
                '$resultCount việc làm phù hợp',
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 4),
              if (bounded)
                Flexible(
                  child: SingleChildScrollView(
                    primary: false,
                    padding: const EdgeInsets.only(bottom: 4),
                    child: groups,
                  ),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: groups,
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _header() => Row(
    children: [
      const Icon(Icons.tune, size: 18, color: AppColors.primary),
      const SizedBox(width: 8),
      const Expanded(
        child: Text(
          'Bộ lọc',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
          ),
        ),
      ),
      InkWell(
        onTap: onReset,
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Text(
            'Xoá lọc',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    ],
  );

  Widget _groups() => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _FilterGroup(
        title: 'Ngành nghề',
        scrollable: true,
        children: [
          for (final (name, count) in facets.categories)
            _CheckboxRow(
              label: name,
              count: count,
              checked: filters.categories.contains(name),
              onChanged: () => onToggle(JobFilterKey.categories, name),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Địa điểm',
        scrollable: true,
        children: [
          for (final (name, count) in facets.cities)
            _CheckboxRow(
              label: name,
              count: count,
              checked: filters.cities.contains(name),
              onChanged: () => onToggle(JobFilterKey.cities, name),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Mức lương',
        children: [
          for (final o in JobFilterOptions.salary)
            _CheckboxRow(
              label: o.label,
              checked: filters.salary.contains(o.value),
              onChanged: () => onToggle(JobFilterKey.salary, o.value),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Kinh nghiệm',
        children: [
          for (final o in JobFilterOptions.experience)
            _CheckboxRow(
              label: o.label,
              count: facets.levelCounts[o.label] ?? 0,
              checked: filters.experience.contains(o.value),
              onChanged: () => onToggle(JobFilterKey.experience, o.value),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Cấp bậc',
        children: [
          for (final o in JobFilterOptions.jobLevel)
            _CheckboxRow(
              label: o.label,
              checked: filters.jobLevel.contains(o.value),
              onChanged: () => onToggle(JobFilterKey.jobLevel, o.value),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Hình thức làm việc',
        children: [
          for (final o in JobFilterOptions.workMode)
            _CheckboxRow(
              label: o.label,
              checked: filters.workMode.contains(o.value),
              onChanged: () => onToggle(JobFilterKey.workMode, o.value),
            ),
        ],
      ),
      _FilterGroup(
        title: 'Loại hình công việc',
        last: true,
        children: [
          for (final o in JobFilterOptions.jobType)
            _CheckboxRow(
              label: o.label,
              checked: filters.jobType.contains(o.value),
              onChanged: () => onToggle(JobFilterKey.jobType, o.value),
            ),
        ],
      ),
    ],
  );
}

/// Phone/tablet (< 1024px): the 7 groups would push results far below the
/// fold, so the stacked sidebar collapses behind a "Bộ lọc" toggle bar.
class CollapsibleFilterSidebar extends StatefulWidget {
  const CollapsibleFilterSidebar({
    super.key,
    required this.sidebar,
    required this.activeCount,
    required this.resultCount,
  });

  final JobFilterSidebar sidebar;
  final int activeCount;
  final int resultCount;

  @override
  State<CollapsibleFilterSidebar> createState() =>
      _CollapsibleFilterSidebarState();
}

class _CollapsibleFilterSidebarState extends State<CollapsibleFilterSidebar> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          child: InkWell(
            onTap: () => setState(() => _open = !_open),
            borderRadius: BorderRadius.circular(AppRadius.x2l),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(AppRadius.x2l),
              ),
              child: Row(
                children: [
                  const Icon(Icons.tune, size: 18, color: AppColors.primary),
                  const SizedBox(width: 8),
                  const Text(
                    'Bộ lọc',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: AppColors.ink,
                    ),
                  ),
                  if (widget.activeCount > 0) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        '${widget.activeCount}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  const Spacer(),
                  Text(
                    '${widget.resultCount} việc làm phù hợp',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.inkMuted,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    _open ? Icons.expand_less : Icons.expand_more,
                    size: 20,
                    color: AppColors.inkMuted,
                  ),
                ],
              ),
            ),
          ),
        ),
        AnimatedSize(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          alignment: Alignment.topCenter,
          child: _open
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: widget.sidebar,
                )
              : const SizedBox(width: double.infinity),
        ),
      ],
    );
  }
}

/// `border-b border-slate-100 py-4 last:border-b-0` + bold title.
class _FilterGroup extends StatelessWidget {
  const _FilterGroup({
    required this.title,
    required this.children,
    this.scrollable = false,
    this.last = false,
  });

  final String title;
  final List<Widget> children;
  final bool scrollable;
  final bool last;

  @override
  Widget build(BuildContext context) {
    final body = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < children.length; i++) ...[
          if (i > 0) const SizedBox(height: 8),
          children[i],
        ],
        if (children.isEmpty)
          const Text(
            'Chưa có dữ liệu',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
      ],
    );
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        border: last
            ? null
            : const Border(bottom: BorderSide(color: AppColors.borderMuted)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (scrollable)
            // `max-h-44 overflow-y-auto`. No explicit Scrollbar: the inner
            // view is not the primary scrollable, so a controller-less
            // Scrollbar would assert on web/desktop; the platform
            // ScrollBehavior already decorates it where scrollbars are shown.
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 176),
              child: SingleChildScrollView(
                primary: false,
                padding: const EdgeInsets.only(right: 4),
                child: body,
              ),
            )
          else
            body,
        ],
      ),
    );
  }
}

/// `flex items-center gap-2.5 text-sm text-ink-soft hover:text-ink` with a
/// 16px checkbox and an optional `(count)` on the right.
class _CheckboxRow extends StatefulWidget {
  const _CheckboxRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    this.count,
  });

  final String label;
  final bool checked;
  final VoidCallback onChanged;
  final int? count;

  @override
  State<_CheckboxRow> createState() => _CheckboxRowState();
}

class _CheckboxRowState extends State<_CheckboxRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onChanged,
        child: Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: Checkbox(
                value: widget.checked,
                onChanged: (_) => widget.onChanged(),
                visualDensity: VisualDensity.compact,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                side: const BorderSide(color: AppColors.slate300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                activeColor: AppColors.primary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 14,
                  color: _hover || widget.checked
                      ? AppColors.ink
                      : AppColors.inkSoft,
                ),
              ),
            ),
            if (widget.count != null) ...[
              const SizedBox(width: 6),
              Text(
                '(${widget.count})',
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
