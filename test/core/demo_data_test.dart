import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/data/demo_data.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';

/// Tests for [DemoData] sample/featured jobs and the merge performed by
/// AdminRepository.seedDemoData.
///
/// Verified against the actual code (not the original task text):
/// - DemoData.sampleJobs() has 12 jobs SYN-00001..SYN-00012 (the task's
///   "18" figure is the *merged* seedDemoData total: 12 sample + 6 featured).
/// - DemoData.sampleEmployers() derives 12 distinct employers from
///   sampleJobs(); seedDemoData adds 6 more from featuredJobs() → 18 total.
/// - JobModel.hot is *derived*: (salaryMax ?? 0) >= 50,000,000. The literal
///   `hot` flag passed to DemoData.featuredJobs()'s private helper is ignored.
void main() {
  group('DemoData.sampleJobs', () {
    final jobs = DemoData.sampleJobs();

    test('returns exactly 12 jobs (task brief said 18 — actual code: 12)', () {
      expect(jobs.length, 12);
    });

    test(r'every jobId matches ^SYN-\d{5}$ and ids are unique SYN-00001..12', () {
      final idPattern = RegExp(r'^SYN-\d{5}$');
      for (final j in jobs) {
        expect(j.jobId, matches(idPattern), reason: 'bad id: ${j.jobId}');
      }
      final ids = jobs.map((j) => j.jobId).toList();
      expect(ids.toSet().length, 12, reason: 'ids must be unique');
      expect(ids, [for (var i = 1; i <= 12; i++) 'SYN-${i.toString().padLeft(5, '0')}']);
    });

    test('every job is approved, open and public', () {
      for (final j in jobs) {
        expect(j.isApproved, isTrue, reason: '${j.jobId} not approved');
        expect(j.status, JobStatus.open, reason: '${j.jobId} not open');
        expect(j.isPublic, isTrue, reason: '${j.jobId} not public');
      }
    });

    test('employerId is non-empty, demo-employer-1..12, and covered by sampleEmployers()', () {
      final seededEmployerIds = DemoData.sampleEmployers().map((e) => e.id).toSet();
      for (final j in jobs) {
        expect(j.employerId, isNotEmpty, reason: '${j.jobId} has empty employerId');
        expect(seededEmployerIds, contains(j.employerId),
            reason: '${j.jobId} employer ${j.employerId} not in sampleEmployers()');
      }
      expect(jobs.map((j) => j.employerId).toSet().length, 12,
          reason: '12 distinct employer ids expected');
      expect(
        jobs.map((j) => j.employerId).toSet(),
        {for (var i = 1; i <= 12; i++) 'demo-employer-$i'},
      );
    });

    test('every applicationDeadline is in the future and no job is expired', () {
      // deadline = nowAtBuild.add(30 - daysAgo); max daysAgo is 7 (SYN-00005),
      // so every deadline is >= ~23 days ahead of "now" at test time.
      final now = DateTime.now();
      for (final j in jobs) {
        expect(j.applicationDeadline, isNotNull, reason: '${j.jobId} has no deadline');
        expect(j.applicationDeadline!.isAfter(now), isTrue,
            reason: '${j.jobId} deadline not in the future');
        expect(j.isExpired, isFalse, reason: '${j.jobId} is expired');
        expect(j.acceptsApplications, isTrue,
            reason: '${j.jobId} does not accept applications');
      }
    });
  });

  group('DemoData.featuredJobs', () {
    final jobs = DemoData.featuredJobs();

    test(r'returns exactly 6 jobs with unique ^jb-\d{3}$ ids', () {
      expect(jobs.length, 6);
      final idPattern = RegExp(r'^jb-\d{3}$');
      for (final j in jobs) {
        expect(j.jobId, matches(idPattern), reason: 'bad id: ${j.jobId}');
      }
      expect(jobs.map((j) => j.jobId).toSet().length, 6);
    });

    test('every job is public', () {
      for (final j in jobs) {
        expect(j.isPublic, isTrue, reason: '${j.jobId} not public');
      }
    });

    test('hot matches jobMapper rule salaryMax >= 50,000,000 for every job', () {
      for (final j in jobs) {
        final expectedHot = (j.salaryMax ?? 0) >= 50000000;
        expect(j.hot, expectedHot,
            reason:
                '${j.jobId} hot=${j.hot} but salaryMax=${j.salaryMax} implies $expectedHot');
      }
    });

    test('spot-check hot: jb-001 (55M) hot, jb-002 (55M) hot, jb-004 (65M) hot', () {
      // jb-001 / jb-002 were bumped from 40M/50M → 55M to match the
      // originally-intended "hot" badge from the web source — the dead
      // `bool hot` closure parameter was removed in the same change.
      final byId = {for (final j in jobs) j.jobId: j};
      expect(byId['jb-001']!.salaryMax, 55000000);
      expect(byId['jb-001']!.hot, isTrue,
          reason: 'jb-001 max 55M >= 50M → hot');
      expect(byId['jb-002']!.salaryMax, 55000000);
      expect(byId['jb-002']!.hot, isTrue, reason: 'jb-002 max 55M >= 50M → hot');
      expect(byId['jb-004']!.salaryMax, 65000000);
      expect(byId['jb-004']!.hot, isTrue, reason: 'jb-004 max 65M >= 50M → hot');
    });

    test('employerIds are the 6 distinct demo-fs/mm/sh/vt/vng/gr', () {
      expect(
        jobs.map((j) => j.employerId).toSet(),
        {'demo-fs', 'demo-mm', 'demo-sh', 'demo-vt', 'demo-vng', 'demo-gr'},
      );
    });
  });

  group('seedDemoData merge ([...sampleJobs, ...featuredJobs])', () {
    final jobs = [...DemoData.sampleJobs(), ...DemoData.featuredJobs()];

    test('totals 18 jobs with 18 unique jobIds', () {
      expect(jobs.length, 18);
      expect(jobs.map((j) => j.jobId).toSet().length, 18);
    });

    test('totals 18 unique employerIds: 12 sample + 6 featured, disjoint', () {
      final sampleIds = DemoData.sampleJobs().map((j) => j.employerId).toSet();
      final featuredIds = DemoData.featuredJobs().map((j) => j.employerId).toSet();
      expect(sampleIds.length, 12);
      expect(featuredIds.length, 6);
      expect(sampleIds.intersection(featuredIds), isEmpty,
          reason: 'sample and featured employer ids must not overlap');
      final allIds = jobs.map((j) => j.employerId).toSet();
      expect(allIds.length, 18);
      expect(allIds, sampleIds.union(featuredIds));
    });

    test('every job employerId is covered by the 18 seeded employer records', () {
      final seededIds = {
        ...DemoData.sampleEmployers().map((e) => e.id),
        ...DemoData.featuredJobs().map((j) => j.employerId),
      };
      expect(seededIds.length, 18);
      for (final j in jobs) {
        expect(seededIds, contains(j.employerId),
            reason: '${j.jobId} employer ${j.employerId} has no seeded profile');
      }
    });
  });

  group('DemoData.sampleEmployers', () {
    final employers = DemoData.sampleEmployers();

    test('returns exactly 12 employers with unique ids', () {
      expect(employers.length, 12);
      expect(employers.map((e) => e.id).toSet().length, 12);
    });

    test('name/city/industry are non-empty (category is a required param in sampleJobs)', () {
      // `category` is required in the sampleJobs() builder, so categoryName is
      // never null there and industry (categoryName ?? '') is never empty.
      for (final e in employers) {
        expect(e.id, isNotEmpty);
        expect(e.name, isNotEmpty, reason: '${e.id} has empty name');
        expect(e.city, isNotEmpty, reason: '${e.id} has empty city');
        expect(e.industry, isNotEmpty, reason: '${e.id} has empty industry');
      }
    });

    test('each employer id matches exactly one sample job employerId', () {
      final jobs = DemoData.sampleJobs();
      for (final e in employers) {
        expect(jobs.where((j) => j.employerId == e.id).length, 1,
            reason: '${e.id} should map to exactly one sample job');
      }
    });
  });

  group('DemoData.categories', () {
    test('has >= 18 (exactly 18) unique, non-empty entries', () {
      expect(DemoData.categories.length, greaterThanOrEqualTo(18));
      expect(DemoData.categories.length, 18);
      expect(DemoData.categories.toSet().length, 18, reason: 'categories must be unique');
      for (final c in DemoData.categories) {
        expect(c.trim(), isNotEmpty);
      }
    });
  });
}
