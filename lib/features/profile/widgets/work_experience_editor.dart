import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import 'profile_form_widgets.dart';

/// work_experience rows editor: list + add/edit dialog
/// (companyName*, position*, startDate, endDate, description ≤ 5000).
class WorkExperienceEditor extends StatelessWidget {
  const WorkExperienceEditor({
    super.key,
    required this.items,
    required this.onChanged,
  });

  final List<WorkExperience> items;
  final ValueChanged<List<WorkExperience>> onChanged;

  Future<void> _edit(BuildContext context, {WorkExperience? existing, int? index}) async {
    final result = await showDialog<WorkExperience>(
      context: context,
      builder: (_) => _WorkExperienceDialog(initial: existing),
    );
    if (result == null) return;
    final next = [...items];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    next.sort((a, b) {
      final ad = a.startDate ?? DateTime(1900);
      final bd = b.startDate ?? DateTime(1900);
      return bd.compareTo(ad);
    });
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          const Text('Chưa có kinh nghiệm làm việc.',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted))
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _ExperienceTile(
              item: items[i],
              onEdit: () => _edit(context, existing: items[i], index: i),
              onDelete: () => onChanged([...items]..removeAt(i)),
            ),
          ],
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.centerLeft,
          child: OutlinedButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add, size: 18),
            label: const Text('Thêm kinh nghiệm'),
          ),
        ),
      ],
    );
  }
}

class _ExperienceTile extends StatelessWidget {
  const _ExperienceTile({required this.item, required this.onEdit, required this.onDelete});
  final WorkExperience item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final range = [
      if (item.startDate != null) Formatters.date(item.startDate),
      item.endDate == null ? 'Hiện tại' : Formatters.date(item.endDate),
    ].join(' – ');
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.slate50,
        border: Border.all(color: AppColors.borderMuted),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.work_outline, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.position,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                Text(item.companyName,
                    style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                if (range.isNotEmpty)
                  Text(range,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                if ((item.description ?? '').trim().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(item.description!.trim(),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft, height: 1.5)),
                ],
              ],
            ),
          ),
          IconButton(
            tooltip: 'Sửa',
            onPressed: onEdit,
            icon: const Icon(Icons.edit_outlined, size: 18),
            color: AppColors.inkSoft,
          ),
          IconButton(
            tooltip: 'Xóa',
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18),
            color: AppColors.red600,
          ),
        ],
      ),
    );
  }
}

class _WorkExperienceDialog extends StatefulWidget {
  const _WorkExperienceDialog({this.initial});
  final WorkExperience? initial;

  @override
  State<_WorkExperienceDialog> createState() => _WorkExperienceDialogState();
}

class _WorkExperienceDialogState extends State<_WorkExperienceDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _company = TextEditingController(text: widget.initial?.companyName ?? '');
  late final _position = TextEditingController(text: widget.initial?.position ?? '');
  late final _description =
      TextEditingController(text: widget.initial?.description ?? '');
  late DateTime? _start = widget.initial?.startDate;
  late DateTime? _end = widget.initial?.endDate;
  late bool _current = widget.initial != null && widget.initial!.endDate == null;

  @override
  void dispose() {
    _company.dispose();
    _position.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate(bool isStart) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (isStart ? _start : _end) ?? now,
      firstDate: DateTime(1970),
      lastDate: DateTime(now.year + 1, 12, 31),
      helpText: isStart ? 'Ngày bắt đầu' : 'Ngày kết thúc',
    );
    if (picked == null) return;
    setState(() {
      if (isStart) {
        _start = picked;
      } else {
        _end = picked;
      }
    });
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    if (_start != null && !_current && _end != null && _end!.isBefore(_start!)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Ngày kết thúc phải sau ngày bắt đầu.')),
      );
      return;
    }
    final desc = _description.text.trim();
    Navigator.of(context).pop(WorkExperience(
      experienceId: widget.initial?.experienceId,
      companyName: _company.text.trim(),
      position: _position.text.trim(),
      startDate: _start,
      endDate: _current ? null : _end,
      description: desc.isEmpty ? null : desc,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      title: Text(widget.initial == null ? 'Thêm kinh nghiệm' : 'Sửa kinh nghiệm'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                FieldLabel(
                  label: 'Công ty',
                  required: true,
                  child: TextFormField(
                    controller: _company,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.lengthBetween(v, 1, 255, label: 'Tên công ty'),
                    decoration: const InputDecoration(hintText: 'VD: FPT Software'),
                  ),
                ),
                const SizedBox(height: 12),
                FieldLabel(
                  label: 'Vị trí',
                  required: true,
                  child: TextFormField(
                    controller: _position,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.lengthBetween(v, 1, 255, label: 'Vị trí'),
                    decoration: const InputDecoration(hintText: 'VD: Backend Developer'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FieldLabel(
                        label: 'Ngày bắt đầu',
                        child: _DateButton(value: _start, onTap: () => _pickDate(true)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FieldLabel(
                        label: 'Ngày kết thúc',
                        child: _DateButton(
                          value: _current ? null : _end,
                          placeholder: _current ? 'Hiện tại' : null,
                          onTap: _current ? null : () => _pickDate(false),
                        ),
                      ),
                    ),
                  ],
                ),
                CheckboxListTile(
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  dense: true,
                  value: _current,
                  onChanged: (v) => setState(() => _current = v ?? false),
                  title: const Text('Đang làm việc tại đây', style: TextStyle(fontSize: 13)),
                ),
                FieldLabel(
                  label: 'Mô tả công việc',
                  child: TextFormField(
                    controller: _description,
                    minLines: 3,
                    maxLines: 6,
                    validator: (v) => Validators.maxLength(v, 5000, label: 'Mô tả'),
                    decoration: const InputDecoration(
                      hintText: 'Trách nhiệm chính, thành tựu, công nghệ sử dụng...',
                      alignLabelWithHint: true,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Hủy')),
        ElevatedButton(onPressed: _submit, child: const Text('Lưu')),
      ],
    );
  }
}

class _DateButton extends StatelessWidget {
  const _DateButton({required this.value, required this.onTap, this.placeholder});
  final DateTime? value;
  final VoidCallback? onTap;
  final String? placeholder;

  @override
  Widget build(BuildContext context) {
    final text = value != null ? Formatters.date(value) : (placeholder ?? 'Chọn ngày');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: onTap == null ? AppColors.slate50 : AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(text,
                  style: TextStyle(
                    fontSize: 14,
                    color: value != null ? AppColors.ink : AppColors.inkMuted,
                  )),
            ),
            const Icon(Icons.calendar_today_outlined, size: 16, color: AppColors.inkMuted),
          ],
        ),
      ),
    );
  }
}
