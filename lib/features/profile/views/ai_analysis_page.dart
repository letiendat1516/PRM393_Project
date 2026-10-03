import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/widgets/app_icons.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/profile_providers.dart';
import '../viewmodels/resumes_viewmodel.dart';
import '../widgets/analysis_chart.dart';
import '../widgets/analysis_panel.dart';
import '../widgets/paste_resume_text_dialog.dart';
import '../widgets/profile_form_widgets.dart';

/// /ho-so/phan-tich/:resumeId — mobile-plan "AI analysis" screen: hero
/// summary, category chart, extracted chips, work history and re-run.
class AiAnalysisPage extends ConsumerWidget {
  const AiAnalysisPage({super.key, required this.resumeId});
  final String resumeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(resumeProvider(resumeId));
    final run = ref.watch(resumesViewModelProvider).runFor(resumeId);
    final uid = ref.watch(currentUidProvider);

    return PublicLayout(
      child: PageContainer(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 48),
          child: resume.when(
            loading: () => const SizedBox(height: 360, child: RouteLoader()),
            error: (e, _) => SizedBox(
              height: 360,
              child: RouteErrorView(
                error: e,
                compact: true,
                onRetry: () => ref.invalidate(resumeProvider(resumeId)),
              ),
            ),
            data: (r) {
              if (r == null || (uid != null && r.jobSeekerId != uid)) {
                return AppCard(
                  padding: const EdgeInsets.all(24),
                  child: EmptyState(
                    icon: Icons.description_outlined,
                    title: 'Không tìm thấy CV.',
                    subtitle: 'CV có thể đã bị xóa hoặc không thuộc tài khoản của bạn.',
                    action: ElevatedButton(
                      onPressed: () => context.go(AppRoutes.resumeProfile),
                      child: const Text('Về Hồ sơ & CV'),
                    ),
                  ),
                );
              }
              return _Body(resume: r, run: run);
            },
          ),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.resume, required this.run});
  final ResumeModel resume;
  final AnalysisRunState run;

  Future<void> _analyze(BuildContext context, WidgetRef ref) async {
    final vm = ref.read(resumesViewModelProvider.notifier);
    var target = resume;
    if ((resume.rawText ?? '').trim().isEmpty) {
      final text = await showPasteResumeTextDialog(context, resume: resume);
      if (text == null) return;
      try {
        await vm.saveRawText(resume.resumeId, text);
      } catch (e) {
        if (context.mounted) showFailure(context, e);
        return;
      }
      target = ResumeModel(
        resumeId: resume.resumeId,
        jobSeekerId: resume.jobSeekerId,
        title: resume.title,
        fileName: resume.fileName,
        filePath: resume.filePath,
        downloadUrl: resume.downloadUrl,
        rawText: text,
        isPrimary: resume.isPrimary,
        uploadDate: resume.uploadDate,
        aiAnalysis: resume.aiAnalysis,
      );
    }
    await vm.analyze(target);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final a = resume.aiAnalysis;
    final meta = [
      resume.fileName,
      if (resume.uploadDate != null) Formatters.localeDateTime(resume.uploadDate!),
    ].join(' · ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Breadcrumb(items: [
          ('Hồ sơ & CV', () => context.go(AppRoutes.resumeProfile)),
          ('Phân tích AI', null),
        ]),
        const SizedBox(height: 16),
        const Eyebrow(label: 'Phân tích CV bằng AI', icon: Icons.auto_awesome),
        const SizedBox(height: 12),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 8,
          children: [
            Text(resume.title.isNotEmpty ? resume.title : resume.fileName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      color: AppColors.ink,
                      letterSpacing: -0.5,
                    )),
            if (resume.isPrimary)
              const Pill(label: 'CV chính', bg: AppColors.primary50, fg: AppColors.primary),
          ],
        ),
        const SizedBox(height: 8),
        Text(meta, style: const TextStyle(color: AppColors.inkSoft, fontSize: 14)),
        const SizedBox(height: 32),
        if (run.error != null) ...[
          AlertError(message: run.error!, onRetry: () => _analyze(context, ref)),
          const SizedBox(height: 16),
        ],
        if (run.loading)
          const StatusBanner(
            tone: BannerTone.primary,
            padding: EdgeInsets.all(16),
            child: Row(
              children: [
                MiniSpinner(size: 14),
                SizedBox(width: 10),
                Expanded(
                  child: Text('AI đang đọc & phân tích CV — có thể mất 30–90 giây...'),
                ),
              ],
            ),
          )
        else if (a == null)
          _NotAnalyzed(resume: resume, onAnalyze: () => _analyze(context, ref))
        else
          _AnalysisLayout(
            resume: resume,
            analysis: a,
            onReanalyze: () => _analyze(context, ref),
          ),
      ],
    );
  }
}

