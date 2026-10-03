import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/applications_repository.dart';

export '../data/applications_repository.dart' show applicationsRepositoryProvider;

/// Backend list limit (applicationValidator: limit default 10).
const kApplicationsPageSize = 10;

enum ApplicationSort { newest, oldest }

extension ApplicationSortLabel on ApplicationSort {
  String get label => switch (this) {
        ApplicationSort.newest => 'Mới nhất',
        ApplicationSort.oldest => 'Cũ nhất',
      };
}

/// The 4 statuses exposed by the application module (filter dropdowns).
const List<ApplicationStatus> kExposedStatuses = [
  ApplicationStatus.submitted,
  ApplicationStatus.underReview,
  ApplicationStatus.accepted,
  ApplicationStatus.rejected,
];

/// A filtered page (items + meta) — mirrors `{ data, meta: {total,page,limit} }`.
class PagedApplications {
  const PagedApplications({
    required this.items,
    required this.total,
    required this.page,
    this.limit = kApplicationsPageSize,
  });

  final List<ApplicationModel> items;
  final int total;
  final int page;
  final int limit;

  int get totalPages => total == 0 ? 1 : ((total - 1) ~/ limit) + 1;
  bool get hasPrev => page > 1;
  bool get hasNext => page * limit < total;

  static PagedApplications paginate(List<ApplicationModel> all, int page, int limit) {
    final total = all.length;
    final pages = total == 0 ? 1 : ((total - 1) ~/ limit) + 1;
    final p = page.clamp(1, pages);
    final start = (p - 1) * limit;
    final end = (start + limit).clamp(0, total);
    return PagedApplications(
      items: start >= total ? const [] : all.sublist(start, end),
      total: total,
      page: p,
      limit: limit,
    );
  }
}

int _byDate(ApplicationModel a, ApplicationModel b, ApplicationSort sort) {
  final da = a.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
  final db = b.applicationDate ?? DateTime.fromMillisecondsSinceEpoch(0);
  return sort == ApplicationSort.newest ? db.compareTo(da) : da.compareTo(db);
}

// ── appliedJobIds (cross-feature contract) ─────────────────────────────

/// Set of jobIds the signed-in seeker has applied to (empty for others).
final appliedJobIdsProvider = StreamProvider<Set<String>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null || !me.isJobSeeker) return Stream.value(const <String>{});
  return ref.watch(applicationsRepositoryProvider).watchAppliedJobIds(me.uid);
});

// ── Seeker list (MyApplicationsPage) ───────────────────────────────────

class MyApplicationsFilter {
  const MyApplicationsFilter({
    this.status,
    this.keyword = '',
    this.sort = ApplicationSort.newest,
    this.page = 1,
  });

  final ApplicationStatus? status;
  final String keyword;
  final ApplicationSort sort;
  final int page;

  MyApplicationsFilter copyWith({
    ApplicationStatus? status,
    bool clearStatus = false,
    String? keyword,
    ApplicationSort? sort,
    int? page,
  }) =>
      MyApplicationsFilter(
        status: clearStatus ? null : (status ?? this.status),
        keyword: keyword ?? this.keyword,
        sort: sort ?? this.sort,
        page: page ?? this.page,
      );

