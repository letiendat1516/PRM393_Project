import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/catalog_models.dart';
import '../viewmodels/employer_providers.dart';

/// "Kỹ năng yêu cầu": selected chips, search box (Enter / comma adds a new
/// tag), scrollable catalog list with checkboxes, counter hint.
class SkillsInput extends ConsumerStatefulWidget {
  const SkillsInput({
    super.key,
    required this.selected,
    required this.maxSkills,
    required this.onToggle,
    required this.onAdd,
    required this.onRemove,
    this.error,
  });

  final List<String> selected;
  final int maxSkills;
  final void Function(String name) onToggle;
  /// Returns false when the cap prevented the add.
  final bool Function(String name) onAdd;
  final void Function(String name) onRemove;
  final String? error;

  @override
  ConsumerState<SkillsInput> createState() => _SkillsInputState();
}

class _SkillsInputState extends ConsumerState<SkillsInput> {
  final _search = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _search.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _isSelected(String name) =>
      widget.selected.any((s) => s.toLowerCase() == name.toLowerCase());

  void _addCustom(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return;
    if (widget.onAdd(name)) {
      _search.clear();
      setState(() {});
      _focus.requestFocus();
    }
  }

  void _onChanged(String v) {
    // Comma-separated input: "React, Node" → add each token.
    if (v.contains(',')) {
      final parts = v.split(',');
      for (final p in parts.sublist(0, parts.length - 1)) {
        if (p.trim().isNotEmpty) widget.onAdd(p.trim());
      }
      _search
        ..text = parts.last.trimLeft()
        ..selection = TextSelection.collapsed(offset: _search.text.length);
    }
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final skills = ref.watch(jobSkillsProvider);
    final loading = skills.isLoading;
    final options = skills.valueOrNull ?? const <SkillModel>[];
    final keyword = _search.text.trim().toLowerCase();
    final filtered = options
        .where((s) => s.skillName.isNotEmpty && s.skillName.toLowerCase().contains(keyword))
        .take(30)
        .toList();
    final inOptions = options.any((s) => s.skillName.toLowerCase() == keyword);
    final candidate = keyword.isEmpty || inOptions || _isSelected(_search.text.trim())
        ? null
        : _search.text.trim();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in widget.selected)
                Container(
                  padding: const EdgeInsets.fromLTRB(12, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: AppColors.primary50,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(s,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.primary)),
                      const SizedBox(width: 4),
                      InkWell(
                        onTap: () => widget.onRemove(s),
                        borderRadius: BorderRadius.circular(999),
                        child: Tooltip(
                          message: 'Bỏ kỹ năng $s',
                          child: const Padding(
                            padding: EdgeInsets.all(2),
                            child: Icon(Icons.close, size: 14, color: AppColors.primary400),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
        ],
        TextField(
          controller: _search,
          focusNode: _focus,
          onChanged: _onChanged,
          onSubmitted: (v) {
            if (candidate != null) {
              _addCustom(candidate);
            } else if (filtered.length == 1 && !_isSelected(filtered.first.skillName)) {
              widget.onToggle(filtered.first.skillName);
              _search.clear();
              setState(() {});
              _focus.requestFocus();
            }
          },
          textInputAction: TextInputAction.done,
          decoration: InputDecoration(
            hintText: 'Tìm kỹ năng, hoặc gõ kỹ năng mới rồi Enter để thêm',
            prefixIcon: const Icon(Icons.search, size: 18),
            suffixIcon: _search.text.isEmpty
                ? null
                : IconButton(
                    tooltip: 'Xoá',
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      _search.clear();
                      setState(() {});
                    },
                  ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 224),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          clipBehavior: Clip.antiAlias,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('Đang tải kỹ năng...',
                      style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  children: [
                    if (candidate != null)
                      InkWell(
                        onTap: () => _addCustom(candidate),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: const BoxDecoration(
                            color: AppColors.amber50,
                            border: Border(bottom: BorderSide(color: AppColors.amber200)),
                          ),
                          child: Row(
                            children: [
                              const Text('＋',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.amber700,
                                      fontSize: 16)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text.rich(
                                  TextSpan(
                                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                    children: [
                                      const TextSpan(text: 'Thêm '),
                                      TextSpan(
                                          text: '"$candidate"',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.w700, color: AppColors.ink)),
                                      const TextSpan(text: ' (kỹ năng khác)'),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (filtered.isEmpty && candidate == null)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('Không tìm thấy kỹ năng phù hợp.',
                            style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                      ),
                    for (var i = 0; i < filtered.length; i++)
                      InkWell(
                        onTap: () => widget.onToggle(filtered[i].skillName),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            border: i == filtered.length - 1
                                ? null
                                : const Border(bottom: BorderSide(color: AppColors.borderMuted)),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: _isSelected(filtered[i].skillName),
                                onChanged: (_) => widget.onToggle(filtered[i].skillName),
                                visualDensity: VisualDensity.compact,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(filtered[i].skillName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.error ??
              'Đã chọn ${widget.selected.length}/${widget.maxSkills} kỹ năng. Nếu không thấy kỹ năng cần, '
                  'gõ tên rồi Enter (hoặc bấm "Thêm") để tự tạo tag khác.',
          style: TextStyle(
            fontSize: 12,
            color: widget.error != null ? AppColors.red600 : AppColors.inkMuted,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
