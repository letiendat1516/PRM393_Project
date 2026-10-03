import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/data/demo_data.dart';
import '../../../core/providers.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';

/// Homepage "Top companies" card data — unifies live `employerProfiles`
/// (isVerified) with the verbatim mock `DemoData.topCompanies`.
class TopCompanyItem {
  const TopCompanyItem({
    required this.id,
    required this.name,
    required this.industry,
    required this.location,
    required this.openPositions,
    required this.size,
    required this.initials,
    required this.cover,
    this.brand,
    this.logoUrl,
    this.isLive = false,
  });

  final String id;
  final String name;
  final String industry;
  final String location;
  final int openPositions;
  final String size;
  final String initials;
  /// Asset path of the cover photo.
  final String cover;
  /// Tailwind brand string from the mock data ('bg-orange-50 text-orange-600').
  final String? brand;
  final String? logoUrl;
  /// true → backed by a Firestore employer (has a /cong-ty/:id page).
  final bool isLive;

  factory TopCompanyItem.fromDemo(TopCompany c) => TopCompanyItem(
        id: c.id,
        name: c.name,
        industry: c.industry,
        location: c.location,
        openPositions: c.openPositions,
        size: c.size,
        initials: c.initials,
        cover: c.cover,
        brand: c.brand,
      );

  static const _covers = [
    'assets/images/company-office.jpg',
    'assets/images/team-meeting.jpg',
    'assets/images/team-collab.jpg',
  ];

  factory TopCompanyItem.fromEmployer(EmployerProfile e, int index) {
    final display = CompanyDisplay.of(e.companyName);
    String nonEmpty(String? v, String fallback) =>
        (v == null || v.trim().isEmpty) ? fallback : v.trim();
    return TopCompanyItem(
      id: e.uid,
      name: display.name,
      industry: nonEmpty(e.industry, 'Doanh nghiệp đã xác thực'),
      location: nonEmpty(e.city, 'Việt Nam'),
      openPositions: e.openPositions,
      size: nonEmpty(e.companySize, 'Đang cập nhật quy mô'),
      initials: display.initials,
      cover: _covers[index % _covers.length],
      logoUrl: e.logoUrl,
      isLive: true,
    );
  }
}

/// Firestore access for the landing page (HomePage.jsx data sources).
class HomeRepository {
  HomeRepository(this._refs);
  final FirestoreRefs _refs;

  /// Size of the live window ranked by [pickFeaturedJobs] (HomePage.jsx ranks
  /// the whole `mockJobs` pool; a few pages of newest public jobs is plenty).
  static const int featuredPoolLimit = 30;

  /// Public jobs (isApproved && OPEN) newest first — a [featuredPoolLimit]
  /// window — merged with the verbatim mock pool `DemoData.sampleJobs()`
  /// (`mockJobs` in HomePage.jsx) and ranked by [pickFeaturedJobs] down to
  /// [AppConfig.listPreviewLimit] cards.
  Stream<List<JobModel>> watchFeaturedJobs({int limit = AppConfig.listPreviewLimit}) {
    return _refs
        .jobs()
        .where('isApproved', isEqualTo: true)
        .where('status', isEqualTo: 'OPEN')
        .orderBy('createdAt', descending: true)
        .limit(featuredPoolLimit)
        .snapshots()
        .map((s) => mergeWithDemo(s.docs.map((d) => d.data()).toList(), limit: limit))
        .handleError((Object e) => throw Failure.from(e));
  }

  /// Pure merge helper (also used by the error fallback in the view):
  /// `pickFeaturedJobs([...live, ...DemoData.sampleJobs()])`, de-duplicated by
  /// jobId (live wins).
  static List<JobModel> mergeWithDemo(List<JobModel> live, {int limit = AppConfig.listPreviewLimit}) {
    final pool = <JobModel>[];
    final seen = <String>{};
    for (final j in live) {
      if (seen.add(j.jobId)) pool.add(j);
    }
    for (final j in DemoData.sampleJobs()) {
      if (seen.add(j.jobId)) pool.add(j);
    }
    return pickFeaturedJobs(pool, count: limit);
  }

  /// HomePage.jsx `pickFeaturedJobs(pool, count = 6)`:
  /// - empty pool → the static `featuredJobs` sample (data/jobs.js);
  /// - rank hot first (`salaryMax >= 50tr`), then `salaryMax` desc (stable:
  ///   ties keep pool order, like `[...pool].sort(...)`);
  /// - pick one job per category until [count] (diversity);
  /// - top up with the next best ranked jobs; `slice(0, count)`.
  static List<JobModel> pickFeaturedJobs(List<JobModel> pool, {int count = AppConfig.listPreviewLimit}) {
    if (pool.isEmpty) return DemoData.featuredJobs().take(count).toList();

    final indexed = [for (var i = 0; i < pool.length; i++) (i, pool[i])];
    indexed.sort((a, b) {
      final hot = (b.$2.hot ? 1 : 0) - (a.$2.hot ? 1 : 0);
      if (hot != 0) return hot;
      final salary = ((b.$2.salaryMax ?? 0) - (a.$2.salaryMax ?? 0));
      if (salary != 0) return salary > 0 ? 1 : -1;
      return a.$1 - b.$1;
    });
    final ranked = [for (final e in indexed) e.$2];

    final seen = <String>{};
    final picked = <JobModel>[];
    for (final j in ranked) {
      final key = (j.categoryName ?? '').trim().toLowerCase();
      if (!seen.add(key)) continue;
      picked.add(j);
      if (picked.length >= count) break;
    }
    for (final j in ranked) {
      if (picked.length >= count) break;
      if (!picked.contains(j)) picked.add(j);
    }
    return picked.take(count).toList();
  }

  /// Verified + active employers (max 3); falls back to `DemoData.topCompanies`
  /// when none exist yet. Both filters are equality `where`s (no orderBy) so
  /// the query needs no composite index.
  Stream<List<TopCompanyItem>> watchTopCompanies({int limit = 3}) {
    return _refs
        .employerProfiles()
        .where('isVerified', isEqualTo: true)
        .where('isActive', isEqualTo: true)
        .limit(limit * 2)
        .snapshots()
        .map((s) {
          final live = s.docs
              .map((d) => d.data())
              .where((e) => e.isActive && e.companyName.trim().isNotEmpty)
              .take(limit)
              .toList();
          if (live.isEmpty) return demoTopCompanies();
          return [
            for (var i = 0; i < live.length; i++) TopCompanyItem.fromEmployer(live[i], i),
          ];
        })
        .handleError((Object e) => throw Failure.from(e));
  }

  static List<TopCompanyItem> demoTopCompanies() =>
      DemoData.topCompanies.map(TopCompanyItem.fromDemo).toList();
}

final homeRepositoryProvider = Provider<HomeRepository>(
  (ref) => HomeRepository(ref.watch(firestoreRefsProvider)),
);
