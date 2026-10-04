import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/job_list_item.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../../applications/viewmodels/applications_providers.dart';
import '../../applications/widgets/apply_modal.dart';
import '../../recommendations/widgets/ai_matching_sheet.dart';
import '../viewmodels/jobs_search_viewmodel.dart';
import '../viewmodels/saved_jobs_provider.dart';
import '../widgets/job_filter_sidebar.dart';
import '../widgets/jobs_results_toolbar.dart';
import '../widgets/jobs_search_header.dart';
import '../widgets/save_job_helper.dart';
import '../widgets/sticky_sidebar_layout.dart';

/// pages/JobsPage.jsx — /viec-lam (?q&location).
class JobsSearchPage extends ConsumerStatefulWidget {
  const JobsSearchPage({super.key, this.initialKeyword, this.initialLocation});

  final String? initialKeyword;
  final String? initialLocation;

  @override
  ConsumerState<JobsSearchPage> createState() => _JobsSearchPageState();
}

class _JobsSearchPageState extends ConsumerState<JobsSearchPage> {
  final _scroll = ScrollController();
  late final TextEditingController _keyword = TextEditingController(
    text: widget.initialKeyword ?? '',
  );

  @override
  void initState() {
    super.initState();
    _scheduleSync();
    _scroll.addListener(_onScroll);
  }

  /// Infinite-scroll trigger: when the viewport is within 600px of the end
  /// of the loaded list, ask the viewmodel to pull the next 20 jobs. The
  /// loadMore() guard already handles duplicate fire-while-loading, so a
  /// single rude listener is enough — no debounce needed.
  void _onScroll() {
    if (!_scroll.hasClients) return;
    final pos = _scroll.position;
    if (pos.extentAfter < 600) {
      _vm.loadMore();
    }
  }

  @override
  void didUpdateWidget(covariant JobsSearchPage old) {
    super.didUpdateWidget(old);
    if (old.initialKeyword != widget.initialKeyword ||
        old.initialLocation != widget.initialLocation) {
      _scheduleSync();
    }
  }

  /// Provider state must not change during build → defer to the next frame.
  void _scheduleSync() =>
      WidgetsBinding.instance.addPostFrameCallback((_) => _syncQuery());

  /// URL → state (homepage SearchBar deep link / refresh).
  void _syncQuery() {
    if (!mounted) return;
    final k = widget.initialKeyword ?? '';
    if (_keyword.text != k) _keyword.text = k;
    ref
        .read(jobsSearchProvider.notifier)
        .applyQuery(
          keyword: widget.initialKeyword,
          location: widget.initialLocation,
        );
  }

  @override
  void dispose() {
    _scroll.removeListener(_onScroll);
    _scroll.dispose();
    _keyword.dispose();
    super.dispose();
  }

  JobsSearchViewModel get _vm => ref.read(jobsSearchProvider.notifier);

  /// Form submit: persist keyword + sync ?q&location (shareable URL).
  Future<void> _submit() async {
    final s = ref.read(jobsSearchProvider);
    await _vm.submitSearch();
    if (!mounted) return;
    final q = <String, String>{
      if (s.keyword.trim().isNotEmpty) 'q': s.keyword.trim(),
      if (s.locationQuery.isNotEmpty) 'location': s.locationQuery,
    };
    final uri = Uri(
      path: AppRoutes.jobs,
      queryParameters: q.isEmpty ? null : q,
    );
    final current = GoRouterState.of(context).uri;
    if (current.toString() != uri.toString()) context.go(uri.toString());
  }

  void _reset() {
    _vm.resetAll();
    _keyword.clear();
    final current = GoRouterState.of(context).uri;
    if (current.hasQuery) context.go(AppRoutes.jobs);
  }

  /// AIScoreModal onScored: the sheet resolves with `jobId → {ai, sql}` as
  /// soon as a scoring run finished in it (even when closed with 'Đóng').
  Future<void> _openAiMatching() async {
    final jobs = ref.read(jobsSearchProvider).filtered;
    final scores = await showAiMatchingSheet(context, jobs: jobs);
    if (!mounted) return;
    if (scores != null) _vm.applyScores(scores);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobsSearchProvider);
    final savedIds =
        ref.watch(savedJobIdsProvider).valueOrNull ?? const <String>{};
    final appliedIds =
        ref.watch(appliedJobIdsProvider).valueOrNull ?? const <String>{};

