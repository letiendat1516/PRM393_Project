import 'package:flutter/material.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/jobs_search_viewmodel.dart';

/// JobsPage `<header>`: white banner with breadcrumb, "Tìm việc làm" + count,
/// search-type pills and the keyword + province search card.
class JobsSearchHeader extends StatelessWidget {
  const JobsSearchHeader({
    super.key,
    required this.state,
    required this.keywordController,
    required this.onKeywordChanged,
    required this.onLocationChanged,
    required this.onSearchTypeChanged,
    required this.onSubmit,
    required this.onHome,
  });

  final JobsSearchState state;
  final TextEditingController keywordController;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String> onLocationChanged;
  final ValueChanged<JobSearchType> onSearchTypeChanged;
  final VoidCallback onSubmit;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sm = width >= 640;
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.borderMuted)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: PageContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Breadcrumb(items: [('Trang chủ', onHome), ('Việc làm', null)]),
            const SizedBox(height: 12),
            Text.rich(
              TextSpan(
                text: 'Tìm việc làm',
                style: TextStyle(
                  fontSize: sm ? 30 : 24,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
                children: [
                  TextSpan(
                    text: state.displayTotal != null
                        ? '  ${Formatters.number(state.displayTotal!)} việc làm'
                        : state.countFailed
                            ? '  — việc làm'
                            : '  đang đếm… việc làm',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: AppColors.inkMuted,
                      letterSpacing: 0,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Search type pills
            Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 4,
              runSpacing: 4,
              children: [
                const Padding(
                  padding: EdgeInsets.only(right: 4),
                  child: Text(
                    'Tìm kiếm theo:',
                    style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ),
                for (final t in JobSearchType.values)
                  _Pill(
                    label: t.label,
                    active: state.searchType == t,
                    onTap: () => onSearchTypeChanged(t),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            _SearchCard(
              sm: sm,
              keywordController: keywordController,
              location: state.locationQuery,
              onKeywordChanged: onKeywordChanged,
              onLocationChanged: onLocationChanged,
              onSubmit: onSubmit,
            ),
          ],
        ),
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.active, required this.onTap});
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.pill),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 3),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : AppColors.slate100,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: active ? Colors.white : AppColors.inkMuted,
            fontWeight: active ? FontWeight.w600 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

/// `rounded-2xl border border-slate-200 bg-white p-2` with keyword input,
/// divider, province select and the primary 'Tìm kiếm' button.
class _SearchCard extends StatelessWidget {
  const _SearchCard({
    required this.sm,
    required this.keywordController,
    required this.location,
    required this.onKeywordChanged,
    required this.onLocationChanged,
    required this.onSubmit,
  });

  final bool sm;
  final TextEditingController keywordController;
  final String location;
  final ValueChanged<String> onKeywordChanged;
  final ValueChanged<String> onLocationChanged;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final keywordField = _FieldGroup(
      icon: Icons.search,
      child: TextField(
        controller: keywordController,
        onChanged: onKeywordChanged,
        onSubmitted: (_) => onSubmit(),
        textInputAction: TextInputAction.search,
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        decoration: const InputDecoration(
          isDense: true,
          hintText: 'Vị trí, kỹ năng, công ty...',
          hintStyle: TextStyle(color: AppColors.inkMuted, fontSize: 14),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          filled: false,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );

    final provinces = DemoData.provinces;
    final value = provinces.contains(location) ? location : '';
    final locationField = _FieldGroup(
      icon: Icons.place_outlined,
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          icon: const Icon(
            Icons.expand_more,
            size: 18,
            color: AppColors.inkMuted,
          ),
          items: [
            const DropdownMenuItem(value: '', child: Text('Tất cả địa điểm')),
            for (final p in provinces)
              DropdownMenuItem(value: p, child: Text(p)),
          ],
          onChanged: (v) => onLocationChanged(v ?? ''),
        ),
      ),
    );

    final button = ElevatedButton.icon(
      onPressed: onSubmit,
      icon: const Icon(Icons.search, size: 18),
      label: const Text('Tìm kiếm'),
      style: ElevatedButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: sm ? 28 : 20, vertical: 14),
      ),
    );

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: sm
          ? Row(
              children: [
                Expanded(child: keywordField),
                Container(width: 1, height: 28, color: AppColors.border),
                Expanded(child: locationField),
                const SizedBox(width: 8),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                keywordField,
                const SizedBox(height: 8),
                locationField,
                const SizedBox(height: 8),
                button,
              ],
            ),
    );
  }
}

/// `flex flex-1 items-center gap-3 rounded-xl px-4 py-2.5 hover:bg-slate-50`.
class _FieldGroup extends StatefulWidget {
  const _FieldGroup({required this.icon, required this.child});
  final IconData icon;
  final Widget child;

  @override
  State<_FieldGroup> createState() => _FieldGroupState();
}

class _FieldGroupState extends State<_FieldGroup> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: _hover ? AppColors.slate50 : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Icon(widget.icon, size: 20, color: AppColors.inkMuted),
            const SizedBox(width: 12),
            Expanded(child: widget.child),
          ],
        ),
      ),
    );
  }
}