class _NotAnalyzed extends StatelessWidget {
  const _NotAnalyzed({required this.resume, required this.onAnalyze});
  final ResumeModel resume;
  final VoidCallback onAnalyze;

  @override
  Widget build(BuildContext context) {
    final hasText = (resume.rawText ?? '').trim().isNotEmpty;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: EmptyState(
        icon: Icons.auto_awesome_outlined,
        title: 'CV chưa được phân tích.',
        subtitle: hasText
            ? 'AI sẽ trích xuất kỹ năng, kinh nghiệm, học vấn, ngôn ngữ và chứng chỉ từ CV của bạn.'
            : 'Tệp chưa được lưu trữ nên AI chưa đọc được nội dung. Bạn sẽ được yêu cầu dán nội dung CV trước khi phân tích.',
        action: ElevatedButton.icon(
          onPressed: onAnalyze,
          icon: Icon(AppIcons.of('sparkles'), size: 18),
          label: const Text('Phân tích CV bằng AI'),
        ),
      ),
    );
  }
}

class _AnalysisLayout extends ConsumerWidget {
  const _AnalysisLayout({
    required this.resume,
    required this.analysis,
    required this.onReanalyze,
  });
  final ResumeModel resume;
  final AiAnalysis analysis;
  final VoidCallback onReanalyze;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyCount =
        ref.watch(resumeAnalysesProvider(resume.resumeId)).valueOrNull?.length;

    final hero = _HeroCard(
      analysis: analysis,
      historyCount: historyCount,
      onReanalyze: onReanalyze,
      onMatching: () => context.go(AppRoutes.jobs),
    );
    final chart = AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeading(
            title: 'Thống kê trích xuất',
            subtitle: 'Số lượng mục AI nhận diện được theo từng nhóm.',
          ),
          const SizedBox(height: 16),
          AnalysisCategoryChart(analysis: analysis),
        ],
      ),
    );
    final details = _DetailsColumn(analysis: analysis);

    return LayoutBuilder(
      builder: (context, c) {
        final wide = c.maxWidth >= 1024 - 64;
        if (!wide) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              hero,
              const SizedBox(height: 24),
              chart,
              const SizedBox(height: 24),
              details,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 5,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [hero, const SizedBox(height: 24), chart],
              ),
            ),
            const SizedBox(width: 24),
            Expanded(flex: 7, child: details),
          ],
        );
      },
    );
  }
}

/// Gradient hero with the completeness score + headline stats + actions.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.analysis,
    required this.onReanalyze,
    required this.onMatching,
    this.historyCount,
  });
  final AiAnalysis analysis;
  final int? historyCount;
  final VoidCallback onReanalyze;
  final VoidCallback onMatching;

  /// Share of the 7 extraction facets the AI could fill.
  int get _completeness {
    final facets = [
      analysis.skills.isNotEmpty,
      analysis.softSkills.isNotEmpty,
      analysis.languages.isNotEmpty,
      analysis.certifications.isNotEmpty,
      (analysis.totalExperienceYears ?? 0) > 0,
      (analysis.educationLevel ?? '').trim().isNotEmpty,
      (analysis.summary ?? '').trim().isNotEmpty,
    ];
    final filled = facets.where((f) => f).length;
    return (filled / facets.length * 100).round();
  }

  @override
  Widget build(BuildContext context) {
    final years = analysis.totalExperienceYears ?? 0;
    final yearsLabel = years <= 0
        ? '—'
        : (years == years.roundToDouble() ? years.toInt().toString() : years.toStringAsFixed(1));
    final edu = (analysis.educationLevel ?? '').trim();
    final score = _completeness;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primary700],
        ),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.elevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.auto_awesome, size: 16, color: Colors.white70),
              const SizedBox(width: 6),
              const Text('KẾT QUẢ TRÍCH XUẤT BẰNG AI',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2)),
              const Spacer(),
              if (historyCount != null && historyCount! > 1)
                Text('Lần phân tích thứ $historyCount',
                    style: const TextStyle(color: Colors.white70, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('$score%',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w800,
                      height: 1,
                      letterSpacing: -1)),
              const SizedBox(width: 12),
              const Padding(
                padding: EdgeInsets.only(bottom: 6),
                child: Text('độ hoàn thiện hồ sơ',
                    style: TextStyle(color: Colors.white70, fontSize: 14)),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: score / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              valueColor: const AlwaysStoppedAnimation(AppColors.secondary),
            ),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 24,
            runSpacing: 12,
            children: [
              _HeroStat(value: yearsLabel, label: 'năm kinh nghiệm'),
              _HeroStat(value: edu.isEmpty ? '—' : edu, label: 'trình độ học vấn'),
              _HeroStat(value: '${analysis.skills.length}', label: 'kỹ năng'),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            [
              if (analysis.analyzedAt != null)
                'Phân tích lúc ${Formatters.localeDateTime(analysis.analyzedAt!)}',
              if ((analysis.modelVersion ?? '').isNotEmpty) 'Model: ${analysis.modelVersion}',
            ].join(' · '),
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 20),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              ElevatedButton.icon(
                onPressed: onMatching,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.primary,
                ),
                icon: const Icon(Icons.gps_fixed, size: 18),
                label: const Text('Dùng CV này để AI Matching'),
              ),
              OutlinedButton.icon(
                onPressed: onReanalyze,
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.white,
                  side: BorderSide(color: Colors.white.withValues(alpha: 0.5)),
                ),
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Phân tích lại'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.value, required this.label});
  final String value;
  final String label;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(value,
              style: const TextStyle(
                  color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800)),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
        ],
      );
}

