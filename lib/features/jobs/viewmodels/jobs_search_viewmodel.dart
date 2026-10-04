import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../data/jobs_facet_catalog.dart';
import '../data/jobs_repository.dart';

// ─────────────────────────────────────────────────────────────────────────
// Option lists (JobFilterSidebar.jsx / JobsPage.jsx constants)
// ─────────────────────────────────────────────────────────────────────────

enum JobSearchType {
  both('Cả hai'),
  title('Tên việc làm'),
  company('Tên công ty');

  const JobSearchType(this.label);
  final String label;
}

enum JobFilterKey {
  categories,
  cities,
  salary,
  experience,
  jobLevel,
  workMode,
  jobType,
}

class FilterOption {
  const FilterOption(this.value, this.label);
  final String value;
  final String label;
}

class JobFilterOptions {
  const JobFilterOptions._();

  static const experience = [
    FilterOption('INTERN', 'Không yêu cầu'),
    FilterOption('FRESHER', 'Dưới 1 năm'),
    FilterOption('JUNIOR', '1 - 2 năm'),
    FilterOption('MID', '2 - 4 năm'),
    FilterOption('SENIOR', '5 năm'),
    FilterOption('LEAD', 'Trên 5 năm'),
  ];

  static const workMode = [
    FilterOption('ONSITE', 'Tại văn phòng'),
    FilterOption('HYBRID', 'Lai hybrid'),
    FilterOption('REMOTE', 'Từ xa (Remote)'),
  ];

  /// JobFilterSidebar.jsx JOB_TYPE_OPTIONS (3 entries — no CONTRACT facet).
  static const jobType = [
    FilterOption('FULL_TIME', 'Toàn thời gian'),
    FilterOption('PART_TIME', 'Bán thời gian'),
    FilterOption('INTERNSHIP', 'Thực tập'),
  ];

  static const jobLevel = [
    FilterOption('Nhân viên', 'Nhân viên'),
    FilterOption('Trưởng nhóm', 'Trưởng nhóm'),
    FilterOption('Trưởng phòng', 'Trưởng / Phó phòng'),
    FilterOption('Quản lý', 'Quản lý / Giám sát'),
    FilterOption('Giám đốc', 'Giám đốc / Phó giám đốc'),
    FilterOption('Thực tập sinh', 'Thực tập sinh'),
  ];

  static List<FilterOption> get salary => [
    for (final b in AppConfig.salaryBands) FilterOption(b.key, b.label),
  ];

