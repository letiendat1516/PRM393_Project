import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_icons.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/resumes_viewmodel.dart';
import 'profile_form_widgets.dart';

/// ResumePage SECTION 2 — CV upload form card
/// (`card grid gap-4 p-6 md:grid-cols-[1fr_1fr_auto]`).
class ResumeUploadCard extends ConsumerStatefulWidget {
  const ResumeUploadCard({super.key});

  @override
  ConsumerState<ResumeUploadCard> createState() => _ResumeUploadCardState();
}

class _ResumeUploadCardState extends ConsumerState<ResumeUploadCard> {
  final _title = TextEditingController();
  PickedResumeFile? _file;
  String? _pickError;

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  Future<void> _pick() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['pdf', 'txt'],
      withData: true,
      allowMultiple: false,
    );
    // The OS picker may outlive this widget (user navigated away).
    if (!mounted) return;
    if (result == null || result.files.isEmpty) return;
    final f = result.files.single;
    final bytes = f.bytes;
    if (bytes == null) {
      setState(() => _pickError = 'Không đọc được tệp đã chọn.');
      return;
    }
    final picked = PickedResumeFile(name: f.name, bytes: bytes, size: f.size);
    setState(() {
      _file = picked;
      _pickError = ResumesViewModel.validateFile(picked);
    });
    ref.read(resumesViewModelProvider.notifier).resetUploadStatus();
  }

  Future<void> _upload() async {
    final created = await ref
        .read(resumesViewModelProvider.notifier)
        .upload(file: _file, title: _title.text);
    if (created != null && mounted) {
      setState(() {
        _file = null;
        _title.clear();
        _pickError = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(resumesViewModelProvider);
    final canUpload = _file != null && _pickError == null && !state.uploading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppCard(
          padding: const EdgeInsets.all(24),
          child: LayoutBuilder(
            builder: (context, c) {
              final wide = c.maxWidth >= 768 - 48;
              final titleField = FieldLabel(
                label: 'Tên CV',
                child: TextField(
                  controller: _title,
                  decoration: const InputDecoration(hintText: 'CV Backend Developer'),
                ),
              );
              final fileField = FieldLabel(
                label: 'Tệp PDF',
                hint: 'PDF hoặc .txt, tối đa 5 MB',
                child: _FilePickerField(
                  file: _file,
                  onPick: state.uploading ? null : _pick,
                ),
              );
              final button = ElevatedButton.icon(
                onPressed: canUpload ? _upload : null,
                icon: state.uploading
                    ? const MiniSpinner(size: 16, color: Colors.white)
                    : Icon(AppIcons.of('upload'), size: 18),
                label: Text(state.uploading ? 'Đang tải...' : 'Tải CV'),
              );

              if (!wide) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleField,
                    const SizedBox(height: 16),
                    fileField,
                    const SizedBox(height: 16),
                    button,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(child: titleField),
                  const SizedBox(width: 16),
                  Expanded(child: fileField),
                  const SizedBox(width: 16),
                  button,
                ],
              );
            },
          ),
        ),
        if (_pickError != null) ...[
          const SizedBox(height: 16),
          StatusBanner(
            tone: BannerTone.error,
            padding: const EdgeInsets.all(16),
            text: _pickError!,
          ),
        ] else if (state.upload == UploadStatus.error && state.uploadError != null) ...[
          const SizedBox(height: 16),
          StatusBanner(
            tone: BannerTone.error,
            padding: const EdgeInsets.all(16),
            text: state.uploadError!,
          ),
        ] else if (state.upload == UploadStatus.success) ...[
          const SizedBox(height: 16),
          const StatusBanner(
            tone: BannerTone.success,
            padding: EdgeInsets.all(16),
            text: ResumesViewModel.uploadSuccess,
          ),
          if (state.storageNotice != null) ...[
            const SizedBox(height: 12),
            StatusBanner(
              tone: BannerTone.warning,
              bordered: true,
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_outlined,
                      size: 18, color: AppColors.amber700),
                  const SizedBox(width: 8),
                  Expanded(child: Text(state.storageNotice!)),
                ],
              ),
            ),
          ],
        ],
      ],
    );
  }
}

/// `<input type="file">` stand-in: bordered box showing the chosen file.
class _FilePickerField extends StatelessWidget {
  const _FilePickerField({required this.file, required this.onPick});
  final PickedResumeFile? file;
  final VoidCallback? onPick;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPick,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border.all(color: AppColors.border),
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.slate100,
                borderRadius: BorderRadius.circular(AppRadius.md),
              ),
              child: const Text('Chọn tệp',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.inkSoft)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                file == null
                    ? 'Chưa chọn tệp nào'
                    : '${file!.name} · ${Formatters.bytes(file!.size)}',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  color: file == null ? AppColors.inkMuted : AppColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