/// Right column: summary, chips groups, languages/certs, work experience.
class _DetailsColumn extends StatelessWidget {
  const _DetailsColumn({required this.analysis});
  final AiAnalysis analysis;

  @override
  Widget build(BuildContext context) {
    final summary = (analysis.summary ?? '').trim();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (summary.isNotEmpty) ...[
          _card(
            title: 'Tóm tắt',
            child: Text(summary,
                style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6)),
          ),
          const SizedBox(height: 24),
        ],
        _card(
          title: 'Kỹ năng',
          subtitle: '${analysis.skills.length} kỹ năng chuyên môn · ${analysis.softSkills.length} kỹ năng mềm',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _chips('Kỹ năng', analysis.skills, AppColors.primary50, AppColors.primary),
              const SizedBox(height: 14),
              _chips('Kỹ năng mềm', analysis.softSkills, AppColors.slate100, AppColors.inkSoft),
              const SizedBox(height: 14),
              _chips('Ngôn ngữ', analysis.languages, AppColors.teal50, AppColors.teal600),
              const SizedBox(height: 14),
              _chips('Chứng chỉ', analysis.certifications, AppColors.violet50, AppColors.violet600),
            ],
          ),
        ),
        const SizedBox(height: 24),
        _card(
          title: 'Kinh nghiệm làm việc',
          subtitle: analysis.workExperience.isEmpty
              ? null
              : '${analysis.workExperience.length} vị trí được AI nhận diện',
          child: analysis.workExperience.isEmpty
              ? const Text('AI không tìm thấy mục kinh nghiệm làm việc trong CV.',
                  style: TextStyle(fontSize: 13, color: AppColors.inkMuted))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < analysis.workExperience.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      _WorkItem(data: analysis.workExperience[i]),
                    ],
                  ],
                ),
        ),
      ],
    );
  }

  Widget _card({required String title, String? subtitle, required Widget child}) => AppCard(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CardHeading(title: title, subtitle: subtitle),
            const SizedBox(height: 16),
            child,
          ],
        ),
      );

  Widget _chips(String caption, List<String> items, Color bg, Color fg) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MicroCaption(caption),
          const SizedBox(height: 6),
          if (items.isEmpty)
            const Text('Không có', style: TextStyle(fontSize: 12, color: AppColors.inkMuted))
          else
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final s in items) Pill(label: s, bg: bg, fg: fg)],
            ),
        ],
      );
}

/// One `work_experience` entry from the AI payload
/// ({company, position, start_date, end_date, description}).
class _WorkItem extends StatelessWidget {
  const _WorkItem({required this.data});
  final Map<String, dynamic> data;

  String _s(String a, [String? b]) =>
      (data[a] ?? (b != null ? data[b] : null) ?? '').toString().trim();

  @override
  Widget build(BuildContext context) {
    final company = _s('company', 'companyName');
    final position = _s('position');
    final start = _s('start_date', 'startDate');
    final end = _s('end_date', 'endDate');
    final desc = _s('description');
    final range = [
      if (start.isNotEmpty) start,
      if (start.isNotEmpty || end.isNotEmpty) (end.isEmpty ? 'Hiện tại' : end),
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
                Text(position.isEmpty ? 'Vị trí chưa rõ' : position,
                    style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.ink)),
                if (company.isNotEmpty)
                  Text(company, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                if (range.isNotEmpty)
                  Text(range, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                if (desc.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(desc,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.inkSoft, height: 1.5)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
