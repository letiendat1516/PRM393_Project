import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/ai_matching_viewmodel.dart';

/// AIScoreModal "RESULTS" step: header with count + 'Lưu kết quả', the
/// scrollable ranked list (ScoreBadge 44 + title/company/reason) and 'Đóng'.
///
/// The session was already stored when scoring finished (onScored →
/// saveSession); 'Lưu kết quả' mirrors the web button — persist the
/// recommendations (fire-and-forget) and close.
class ScoringResults extends ConsumerWidget {
  const ScoringResults({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(aiMatchingViewModelProvider);
    final vm = ref.read(aiMatchingViewModelProvider.notifier);
    final ranked = state.ranked;
    final total = state.jobs.length;
    final scored = ranked.length;
    final saved = state.savedSessionId;

    Future<void> saveAndClose() async {
      await vm.saveResults();
      if (context.mounted) onClose();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          alignment: WrapAlignment.spaceBetween,
          runSpacing: 8,
          spacing: 12,
          children: [
            Text(
              'Kết quả chấm điểm ($scored/$total việc làm)',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            ElevatedButton.icon(
              onPressed: state.saving ? null : saveAndClose,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                minimumSize: const Size(0, 40),
              ),
              icon: state.saving
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Icon(Icons.check, size: 16),
              label: const Text('Lưu kết quả'),
            ),
          ],
        ),
        if (scored < total) ...[
          const SizedBox(height: 6),
          Text(
            '⚠ Chấm được $scored/$total — một số batch bị lỗi, thử lại sau nếu cần đủ.',
            style: const TextStyle(fontSize: 12, color: AppColors.amber700),
          ),
        ],
        if (state.warning != null) ...[
          const SizedBox(height: 8),
          InfoBanner(message: state.warning!, tone: InfoTone.warning, icon: Icons.warning_amber_outlined),
        ],
        if (saved != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.emerald50,
              borderRadius: BorderRadius.circular(AppRadius.xl),
            ),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 6,
              children: [
                const Text('Đã lưu phiên chấm điểm.',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.emerald700)),
                InkWell(
                  onTap: () {
                    // Capture the router before popping: after onClose() this
                    // element is on its way out of the tree.
                    final router = GoRouter.of(context);
                    onClose();
                    router.go(AppRoutes.recommendedSessionOf(saved));
                  },
                  child: const Text(
                    'Xem phiên',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.emerald700,
                      decoration: TextDecoration.underline,
                      decorationColor: AppColors.emerald700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        if (state.error != null) ...[
          const SizedBox(height: 10),
          AlertError(message: state.error!),
        ],
        const SizedBox(height: 12),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 320),
          child: scored == 0
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Text('Không có việc làm nào được chấm điểm.',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 13, color: AppColors.inkMuted)),
                )
              : ListView.separated(
                  shrinkWrap: true,
                  itemCount: ranked.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (_, i) => _ResultRow(job: ranked[i].$1, score: ranked[i].$2),
                ),
        ),
        const SizedBox(height: 20),
        OutlinedButton.icon(
          onPressed: onClose,
          icon: const Icon(Icons.close, size: 18),
          label: const Text('Đóng'),
        ),
      ],
    );
  }
}

class _ResultRow extends StatelessWidget {
  const _ResultRow({required this.job, required this.score});
  final JobModel job;
  final JobScore score;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          border: Border.all(color: AppColors.borderMuted),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                ScoreBadge(score: score, size: 44),
                const SizedBox(height: 2),
                Text(
                  score.source == 'sql' ? 'Điểm SQL' : 'Điểm AI',
                  style: const TextStyle(
                      fontSize: 9, fontWeight: FontWeight.w600, color: AppColors.inkMuted),
                ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(job.jobTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink)),
                  Text(job.employerName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                  if (score.recommendationReason.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(score.recommendationReason,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.4)),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
