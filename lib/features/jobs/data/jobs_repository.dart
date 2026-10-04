import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/demo_data.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';

/// Firestore access for the public job catalogue (JobsPage, JobDetailPage,
/// CompanyDetailPage). Mirrors backend JobRepository.searchJobs public
/// semantics: `isApproved == true && status == 'OPEN'`, `createdAt desc`.
///
/// The web app merges 12 hard-coded sample jobs (data/jobsList.js) into every
/// list and resolves `/viec-lam/:id` mock-first, so the same demo content is
/// served here from [DemoData.sampleJobs].
class JobsRepository {
  JobsRepository(this._refs);
  final FirestoreRefs _refs;

  /// Hard upper bound on a single `watchPublicJobs` fetch. Callers now
  /// drive the actual limit (`JobsSearchViewModel.loadedLimit`, 3 pages
  /// × pageSize) so the initial payload stays small; the total page
  /// count comes from [countPublicJobs] regardless of what is loaded.
  static const int publicLimit = 10000;

  /// Default lazy chunk the ViewModel asks for first. Also the step size
  /// infinite-scroll uses to grow [JobsSearchState.loadedLimit] when the
  /// user reaches the end of the loaded window.
  static const int defaultChunk = 20;

  /// Public employer job list limit (/employers/:id/jobs → limit 100).
  static const int employerLimit = 100;

  Query<JobModel> _publicQuery() => _refs
      .jobs()
      .where('isApproved', isEqualTo: true)
      .where('status', isEqualTo: 'OPEN');

