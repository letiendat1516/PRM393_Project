import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/misc_models.dart';
import '../../../shared/widgets/app_scaffold.dart';
import '../../../shared/widgets/empty_state.dart';
import '../../../shared/widgets/job_list_item.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../applications/viewmodels/applications_providers.dart';
import '../../applications/widgets/apply_modal.dart';
import '../data/saved_jobs_repository.dart';
import '../viewmodels/saved_jobs_provider.dart';

/// FLUTTER_REBUILD_PLAN mobile screen — /viec-da-luu (job seeker).
class SavedJobsPage extends ConsumerWidget {
  const SavedJobsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(savedJobsStreamProvider);
    final appliedIds =
        ref.watch(appliedJobIdsProvider).valueOrNull ?? const <String>{};

    return AppScaffold(
      title: 'Việc đã lưu',
      body: saved.when(
        loading: () => const RouteLoader(label: 'Đang tải việc làm đã lưu...'),
        error: (e, _) => RouteErrorView(
          error: e,
          compact: true,
          onRetry: () => ref.invalidate(savedJobsStreamProvider),
        ),
        data: (list) => list.isEmpty
            ? EmptyState(
                icon: Icons.bookmarks_outlined,
                title: 'Chưa có việc làm nào được lưu',
                subtitle:
                    'Nhấn biểu tượng đánh dấu trên tin tuyển dụng để lưu lại và xem sau.',
                action: ElevatedButton.icon(
                  onPressed: () => context.go(AppRoutes.jobs),
                  icon: const Icon(Icons.search, size: 18),
                  label: const Text('Tìm việc làm'),
                ),
              )
            : _SavedList(items: list, appliedIds: appliedIds),
      ),
    );
  }
}

/// Stream-driven list with swipe-to-remove. The Firestore delete runs inside
/// `confirmDismiss` so a failed removal snaps the row back instead of leaving
/// a dismissed Dismissible in the tree; [_removing] hides a row synchronously
/// once it has been dismissed until the snapshot without it arrives.
class _SavedList extends ConsumerStatefulWidget {
  const _SavedList({required this.items, required this.appliedIds});
  final List<SavedJob> items;
  final Set<String> appliedIds;

  @override
  ConsumerState<_SavedList> createState() => _SavedListState();
}

class _SavedListState extends ConsumerState<_SavedList> {
  final _removing = <String>{};

  @override
  void didUpdateWidget(covariant _SavedList old) {
    super.didUpdateWidget(old);
    if (_removing.isEmpty) return;
    final present = {for (final s in widget.items) s.jobId};
    _removing.removeWhere((id) => !present.contains(id));
  }

  /// Dismissible.confirmDismiss: performs the removal and only lets the row
  /// collapse when the write succeeded.
  Future<bool> _confirmRemove(SavedJob s) async {
    try {
      await removeSavedJob(ref, s.jobId);
      if (mounted) showSuccess(context, 'Đã bỏ lưu tin tuyển dụng.');
      return true;
    } catch (e) {
      if (mounted) showFailure(context, e);
      return false;
    }
  }

  /// Bookmark button inside the card (no swipe animation involved).
  Future<void> _remove(SavedJob s) async {
    setState(() => _removing.add(s.jobId));
    try {
      await removeSavedJob(ref, s.jobId);
      if (mounted) showSuccess(context, 'Đã bỏ lưu tin tuyển dụng.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _removing.remove(s.jobId));
      showFailure(context, e);
    }
  }

  @override
  Widget build(BuildContext context) {
    final visible = [
      for (final s in widget.items)
        if (!_removing.contains(s.jobId)) s,
    ];
    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: visible.length + 1,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${visible.length} việc làm đã lưu · vuốt sang trái để bỏ lưu',
              style: const TextStyle(fontSize: 13, color: AppColors.inkMuted),
            ),
          );
        }
        final s = visible[i - 1];
        final job = SavedJobsRepository.jobFromSaved(s);
        return Dismissible(
          key: ValueKey('saved-${s.jobId}'),
          direction: DismissDirection.endToStart,
          confirmDismiss: (_) => _confirmRemove(s),
          onDismissed: (_) {
            // The snapshot without this doc normally lands before the write
            // resolves; hide the row locally in case it has not yet.
            if (mounted) setState(() => _removing.add(s.jobId));
          },
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            decoration: BoxDecoration(
              color: AppColors.red600,
              borderRadius: BorderRadius.circular(AppRadius.x2l),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.bookmark_remove_outlined, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Bỏ lưu',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          child: JobListItem(
            job: job,
            saved: true,
            applied: widget.appliedIds.contains(job.jobId),
            onToggleSave: () => _remove(s),
            onApply: () => showApplyModal(context, job),
          ),
        );
      },
    );
  }
}
