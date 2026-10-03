import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../data/job_form_input.dart';
import '../viewmodels/create_job_viewmodel.dart';
import 'category_field.dart';
import 'form_helpers.dart';
import 'skills_input.dart';

/// Text controllers owned by the page so they can be re-synced when the
/// input is replaced (draft restore / edit load).
class JobFormControllers {
  JobFormControllers();

  final title = TextEditingController();
  final category = TextEditingController();
  final categoryFocus = FocusNode();
  final moTa = TextEditingController();
  final yeuCau = TextEditingController();
  final quyenLoi = TextEditingController();
  final thoiGian = TextEditingController();
  final salaryMin = TextEditingController();
  final salaryMax = TextEditingController();
  final currency = TextEditingController();
  final location = TextEditingController();
  final city = TextEditingController();
  final cityFocus = FocusNode();
  final positions = TextEditingController();

  void syncFrom(JobFormInput i) {
    _set(title, i.title);
    _set(category, i.categoryName);
    _set(moTa, i.moTaCongViec);
    _set(yeuCau, i.yeuCauUngVien);
    _set(quyenLoi, i.quyenLoi);
    _set(thoiGian, i.thoiGianLamViec);
    _set(salaryMin, i.salaryMin?.toString() ?? '');
    _set(salaryMax, i.salaryMax?.toString() ?? '');
    _set(currency, i.currency);
    _set(location, i.location);
    _set(city, i.city);
    _set(positions, '${i.positions}');
  }

  static void _set(TextEditingController c, String v) {
    if (c.text == v) return;
    c.value = TextEditingValue(text: v, selection: TextSelection.collapsed(offset: v.length));
  }

  void dispose() {
    for (final c in [
      title, category, moTa, yeuCau, quyenLoi, thoiGian, salaryMin, salaryMax, currency, location, city,
      positions,
    ]) {
      c.dispose();
    }
    categoryFocus.dispose();
    cityFocus.dispose();
  }
}

/// Step 1 — Thông tin.
class JobInfoStep extends StatelessWidget {
  const JobInfoStep({super.key, required this.c, required this.state, required this.vm});
  final JobFormControllers c;
  final CreateJobState state;
  final CreateJobViewModel vm;