  /// Live list of every public job (approved + OPEN), newest first.
  ///
  /// When [keyword] is non-empty, the stream chains
  /// `where('titleTokens', arrayContainsAny: tokens)` (≤10 tokens, backed by
  /// JobModel.tokenize + the titleTokens index) so searches scale past the
  /// 1000-doc fetch cap. The client-side viewmodel still refines by
  /// city/workMode/jobType/etc.
  ///
  /// At most ONE server-side facet ([city], [workMode] or [jobType]) is
  /// applied via [_applyFacetFilter] so single-facet filtering happens in
  /// Firestore instead of pulling the whole 9800-doc catalogue into the
  /// client (which OOMs the Android debug heap). Everything else stays
  /// client-side on the loaded window.
  Stream<List<JobModel>> watchPublicJobs({
    String keyword = '',
    String? city,
    WorkMode? workMode,
    JobType? jobType,
    String? categoryName,
    int limit = publicLimit,
  }) {
    if (_isUnmatchableKeyword(keyword)) {
      return Stream.value(const <JobModel>[]);
    }
    final tokens = _searchTokens(keyword);
    Query<JobModel> q = _publicQuery();
    if (tokens.isNotEmpty) {
      q = q.where('titleTokens', arrayContainsAny: tokens);
    }
    q = _applyFacetFilter(
      q,
      city: city,
      workMode: workMode,
      jobType: jobType,
      categoryName: categoryName,
    );
    return _guard(
      q
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList()),
    );
  }

  /// Chains EVERY provided equality facet onto [query] in order
  /// `city > workMode > jobType > categoryName`. Any subset of the four
  /// may be combined — the matching composite index must exist in
  /// firestore.indexes.json; the "IT + Hà Nội → 1 job" bug was caused by
  /// the previous ≤1-facet gate forcing the second chip to be applied
  /// client-side against the 20-doc loaded window.
  Query<JobModel> _applyFacetFilter(
    Query<JobModel> query, {
    String? city,
    WorkMode? workMode,
    JobType? jobType,
    String? categoryName,
  }) {
    if (city != null) query = query.where('city', isEqualTo: city);
    if (workMode != null) {
      query = query.where('workMode', isEqualTo: enumToWire(workMode));
    }
    if (jobType != null) {
      query = query.where('jobType', isEqualTo: enumToWire(jobType));
    }
    if (categoryName != null) {
      query = query.where('categoryName', isEqualTo: categoryName);
    }
    return query;
  }

  /// Firestore `arrayContainsAny` caps at 10 operands. We feed it the first
  /// 10 tokenised fragments of the user's keyword (matches titleTokens on
  /// write) plus a short synonym table for common Vietnamese industry /
  /// tech terms so a search for "IT" or "CNTT" surfaces jobs whose titles
  /// use the English role name (Backend / Frontend / DevOps / Developer)
  /// — the synthetic catalogue has 49 categories like "Backend Developer"
  /// and no literal "IT" category, so without expansion generic queries
  /// returned 0–2 matches.
  static List<String> _searchTokens(String keyword) {
    final k = keyword.trim();
    if (k.isEmpty) return const [];
    final base = JobModel.tokenize(k).toList();
    final expanded = <String>{...base};
    for (final t in base) {
      final syn = _searchSynonyms[t];
      if (syn != null) expanded.addAll(syn);
    }
    return expanded.take(10).toList(growable: false);
  }

  /// Keys are already-tokenised fragments (lowercase, no diacritics). Values
  /// are additional tokens to OR into the Firestore `arrayContainsAny` query.
  /// Kept conservative — every entry should map a widely-used generic term
  /// to concrete role words that actually appear in the catalogue.
  static const Map<String, List<String>> _searchSynonyms = {
    'it': ['developer', 'engineer', 'backend', 'frontend', 'devops'],
    'cntt': ['developer', 'engineer', 'backend', 'frontend', 'devops'],
    'lap': ['developer', 'engineer', 'programmer'],
    'trinh': ['developer', 'programmer', 'coder'],
    'kinh': ['sales', 'business'],
    'doanh': ['sales', 'business'],
    'ban': ['sales', 'retail'],
    'nhan': ['hr', 'recruitment'],
    'su': ['hr', 'recruitment'],
    'mar': ['marketing', 'digital', 'content', 'brand'],
    'ke': ['accountant', 'accounting', 'finance'],
    'toan': ['accountant', 'accounting', 'finance'],
  };

  /// True when the user typed something non-empty that [JobModel.tokenize]
  /// cannot turn into a search token (e.g. a single character). Without
  /// this guard the Firestore query drops the `arrayContainsAny` clause
  /// entirely and returns every public job, which to the user looks like
  /// "typed 'c', got 9800 results".
  static bool _isUnmatchableKeyword(String keyword) {
    final trimmed = keyword.trim();
    return trimmed.isNotEmpty && _searchTokens(trimmed).isEmpty;
  }

  /// Full count of public jobs matching [keyword] (and the same single
  /// server-side facet [watchPublicJobs] honours) via Firestore aggregation
  /// (`.count().get()`) — one Firestore read regardless of dataset size.
  /// Used by [JobsSearchViewModel] so the pagination widget can show
  /// 'N việc làm' without paying for a 9800-doc stream when the user only
  /// looks at page 1.
  Future<int> countPublicJobs({
    String keyword = '',
    String? city,
    WorkMode? workMode,
    JobType? jobType,
    String? categoryName,
  }) async {
    if (_isUnmatchableKeyword(keyword)) return 0;
    final tokens = _searchTokens(keyword);
    Query<JobModel> q = _publicQuery();
    if (tokens.isNotEmpty) {
      q = q.where('titleTokens', arrayContainsAny: tokens);
    }
    q = _applyFacetFilter(
      q,
      city: city,
      workMode: workMode,
      jobType: jobType,
      categoryName: categoryName,
    );
    try {
      final agg = await q.count().get();
      return agg.count ?? 0;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Runs a parallel `.count()` for every [values] on a single [field], so
  /// the sidebar can show the real server-side bucket size ("Backend
  /// Developer (200)") instead of the loaded-window count (30 docs = "30").
  /// The current [keyword] funnels through [_searchTokens] so facet totals
  /// stay consistent with the result list when the user has typed a query.
  ///
  /// Returns a map of `value → count`; missing / failed entries drop
  /// silently (0 server hits is indistinguishable from a transient failure
  /// at this layer, and the UI already falls back to the loaded-window
  /// count for anything missing).
  Future<Map<String, int>> aggregateFacetCounts({
    required String field,
    required List<String> values,
    String keyword = '',
  }) async {
    if (_isUnmatchableKeyword(keyword) || values.isEmpty) return const {};
    final tokens = _searchTokens(keyword);
    Future<MapEntry<String, int>?> one(String v) async {
      try {
        Query<JobModel> q = _publicQuery();
        if (tokens.isNotEmpty) {
          q = q.where('titleTokens', arrayContainsAny: tokens);
        }
        q = q.where(field, isEqualTo: v);
        final agg = await q.count().get();
        final n = agg.count ?? 0;
        return n > 0 ? MapEntry(v, n) : null;
      } catch (_) {
        return null;
      }
    }

    final results = await Future.wait(values.map(one));
    return {for (final e in results.whereType<MapEntry<String, int>>()) e.key: e.value};
  }

  /// Mock-first job lookup (JobDetailPage): a sample job short-circuits the
  /// network, otherwise `jobs/{id}` is streamed. Emits `null` when missing —
  /// including when the security rules deny the read (CLOSED / unapproved
  /// job for a non-owner), which the web reports as 404
  /// 'Việc làm bạn tìm không tồn tại hoặc đã bị đóng.' rather than a
  /// permissions error.
  Stream<JobModel?> watchJob(String jobId) {
    final mock = mockJobById(jobId);
    if (mock != null) return Stream.value(mock);
    return _refs
        .jobs()
        .doc(jobId)
        .snapshots()
        .map<JobModel?>((s) => s.data())
        .transform(
          StreamTransformer<JobModel?, JobModel?>.fromHandlers(
            handleError: (e, st, sink) {
              final f = Failure.from(e);
              if (f.code == 'FORBIDDEN' || f.code == 'NOT_FOUND') {
                sink.add(null);
              } else {
                sink.addError(f, st);
              }
            },
          ),
        );
  }

  /// Public jobs of one employer (CompanyDetailPage / related jobs).
  Stream<List<JobModel>> watchEmployerPublicJobs(
    String employerUid, {
    int limit = employerLimit,
  }) {
    if (isDemoEmployer(employerUid)) {
      return Stream.value(
        DemoData.sampleJobs()
            .where((j) => j.employerId == employerUid)
            .toList(),
      );
    }
    return _guard(
      _publicQuery()
          .where('employerId', isEqualTo: employerUid)
          .orderBy('createdAt', descending: true)
          .limit(limit)
          .snapshots()
          .map((s) => s.docs.map((d) => d.data()).toList()),
    );
  }

  /// employerProfiles/{uid}; demo employers are synthesised from the sample
  /// jobs so mock job → company links keep working.
  Stream<EmployerProfile?> watchEmployerProfile(String employerUid) {
    if (isDemoEmployer(employerUid)) {
      return Stream.value(demoEmployerProfile(employerUid));
    }
    return _guard(
      _refs
          .employerProfiles()
          .doc(employerUid)
          .snapshots()
          .map((s) => s.data()),
    );
  }

  // ── Demo helpers ──────────────────────────────────────────────────────

  static bool isDemoEmployer(String uid) => uid.startsWith('demo-');

  static JobModel? mockJobById(String id) {
    for (final j in DemoData.sampleJobs()) {
      if (j.jobId == id) return j;
    }
    return null;
  }

  static EmployerProfile? demoEmployerProfile(String uid) {
    for (final j in DemoData.sampleJobs()) {
      if (j.employerId == uid) {
        return EmployerProfile(
          uid: uid,
          companyName: j.employerName,
          city: j.employerCity ?? j.city,
          industry: j.categoryName,
          logoUrl: j.employerLogoUrl,
          website: j.employerWebsite,
          isVerified: true,
          openPositions: DemoData.sampleJobs()
              .where((x) => x.employerId == uid)
              .length,
        );
      }
    }
    return null;
  }

  /// jobMapper.mergeJobs parity: mock entries first, then database jobs that
  /// are public, de-duplicated by id. Once Firestore has a real dataset
  /// (>= [mockFallbackThreshold] public jobs — e.g. after the crawl-topcv
  /// import), the SYN- mocks are dropped so they don't dilute real results.
  static const int mockFallbackThreshold = 50;

  static List<JobModel> mergeWithMocks(List<JobModel> apiJobs) {
    final publicApi = [
      for (final j in apiJobs)
        if (j.jobId.isNotEmpty && j.isPublic) j,
    ];
    if (publicApi.length >= mockFallbackThreshold) {
      return publicApi;
    }
    final out = <String, JobModel>{};
    for (final m in DemoData.sampleJobs()) {
      out[m.jobId] = m;
    }
    for (final j in publicApi) {
      out.putIfAbsent(j.jobId, () => j);
    }
    return out.values.toList();
  }

  Stream<T> _guard<T>(Stream<T> s) =>
      s.handleError((Object e) => throw Failure.from(e));
}

final jobsRepositoryProvider = Provider<JobsRepository>(
  (ref) => JobsRepository(ref.watch(firestoreRefsProvider)),
);
