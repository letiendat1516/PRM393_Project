import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/features/jobs/viewmodels/jobs_search_viewmodel.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';

/// JobsSearchState — các thuộc tính derive của lazy pagination:
/// totalPages tin totalCount server khi không filter, tin filtered khi filter;
/// displayTotal tương tự; currentPage/pageJobs hoạt động trên cửa sổ đã load.
void main() {
  JobModel mk(String id, {String title = 'Flutter Developer'}) => JobModel(
        jobId: id,
        employerId: 'emp-$id',
        employerName: 'Công ty $id',
        jobTitle: title,
      );

  List<JobModel> many(int n) => [for (var i = 1; i <= n; i++) mk('j$i')];

  test('pageSize contract = 10 (AppConfig.pageSize)', () {
    expect(JobsSearchState.pageSize, 10);
  });

  group('totalPages', () {
    test('không filter + totalCount=9800 + loadedLimit=30 → 980 trang (không phải 3)', () {
      final s = JobsSearchState(sourceJobs: many(30), totalCount: 9800);
      expect(s.totalPages, 980, reason: 'ceil(9800/10) — dựa trên totalCount server');
    });

    test('không filter + totalCount=null → dựa trên số doc đã load', () {
      final s = JobsSearchState(sourceJobs: many(30), totalCount: null);
      expect(s.totalPages, 3);
    });

    test('filter active + filtered.length=5 → đúng 1 trang, bỏ qua totalCount', () {
      final s = JobsSearchState(
        sourceJobs: many(30),
        keyword: 'j2', // match j2, j20..j29 → >5; dùng filter hẹp hơn ở dưới
        totalCount: 9800,
      );
      expect(s.hasActiveFilters || s.hasSearchContext, isTrue);
      expect(s.totalPages, (s.filtered.length / 10).ceil(), reason: 'đếm trên filtered');

      final s1 = JobsSearchState(
        sourceJobs: many(30),
        keyword: 'không-tồn-tại',
        totalCount: 9800,
      );
      expect(s1.filtered, isEmpty);
      expect(s1.totalPages, 0);
    });

    test('filter active với đúng 5 kết quả → 1 trang', () {
      // 30 job, keyword khớp đúng 5 (j3, j13, j23, j30... đặt title riêng).
      final jobs = [
        for (var i = 1; i <= 25; i++) mk('j$i'),
        for (var i = 1; i <= 5; i++) mk('hit$i', title: 'Nodejs Hot $i'),
      ];
      final s = JobsSearchState(sourceJobs: jobs, keyword: 'Hot', totalCount: 9800);
      expect(s.filtered.length, 5);
      expect(s.totalPages, 1);
    });
  });

  group('displayTotal', () {
    test('không filter: trả totalCount khi có', () {
      final s = JobsSearchState(sourceJobs: many(30), totalCount: 9800);
      expect(s.displayTotal, 9800);
    });

    test('không filter + totalCount null: trả sourceJobs.length', () {
      final s = JobsSearchState(sourceJobs: many(30), totalCount: null);
      expect(s.displayTotal, 30);
    });

    test('filter active: trả filtered.length kể cả khi totalCount đã set', () {
      final jobs = [
        for (var i = 1; i <= 25; i++) mk('j$i'),
        for (var i = 1; i <= 5; i++) mk('hit$i', title: 'Nodejs Hot $i'),
      ];
      final s = JobsSearchState(sourceJobs: jobs, keyword: 'Hot', totalCount: 9800);
      expect(s.displayTotal, 5);
    });
  });

  group('currentPage clamp', () {
    test('page vượt quá totalPages → kẹp về totalPages', () {
      final s = JobsSearchState(sourceJobs: many(25), page: 999, totalCount: null);
      expect(s.totalPages, 3);
      expect(s.currentPage, 3);
    });

    test('page 0 → kẹp về 1', () {
      final s = JobsSearchState(sourceJobs: many(25), page: 0, totalCount: null);
      expect(s.currentPage, 1);
    });

    test('totalPages 0 (không kết quả) → currentPage = 1', () {
      final s = JobsSearchState(sourceJobs: many(3), keyword: 'không-match', totalCount: null);
      expect(s.totalPages, 0);
      expect(s.currentPage, 1);
    });

    test('page hợp lệ giữ nguyên', () {
      final s = JobsSearchState(sourceJobs: many(25), page: 2, totalCount: null);
      expect(s.currentPage, 2);
    });
  });

  group('pageJobs', () {
    test('lấy đúng 10 item tại vị trí (currentPage-1)*pageSize', () {
      final s = JobsSearchState(sourceJobs: many(25), page: 2, totalCount: null);
      expect(s.pageJobs.length, 10);
      expect(s.pageJobs.first.jobId, 'j11');
      expect(s.pageJobs.last.jobId, 'j20');
    });

    test('trang cuối lấy phần còn dư', () {
      final s = JobsSearchState(sourceJobs: many(25), page: 3, totalCount: null);
      expect(s.pageJobs.length, 5);
      expect(s.pageJobs.first.jobId, 'j21');
      expect(s.pageJobs.last.jobId, 'j25');
    });

    test('keyword lọc trước khi phân trang', () {
      final jobs = [
        for (var i = 1; i <= 30; i++) mk('j$i'),
        for (var i = 1; i <= 12; i++) mk('hit$i', title: 'Nodejs Hot $i'),
      ];
      final s = JobsSearchState(sourceJobs: jobs, keyword: 'Hot', page: 2);
      expect(s.filtered.length, 12);
      expect(s.pageJobs.length, 2);
      expect(s.pageJobs.map((j) => j.jobId).toList(), ['hit11', 'hit12']);
    });
  });

  group('hasSearchContext / effectiveSort / canUseAiMatching', () {
    test('hasSearchContext đúng theo keyword + locationQuery (trim)', () {
      expect(JobsSearchState(sourceJobs: const []).hasSearchContext, isFalse);
      expect(
        JobsSearchState(sourceJobs: const [], keyword: '  ').hasSearchContext,
        isFalse,
        reason: 'chỉ khoảng trắng → không tính là search',
      );
      expect(JobsSearchState(sourceJobs: const [], keyword: 'a').hasSearchContext, isTrue);
      expect(
        JobsSearchState(sourceJobs: const [], locationQuery: 'Hà Nội').hasSearchContext,
        isTrue,
      );
    });

    test("effectiveSort: 'aiScore' không hợp lệ khi chưa có score → về 'posted'", () {
      final s = JobsSearchState(sourceJobs: many(5), sort: 'aiScore');
      expect(s.hasScores, isFalse);
      expect(s.effectiveSort, 'posted');
    });

    test('canUseAiMatching: 0 < filtered ≤ 100', () {
      expect(JobsSearchState(sourceJobs: many(5)).canUseAiMatching, isTrue);
      expect(JobsSearchState(sourceJobs: many(101)).canUseAiMatching, isFalse);
      expect(
        JobsSearchState(sourceJobs: many(5), keyword: 'không-match').canUseAiMatching,
        isFalse,
      );
    });
  });

  group('copyWith giữ sentinel semantics cho totalCount/aiScores', () {
    test('copyWith không truyền totalCount → giữ giá trị cũ', () {
      final s = JobsSearchState(sourceJobs: many(5), totalCount: 9800);
      expect(s.copyWith(page: 2).totalCount, 9800);
    });

    test('copyWith totalCount: null → xoá về null (reset khi đổi keyword)', () {
      final s = JobsSearchState(sourceJobs: many(5), totalCount: 9800);
      expect(s.copyWith(totalCount: null).totalCount, isNull);
    });
  });
}
