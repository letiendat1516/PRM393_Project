import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/profile_providers.dart';
import '../viewmodels/resumes_viewmodel.dart';
import '../widgets/paste_resume_text_dialog.dart';
import '../widgets/profile_basics_card.dart';
import '../widgets/profile_form_widgets.dart';
import '../widgets/resume_card.dart';
import '../widgets/resume_upload_card.dart';

/// /ho-so — ResumePage.jsx "Hồ sơ & CV": profile form + CV upload + CV list
/// with per-resume AI extraction panels. Job seekers only (router guard).
class ResumeProfilePage extends ConsumerWidget {
  const ResumeProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(jobSeekerProfileProvider);
    final resumes = ref.watch(myResumesProvider);
    final runs = ref.watch(resumesViewModelProvider).runs;

    return PublicLayout(
      child: PageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ────────────────────────────────────────────────
              const Eyebrow(label: 'Ứng viên'),
              const SizedBox(height: 12),
              Text('Hồ sơ & CV',
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontSize: 30,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink,
                        letterSpacing: -0.5,
                      )),
              const SizedBox(height: 8),
              const Text('Quản lý thông tin cá nhân và CV PDF dùng để ứng tuyển.',
                  style: TextStyle(color: AppColors.inkSoft, fontSize: 15, height: 1.6)),

              // ── Section 1: profile ────────────────────────────────────
              const SizedBox(height: 32),
              profile.when(
                loading: () => const ProfileBasicsCard(profile: null, loading: true),
                // Web swallows the initial fetch error (form stays empty).
                error: (_, _) => const ProfileBasicsCard(profile: null),
                data: (p) => ProfileBasicsCard(
                  key: ValueKey('profile-${p?.uid ?? 'none'}'),
                  profile: p,
                ),
              ),

              // ── Section 2: upload ─────────────────────────────────────
              const SizedBox(height: 32),
              const ResumeUploadCard(),

              // ── Section 3: list ───────────────────────────────────────
              const SizedBox(height: 32),
              Row(
                children: [
                  const Expanded(
                    child: Text('CV của tôi',
                        style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink)),
                  ),
                  Text('${resumes.valueOrNull?.length ?? 0} CV',
                      style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                ],
              ),
              const SizedBox(height: 16),
              resumes.when(
                loading: () => const AppCard(
                  padding: EdgeInsets.all(40),
                  child: Center(child: MiniSpinner(size: 28)),
                ),
                error: (e, _) => StatusBanner(
                  tone: BannerTone.error,
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Không thể tải danh sách CV. ${Failure.from(e).message}',
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(myResumesProvider),
                        child: const Text('Thử lại'),
                      ),
                    ],
                  ),
                ),
                data: (list) => list.isEmpty
                    ? const AppCard(
                        padding: EdgeInsets.all(40),
                        child: Center(
                          child: Text('Bạn chưa tải CV nào.',
                              style: TextStyle(color: AppColors.inkMuted)),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            ResumeCard(
                              key: ValueKey(list[i].resumeId),
                              resume: list[i],
                              run: runs[list[i].resumeId] ?? AnalysisRunState.idle,
                              onDownload: () => _download(context, list[i]),
                              onExtract: () => _extract(context, ref, list[i]),
                              onSetPrimary: () => _setPrimary(context, ref, list[i]),
                              onDelete: () => _delete(context, ref, list[i]),
                              onPasteText: () => _pasteText(context, ref, list[i]),
                              onOpenDetail: () => context
                                  .push(AppRoutes.aiAnalysisOf(list[i].resumeId)),
                            ),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Actions ─────────────────────────────────────────────────────────────

  Future<void> _download(BuildContext context, ResumeModel r) async {
    final url = r.downloadUrl;
    if (url == null || url.isEmpty) return;
    try {
      final uri = Uri.tryParse(url);
      if (uri == null) throw const Failure('Không thể mở tệp CV.');
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) throw const Failure('Không thể mở tệp CV.');
    } catch (e) {
      // launchUrl throws PlatformException when no handler / bad scheme.
      if (context.mounted) {
        showFailure(
          context,
          e is Failure ? e : const Failure('Không thể mở tệp CV.'),
        );
      }
    }
  }

  /// Extract: needs rawText. Without it (PDF whose bytes could not be read),
  /// open the paste dialog first and analyze right after saving.
  Future<void> _extract(BuildContext context, WidgetRef ref, ResumeModel r) async {
    final vm = ref.read(resumesViewModelProvider.notifier);
    var target = r;
    if ((r.rawText ?? '').trim().isEmpty) {
      final text = await showPasteResumeTextDialog(context, resume: r);
      if (text == null) return;
      try {
        await vm.saveRawText(r.resumeId, text);
      } catch (e) {
        if (context.mounted) showFailure(context, e);
        return;
      }
      target = ResumeModel(
        resumeId: r.resumeId,
        jobSeekerId: r.jobSeekerId,
        title: r.title,
        fileName: r.fileName,
        filePath: r.filePath,
        downloadUrl: r.downloadUrl,
        rawText: text,
        isPrimary: r.isPrimary,
        uploadDate: r.uploadDate,
        aiAnalysis: r.aiAnalysis,
      );
    }
    await vm.analyze(target);
  }

  Future<void> _pasteText(BuildContext context, WidgetRef ref, ResumeModel r) async {
    final text = await showPasteResumeTextDialog(context, resume: r);
    if (text == null) return;
    try {
      await ref.read(resumesViewModelProvider.notifier).saveRawText(r.resumeId, text);
      if (context.mounted) showSuccess(context, 'Đã lưu nội dung CV.');
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> _setPrimary(BuildContext context, WidgetRef ref, ResumeModel r) async {
    try {
      await ref.read(resumesViewModelProvider.notifier).setPrimary(r.resumeId);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }

  Future<void> _delete(BuildContext context, WidgetRef ref, ResumeModel r) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        title: const Text('Xóa CV này?'),
        content: Text(
          'CV "${r.title.isNotEmpty ? r.title : r.fileName}" và kết quả phân tích sẽ bị xóa vĩnh viễn.',
          style: const TextStyle(color: AppColors.inkSoft, height: 1.5),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Hủy')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.red600),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await ref.read(resumesViewModelProvider.notifier).delete(r);
    } catch (e) {
      if (context.mounted) showFailure(context, e);
    }
  }
}
