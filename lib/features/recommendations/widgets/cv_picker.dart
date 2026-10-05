import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/pdf_text_extractor.dart';
import '../../../shared/models/resume_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../viewmodels/ai_matching_viewmodel.dart';
import '../viewmodels/sessions_provider.dart';

/// AIScoreModal "CV SELECTION" step: mode toggle, preset radio cards or the
/// upload/paste area, plus the scoring-method selector.
class CvPicker extends ConsumerStatefulWidget {
  const CvPicker({super.key});

  @override
  ConsumerState<CvPicker> createState() => _CvPickerState();
}

class _CvPickerState extends ConsumerState<CvPicker> {
  final _textCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _textCtrl.text = ref.read(aiMatchingViewModelProvider).uploadedText;
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  AiMatchingViewModel get _vm => ref.read(aiMatchingViewModelProvider.notifier);

  /// AIScoreModal.handleFileChange: accept .txt/.pdf/.doc/.docx, extract PDF
  /// text client-side (page loop), read anything else as text, cap at 8000.
  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['txt', 'pdf', 'doc', 'docx'],
      withData: true,
    );
    final file = result?.files.firstOrNull;
    if (file == null || !mounted) return;
    final name = file.name;
    // setFileName(file.name); setError(null);
    _vm.setFileName(name);

    try {
      final bytes = file.bytes;
      if (bytes == null) throw Exception('Không đọc được dữ liệu file');
      String text;
      if (name.toLowerCase().endsWith('.pdf')) {
        text = await compute(extractPdfText, bytes);
      } else {
        // .txt / .doc — read as text (`file.text()`)
        text = utf8.decode(bytes, allowMalformed: true);
      }
      if (!mounted) return;
      if (text.trim().isEmpty) {
        _vm.setError('Không thể trích xuất text từ file. Hãy thử file khác (.pdf, .txt).');
        return;
      }
      final capped = text.length > AppConfig.aiResumeTextCap
          ? text.substring(0, AppConfig.aiResumeTextCap)
          : text;
      _textCtrl.text = capped;
      _vm.setUploadedText(capped, fileName: name);
    } catch (e) {
      if (!mounted) return;
      // `Lỗi đọc file: ${err.message}. …` — err.message only (no 'Exception:' prefix).
      final msg = e is Failure
          ? e.message
          : e.toString().replaceFirst(RegExp(r'^[A-Za-z_]*(Exception|Error):\s*'), '');
      _vm.setError('Lỗi đọc file: $msg. Hãy thử file PDF hoặc TXT khác.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiMatchingViewModelProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Mode toggle
        Row(
          children: [
            Expanded(
              child: _ToggleButton(
                label: 'CV đã trích xuất',
                selected: state.mode == CvMode.preset,
                onTap: () => _vm.setMode(CvMode.preset),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _ToggleButton(
                label: 'Tải lên CV mới',
                selected: state.mode == CvMode.upload,
                onTap: () => _vm.setMode(CvMode.upload),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (state.mode == CvMode.preset) _presetSection(state) else _uploadSection(state),
      ],
    );
  }

  // ── Preset CVs ───────────────────────────────────────────────────────
  Widget _presetSection(AiMatchingState state) {
    final me = ref.watch(currentUserProvider).valueOrNull;
    if (me == null) {
      return _DashedNote(
        title: 'Vui lòng đăng nhập để dùng CV đã trích xuất.',
        child: Text.rich(TextSpan(children: [
          const TextSpan(text: 'Bạn có thể '),
          _link(context, 'đăng nhập', () => context.go(AppRoutes.login)),
          const TextSpan(text: ' hoặc chọn '),
          const TextSpan(text: 'Tải lên CV mới', style: TextStyle(fontWeight: FontWeight.w600)),
          const TextSpan(text: ' để dán nội dung CV và chấm điểm.'),
        ])),
      );
    }
    if (!me.isJobSeeker) {
      return _DashedNote(
        title: 'Chỉ tài khoản ứng viên mới có CV đã trích xuất.',
        child: const Text('Chọn "Tải lên CV mới" để dán nội dung CV cần chấm điểm.'),
      );
    }
    final resumes = ref.watch(analyzedResumesProvider);
    return resumes.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2)),
            SizedBox(width: 8),
            Text('Đang tải CV đã trích xuất...',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
          ],
        ),
      ),
      error: (e, _) => _DashedNote(
        title: 'Không tải được danh sách CV.',
        child: Text('$e', maxLines: 2, overflow: TextOverflow.ellipsis),
      ),
      data: (list) {
        if (list.isEmpty) {
          return _DashedNote(
            title: 'Bạn chưa trích xuất CV nào.',
            child: Text.rich(TextSpan(children: [
              const TextSpan(text: 'Vào '),
              _link(context, 'Hồ sơ & CV', () => context.go(AppRoutes.resumeProfile)),
              const TextSpan(text: ' → bấm '),
              const TextSpan(text: '✦ Trích xuất CV', style: TextStyle(fontWeight: FontWeight.w600)),
              const TextSpan(text: ' để AI phân tích CV của bạn.'),
            ])),
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'CV CỦA TÔI (ĐÃ TRÍCH XUẤT)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMuted,
                letterSpacing: 0.6,
              ),
            ),
            const SizedBox(height: 8),
            RadioGroup<String>(
              groupValue: state.selectedResumeId,
              onChanged: (v) => _vm.selectResume(v),
              child: Column(
                children: [
                  for (final r in list) ...[
                    _ResumeCard(
                      resume: r,
                      selected: state.selectedResumeId == r.resumeId,
                      onTap: () => _vm.selectResume(r.resumeId),
                    ),
                    const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Upload / paste ───────────────────────────────────────────────────
  Widget _uploadSection(AiMatchingState state) {
    final hasFile = state.fileName != null && state.fileName!.isNotEmpty;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: state.loading ? null : _pickFile,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          child: Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.slate300, width: 2),
            ),
            child: Column(
              children: hasFile
                  ? [
                      const Icon(Icons.description_outlined, size: 32, color: AppColors.primary),
                      const SizedBox(height: 8),
                      Text(state.fileName!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      Text('${state.uploadedText.length} ký tự',
                          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                    ]
                  : const [
                      Icon(Icons.upload_file_outlined, size: 32, color: AppColors.inkMuted),
                      SizedBox(height: 8),
                      Text('Tải lên CV (.txt, .pdf)',
                          style: TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.ink)),
                      SizedBox(height: 2),
                      Text('CV sẽ được AI trích xuất tự động trước khi chấm điểm',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                    ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        const Text('Hoặc dán nội dung CV',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.ink)),
        const SizedBox(height: 6),
        TextField(
          controller: _textCtrl,
          enabled: !state.loading,
          minLines: 5,
          maxLines: 10,
          maxLength: AppConfig.aiResumeTextCap,
          onChanged: (v) => _vm.setUploadedText(v, keepFileName: true),
          style: const TextStyle(fontSize: 13, height: 1.5),
          decoration: const InputDecoration(
            hintText: 'Dán nội dung CV của bạn vào đây (tối đa 8000 ký tự)...',
            alignLabelWithHint: true,
          ),
        ),
      ],
    );
  }

  /// Inline link inside a Text.rich (WidgetSpan avoids recognizer disposal).
  InlineSpan _link(BuildContext context, String text, VoidCallback onTap) => WidgetSpan(
        alignment: PlaceholderAlignment.baseline,
        baseline: TextBaseline.alphabetic,
        child: InkWell(
          onTap: onTap,
          child: Text(
            text,
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary, height: 1.5),
          ),
        ),
      );
}

/// `flex-1 rounded-xl border px-4 py-2.5 text-sm font-medium` toggle.
class _ToggleButton extends StatelessWidget {
  const _ToggleButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: selected ? AppColors.primary : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }
}

/// Radio card for one analysed resume: title + 'Của tôi' badge, first 5
/// skills (+N) and 'N năm KN'.
class _ResumeCard extends StatelessWidget {
  const _ResumeCard({required this.resume, required this.selected, required this.onTap});

  final ResumeModel resume;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final a = resume.aiAnalysis;
    final skills = a?.skills ?? const <String>[];
    final years = a?.totalExperienceYears ?? 0;
    final yearsLabel = years == years.roundToDouble() ? years.toInt().toString() : years.toString();
    final shown = skills.take(5).join(', ');
    final extra = skills.length > 5 ? ' +${skills.length - 5}' : '';
    final name = resume.title.isNotEmpty ? resume.title : resume.fileName;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary50 : AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: selected ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            Radio<String>(value: resume.resumeId),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: const Text('Của tôi',
                            style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: AppColors.emerald700)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${shown.isEmpty ? 'Chưa có kỹ năng' : shown}$extra · $yearsLabel năm KN',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `rounded-xl border border-dashed border-slate-300 px-4 py-3 text-xs`.
class _DashedNote extends StatelessWidget {
  const _DashedNote({required this.title, required this.child});
  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.slate300),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.5),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.ink)),
            const SizedBox(height: 2),
            child,
          ],
        ),
      ),
    );
  }
}
