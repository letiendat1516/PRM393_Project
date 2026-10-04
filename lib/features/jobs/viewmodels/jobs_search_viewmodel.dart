import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
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

  factory JobFacets.from(List<JobModel> jobs) {
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

    return JobFacets(
      categories: sorted(cat),
      cities: sorted(city),
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

  static const pageSize = AppConfig.pageSize;

  // ── derived (lazy, computed once per state instance) ─────────────────
  late final JobFacets facets = JobFacets.from(sourceJobs);
  late final List<JobModel> filtered = _computeFiltered();

  /// When a client-side-only filter / search is active the user only sees
  /// matches inside the already-loaded window, so page count follows
  /// [filtered]. For a server-side facet (and the no-filter default) we
  /// trust [totalCount] so the pager still reads '… 274 275' for Hà Nội.
  late final int totalPages = isServerSideFacet
      ? (((totalCount ?? sourceJobs.length)) / pageSize).ceil()
      : (hasSearchContext || hasActiveFilters)
          ? (filtered.length / pageSize).ceil()
          : (((totalCount ?? filtered.length)) / pageSize).ceil();
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

  /// displayTotal: filtered count while a client-side-only filter / search
  /// is active, else the server-reported total — including the server-side
  /// facet case where [totalCount] already matches '2.744 việc làm ở
  /// Hà Nội' instead of the 30 docs cached locally.
  int get displayTotal {
    if (isServerSideFacet) return totalCount ?? sourceJobs.length;
    if (hasSearchContext || hasActiveFilters) return filtered.length;
    return totalCount ?? sourceJobs.length;
  }

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
  }

  final JobsRepository repository;
  final PrefsService prefs;
  StreamSubscription<List<JobModel>>? _sub;
  String _subscribedKeyword = '';
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

  /// Runs the Firestore `.count()` aggregation for the active keyword +
  /// facet and stashes it in `state.totalCount`. The id guard drops late
  /// responses when the user has already changed the keyword again.
  Future<void> _fetchTotalCount(String keyword, JobsServerFilter filter) async {
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
      state = state.copyWith(totalCount: n);
    } catch (_) {
      // Count failure is non-fatal — fall back to the loaded-chunk size.
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
  }

  // ── search ───────────────────────────────────────────────────────────
  void setKeyword(String v) {
    if (v == state.keyword) return;
    state = state.copyWith(keyword: v, page: 1);
  }

  void setLocation(String v) {
    if (v == state.locationQuery) return;
    state = state.copyWith(locationQuery: v, page: 1);
  }

  void setSearchType(JobSearchType t) {
    if (t == state.searchType) return;
    state = state.copyWith(searchType: t, page: 1);
  }

  /// Form submit: remember the keyword (SharedPreferences lastSearchKeywords)
  /// AND re-open the Firestore stream with the trimmed keyword so the
  /// titleTokens `arrayContainsAny` filter kicks in. A keyword change
  /// resets the loaded window back to the 3-page default and re-runs the
  /// count aggregation so the pager header matches the new result set.
  Future<void> submitSearch() async {
    final trimmed = state.keyword.trim();
    if (trimmed != _subscribedKeyword) {
      state = state.copyWith(
        loading: true,
        loadedLimit: JobsRepository.defaultChunk,
        totalCount: null,
        page: 1,
      );
      final filter = _serverFilter();
      final target = _desiredLimit();
      state = state.copyWith(loadedLimit: target);
      _resubscribe(trimmed, target, filter);
      _fetchTotalCount(trimmed, filter);
    }
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
      totalCount: null,
    );
    _resubscribe('', JobsRepository.defaultChunk, _noServerFilter);
    _fetchTotalCount('', _noServerFilter);
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
      // Symmetric with submitSearch/resetAll: the old totalCount describes
      // the previous facet's scope — drop it instead of flashing a stale
      // '2.800 việc làm' header (permanently stale if the aggregation
      // fails) until the fresh count lands.
      totalCount: filterChanged ? null : _sentinel,
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