  @override
  Widget build(BuildContext context) {
    final e = state.fieldErrors;
    return FormCard(
      children: [
        FieldBlock(
          label: 'Tên vị trí tuyển dụng',
          required: true,
          error: e['title'],
          hint: 'Từ 3 đến 150 ký tự.',
          child: TextField(
            controller: c.title,
            maxLength: 150,
            textInputAction: TextInputAction.next,
            onChanged: (v) => vm.update((i) => i.copyWith(title: v)),
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Lập trình viên Frontend',
              counterText: '',
            ),
          ),
        ),
        FieldBlock(
          label: 'Ngành nghề',
          required: true,
          error: e['category'],
          child: CategoryField(
            controller: c.category,
            focusNode: c.categoryFocus,
            selectedId: state.input.categoryId,
            onChanged: (id, name) => vm.update((i) => i.copyWith(categoryId: id, categoryName: name)),
          ),
        ),
        FieldBlock(
          label: 'Mô tả công việc',
          required: true,
          error: e['description'],
          hint: 'Tối thiểu 10 ký tự. Mỗi dòng là một ý — sẽ hiển thị dạng gạch đầu dòng.',
          child: TextField(
            controller: c.moTa,
            minLines: 5,
            maxLines: 12,
            maxLength: 10000,
            onChanged: (v) => vm.update((i) => i.copyWith(moTaCongViec: v)),
            decoration: const InputDecoration(
              hintText: 'Mô tả nhiệm vụ, trách nhiệm và yêu cầu chính của công việc.',
              counterText: '',
              alignLabelWithHint: true,
            ),
          ),
        ),
        FieldBlock(
          label: 'Yêu cầu ứng viên',
          hint: 'Mỗi dòng một yêu cầu (tuỳ chọn).',
          child: TextField(
            controller: c.yeuCau,
            minLines: 3,
            maxLines: 10,
            onChanged: (v) => vm.update((i) => i.copyWith(yeuCauUngVien: v)),
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Tối thiểu 2 năm kinh nghiệm ReactJS\nTiếng Anh đọc hiểu tài liệu',
            ),
          ),
        ),
        FieldBlock(
          label: 'Quyền lợi',
          hint: 'Mỗi dòng một quyền lợi (tuỳ chọn).',
          child: TextField(
            controller: c.quyenLoi,
            minLines: 3,
            maxLines: 10,
            onChanged: (v) => vm.update((i) => i.copyWith(quyenLoi: v)),
            decoration: const InputDecoration(
              hintText: 'Ví dụ: Thưởng tháng 13\nBảo hiểm sức khoẻ cao cấp',
            ),
          ),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Thời gian làm việc',
            child: TextField(
              controller: c.thoiGian,
              onChanged: (v) => vm.update((i) => i.copyWith(thoiGianLamViec: v)),
              decoration: const InputDecoration(hintText: 'Ví dụ: Thứ 2 - Thứ 6, 9:00 - 18:00'),
            ),
          ),
          right: FieldBlock(
            label: 'Yêu cầu bằng cấp',
            child: AppDropdown<String>(
              value: JobFormInput.bangCapOptions.contains(state.input.yeuCauBangCap)
                  ? state.input.yeuCauBangCap
                  : JobFormInput.bangCapOptions.first,
              items: JobFormInput.bangCapOptions,
              labelOf: (s) => s,
              onChanged: (v) => vm.update((i) => i.copyWith(yeuCauBangCap: v)),
            ),
          ),
        ),
      ],
    );
  }
}

/// Step 2 — Lương & địa điểm.
class JobSalaryLocationStep extends StatelessWidget {
  const JobSalaryLocationStep({super.key, required this.c, required this.state, required this.vm});
  final JobFormControllers c;
  final CreateJobState state;
  final CreateJobViewModel vm;

  int? _int(String v) => int.tryParse(v.replaceAll(RegExp(r'[^0-9]'), ''));

