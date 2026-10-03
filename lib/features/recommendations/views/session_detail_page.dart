import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/services/ai_session_store.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/job_list_item.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../applications/viewmodels/applications_providers.dart';
import '../../applications/widgets/apply_modal.dart';
import '../../jobs/viewmodels/saved_jobs_provider.dart';
import '../../jobs/widgets/save_job_helper.dart';
import '../viewmodels/sessions_provider.dart';
import '../widgets/method_badge.dart';
import '../widgets/recommendations_shell.dart';

/// /de-xuat/:sessionId — SessionDetailPage (RecommendedPage.jsx named export):
/// stats tiles + jobs ranked by match score (JobListItem with score).
class SessionDetailPage extends ConsumerWidget {
  const SessionDetailPage({super.key, required this.sessionId});

  final String sessionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionByIdProvider(sessionId));

    return session.when(
      loading: () => const RecommendationsShell(
        child: Padding(padding: EdgeInsets.symmetric(vertical: 80), child: RouteLoader()),
      ),
      error: (e, _) => RecommendationsShell(
        child: RouteErrorView(
          error: e,
          compact: true,
          onRetry: () => ref.read(sessionsProvider.notifier).refresh(),
        ),
      ),
      data: (s) => s == null ? const _NotFound() : _Found(session: s),
    );
  }
}

/// `mx-auto max-w-2xl px-4 py-20 text-center` — "Không tìm thấy phiên".
class _NotFound extends StatelessWidget {
  const _NotFound();

  @override
  Widget build(BuildContext context) {
    return RecommendationsShell(
      maxWidth: 672,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 56),
        child: Column(
          children: [
            const Icon(Icons.close, size: 32, color: AppColors.inkMuted),
            const SizedBox(height: 12),
            const Text('Không tìm thấy phiên',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink)),
            const SizedBox(height: 16),
            OutlinedButton(
              onPressed: () => context.go(AppRoutes.recommended),
              child: const Text('Quay lại danh sách'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Session rows: JobListItem with score + the same bookmark / 'Ứng tuyển'
/// (ApplyModal) wiring as /viec-lam (RecommendedPage.jsx renders ApplyModal
/// as a sibling and toggles saved state per row).
class _Found extends ConsumerWidget {
  const _Found({required this.session});
  final AiSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wide = MediaQuery.of(context).size.width >= 640;
    final savedIds = ref.watch(savedJobIdsProvider).valueOrNull ?? const <String>{};
    final appliedIds = ref.watch(appliedJobIdsProvider).valueOrNull ?? const <String>{};

    // scoredJobs: snapshot present → (job, bestScore); sorted desc.
    final scored = <(JobModel, JobScore)>[];
    for (final entry in session.scores.entries) {
      final snap = session.jobs[entry.key];
      final best = entry.value['ai'] ?? entry.value['sql'];
      if (snap == null || best == null) continue;
      scored.add((AiSessionStore.jobFromSnapshot(snap), best));
    }
    scored.sort((a, b) => b.$2.matchScore.compareTo(a.$2.matchScore));
    final avg = scored.isEmpty
        ? 0
        : (scored.fold<int>(0, (a, e) => a + e.$2.matchScore) / scored.length).round();
    final highMatch = scored.where((e) => e.$2.matchScore >= 70).length;

    return RecommendationsShell(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Breadcrumb(items: [
            ('Trang chủ', () => context.go(AppRoutes.home)),
            ('Đề xuất', () => context.go(AppRoutes.recommended)),
            (session.cvName, null),
          ]),
          const SizedBox(height: 16),
          Align(
            alignment: Alignment.centerLeft,
            child: InkWell(
              onTap: () => context.go(AppRoutes.recommended),
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.arrow_back, size: 16, color: AppColors.inkMuted),
                    SizedBox(width: 6),
                    Text('Tất cả phiên', style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Header
          Row(
            children: [
              Flexible(
                child: Text(
                  session.cvName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: wide ? 30 : 24,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                    height: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              MethodBadge(method: session.method),
            ],
          ),
          const SizedBox(height: 4),
          Text(Formatters.localeDateTime(session.scoredAt),
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
          const SizedBox(height: 24),
          // Stats row — always 3 columns
          Row(
            children: [
              Expanded(
                child: _StatTile(value: '${scored.length}', caption: 'Việc làm', color: AppColors.ink),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: (avg / 10).toStringAsFixed(1),
                  caption: 'Điểm TB',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  value: '$highMatch',
                  caption: 'Phù hợp cao (≥70)',
                  color: AppColors.green600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Row(
            children: [
              Icon(Icons.trending_up, size: 16, color: AppColors.inkMuted),
              SizedBox(width: 6),
              Expanded(
                child: Text('Xếp hạng theo độ phù hợp (cao → thấp)',
                    style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (scored.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 32),
              child: Text(
                'Phiên này không còn dữ liệu việc làm để hiển thị.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: AppColors.inkMuted),
              ),
            )
          else
            for (var i = 0; i < scored.length; i++) ...[
              JobListItem(
                key: ValueKey(scored[i].$1.jobId),
                job: scored[i].$1,
                score: scored[i].$2,
                saved: savedIds.contains(scored[i].$1.jobId),
                onToggleSave: () => handleToggleSave(context, ref, scored[i].$1),
                onApply: () => showApplyModal(context, scored[i].$1),
                applied: appliedIds.contains(scored[i].$1.jobId),
              ),
              if (i < scored.length - 1) const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

/// `.card p-4` with `text-lg font-bold` value and `text-xs text-ink-muted` caption.
class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.caption, required this.color});
  final String value;
  final String caption;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: color)),
          Text(caption,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
      ),
    );
  }
}
