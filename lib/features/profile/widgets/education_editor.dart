import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import 'profile_form_widgets.dart';

/// education rows editor: list + add/edit dialog
/// (schoolName* 1..255, degree ≤100, major ≤255, startYear/endYear 1900..9999).
class EducationEditor extends StatelessWidget {
  const EducationEditor({super.key, required this.items, required this.onChanged});

  final List<Education> items;
  final ValueChanged<List<Education>> onChanged;

  Future<void> _edit(BuildContext context, {Education? existing, int? index}) async {
    final result = await showDialog<Education>(
      context: context,
      builder: (_) => _EducationDialog(initial: existing),
    );
    if (result == null) return;
    final next = [...items];
    if (index == null) {
      next.add(result);
    } else {
      next[index] = result;
    }
    next.sort((a, b) => (b.startYear ?? 0).compareTo(a.startYear ?? 0));
    onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (items.isEmpty)
          const Text('Chưa có thông tin học vấn.',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted))
        else
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) const SizedBox(height: 10),
            _EducationTile(
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
            label: const Text('Thêm học vấn'),
          ),
        ),
      ],
    );
  }
}

class _EducationTile extends StatelessWidget {
  const _EducationTile({required this.item, required this.onEdit, required this.onDelete});
  final Education item;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final degreeMajor = [
      if ((item.degree ?? '').trim().isNotEmpty) item.degree!.trim(),
      if ((item.major ?? '').trim().isNotEmpty) item.major!.trim(),
    ].join(' · ');
    final years = [
      if (item.startYear != null) '${item.startYear}',
      if (item.endYear != null) '${item.endYear}',
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
            child: Icon(Icons.school_outlined, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.schoolName,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (degreeMajor.isNotEmpty)
                  Text(degreeMajor,
                      style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                if (years.isNotEmpty)
                  Text(years, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
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

class _EducationDialog extends StatefulWidget {
  const _EducationDialog({this.initial});
  final Education? initial;

  @override
  State<_EducationDialog> createState() => _EducationDialogState();
}

class _EducationDialogState extends State<_EducationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final _school = TextEditingController(text: widget.initial?.schoolName ?? '');
  late final _degree = TextEditingController(text: widget.initial?.degree ?? '');
  late final _major = TextEditingController(text: widget.initial?.major ?? '');
  late final _startYear =
      TextEditingController(text: widget.initial?.startYear?.toString() ?? '');
  late final _endYear =
      TextEditingController(text: widget.initial?.endYear?.toString() ?? '');

  @override
  void dispose() {
    _school.dispose();
    _degree.dispose();
    _major.dispose();
    _startYear.dispose();
    _endYear.dispose();
    super.dispose();
  }

  static String? _year(String? v) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    final n = int.tryParse(s);
    if (n == null || n < 1900 || n > 9999) return 'Năm phải từ 1900 đến 9999.';
    return null;
  }

  static String? _optionalMax(String? v, int max, String label) {
    final s = (v ?? '').trim();
    if (s.isEmpty) return null;
    return Validators.maxLength(s, max, label: label);
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final start = int.tryParse(_startYear.text.trim());
    final end = int.tryParse(_endYear.text.trim());
    if (start != null && end != null && end < start) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Năm kết thúc phải sau năm bắt đầu.')),
      );
      return;
    }
    String? opt(TextEditingController c) {
      final s = c.text.trim();
      return s.isEmpty ? null : s;
    }

    Navigator.of(context).pop(Education(
      educationId: widget.initial?.educationId,
      schoolName: _school.text.trim(),
      degree: opt(_degree),
      major: opt(_major),
      startYear: start,
      endYear: end,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final yearFormatters = [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(4),
    ];
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      title: Text(widget.initial == null ? 'Thêm học vấn' : 'Sửa học vấn'),
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
                  label: 'Trường',
                  required: true,
                  child: TextFormField(
                    controller: _school,
                    textInputAction: TextInputAction.next,
                    validator: (v) => Validators.lengthBetween(v, 1, 255, label: 'Tên trường'),
                    decoration: const InputDecoration(hintText: 'VD: Đại học FPT'),
                  ),
                ),
                const SizedBox(height: 12),
                FieldLabel(
                  label: 'Bằng cấp',
                  child: TextFormField(
                    controller: _degree,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _optionalMax(v, 100, 'Bằng cấp'),
                    decoration: const InputDecoration(hintText: 'VD: Cử nhân, Kỹ sư, Thạc sĩ'),
                  ),
                ),
                const SizedBox(height: 12),
                FieldLabel(
                  label: 'Chuyên ngành',
                  child: TextFormField(
                    controller: _major,
                    textInputAction: TextInputAction.next,
                    validator: (v) => _optionalMax(v, 255, 'Chuyên ngành'),
                    decoration: const InputDecoration(hintText: 'VD: Kỹ thuật phần mềm'),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: FieldLabel(
                        label: 'Năm bắt đầu',
                        child: TextFormField(
                          controller: _startYear,
                          keyboardType: TextInputType.number,
                          inputFormatters: yearFormatters,
                          validator: _year,
                          decoration: const InputDecoration(hintText: '2019'),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: FieldLabel(
                        label: 'Năm kết thúc',
                        child: TextFormField(
                          controller: _endYear,
                          keyboardType: TextInputType.number,
                          inputFormatters: yearFormatters,
                          validator: _year,
                          decoration: const InputDecoration(hintText: '2023'),
                        ),
                      ),
                    ),
                  ],
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