  @override
  Widget build(BuildContext context) {
    final e = state.fieldErrors;
    final input = state.input;

    return FormCard(
      children: [
        SwitchListTile.adaptive(
          contentPadding: EdgeInsets.zero,
          value: input.isSalaryNegotiable,
          onChanged: (v) => vm.update((i) => i.copyWith(isSalaryNegotiable: v)),
          title: const Text('Mức lương thoả thuận',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          subtitle: const Text('Ẩn khoảng lương, hiển thị "Thoả thuận" trên tin.',
              style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Lương tối thiểu',
            error: e['salaryMin'],
            hint: input.salaryMin == null
                ? null
                : Formatters.salary(min: input.salaryMin, currency: input.currency),
            child: TextField(
              controller: c.salaryMin,
              enabled: !input.isSalaryNegotiable,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => vm.update((i) => i.copyWith(salaryMin: _int(v))),
              decoration: const InputDecoration(hintText: '10000000'),
            ),
          ),
          right: FieldBlock(
            label: 'Lương tối đa',
            error: e['salaryMax'],
            hint: input.salaryMax == null
                ? null
                : Formatters.salary(max: input.salaryMax, currency: input.currency),
            child: TextField(
              controller: c.salaryMax,
              enabled: !input.isSalaryNegotiable,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => vm.update((i) => i.copyWith(salaryMax: _int(v))),
              decoration: const InputDecoration(hintText: '20000000'),
            ),
          ),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Đơn vị tiền tệ',
            error: e['currency'],
            hint: 'Mã 3 chữ cái, mặc định VND.',
            child: TextField(
              controller: c.currency,
              maxLength: 3,
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp('[A-Za-z]')),
                UpperCaseTextFormatter(),
              ],
              onChanged: (v) => vm.update((i) => i.copyWith(currency: v)),
              decoration: const InputDecoration(hintText: 'VND', counterText: ''),
            ),
          ),
          right: FieldBlock(
            label: 'Kỳ trả lương',
            child: AppDropdown<SalaryPeriod>(
              value: input.salaryPeriod,
              items: SalaryPeriod.values,
              labelOf: (p) => switch (p) {
                SalaryPeriod.hour => 'Theo giờ',
                SalaryPeriod.month => 'Theo tháng',
                SalaryPeriod.year => 'Theo năm',
              },
              onChanged: (v) => vm.update((i) => i.copyWith(salaryPeriod: v)),
            ),
          ),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Địa điểm làm việc',
            required: true,
            error: e['location'],
            child: TextField(
              controller: c.location,
              maxLength: 150,
              onChanged: (v) => vm.update((i) => i.copyWith(location: v)),
              decoration: const InputDecoration(hintText: 'Ví dụ: 120 Yên Lãng', counterText: ''),
            ),
          ),
          right: FieldBlock(
            label: 'Thành phố',
            required: true,
            error: e['city'],
            child: _CityField(
              controller: c.city,
              focusNode: c.cityFocus,
              onChanged: (v) => vm.update((i) => i.copyWith(city: v)),
            ),
          ),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Hình thức làm việc',
            child: AppDropdown<WorkMode>(
              value: input.workMode,
              items: WorkMode.values,
              labelOf: (m) => switch (m) {
                WorkMode.onsite => 'Làm tại văn phòng',
                WorkMode.remote => 'Làm từ xa',
                WorkMode.hybrid => 'Kết hợp',
              },
              onChanged: (v) => vm.update((i) => i.copyWith(workMode: v)),
            ),
          ),
          right: FieldBlock(
            label: 'Loại hình công việc',
            child: AppDropdown<JobType>(
              value: input.jobType,
              items: JobType.values,
              labelOf: (t) => t.label,
              onChanged: (v) => vm.update((i) => i.copyWith(jobType: v)),
            ),
          ),
        ),
        TwoColumn(
          left: FieldBlock(
            label: 'Kinh nghiệm',
            child: AppDropdown<ExperienceLevel>(
              value: input.experienceLevel,
              items: ExperienceLevel.values,
              labelOf: (l) => '${l.label} (${l.jobMapperLabel})',
              onChanged: (v) => vm.update((i) => i.copyWith(experienceLevel: v)),
            ),
          ),
          right: FieldBlock(
            label: 'Số lượng tuyển',
            required: true,
            error: e['positionsAvailable'],
            child: TextField(
              controller: c.positions,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              onChanged: (v) => vm.update((i) => i.copyWith(positions: int.tryParse(v) ?? 0)),
              decoration: const InputDecoration(hintText: '1'),
            ),
          ),
        ),
        FieldBlock(
          // Web: <input required type="date" min={today}>.
          label: 'Hạn nộp hồ sơ',
          required: true,
          error: e['applicationDeadline'],
          child: _DeadlinePicker(
            value: input.deadline,
            // Edit mode never persists a cleared deadline (the patch keeps the
            // existing value), so do not offer a clear button there.
            canClear: !vm.isEditing,
            onChanged: (d) => vm.update((i) => i.copyWith(deadline: d)),
          ),
        ),
      ],
    );
  }
}

