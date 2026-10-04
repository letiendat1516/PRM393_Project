import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/widgets/app_icons.dart';
import '../viewmodels/resumes_viewmodel.dart';
import 'analysis_panel.dart';
import 'profile_form_widgets.dart';

/// ResumePage `<article class="card overflow-hidden">` — CV row with the
/// action cluster and the analysis strip (loading / error / done).
class ResumeCard extends StatelessWidget {
  const ResumeCard({
    super.key,
    required this.resume,
    required this.run,
    this.onDownload,
    this.onExtract,
    this.onSetPrimary,
    this.onDelete,
    this.onPasteText,
    this.onOpenDetail,
  });

  final ResumeModel resume;
  final AnalysisRunState run;
  final VoidCallback? onDownload;
  final VoidCallback? onExtract;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;
  final VoidCallback? onPasteText;
  final VoidCallback? onOpenDetail;

  bool get _hasText => (resume.rawText ?? '').trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final analysis = resume.aiAnalysis;
    final meta = [
      resume.fileName,
      if (resume.uploadDate != null) Formatters.localeDateTime(resume.uploadDate!),
    ].join(' · ');

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        border: Border.all(color: AppColors.borderMuted),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(
              builder: (context, c) {
                final left = _TitleBlock(
                  resume: resume,
                  meta: meta,
                  analyzed: analysis != null,
                );
                final actions = _Actions(
                  resume: resume,
                  run: run,
                  hasText: _hasText,
                  onDownload: onDownload,
                  onExtract: onExtract,
                  onSetPrimary: onSetPrimary,
                  onDelete: onDelete,
                  onPasteText: onPasteText,
                );
                if (c.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [left, const SizedBox(height: 14), actions],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Expanded(child: left),
                    const SizedBox(width: 16),
                    Flexible(child: actions),
                  ],
                );
              },
            ),
          ),
          if (!_hasText && resume.downloadUrl == null && !run.loading && run.error == null)
            _Strip(
              bg: AppColors.amber50,
              child: Row(
                children: [
                  const Icon(Icons.info_outline, size: 14, color: AppColors.amber700),
                  const SizedBox(width: 6),
                  const Expanded(
                    child: Text(
                      'Chưa đọc được nội dung CV (file ảnh/scan). Dán nội dung để AI chấm điểm.',
                      style: TextStyle(fontSize: 12, color: AppColors.amber700),
                    ),
                  ),
                  if (onPasteText != null)
                    TextButton(
                      onPressed: onPasteText,
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.amber700,
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        minimumSize: Size.zero,
                        textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                      child: const Text('Dán nội dung CV'),
                    ),
                ],
              ),
            ),
          if (run.error != null)
            _Strip(
              bg: AppColors.red50,
              child: Text('⚠ ${run.error}',
                  style: const TextStyle(fontSize: 12, color: AppColors.red600)),
            )
          else if (run.loading)
            _Strip(
              bg: AppColors.primary50,
              child: const Row(
                children: [
                  MiniSpinner(size: 12),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'AI đang đọc & phân tích CV — có thể mất 30–90 giây...',
                      style: TextStyle(fontSize: 12, color: AppColors.primary),
                    ),
                  ),
                ],
              ),
            )
          else if (analysis != null)
            AnalysisPanel(data: analysis, onOpenDetail: onOpenDetail),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.resume, required this.meta, required this.analyzed});
  final ResumeModel resume;
  final String meta;
  final bool analyzed;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(AppIcons.of('fileText'), size: 22, color: AppColors.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 12,
            runSpacing: 6,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    resume.title.isNotEmpty ? resume.title : resume.fileName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.ink, fontSize: 15),
                  ),
                  Text(meta,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ],
              ),
              if (resume.isPrimary)
                const Pill(
                    label: 'CV chính', bg: AppColors.primary50, fg: AppColors.primary),
              if (analyzed)
                Pill(
                  label: 'Đã trích xuất',
                  bg: AppColors.emerald50,
                  fg: AppColors.emerald700,
                  icon: AppIcons.of('check'),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions({
    required this.resume,
    required this.run,
    required this.hasText,
    this.onDownload,
    this.onExtract,
    this.onSetPrimary,
    this.onDelete,
    this.onPasteText,
  });

  final ResumeModel resume;
  final AnalysisRunState run;
  final bool hasText;
  final VoidCallback? onDownload;
  final VoidCallback? onExtract;
  final VoidCallback? onSetPrimary;
  final VoidCallback? onDelete;
  final VoidCallback? onPasteText;

  @override
  Widget build(BuildContext context) {
    final analyzed = resume.aiAnalysis != null;
    final canDownload = resume.downloadUrl != null && resume.downloadUrl!.isNotEmpty;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SmallSecondaryButton(
          label: 'Tải xuống',
          onPressed: canDownload ? onDownload : null,
          tooltip: canDownload ? null : 'Tệp chưa được lưu trữ',
        ),
        SmallSecondaryButton(
          label: run.loading
              ? 'Đang trích xuất...'
              : (analyzed ? 'Trích xuất lại' : 'Trích xuất CV'),
          foreground: AppColors.primary,
          icon: run.loading
              ? const MiniSpinner(size: 14)
              : Icon(AppIcons.of('sparkles'), size: 15, color: AppColors.primary),
          onPressed: run.loading ? null : onExtract,
        ),
        if (!hasText && onPasteText != null)
          SmallSecondaryButton(
            label: 'Dán nội dung CV',
            icon: const Icon(Icons.content_paste_outlined, size: 15),
            onPressed: onPasteText,
          ),
        if (!resume.isPrimary)
          SmallSecondaryButton(label: 'Đặt làm CV chính', onPressed: onSetPrimary),
        TextButton(
          onPressed: onDelete,
          style: TextButton.styleFrom(
            foregroundColor: AppColors.red600,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            minimumSize: const Size(0, 36),
            textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
          child: const Text('Xóa'),
        ),
      ],
    );
  }
}

/// `border-t border-slate-100 px-5 py-3` tinted strip.
class _Strip extends StatelessWidget {
  const _Strip({required this.bg, required this.child});
  final Color bg;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          border: const Border(top: BorderSide(color: AppColors.borderMuted)),
        ),
        child: child,
      );
}