  List<ApplicationModel> apply(List<ApplicationModel> all) {
    final kw = keyword.trim().toLowerCase();
    final out = all.where((a) {
      if (status != null && a.status != status) return false;
      if (kw.isNotEmpty) {
        final hay = '${a.jobTitle} ${a.companyName}'.toLowerCase();
        if (!hay.contains(kw)) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => _byDate(a, b, sort));
    return out;
  }
}

/// autoDispose: the web page re-initialises
/// `{page:1,status:'',keyword:'',sort:'newest'}` on every mount.
final myApplicationsFilterProvider =
    StateProvider.autoDispose<MyApplicationsFilter>((_) => const MyApplicationsFilter());

final _myApplicationsRawProvider =
    StreamProvider.autoDispose<List<ApplicationModel>>((ref) {
  final meAsync = ref.watch(currentUserProvider);
  // Stay in `loading` ('Đang tải hồ sơ...') until users/{uid} resolves —
  // a completed empty stream leaves the StreamProvider in AsyncLoading.
  if (meAsync.isLoading && !meAsync.hasValue) return const Stream.empty();
  final me = meAsync.valueOrNull;
  if (me == null) return Stream.value(const []);
  return ref.watch(applicationsRepositoryProvider).watchMine(me.uid);
});

/// Filtered + sorted + paginated seeker list (live).
final myApplicationsProvider = Provider.autoDispose<AsyncValue<PagedApplications>>((ref) {
  final filter = ref.watch(myApplicationsFilterProvider);
  return ref.watch(_myApplicationsRawProvider).whenData(
        (all) => PagedApplications.paginate(filter.apply(all), filter.page, kApplicationsPageSize),
      );
});

// ── Detail (seeker + employer) ─────────────────────────────────────────

final applicationDetailProvider =
    StreamProvider.autoDispose.family<ApplicationModel?, String>((ref, id) {
  return ref.watch(applicationsRepositoryProvider).watchOne(id);
});

final statusHistoryProvider = StreamProvider.autoDispose
    .family<List<ApplicationStatusHistoryItem>, String>((ref, id) {
  return ref.watch(applicationsRepositoryProvider).watchHistory(id);
});

/// Application with its statusHistory attached (both streams combined).
final applicationWithHistoryProvider =
    Provider.autoDispose.family<AsyncValue<ApplicationModel?>, String>((ref, id) {
  final app = ref.watch(applicationDetailProvider(id));
  final history = ref.watch(statusHistoryProvider(id));
  if (app.hasError) return AsyncValue.error(app.error!, app.stackTrace!);
  if (app.isLoading) return const AsyncValue.loading();
  final value = app.valueOrNull;
  if (value == null) return const AsyncValue.data(null);
  // Web getMine/reviewForEmployer is ONE request: a failed history read
  // fails the page rather than silently rendering only the SUBMITTED node.
  if (history.hasError) return AsyncValue.error(history.error!, history.stackTrace!);
  if (history.isLoading && !history.hasValue) return const AsyncValue.loading();
  final items = history.valueOrNull ?? const <ApplicationStatusHistoryItem>[];
  return AsyncValue.data(value.copyWith(statusHistory: items));
});

/// Latest job_recommendation for (seeker, job) — review "Thông tin phù hợp".
final latestRecommendationProvider = FutureProvider.autoDispose
    .family<JobRecommendation?, ({String seekerUid, String jobId})>((ref, key) {
  return ref
      .watch(applicationsRepositoryProvider)
      .latestRecommendation(key.seekerUid, key.jobId);
});

/// Job document for the apply wizard header.
final applyJobProvider = FutureProvider.autoDispose.family<JobModel?, String>((ref, jobId) {
  return ref.watch(applicationsRepositoryProvider).getJob(jobId);
});

// ── Employer / admin list ──────────────────────────────────────────────

class EmployerApplicationsFilter {
  const EmployerApplicationsFilter({
    this.status,
    this.jobId,
    this.candidateName = '',
    this.submittedFrom,
    this.submittedTo,
    this.sort = ApplicationSort.newest,
    this.page = 1,
  });

  final ApplicationStatus? status;
  final String? jobId;
  final String candidateName;
  final DateTime? submittedFrom;
  final DateTime? submittedTo;
  final ApplicationSort sort;
  final int page;

  EmployerApplicationsFilter copyWith({
    ApplicationStatus? status,
    bool clearStatus = false,
    String? jobId,
    bool clearJobId = false,
    String? candidateName,
    DateTime? submittedFrom,
    bool clearFrom = false,
    DateTime? submittedTo,
    bool clearTo = false,
    ApplicationSort? sort,
    int? page,
  }) =>
      EmployerApplicationsFilter(
        status: clearStatus ? null : (status ?? this.status),
        jobId: clearJobId ? null : (jobId ?? this.jobId),
        candidateName: candidateName ?? this.candidateName,
        submittedFrom: clearFrom ? null : (submittedFrom ?? this.submittedFrom),
        submittedTo: clearTo ? null : (submittedTo ?? this.submittedTo),
        sort: sort ?? this.sort,
        page: page ?? this.page,
      );

  bool get hasActiveFilters =>
      status != null ||
      jobId != null ||
      candidateName.trim().isNotEmpty ||
      submittedFrom != null ||
      submittedTo != null;

  List<ApplicationModel> apply(List<ApplicationModel> all) {
    final name = candidateName.trim().toLowerCase();
    final from = submittedFrom == null
        ? null
        : DateTime(submittedFrom!.year, submittedFrom!.month, submittedFrom!.day);
    // `${submittedTo}T23:59:59.999Z` ⇒ inclusive end of day.
    final to = submittedTo == null
        ? null
        : DateTime(submittedTo!.year, submittedTo!.month, submittedTo!.day, 23, 59, 59, 999);
    final out = all.where((a) {
      if (status != null && a.status != status) return false;
      if (jobId != null && a.jobId != jobId) return false;
      if (name.isNotEmpty && !a.candidateFullName.toLowerCase().contains(name)) return false;
      final d = a.applicationDate;
      if (from != null && (d == null || d.isBefore(from))) return false;
      if (to != null && (d == null || d.isAfter(to))) return false;
      return true;
    }).toList()
      ..sort((a, b) => _byDate(a, b, sort));
    return out;
  }
}

final employerApplicationsFilterProvider =
    StateProvider<EmployerApplicationsFilter>((_) => const EmployerApplicationsFilter());

final _employerApplicationsRawProvider =
    StreamProvider.autoDispose<List<ApplicationModel>>((ref) {
  final meAsync = ref.watch(currentUserProvider);
  // Web shows 'Đang tải...' first — never flash the empty card while
  // users/{uid} is still loading.
  if (meAsync.isLoading && !meAsync.hasValue) return const Stream.empty();
  final me = meAsync.valueOrNull;
  if (me == null || !(me.isEmployer || me.isAdmin)) return Stream.value(const []);
  // admin ⇒ employerId null ⇒ every employer's applications.
  return ref
      .watch(applicationsRepositoryProvider)
      .watchForEmployer(me.isAdmin ? null : me.uid);
});

/// Filtered + sorted + paginated employer/admin list (live).
final employerApplicationsProvider =
    Provider.autoDispose<AsyncValue<PagedApplications>>((ref) {
  final filter = ref.watch(employerApplicationsFilterProvider);
  return ref.watch(_employerApplicationsRawProvider).whenData(
        (all) => PagedApplications.paginate(filter.apply(all), filter.page, kApplicationsPageSize),
      );
});

/// Distinct (jobId, jobTitle) pairs for the employer "job" filter dropdown.
final employerApplicationJobOptionsProvider =
    Provider.autoDispose<List<({String jobId, String jobTitle})>>((ref) {
  final all = ref.watch(_employerApplicationsRawProvider).valueOrNull ?? const [];
  final seen = <String, String>{};
  for (final a in all) {
    seen.putIfAbsent(a.jobId, () => a.jobTitle);
  }
  final list = seen.entries.map((e) => (jobId: e.key, jobTitle: e.value)).toList()
    ..sort((a, b) => a.jobTitle.toLowerCase().compareTo(b.jobTitle.toLowerCase()));
  return list;
});
