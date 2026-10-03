import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import 'profile_form_widgets.dart';

/// Skills chips editor (job_seeker_skill rows, source MANUAL).
/// Add: name (1..100) + experienceYears (0..50). Names are unique
/// case-insensitively; blanks are dropped (JobSeekerService semantics).
class SkillsEditor extends StatefulWidget {
  const SkillsEditor({super.key, required this.skills, required this.onChanged});

  final List<ProfileSkill> skills;
  final ValueChanged<List<ProfileSkill>> onChanged;

  @override
  State<SkillsEditor> createState() => _SkillsEditorState();
}

class _SkillsEditorState extends State<SkillsEditor> {
  final _name = TextEditingController();
  final _years = TextEditingController();
  final _nameFocus = FocusNode();
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _years.dispose();
    _nameFocus.dispose();
    super.dispose();
  }

  void _add() {
    final name = _name.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Tên kỹ năng là bắt buộc.');
      return;
    }
    if (name.length > 100) {
      setState(() => _error = 'Tên kỹ năng tối đa 100 ký tự.');
      return;
    }
    final yearsText = _years.text.trim().replaceAll(',', '.');
    final years = yearsText.isEmpty ? 0.0 : double.tryParse(yearsText);
    if (years == null || years < 0 || years > 50) {
      setState(() => _error = 'Số năm kinh nghiệm phải từ 0 đến 50.');
      return;
    }
    final exists = widget.skills.any(
      (s) => s.skillName.toLowerCase() == name.toLowerCase(),
    );
    if (exists) {
      setState(() => _error = 'Kỹ năng này đã có trong danh sách.');
      return;
    }
    widget.onChanged([
      ...widget.skills,
      ProfileSkill(
        skillName: name,
        experienceYears: years,
        source: SkillSource.manual,
      ),
    ]);
    setState(() {
      _error = null;
      _name.clear();
      _years.clear();
    });
    _nameFocus.requestFocus();
  }

  void _remove(ProfileSkill s) {
    widget.onChanged([...widget.skills]..remove(s));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.skills.isEmpty)
          const Text('Chưa có kỹ năng nào. Thêm kỹ năng để tăng độ phù hợp khi AI chấm điểm.',
              style: TextStyle(fontSize: 13, color: AppColors.inkMuted, height: 1.5))
        else
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in widget.skills)
                InputChip(
                  label: Text(_label(s)),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                  backgroundColor: AppColors.primary50,
                  deleteIconColor: AppColors.primary,
                  onDeleted: () => _remove(s),
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
            ],
          ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, c) {
            final nameField = FieldLabel(
              label: 'Tên kỹ năng',
              child: TextField(
                controller: _name,
                focusNode: _nameFocus,
                textInputAction: TextInputAction.next,
                onSubmitted: (_) => _add(),
                onChanged: (_) {
                  if (_error != null) setState(() => _error = null);
                },
                decoration: const InputDecoration(hintText: 'VD: Java, ReactJS, Excel'),
              ),
            );
            final yearsField = FieldLabel(
              label: 'Số năm kinh nghiệm',
              child: TextField(
                controller: _years,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
                onSubmitted: (_) => _add(),
                decoration: const InputDecoration(hintText: '0'),
              ),
            );
            final addBtn = OutlinedButton.icon(
              onPressed: _add,
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Thêm kỹ năng'),
            );
            if (c.maxWidth < 560) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  nameField,
                  const SizedBox(height: 12),
                  yearsField,
                  const SizedBox(height: 12),
                  addBtn,
                ],
              );
            }
            return Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Expanded(flex: 3, child: nameField),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: yearsField),
                const SizedBox(width: 12),
                addBtn,
              ],
            );
          },
        ),
        if (_error != null) ...[
          const SizedBox(height: 8),
          Text(_error!, style: const TextStyle(fontSize: 12, color: AppColors.red600)),
        ],
      ],
    );
  }

  static String _label(ProfileSkill s) {
    final y = s.experienceYears;
    if (y <= 0) return s.skillName;
    final yt = y == y.roundToDouble() ? y.toInt().toString() : y.toStringAsFixed(1);
    return '${s.skillName} · $yt năm';
  }
}
