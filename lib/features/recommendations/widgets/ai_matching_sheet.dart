import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/ai_matching_viewmodel.dart';
import 'cv_picker.dart';
import 'scoring_results.dart';

/// `jobId → {'ai': JobScore?, 'sql': JobScore?}` — the AIScoreModal scoreMap.
typedef AiScoreResults = Map<String, Map<String, JobScore>>;

/// Opens the AI Matching flow (components/job/AIScoreModal.jsx) for the
/// currently filtered [jobs] (≤100). Dialog on wide screens, bottom sheet on
/// phones.
///
/// Resolves when the sheet closes — with the scoring results if a run
/// completed inside it (regardless of 'Lưu kết quả' / 'Đóng' / barrier /
/// back), else `null`. Mirrors `onScored(scoreMap, cvName)`: consumers adopt
/// `ai ?? sql` per job and switch the sort to 'Độ phù hợp AI'. The session is
/// already stored in AiSessionStore by the time this resolves.
Future<AiScoreResults?> showAiMatchingSheet(
  BuildContext context, {
  required List<JobModel> jobs,
}) async {
  // Captured from the viewmodel while the sheet is alive so every close path
  // (including ones that pop with null) still reports the results.
  AiScoreResults? captured;
  void onResults(AiScoreResults r) => captured = r;

  final wide = MediaQuery.of(context).size.width >= 768;
  AiScoreResults? popped;
  if (wide) {
    popped = await showDialog<AiScoreResults>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (_) => Dialog(
        backgroundColor: AppColors.surface,
        insetPadding: const EdgeInsets.fromLTRB(16, 48, 16, 24),
        alignment: Alignment.topCenter,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 672),
          child: AiMatchingSheet(jobs: jobs, onResults: onResults),
        ),
      ),
    );
  } else {
    popped = await showModalBottomSheet<AiScoreResults>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.x2l)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.92),
          child: AiMatchingSheet(jobs: jobs, onResults: onResults),
        ),
      ),
    );
  }
  return popped ?? captured;
}

/// Sheet body: header (sparkles tile + 'AI Matching'), CV picker or results,
/// info note, error, primary action.
class AiMatchingSheet extends ConsumerStatefulWidget {
  const AiMatchingSheet({super.key, required this.jobs, this.onResults});

  final List<JobModel> jobs;

  /// Called whenever a scoring run completes (results become non-null).
  final ValueChanged<AiScoreResults>? onResults;

  @override
  ConsumerState<AiMatchingSheet> createState() => _AiMatchingSheetState();
}

class _AiMatchingSheetState extends ConsumerState<AiMatchingSheet> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(aiMatchingViewModelProvider.notifier).setJobs(widget.jobs);
    });
  }

  /// Pops with the results of the completed run (null when none).
  void _close() => Navigator.of(context).pop(ref.read(aiMatchingViewModelProvider).results);

  @override
  Widget build(BuildContext context) {
    ref.listen<AiScoreResults?>(
      aiMatchingViewModelProvider.select((s) => s.results),
      (_, results) {
        if (results != null) widget.onResults?.call(results);
      },
    );
    final state = ref.watch(aiMatchingViewModelProvider);
    final vm = ref.read(aiMatchingViewModelProvider.notifier);
    final n = widget.jobs.length;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header
        Container(
          padding: const EdgeInsets.fromLTRB(24, 20, 16, 20),
          decoration: const BoxDecoration(
            border: Border(bottom: BorderSide(color: AppColors.borderMuted)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppColors.primary50,
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: const Icon(Icons.auto_awesome, size: 22, color: AppColors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('AI Matching',
                        style: TextStyle(
                            fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
                    Text('Chấm điểm $n việc làm với CV bằng Gemini AI',
                        style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              IconButton(
                onPressed: state.loading ? null : _close,
                tooltip: 'Đóng',
                icon: const Icon(Icons.close, size: 20, color: AppColors.inkMuted),
              ),
            ],
          ),
        ),
        // Body
        Flexible(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
            child: state.hasResults
                ? ScoringResults(onClose: _close)
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const CvPicker(),
                      const SizedBox(height: 20),
                      _infoNote(n),
                      if (state.warning != null) ...[
                        const SizedBox(height: 12),
                        InfoBanner(
                          message: state.warning!,
                          tone: InfoTone.warning,
                          icon: Icons.warning_amber_outlined,
                        ),
                      ],
                      if (state.error != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: AppColors.red50,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                          ),
                          child: Text(state.error!,
                              style: const TextStyle(
                                  fontSize: 14, color: AppColors.red600, height: 1.5)),
                        ),
                      ],
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: state.canScore ? vm.score : null,
                        child: state.loading
                            ? Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white),
                                  ),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      // AIScoreModal: 'Đang chấm điểm' + (progress.total > 0
                                      //   ? ' — đang xử lý X/Y việc làm...' : '...')
                                      state.progressTotal > 0
                                          ? 'Đang chấm điểm — đang xử lý ${state.progressCurrent}/${state.progressTotal} việc làm...'
                                          : 'Đang chấm điểm...',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                ],
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.auto_awesome, size: 18),
                                  const SizedBox(width: 8),
                                  Text(state.method.buttonLabel),
                                ],
                              ),
                      ),
                      if (state.loading && state.progressTotal > 0) ...[
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          child: LinearProgressIndicator(
                            value: state.progressCurrent / state.progressTotal,
                            minHeight: 6,
                            backgroundColor: AppColors.slate100,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  /// `rounded-xl bg-primary-50 px-4 py-3 text-xs` note about AI Logs.
  Widget _infoNote(int n) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.primary50,
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, size: 14, color: AppColors.primary),
                const SizedBox(width: 6),
                Text('Sẽ chấm $n việc làm',
                    style: const TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
              ],
            ),
            const SizedBox(height: 4),
            const Text.rich(
              TextSpan(children: [
                TextSpan(
                    text:
                        'Mỗi lần chấm điểm được ghi log (prompt, response, thời gian) vào trang '),
                TextSpan(text: 'AI Logs', style: TextStyle(fontWeight: FontWeight.w500)),
                TextSpan(text: ' để theo dõi và cải thiện prompt.'),
              ]),
              style: TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.5),
            ),
          ],
        ),
      );
}
