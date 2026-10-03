import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../../../shared/models/resume_model.dart';

/// 'Dán nội dung CV' — lets the seeker paste the text of a PDF whose bytes
/// could not be stored / read, so the AI extraction has input.
/// Returns the trimmed text or null when cancelled.
Future<String?> showPasteResumeTextDialog(
  BuildContext context, {
  required ResumeModel resume,
}) {
  return showDialog<String>(
    context: context,
    builder: (_) => _PasteResumeTextDialog(resume: resume),
  );
}

class _PasteResumeTextDialog extends StatefulWidget {
  const _PasteResumeTextDialog({required this.resume});
  final ResumeModel resume;

  @override
  State<_PasteResumeTextDialog> createState() => _PasteResumeTextDialogState();
}

class _PasteResumeTextDialogState extends State<_PasteResumeTextDialog> {
  late final TextEditingController _ctrl =
      TextEditingController(text: widget.resume.rawText ?? '');
  String? _error;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _submit() {
    final err = Validators.resumeText(_ctrl.text);
    if (err != null) {
      setState(() => _error = err);
      return;
    }
    Navigator.of(context).pop(_ctrl.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      title: const Text('Dán nội dung CV'),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 560),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tệp "${widget.resume.fileName}" chưa được lưu trữ nên AI không đọc được '
              'nội dung. Hãy mở CV, sao chép toàn bộ văn bản và dán vào đây.',
              style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.5),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _ctrl,
              minLines: 8,
              maxLines: 14,
              autofocus: true,
              onChanged: (_) {
                if (_error != null) setState(() => _error = null);
              },
              decoration: InputDecoration(
                hintText: 'Nội dung CV (kinh nghiệm, kỹ năng, học vấn...)',
                errorText: _error,
                alignLabelWithHint: true,
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Hủy'),
        ),
        ElevatedButton(onPressed: _submit, child: const Text('Lưu nội dung')),
      ],
    );
  }
}