  /// Human label for an active-filter chip.
  static String labelFor(JobFilterKey key, String value) {
    List<FilterOption>? opts;
    switch (key) {
      case JobFilterKey.categories:
      case JobFilterKey.cities:
        return value;
      case JobFilterKey.salary:
        opts = salary;
      case JobFilterKey.experience:
        opts = experience;
      case JobFilterKey.jobLevel:
        opts = jobLevel;
      case JobFilterKey.workMode:
        opts = workMode;
      case JobFilterKey.jobType:
        opts = jobType;
    }
    for (final o in opts) {
      if (o.value == value) return o.label;
    }
    return value;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// State
// ─────────────────────────────────────────────────────────────────────────

class JobsFilters {
  const JobsFilters({
    this.categories = const {},
    this.cities = const {},
    this.salary = const {},
    this.experience = const {},
    this.jobLevel = const {},
    this.workMode = const {},
    this.jobType = const {},
  });

  final Set<String> categories;
  final Set<String> cities;
  final Set<String> salary;
  final Set<String> experience;
  final Set<String> jobLevel;
  final Set<String> workMode;
  final Set<String> jobType;

  Set<String> of(JobFilterKey k) => switch (k) {
    JobFilterKey.categories => categories,
    JobFilterKey.cities => cities,
    JobFilterKey.salary => salary,
    JobFilterKey.experience => experience,
    JobFilterKey.jobLevel => jobLevel,
    JobFilterKey.workMode => workMode,
    JobFilterKey.jobType => jobType,
  };

  JobsFilters replace(JobFilterKey k, Set<String> v) => JobsFilters(
    categories: k == JobFilterKey.categories ? v : categories,
    cities: k == JobFilterKey.cities ? v : cities,
    salary: k == JobFilterKey.salary ? v : salary,
    experience: k == JobFilterKey.experience ? v : experience,
    jobLevel: k == JobFilterKey.jobLevel ? v : jobLevel,
    workMode: k == JobFilterKey.workMode ? v : workMode,
    jobType: k == JobFilterKey.jobType ? v : jobType,
  );

  bool get isEmpty => JobFilterKey.values.every((k) => of(k).isEmpty);
  bool get isNotEmpty => !isEmpty;

  /// flattenFilters(): ordered (key, value) pairs for the chip row.
  List<(JobFilterKey, String)> flatten() => [
    for (final k in JobFilterKey.values)
      for (final v in of(k)) (k, v),
  ];
}

/// buildFacets(): option lists derived from the dataset.
class JobFacets {
  const JobFacets({
    this.categories = const [],
    this.cities = const [],
    this.levelCounts = const {},
  });

  /// (name, count) sorted by count desc.
  final List<(String, int)> categories;
  final List<(String, int)> cities;

  /// jobMapper experience label → count.
  final Map<String, int> levelCounts;

  factory JobFacets.from(
    List<JobModel> jobs, {
    Map<String, int>? serverCategoryCounts,
    Map<String, int>? serverCityCounts,
  }) {
    final cat = <String, int>{};
    final city = <String, int>{};
    final lvl = <String, int>{};
    for (final j in jobs) {
      final c = JobsSearchState.categoryOf(j);
      final l = JobsSearchState.locationOf(j);
      cat[c] = (cat[c] ?? 0) + 1;
      city[l] = (city[l] ?? 0) + 1;
      final e = j.experienceLevel.jobMapperLabel;
      lvl[e] = (lvl[e] ?? 0) + 1;
    }
    List<(String, int)> sorted(Map<String, int> m) {
      final list = [for (final e in m.entries) (e.key, e.value)];
      _stableSort(list, (a, b) => b.$2.compareTo(a.$2));
      return list;
    }

    // Server counts override loaded-window counts so the sidebar advertises
    // "Backend Developer (200)" instead of the local 30-doc slice. Values the
    // server didn't aggregate still fall back to the loaded-window count so
    // long-tail buckets stay visible as the user scrolls (fixes the
    // complaint "9800 job nhưng filter tổng vào mới được 36 jobs").
    final effectiveCat = <String, int>{...cat};
    if (serverCategoryCounts != null) {
      effectiveCat.addAll(serverCategoryCounts);
    }
    final effectiveCity = <String, int>{...city};
    if (serverCityCounts != null) {
      effectiveCity.addAll(serverCityCounts);
    }

    return JobFacets(
      categories: sorted(effectiveCat),
      cities: sorted(effectiveCity),
      levelCounts: lvl,
    );
  }
}

class JobsSearchState {
  JobsSearchState({
    required this.sourceJobs,
    this.loading = true,
    this.error,
    this.keyword = '',
    this.locationQuery = '',
    this.searchType = JobSearchType.both,
    this.filters = const JobsFilters(),
    this.sort = 'posted',
    this.page = 1,
    this.aiScores,
    this.loadedLimit = JobsRepository.defaultChunk,
    this.totalCount,
    this.isLoadingMore = false,
    this.countFailed = false,
    this.serverCategoryCounts,
    this.serverCityCounts,
  });

  /// Mock + database jobs (mergeJobs output).
  final List<JobModel> sourceJobs;
  final bool loading;
  final String? error;
  final String keyword;
  final String locationQuery;
  final JobSearchType searchType;
  final JobsFilters filters;
  final String sort;
  final int page;

  /// jobId → score adopted from the AI Matching run of this visit
  /// (JobsPage.jsx `useState(null)`: never pre-populated from stored sessions).
  final Map<String, JobScore>? aiScores;

  /// How many docs the current Firestore stream is asking for. Starts at
  /// [JobsRepository.defaultChunk] (3 pages × pageSize) so the first paint
  /// is cheap; bumped by [JobsSearchViewModel.setPage] when the user asks
  /// for a page past the loaded window.
  final int loadedLimit;

  /// Full count from Firestore `.count()` for the current keyword — drives
  /// the total-pages header even while only [loadedLimit] docs are loaded.
  /// Null until the first aggregation query returns.
  final int? totalCount;

  /// True while [JobsSearchViewModel] is resubscribing to a larger limit
  /// after a deep page-jump — used by the UI to disable rapid re-clicks.
  final bool isLoadingMore;

  /// True after `_fetchTotalCount` has exhausted its retries without a
  /// successful response (e.g. Firestore `.count()` misconfigured, missing
  /// composite index, offline). The widgets switch from "đang đếm…" to a
  /// terminal "— việc làm" placeholder so the UI doesn't hang on a loading
  /// spinner forever when counting will never succeed.
  final bool countFailed;

  /// Server-side `.count()` per categoryName for the current keyword,
  /// scoped by [JobsFacetCatalog.categories]. Null until the first
  /// aggregation lands; populated keys override the loaded-window counts
  /// in the sidebar so "Backend Developer (200)" replaces "(30)".
  final Map<String, int>? serverCategoryCounts;

  /// Same contract as [serverCategoryCounts] but for the `city` field,
  /// scoped by [JobsFacetCatalog.cities].
  final Map<String, int>? serverCityCounts;

  static const pageSize = AppConfig.pageSize;

  // ── derived (lazy, computed once per state instance) ─────────────────
  late final JobFacets facets = JobFacets.from(
    sourceJobs,
    serverCategoryCounts: serverCategoryCounts,
    serverCityCounts: serverCityCounts,
  );
  late final List<JobModel> filtered = _computeFiltered();

  /// Pure client-side scope ⇒ page count follows the loaded window via
  /// [filtered]. For every server-scoped case (server-side facet, keyword
  /// alone, or no filter at all) [totalCount] is authoritative. Returns 0
  /// while the server count is in flight — the UI hides the pager instead
  /// of silently showing "trang 1 / 3" built from the 30-doc window.
  late final int totalPages = _isClientSideScope
      ? (filtered.length / pageSize).ceil()
      : totalCount == null
          ? 0
          : (totalCount! / pageSize).ceil();
  late final int currentPage = totalPages == 0 ? 1 : page.clamp(1, totalPages);
  late final List<JobModel> pageJobs = filtered
      .skip((currentPage - 1) * pageSize)
      .take(pageSize)
      .toList();

  bool get hasScores => aiScores != null && aiScores!.isNotEmpty;

  /// 'aiScore' is only valid while scores exist.
  String get effectiveSort => sort == 'aiScore' && !hasScores ? 'posted' : sort;

  bool get hasSearchContext =>
      keyword.trim().isNotEmpty || locationQuery.trim().isNotEmpty;

  /// Chips row + 'Xoá tất cả' visibility (hasActiveFilters()).
  bool get hasActiveFilters => filters.isNotEmpty;

  /// True when the active filter is exactly ONE chip from
  /// {cities, workMode, jobType, categories} — in which case
  /// [JobsRepository] already scopes the stream *and* the aggregation count
  /// server-side, so [totalCount] reflects the full matching subset
  /// (e.g. 200 Backend Developer jobs, 2744 Hà Nội jobs) instead of only the
  /// loaded 30-doc window.
  bool get isServerSideFacet {
    final chips = filters.flatten();
    if (chips.length != 1) return false;
    final (key, value) = chips.first;
    // Match the fallback sentinels in [JobsSearchViewModel._serverFilter]: the
    // 'Chưa cập nhật' / 'Ngành nghề khác' buckets are UI synthetic labels, not
    // Firestore field values, so chip ∧ facet don't actually agree server-side.
    if (key == JobFilterKey.cities && value == 'Chưa cập nhật') return false;
    if (key == JobFilterKey.categories && value == 'Ngành nghề khác') {
      return false;
    }
    return key == JobFilterKey.cities ||
        key == JobFilterKey.workMode ||
        key == JobFilterKey.jobType ||
        key == JobFilterKey.categories;
  }

  /// Pure client-side scope ⇒ visible slice of the loaded window
  /// ([filtered.length]). Every other scope — server-side facet, keyword
  /// alone, no filter — surfaces the Firestore `.count()` so the header
  /// reads 9.800 / 2.744 / 899 instead of 30 → 60 → 90 climbing with the
  /// loaded chunk. Null while the first count request is in flight; the
  /// widgets render "đang đếm…" instead of substituting the loaded window.
  int? get displayTotal {
    if (_isClientSideScope) return filtered.length;
    return totalCount;
  }

  /// True when the current scope narrows jobs with filters the Firestore
  /// stream does NOT see — a multi-chip combination, a non-hoistable chip
  /// ('Ngành nghề khác' / 'Chưa cập nhật'), or the free-text locationQuery.
  /// In that case [filtered.length] is the honest answer (bounded by the
  /// loaded window, which is a known tradeoff of client-side filtering).
  /// Everything else is scoped by Firestore + `.count()`, so [totalCount]
  /// is authoritative — no fallback to the loaded window.
  bool get _isClientSideScope {
    if (isServerSideFacet) return false;
    if (locationQuery.trim().isNotEmpty) return true;
    // Must check _hasEffectiveFilters, NOT hasActiveFilters — the jobLevel
    // chip is a display-only facet (see _computeFiltered: it's deliberately
    // skipped). If jobLevel is the only chip set, filtered == sourceJobs
    // == loaded window, and switching to "filtered.length" would
    // reproduce the exact 30→60→90 climbing bug the fix is trying to kill.
    if (!_hasEffectiveFilters) return false;
    return true;
  }

  /// Filters that _computeFiltered actually narrows the result list by.
  /// Excludes jobLevel (display-only; dropped in the useMemo at line ~449).
  bool get _hasEffectiveFilters =>
      filters.categories.isNotEmpty ||
      filters.cities.isNotEmpty ||
      filters.salary.isNotEmpty ||
      filters.experience.isNotEmpty ||
      filters.workMode.isNotEmpty ||
      filters.jobType.isNotEmpty;

  /// AI Matching button gating: 0 < filtered ≤ 100.
  bool get canUseAiMatching =>
      filtered.isNotEmpty && filtered.length <= AppConfig.aiMaxJobsPerScoring;

  List<SortOption> get sortOptions => [
    for (final o in AppConfig.sortOptions)
      if (o.key != 'aiScore' || hasScores) o,
  ];

  JobScore? scoreOf(JobModel j) => aiScores?[j.jobId];

  // ── jobMapper display fallbacks ──────────────────────────────────────
  //
  // Facet grouping now goes through `city` first. The old `location ?? city`
  // priority meant jobs whose employer form had a free-text `location`
  // (e.g. "Quận 1, HCM") showed up under a chip the Firestore server-side
  // city filter couldn't match — the sidebar reported "9" results that
  // became 0 after you tapped it.
  static String locationOf(JobModel j) {
    final city = j.city.trim();
    if (city.isNotEmpty) return city;
    final loc = j.location?.trim() ?? '';
    return loc.isNotEmpty ? loc : 'Chưa cập nhật';
  }

  static String categoryOf(JobModel j) {
    final c = j.categoryName?.trim() ?? '';
    return c.isNotEmpty ? c : 'Ngành nghề khác';
  }

  static bool negotiableOf(JobModel j) =>
      j.isSalaryNegotiable || (j.salaryMin == null && j.salaryMax == null);

  // ── filtering (JobsPage.jsx useMemo) ─────────────────────────────────
  List<JobModel> _computeFiltered() {
    final kw = keyword.trim().toLowerCase();
    final loc = locationQuery.trim().toLowerCase();

    var result = sourceJobs.where((j) {
      if (kw.isNotEmpty) {
        final title = j.jobTitle.toLowerCase();
        final company = j.employerName.toLowerCase();
        final all =
            '${j.jobTitle} ${j.employerName} ${categoryOf(j)} ${j.tags.join(' ')}'
                .toLowerCase();
        switch (searchType) {
          case JobSearchType.title:
            if (!title.contains(kw)) return false;
          case JobSearchType.company:
            if (!company.contains(kw)) return false;
          case JobSearchType.both:
            if (!all.contains(kw)) return false;
        }
      }
      final location = locationOf(j);
      if (loc.isNotEmpty && !location.toLowerCase().contains(loc)) return false;
      if (filters.categories.isNotEmpty &&
          !filters.categories.contains(categoryOf(j))) {
        return false;
      }
      if (filters.cities.isNotEmpty && !filters.cities.contains(location)) {
        return false;
      }
      if (filters.experience.isNotEmpty &&
          !filters.experience.contains(enumToWire(j.experienceLevel))) {
        return false;
      }
      if (filters.workMode.isNotEmpty &&
          !filters.workMode.contains(enumToWire(j.workMode))) {
        return false;
      }
      if (filters.jobType.isNotEmpty &&
          !filters.jobType.contains(enumToWire(j.jobType))) {
        return false;
      }
      // NOTE: jobLevel is a display-only facet on the web too (never applied).
      if (!_salaryMatches(j, filters.salary)) return false;
      return true;
    }).toList();

    switch (effectiveSort) {
      case 'posted':
        _stableSort(
          result,
          (a, b) =>
              _postedDays(a.createdAt).compareTo(_postedDays(b.createdAt)),
        );
      case 'updated':
        _stableSort(
          result,
          (a, b) => _postedDays(
            a.updatedAt ?? a.createdAt,
          ).compareTo(_postedDays(b.updatedAt ?? b.createdAt)),
        );
      case 'urgent':
        _stableSort(result, (a, b) => (b.hot ? 1 : 0) - (a.hot ? 1 : 0));
      case 'salaryDesc':
        num maxOf(JobModel j) =>
            negotiableOf(j) ? 0 : (j.salaryMax ?? j.salaryMin ?? 0);
        _stableSort(result, (a, b) => maxOf(b).compareTo(maxOf(a)));
      case 'aiScore':
        int s(JobModel j) => aiScores?[j.jobId]?.matchScore ?? -1;
        _stableSort(result, (a, b) => s(b).compareTo(s(a)));
    }
    return result;
  }

  /// salaryMatches(): overlap of the job's range with any selected band;
  /// 'negotiable' matches jobs without salary.
  static bool _salaryMatches(JobModel j, Set<String> bands) {
    if (bands.isEmpty) return true;
    final negotiable = negotiableOf(j);
    for (final key in bands) {
      if (key == 'negotiable') {
        if (negotiable) return true;
        continue;
      }
      if (negotiable) continue;
      final band = AppConfig.salaryBands.where((b) => b.key == key).firstOrNull;
      if (band == null) continue;
      final lo = band.min;
      final hi = band.max;
      final jobMax = j.salaryMax ?? j.salaryMin ?? 0;
      final jobMin = j.salaryMin ?? 0;
      if ((lo == null || jobMax >= lo) && (hi == null || jobMin <= hi)) {
        return true;
      }
    }
    return false;
  }

  /// parsePostedDays(postedText): "N ngày" → N, "N tuần" → 7N, "tháng" → 30.
  static int _postedDays(DateTime? d) {
    final t = Formatters.postedText(d).toLowerCase();
    var m = RegExp(r'(\d+)\s*ngày').firstMatch(t);
    if (m != null) return int.parse(m.group(1)!);
    m = RegExp(r'(\d+)\s*tuần').firstMatch(t);
    if (m != null) return int.parse(m.group(1)!) * 7;
    if (t.contains('tháng')) return 30;
    return 0;
  }

  JobsSearchState copyWith({
    List<JobModel>? sourceJobs,
    bool? loading,
    Object? error = _sentinel,
    String? keyword,
    String? locationQuery,
    JobSearchType? searchType,
    JobsFilters? filters,
    String? sort,
    int? page,
    Object? aiScores = _sentinel,
    int? loadedLimit,
    Object? totalCount = _sentinel,
    bool? isLoadingMore,
    bool? countFailed,
    Object? serverCategoryCounts = _sentinel,
    Object? serverCityCounts = _sentinel,
  }) => JobsSearchState(
    sourceJobs: sourceJobs ?? this.sourceJobs,
    loading: loading ?? this.loading,
    error: identical(error, _sentinel) ? this.error : error as String?,
    keyword: keyword ?? this.keyword,
    locationQuery: locationQuery ?? this.locationQuery,
    searchType: searchType ?? this.searchType,
    filters: filters ?? this.filters,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    aiScores: identical(aiScores, _sentinel)
        ? this.aiScores
        : aiScores as Map<String, JobScore>?,
    loadedLimit: loadedLimit ?? this.loadedLimit,
    totalCount: identical(totalCount, _sentinel)
        ? this.totalCount
        : totalCount as int?,
    isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    countFailed: countFailed ?? this.countFailed,
    serverCategoryCounts: identical(serverCategoryCounts, _sentinel)
        ? this.serverCategoryCounts
        : serverCategoryCounts as Map<String, int>?,
    serverCityCounts: identical(serverCityCounts, _sentinel)
        ? this.serverCityCounts
        : serverCityCounts as Map<String, int>?,
  );
}

const _sentinel = Object();

/// JS Array.prototype.sort is stable; Dart's List.sort is not.
void _stableSort<T>(List<T> list, int Function(T, T) cmp) {
  final indexed = List.generate(list.length, (i) => (i, list[i]));
  indexed.sort((a, b) {
    final c = cmp(a.$2, b.$2);
    return c != 0 ? c : a.$1.compareTo(b.$1);
  });
  for (var i = 0; i < list.length; i++) {
    list[i] = indexed[i].$2;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// ViewModel
// ─────────────────────────────────────────────────────────────────────────

/// The single facet (if any) currently pushed down to Firestore — see
/// [JobsSearchViewModel._serverFilter].
typedef JobsServerFilter = ({
  String? city,
  WorkMode? workMode,
  JobType? jobType,
  String? categoryName,
});

class JobsSearchViewModel extends StateNotifier<JobsSearchState> {
  JobsSearchViewModel({required this.repository, required this.prefs})
    : super(
        JobsSearchState(sourceJobs: JobsRepository.mergeWithMocks(const [])),
      ) {
    _resubscribe('', state.loadedLimit, _noServerFilter);
    _fetchTotalCount('', _noServerFilter);
    _fetchFacetCounts('');
  }

  final JobsRepository repository;
  final PrefsService prefs;
  StreamSubscription<List<JobModel>>? _sub;
  String _subscribedKeyword = '';

  /// Debounces live-search typing so every keystroke doesn't open a new
  /// Firestore subscription. 350 ms matches the TopCV search bar's perceived
  /// responsiveness without flooding the aggregation query.
  Timer? _keywordDebounce;
  static const Duration _keywordDebounceDelay = Duration(milliseconds: 350);
  int _subscribedLimit = 0;
  int _countRequestId = 0;

  /// The facet currently applied by the Firestore subscription (mirrors
  /// [_subscribedKeyword]/[_subscribedLimit]); compared against
  /// [_serverFilter] by [_reconcileSubscription].
  JobsServerFilter _subscribedFilter = _noServerFilter;

  /// Sentinel "no facet hoisted" — every filter stays client-side.
  static const JobsServerFilter _noServerFilter = (
    city: null,
    workMode: null,
    jobType: null,
    categoryName: null,
  );

  /// Hoists the filter state into a Firestore `.where()` when it is EXACTLY
  /// one hoistable facet value (city | workMode | jobType | categoryName)
  /// and nothing else is selected. Multi-facet, or any salary / experience /
  /// jobLevel chip alongside, returns [_noServerFilter] so those combos keep
  /// filtering the loaded window client-side — the composite indexes only
  /// cover one facet at a time, and pulling all 9800 docs for exact
  /// multi-facet counts OOMs the Android debug heap. Category hoisting
  /// matters because the catalogue has 49 real categories ("Backend
  /// Developer", "Content Marketing" …) with ~200 jobs each; without
  /// pushing the filter down a single chip would otherwise only match the
  /// 30-doc loaded window, so users saw "2 việc làm" when the server has
  /// hundreds.
  JobsServerFilter _serverFilter() {
    final flat = state.filters.flatten();
    if (flat.length != 1) return _noServerFilter;
    final (key, value) = flat.single;
    return switch (key) {
      // 'Chưa cập nhật' is JobsSearchState.locationOf's fallback for jobs
      // with neither location nor city — no Firestore `city` document holds
      // that literal, so hoisting it would return 0 server hits for a chip
      // the sidebar may advertise with a count. Keep it client-side.
      JobFilterKey.cities when value == 'Chưa cập nhật' => _noServerFilter,
      JobFilterKey.cities => (
        city: value,
        workMode: null,
        jobType: null,
        categoryName: null,
      ),
      JobFilterKey.workMode => (
        city: null,
        workMode: parseWorkMode(value),
        jobType: null,
        categoryName: null,
      ),
      JobFilterKey.jobType => (
        city: null,
        workMode: null,
        jobType: parseJobType(value),
        categoryName: null,
      ),
      // Same fallback story as cities — the chip "Ngành nghề khác" is
      // JobsSearchState.categoryOf's bucket for jobs without a categoryName,
      // which never appears as a Firestore value, so keep that one client-
      // side and let every real category hoist cleanly.
      JobFilterKey.categories when value == 'Ngành nghề khác' => _noServerFilter,
      JobFilterKey.categories => (
        city: null,
        workMode: null,
        jobType: null,
        categoryName: value,
      ),
      _ => _noServerFilter,
    };
  }

  /// Re-opens the Firestore stream when the search keyword, the loaded
  /// chunk size or the hoisted server-side facet changes. Passing [limit]
  /// explicitly lets [setPage] grow the window lazily without touching
  /// keyword semantics.
  void _resubscribe(String keyword, int limit, JobsServerFilter filter) {
    _sub?.cancel();
    _subscribedKeyword = keyword;
    _subscribedLimit = limit;
    _subscribedFilter = filter;
    _sub = repository
        .watchPublicJobs(
          keyword: keyword,
          city: filter.city,
          workMode: filter.workMode,
          jobType: filter.jobType,
          categoryName: filter.categoryName,
          limit: limit,
        )
        .listen(_onJobs, onError: _onError);
  }

  /// Parallel `.count()` for every canonical category + top-city, scoped
  /// by [keyword] so the sidebar reflects the search context. Runs on
  /// view-model init and after keyword changes; drops stale responses via
  /// [_facetRequestId] so the user typing fast only ever lands the newest
  /// counts. Non-fatal — any failure keeps the previous server counts.
  int _facetRequestId = 0;
  Future<void> _fetchFacetCounts(String keyword) async {
    final id = ++_facetRequestId;
    try {
      final results = await Future.wait([
        repository.aggregateFacetCounts(
          field: 'categoryName',
          values: JobsFacetCatalog.categories,
          keyword: keyword,
        ),
        repository.aggregateFacetCounts(
          field: 'city',
          values: JobsFacetCatalog.cities,
          keyword: keyword,
        ),
      ]);
      if (!mounted || id != _facetRequestId) return;
      state = state.copyWith(
        serverCategoryCounts: results[0],
        serverCityCounts: results[1],
      );
    } catch (_) {
      // Keep whatever server counts we last saw.
    }
  }

  /// Runs the Firestore `.count()` aggregation for the active keyword +
  /// facet and stashes it in `state.totalCount`. The id guard drops late
  /// responses when the user has already changed the keyword again.
  /// Callers null out `totalCount` BEFORE calling this so the UI shows
  /// "đang đếm…"; on terminal failure after 2 retries we set
  /// `countFailed: true` so widgets can switch to a "— việc làm"
  /// terminal state instead of hanging on the loading placeholder.
  Future<void> _fetchTotalCount(
    String keyword,
    JobsServerFilter filter, {
    int attempt = 0,
  }) async {
    final id = ++_countRequestId;
    try {
      final n = await repository.countPublicJobs(
        keyword: keyword,
        city: filter.city,
        workMode: filter.workMode,
        jobType: filter.jobType,
        categoryName: filter.categoryName,
      );
      if (!mounted || id != _countRequestId) return;
      state = state.copyWith(totalCount: n, countFailed: false);
    } catch (e, st) {
      // Make the failure observable — the previous swallow-with-no-log
      // meant a misconfigured .count() permanently showed 30/60 instead of
      // the real total and nothing in the dev log told us why.
      debugPrint(
        'countPublicJobs failed for "$keyword" / $filter (attempt $attempt): $e\n$st',
      );
      if (!mounted || id != _countRequestId) return;
      if (attempt < 2) {
        // Short backoff retry; totalCount stays null so the UI keeps the
        // "đang đếm…" placeholder.
        final delay = Duration(milliseconds: 500 * (attempt + 1));
        Future.delayed(delay, () {
          if (!mounted || id != _countRequestId) return;
          _fetchTotalCount(keyword, filter, attempt: attempt + 1);
        });
        return;
      }
      // Final failure: flip to the terminal UI state so widgets stop
      // showing the loading placeholder and render "— việc làm" instead
      // (vs. hanging on "đang đếm…" forever).
      state = state.copyWith(countFailed: true);
    }
  }

  void _onJobs(List<JobModel> jobs) {
    if (!mounted) return;
    // Mocks are a "Firestore empty / barely seeded" fallback; the moment
    // the user is actively searching — or a server-side facet narrowed the
    // stream — we trust the server result as-is so "0 kết quả" stays 0 and
    // facet counts stay exact instead of being padded with 12 SYN demo rows.
    final merged =
        (_subscribedKeyword.isNotEmpty || _subscribedFilter != _noServerFilter)
        ? jobs.where((j) => j.jobId.isNotEmpty && j.isPublic).toList()
        : JobsRepository.mergeWithMocks(jobs);
    // Keep only scores that still point at a job of the dataset.
    Map<String, JobScore>? scores = state.aiScores;
    if (scores != null) {
      final ids = {for (final j in merged) j.jobId};
      scores = {
        for (final e in scores.entries)
          if (ids.contains(e.key)) e.key: e.value,
      };
    }
    state = state.copyWith(
      sourceJobs: merged,
      loading: false,
      isLoadingMore: false,
      error: null,
      aiScores: scores,
    );
  }

  void _onError(Object e) {
    if (!mounted) return;
    // Backend failure on the web keeps showing the sample data.
    state = state.copyWith(loading: false, error: Failure.from(e).message);
  }

  /// Re-subscribe after an error (RouteErrorView 'Thử lại').
  void retry() {
    state = state.copyWith(loading: true, error: null);
    _resubscribe(_subscribedKeyword, _subscribedLimit, _subscribedFilter);
    _fetchTotalCount(_subscribedKeyword, _subscribedFilter);
  }

  // ── URL params (?q&location) ─────────────────────────────────────────
  void applyQuery({String? keyword, String? location}) {
    final k = keyword ?? '';
    final l = location ?? '';
    if (k == state.keyword && l == state.locationQuery) return;
    state = state.copyWith(keyword: k, locationQuery: l, page: 1);
    // Deep-linked keywords (homepage SearchBar → /viec-lam?q=java) must hit
    // Firestore immediately — otherwise the stream still returns the first
    // 30 jobs of the whole catalogue and `_computeFiltered` only lands the
    // handful of matches inside that window, which users reported as "sao
    // tổng là 82 mà không phải 9800". Trigger the same resubscribe path as
    // submitSearch, no debounce (URL change is already a user action).
    _applyKeywordSubscription();
  }

  // ── search ───────────────────────────────────────────────────────────
  void setKeyword(String v) {
    if (v == state.keyword) return;
    state = state.copyWith(keyword: v, page: 1);
    // Live-search as the user types: resubscribe to Firestore so the
    // titleTokens arrayContainsAny filter widens the result set from the
    // 30-doc window to the full 9800-doc catalogue. Debounced so the
    // aggregation count doesn't fire on every keystroke.
    _keywordDebounce?.cancel();
    _keywordDebounce = Timer(_keywordDebounceDelay, _applyKeywordSubscription);
  }

  void setLocation(String v) {
    if (v == state.locationQuery) return;
    state = state.copyWith(locationQuery: v, page: 1);
  }

  void setSearchType(JobSearchType t) {
    if (t == state.searchType) return;
    state = state.copyWith(searchType: t, page: 1);
  }

  /// Reopens the Firestore stream with the current keyword + facet so the
  /// result set reflects what the user actually typed. Shared between
  /// [setKeyword] (debounced live-search), [applyQuery] (deep-linked URL
  /// change) and [submitSearch] (form submit); the no-op guard
  /// `trimmed == _subscribedKeyword` keeps same-keystroke rebuilds free.
  void _applyKeywordSubscription() {
    if (!mounted) return;
    final trimmed = state.keyword.trim();
    if (trimmed == _subscribedKeyword) return;
    // Drop the old totalCount — it describes the previous keyword's
    // scope and keeping it would flash the wrong total next to the new
    // filter (e.g. "9.800 việc làm" on a 'java' query that really has
    // ~800 matches). displayTotal now returns null → UI shows
    // "đang đếm…" until the new .count() lands. Safe because displayTotal
    // no longer falls back to sourceJobs.length.
    state = state.copyWith(
      loading: true,
      loadedLimit: JobsRepository.defaultChunk,
      totalCount: null,
      countFailed: false,
      page: 1,
    );
    final filter = _serverFilter();
    final target = _desiredLimit();
    state = state.copyWith(loadedLimit: target);
    _resubscribe(trimmed, target, filter);
    _fetchTotalCount(trimmed, filter);
    // Re-aggregate per-facet counts so the sidebar reflects "N jobs
    // matching this chip under the current keyword", not the loaded window.
    _fetchFacetCounts(trimmed);
  }

  /// Form submit: remember the keyword (SharedPreferences lastSearchKeywords)
  /// AND re-open the Firestore stream so titleTokens arrayContainsAny kicks
  /// in. Cancels any pending debounce so the user's explicit "Tìm" tap is
  /// honoured immediately instead of waiting for the 350ms timer.
  Future<void> submitSearch() async {
    _keywordDebounce?.cancel();
    _applyKeywordSubscription();
    await prefs.pushSearchKeyword(state.keyword);
  }

  // ── filters ──────────────────────────────────────────────────────────
  void toggleFilter(JobFilterKey key, String value) {
    final set = {...state.filters.of(key)};
    if (!set.remove(value)) set.add(value);
    state = state.copyWith(filters: state.filters.replace(key, set), page: 1);
    _reconcileSubscription();
  }

  void removeFilter(JobFilterKey key, String value) {
    final set = {...state.filters.of(key)}..remove(value);
    state = state.copyWith(filters: state.filters.replace(key, set), page: 1);
    _reconcileSubscription();
  }

  /// handleReset(): clears filters, keyword, location and search type.
  void resetAll() {
    state = state.copyWith(
      filters: const JobsFilters(),
      keyword: '',
      locationQuery: '',
      searchType: JobSearchType.both,
      page: 1,
      loadedLimit: JobsRepository.defaultChunk,
      // Drop the previous scope's count — displayTotal returns null so
      // the UI shows "đang đếm…" until the full-catalogue .count() lands.
      totalCount: null,
      countFailed: false,
    );
    _resubscribe('', JobsRepository.defaultChunk, _noServerFilter);
    _fetchTotalCount('', _noServerFilter);
    _fetchFacetCounts('');
  }

  // ── sort / paging ────────────────────────────────────────────────────
  void setSort(String key) {
    if (key == state.sort) return;
    state = state.copyWith(sort: key, page: 1);
  }

  void setPage(int p) {
    final total = state.totalPages == 0 ? 1 : state.totalPages;
    final clamped = p.clamp(1, total);
    state = state.copyWith(page: clamped);
    _reconcileSubscription();
  }

  /// Desired Firestore stream limit for the current state.
  ///
  /// Always based on the current page + a 2-page prefetch buffer, rounded
  /// up to a multiple of [JobsRepository.defaultChunk]. The ceiling is
  /// capped at [_lazyLimitCap] (not [JobsRepository.publicLimit]) so a
  /// direct jump to page 500 doesn't ask Firestore for 5000 docs at once
  /// and OOM the Android debug heap (~200 MB); beyond that the UI silently
  /// clamps to the last reachable page. A single hoisted facet is narrowed
  /// server-side (see [_serverFilter]); everything else stays client-side
  /// on the loaded chunk.
  static const int _lazyLimitCap = 3000;
  int _desiredLimit() {
    const preloadPages = 2;
    final target = (state.page + preloadPages) * JobsSearchState.pageSize;
    const chunk = JobsRepository.defaultChunk;
    final grown = ((target + chunk - 1) ~/ chunk) * chunk;
    return grown.clamp(chunk, _lazyLimitCap);
  }

  /// Resubscribe the Firestore stream iff [_desiredLimit] OR the hoisted
  /// server-side facet changed. Pulls loadedLimit along so derived state
  /// ([JobsSearchState.totalPages], pagination) stays consistent with the
  /// subscription, and re-runs the count aggregation when the facet changed
  /// (e.g. 2800 for 'Hà Nội' instead of 9800 for the whole catalogue).
  void _reconcileSubscription() {
    final filter = _serverFilter();
    final target = _desiredLimit();
    final filterChanged = filter != _subscribedFilter;
    if (!filterChanged && target == _subscribedLimit) return;
    state = state.copyWith(
      loadedLimit: target,
      isLoadingMore: true,
      // On a scope change (filter chip toggled), null out totalCount so
      // the UI switches to "đang đếm…" instead of flashing the previous
      // scope's number (e.g. 9.800 while the Hà Nội count is in flight).
      // On a pure pagination bump (filterChanged=false) we keep totalCount
      // via the sentinel — this is the fix for "lướt trang 3 ghi tổng 60".
      totalCount: filterChanged ? null : _sentinel,
      countFailed: filterChanged ? false : state.countFailed,
    );
    _resubscribe(_subscribedKeyword, target, filter);
    if (filterChanged) {
      _fetchTotalCount(_subscribedKeyword, filter);
    }
  }

  // ── AI scores (JobsPage.jsx onScored) ────────────────────────────────
  /// AIScoreModal `onScored(scoreMap)`: adopt `ai ?? sql` per job (restricted
  /// to the current dataset), switch the sort to 'Độ phù hợp AI (cao→thấp)'
  /// and go back to page 1. [scores] is `jobId → {'ai': …, 'sql': …}`.
  void applyScores(Map<String, Map<String, JobScore>> scores) {
    if (!mounted) return;
    final ids = {for (final j in state.sourceJobs) j.jobId};
    final adopted = <String, JobScore>{};
    for (final e in scores.entries) {
      if (!ids.contains(e.key)) continue;
      final best = e.value['ai'] ?? e.value['sql'];
      if (best != null) adopted[e.key] = best;
    }
    state = state.copyWith(aiScores: adopted, sort: 'aiScore', page: 1);
  }

  @override
  void dispose() {
    _keywordDebounce?.cancel();
    _sub?.cancel();
    super.dispose();
  }
}

final jobsSearchProvider =
    StateNotifierProvider.autoDispose<JobsSearchViewModel, JobsSearchState>((
      ref,
    ) {
      return JobsSearchViewModel(
        repository: ref.watch(jobsRepositoryProvider),
        prefs: ref.watch(prefsServiceProvider),
      );
    });