/// "Thành phố" — free text (web `<input required placeholder="Hà Nội">`)
/// with DemoData.provinces offered as suggestions; any value is accepted.
class _CityField extends StatelessWidget {
  const _CityField({
    required this.controller,
    required this.focusNode,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return RawAutocomplete<String>(
      textEditingController: controller,
      focusNode: focusNode,
      optionsBuilder: (v) {
        final q = v.text.trim().toLowerCase();
        if (q.isEmpty) return DemoData.provinces.take(12);
        return DemoData.provinces.where((p) => p.toLowerCase().contains(q)).take(12);
      },
      // Programmatic selection does not fire TextField.onChanged.
      onSelected: onChanged,
      fieldViewBuilder: (context, textCtrl, focus, onSubmit) => TextField(
        controller: textCtrl,
        focusNode: focus,
        maxLength: 100,
        textInputAction: TextInputAction.next,
        onChanged: onChanged,
        onSubmitted: (_) => onSubmit(),
        decoration: const InputDecoration(
          hintText: 'Hà Nội',
          counterText: '',
          prefixIcon: Icon(Icons.location_city_outlined, size: 18),
        ),
      ),
      optionsViewBuilder: (context, onSelected, options) => Align(
        alignment: Alignment.topLeft,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 240, maxWidth: 420),
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: options.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final p = options.elementAt(i);
                return ListTile(
                  dense: true,
                  title: Text(p, style: const TextStyle(fontSize: 14)),
                  onTap: () => onSelected(p),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DeadlinePicker extends StatelessWidget {
  const _DeadlinePicker({
    required this.value,
    required this.onChanged,
    this.canClear = true,
  });
  final DateTime? value;
  final ValueChanged<DateTime?> onChanged;
  /// Whether the "Bỏ chọn" clear button is offered (hidden in edit mode).
  final bool canClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.xl),
      onTap: () async {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final picked = await showDatePicker(
          context: context,
          initialDate: value != null && !value!.isBefore(today) ? value! : today.add(const Duration(days: 30)),
          firstDate: today,
          lastDate: today.add(const Duration(days: 365 * 2)),
          helpText: 'Chọn hạn nộp hồ sơ',
          cancelText: 'Huỷ',
          confirmText: 'Chọn',
        );
        if (picked != null) onChanged(DateTime(picked.year, picked.month, picked.day, 23, 59));
      },
      child: InputDecorator(
        decoration: InputDecoration(
          prefixIcon: const Icon(Icons.event_outlined, size: 18),
          suffixIcon: value == null || !canClear
              ? null
              : IconButton(
                  tooltip: 'Bỏ chọn',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: () => onChanged(null),
                ),
        ),
        child: Text(
          value == null ? 'Chọn ngày' : Formatters.deadlineFull(value),
          style: TextStyle(
            fontSize: 14,
            color: value == null ? AppColors.inkMuted : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

/// Step 3 — Kỹ năng & xem trước (preview rendered by the page).
class JobSkillsStep extends StatelessWidget {
  const JobSkillsStep({super.key, required this.state, required this.vm, this.preview});
  final CreateJobState state;
  final CreateJobViewModel vm;
  /// Shown below the skills on narrow layouts (null on wide — side column).
  final Widget? preview;

  @override
  Widget build(BuildContext context) {
    return FormCard(
      children: [
        FieldBlock(
          label: 'Kỹ năng yêu cầu',
          child: SkillsInput(
            selected: state.input.skills,
            maxSkills: state.maxSkills,
            error: state.fieldErrors['skills'],
            onToggle: vm.toggleSkill,
            onAdd: vm.addSkill,
            onRemove: vm.removeSkill,
          ),
        ),
        if (preview != null) ...[
          const Divider(),
          preview!,
        ],
      ],
    );
  }
}

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) =>
      newValue.copyWith(text: newValue.text.toUpperCase());
}

/// Helper used by the page to build the preview job from state.
JobModel buildPreviewJob(CreateJobState s, {
  required String employerId,
  required String employerName,
  String? employerLogoUrl,
  String? employerCity,
}) =>
    s.input.toPreview(
      employerId: employerId,
      employerName: employerName,
      employerLogoUrl: employerLogoUrl,
      employerCity: employerCity,
      requireApproval: s.requireApproval,
    );