    final header = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobsSearchHeader(
          state: state,
          keywordController: _keyword,
          onKeywordChanged: _vm.setKeyword,
          onLocationChanged: _vm.setLocation,
          onSearchTypeChanged: _vm.setSearchType,
          onSubmit: _submit,
          onHome: () => context.go(AppRoutes.home),
        ),
        if (state.loading || state.error != null)
          PageContainer(
            child: Padding(
              padding: const EdgeInsets.only(top: 20),
              child: state.loading
                  ? const InfoBanner(
                      tone: InfoTone.info,
                      message:
                          'Đang tải thêm các tin tuyển dụng đã được quản trị viên duyệt...',
                    )
                  : InfoBanner(
                      tone: InfoTone.warning,
                      message:
                          '${state.error} Trang hiện vẫn đang hiển thị dữ liệu mẫu.',
                    ),
            ),
          ),
      ],
    );

    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final filterSidebar = JobFilterSidebar(
      filters: state.filters,
      facets: state.facets,
      resultCount: state.displayTotal,
      countFailed: state.countFailed,
      onToggle: _vm.toggleFilter,
      onReset: _reset,
    );
    final sidebar = wide
        ? filterSidebar
        : CollapsibleFilterSidebar(
            sidebar: filterSidebar,
            activeCount: state.filters.flatten().length,
            resultCount: state.displayTotal,
            countFailed: state.countFailed,
          );

    final results = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        JobsResultsToolbar(
          state: state,
          onAiMatching: _openAiMatching,
          onSortChanged: _vm.setSort,
        ),
        const SizedBox(height: 16),
        if (state.hasActiveFilters) ...[
          ActiveFilterChips(
            filters: state.filters,
            onRemove: _vm.removeFilter,
            onClearAll: _reset,
          ),
          const SizedBox(height: 16),
        ],
        if (state.filtered.isEmpty && !state.loading)
          _EmptyResults(onReset: _reset)
        else
          for (final job in state.filtered) ...[
            JobListItem(
              key: ValueKey(job.jobId),
              job: job,
              score: state.scoreOf(job),
              saved: savedIds.contains(job.jobId),
              applied: appliedIds.contains(job.jobId),
              onToggleSave: () => handleToggleSave(context, ref, job),
              onApply: () => _apply(job),
            ),
            const SizedBox(height: 12),
          ],
        // Infinite-scroll feedback: loading dots while fetching the next
        // 20 docs; a quiet "Đã tải hết việc làm" footer once the loaded
        // window matches the server count. Keeps the user from pulling at
        // a dead stream expecting more.
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 3),
              ),
            ),
          )
        else if (state.filtered.isNotEmpty &&
            state.totalCount != null &&
            state.sourceJobs.length >= state.totalCount!)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                'Đã tải hết việc làm',
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.inkMuted,
                ),
              ),
            ),
          ),
      ],
    );

    return PublicLayout(
      scrollable: false,
      scrollController: _scroll,
      child: StickySidebarLayout(
        controller: _scroll,
        header: header,
        sidebar: sidebar,
        body: results,
        sidebarWidth: 288,
        stickyTop: 24,
      ),
    );
  }

  Future<void> _apply(JobModel job) => showApplyModal(context, job);
}

/// `card … px-6 py-16 text-center` with a 64px slate circle + search icon.
class _EmptyResults extends StatelessWidget {
  const _EmptyResults({required this.onReset});
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 64),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: const BoxDecoration(
              color: AppColors.slate100,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search,
              size: 28,
              color: AppColors.inkMuted,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Không tìm thấy việc làm phù hợp',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 448),
            child: const Text(
              'Thử thay đổi từ khoá hoặc bỏ bớt bộ lọc để mở rộng kết quả tìm kiếm.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.inkSoft,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 20),
          OutlinedButton(onPressed: onReset, child: const Text('Xoá bộ lọc')),
        ],
      ),
    );
  }
}
