// Contract test cho ĐỢT 5 (V15 + V16): single-facet server-side filter.
//
// Bối cảnh: bump loadedLimit lên publicLimit khi filter active để facet chạy
// chuẩn trên 9800 docs → OOM crash (Android debug heap ~200MB). Giải pháp:
// đẩy ĐÚNG MỘT facet (city | workMode | jobType, đúng 1 giá trị) về Firestore
// `.where()` server-side; multi-facet và salary/category/experience/jobLevel
// giữ client-side trên loaded window như cũ.
//
// Ba lớp kiểm tra (tiếp nối pattern jobs_repository_search_test.dart — Đợt 4):
// 1. PHÂN LOẠI (group đầu): chạy `JobsFilters` THẬT (public, thuần Dart) qua
//    decision mirror sao chép 1-1 `_serverFilter()` (private, không gọi được
//    vì khởi tạo ViewModel cần Firestore) — dùng `parseWorkMode`/
//    `parseJobType`/`enumToWire` THẬT nên phần wire round-trip tự drift theo
//    lib. Group này không thực thi code ViewModel nào.
// 2. CONTRACT SOURCE — REPO (V15): đọc `jobs_repository.dart` từ đĩa, khẳng
//    định watch/count nhận 3 facet param, chain `.where(...)` qua
//    `_applyFacetFilter` đúng thứ tự city > workMode > jobType, assert ≤1
//    facet, và guard `_isUnmatchableKeyword` vẫn chạy TRƯỚC facet chain.
// 3. CONTRACT SOURCE — VIEWMODEL (V16): `_serverFilter()` chỉ hoist khi flatten
//    đúng 1 entry thuộc 3 facet hoistable; `_resubscribe`/`_fetchTotalCount`
//    truyền filter qua repo; `_reconcileSubscription` so sánh filter và
//    refetch count khi facet đổi; `_onJobs` bỏ mock khi facet active.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/features/jobs/viewmodels/jobs_search_viewmodel.dart';

// ─────────────────────────────────────────────────────────────────────────
// Helpers (same technique as jobs_repository_search_test.dart)
// ─────────────────────────────────────────────────────────────────────────

/// So sánh source bất kể dart format ngắt dòng/thụt lề: xoá SẠCH whitespace.
String squash(String s) => s.replaceAll(RegExp(r'\s'), '');
bool has(String haystack, String needle) =>
    squash(haystack).contains(squash(needle));
int pos(String haystack, String needle) =>
    squash(haystack).indexOf(squash(needle));

/// Trích member có danh sách tham số (signature kết thúc bằng `(`) bằng balan
/// `()` của param list rồi balan `{}` của thân hàm.
String memberBody(String src, String signature) {
  final start = src.indexOf(signature);
  if (start < 0) return '';
  var i = start + signature.length;
  var depth = 1;
  while (i < src.length && depth > 0) {
    final c = src[i++];
    if (c == '(') depth++;
    if (c == ')') depth--;
  }
  final braceOpen = src.indexOf('{', i);
  if (braceOpen < 0) return src.substring(start);
  var b = braceOpen;
  var bd = 0;
  do {
    final c = src[b++];
    if (c == '{') bd++;
    if (c == '}') bd--;
  } while (b < src.length && bd > 0);
  return src.substring(start, b);
}

/// Trích thân hàm theo header KẾT THÚC bằng ` {` (balan braces thuần) — cho
/// member không tham số hoặc signature ngắn một dòng. Header phải khớp NGUYÊN
/// VĂN source (không squash) — dart format đổi ngắt dòng thì đỏ, chủ đích.
String braceBody(String src, String header) {
  final start = src.indexOf(header);
  if (start < 0) return '';
  var i = start + header.length;
  var depth = 1;
  while (i < src.length && depth > 0) {
    final c = src[i++];
    if (c == '{') depth++;
    if (c == '}') depth--;
  }
  return src.substring(start, i);
}

/// Mirror 1-1 của `JobsSearchViewModel._serverFilter()`
/// (lib/features/jobs/viewmodels/jobs_search_viewmodel.dart): flatten toàn bộ
/// filter state, hoist CHỈ khi đúng 1 (key, value) và key ∈ {cities,
/// workMode, jobType, categories}. categoryName được thêm trong fix search
/// (49 category trong catalogue, mỗi category ~200 jobs — hoist để
/// server-side count accurate thay vì chỉ matching trên 30-doc loaded window).
({String? city, WorkMode? workMode, JobType? jobType, String? categoryName})
mirrorServerFilter(JobsFilters filters) {
  const nulls = (
    city: null,
    workMode: null,
    jobType: null,
    categoryName: null,
  );
  final flat = filters.flatten();
  if (flat.length != 1) return nulls;
  final (key, value) = flat.single;
  return switch (key) {
    // 'Chưa cập nhật' là fallback display (locationOf) cho job thiếu cả
    // location lẫn city — không doc nào có city == chuỗi đó trên Firestore.
    JobFilterKey.cities when value == 'Chưa cập nhật' => nulls,
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
    // 'Ngành nghề khác' là bucket categoryOf() cho job thiếu categoryName —
    // y hệt 'Chưa cập nhật' với city, không doc nào có categoryName == chuỗi
    // đó nên không hoist.
    JobFilterKey.categories when value == 'Ngành nghề khác' => nulls,
    JobFilterKey.categories => (
      city: null,
      workMode: null,
      jobType: null,
      categoryName: value,
    ),
    _ => nulls,
  };
}

const _nulls = (
  city: null,
  workMode: null,
  jobType: null,
  categoryName: null,
);

void main() {
  final repoSrc = File('lib/features/jobs/data/jobs_repository.dart')
      .readAsStringSync();
  final vmSrc = File('lib/features/jobs/viewmodels/jobs_search_viewmodel.dart')
      .readAsStringSync();

  group('phân loại _serverFilter (JobsFilters thật + decision mirror)', () {
    test('đúng 1 city → hoist city, 3 facet còn lại null', () {
      final f = mirrorServerFilter(const JobsFilters(cities: {'Hà Nội'}));
      expect(
        f,
        (city: 'Hà Nội', workMode: null, jobType: null, categoryName: null),
      );
    });

    test('đúng 1 workMode (wire) → hoist enum đã parse', () {
      final f = mirrorServerFilter(const JobsFilters(workMode: {'REMOTE'}));
      expect(
        f,
        (
          city: null,
          workMode: WorkMode.remote,
          jobType: null,
          categoryName: null,
        ),
      );
    });

    test('đúng 1 jobType (wire) → hoist enum đã parse', () {
      final f = mirrorServerFilter(const JobsFilters(jobType: {'FULL_TIME'}));
      expect(
        f,
        (
          city: null,
          workMode: null,
          jobType: JobType.fullTime,
          categoryName: null,
        ),
      );
    });

    test('đúng 1 categoryName → hoist để count server-side (fix "chỉ 2 IT")',
        () {
      final f = mirrorServerFilter(
        const JobsFilters(categories: {'Backend Developer'}),
      );
      expect(
        f,
        (
          city: null,
          workMode: null,
          jobType: null,
          categoryName: 'Backend Developer',
        ),
        reason: 'catalog có 49 category x ~200 jobs — hoist để chip trả về '
            'full subset thay vì chỉ 30-doc loaded window',
      );
    });

    test("chip category 'Ngành nghề khác' → KHÔNG hoist (bucket không có "
        'trên server)', () {
      expect(
        mirrorServerFilter(
          const JobsFilters(categories: {'Ngành nghề khác'}),
        ),
        _nulls,
        reason: 'bucket categoryOf() cho job thiếu categoryName — hoist lên '
            "sẽ where categoryName == 'Ngành nghề khác' → 0 kết quả",
      );
    });

    test('2 city cùng lúc → KHÔNG hoist (multi-value một facet)', () {
      expect(
        mirrorServerFilter(const JobsFilters(cities: {'Hà Nội', 'Đà Nẵng'})),
        _nulls,
        reason: '2 city không có index (isEqualTo AND) — phải lọc client',
      );
    });

    test('city + workMode → KHÔNG hoist (multi-facet)', () {
      expect(
        mirrorServerFilter(
          const JobsFilters(cities: {'Hà Nội'}, workMode: {'REMOTE'}),
        ),
        _nulls,
        reason: 'composite index chỉ cover 1 facet — 2 facet phải client-side',
      );
    });

    test('city + mỗi facet khác → KHÔNG hoist (2 facet composite)', () {
      for (final f in const [
        JobsFilters(cities: {'Hà Nội'}, salary: {'negotiable'}),
        JobsFilters(cities: {'Hà Nội'}, categories: {'Backend Developer'}),
        JobsFilters(cities: {'Hà Nội'}, experience: {'SENIOR'}),
        JobsFilters(cities: {'Hà Nội'}, jobLevel: {'Nhân viên'}),
      ]) {
        expect(
          mirrorServerFilter(f),
          _nulls,
          reason: 'chỉ 1 chip duy nhất mới được hoist — ${f.flatten()}',
        );
      }
    });

    test('đúng 1 chip nhưng thuộc facet không hoist được → nulls', () {
      expect(
        mirrorServerFilter(const JobsFilters(experience: {'FRESHER'})),
        _nulls,
      );
      expect(
        mirrorServerFilter(const JobsFilters(jobLevel: {'Trưởng nhóm'})),
        _nulls,
      );
      expect(
        mirrorServerFilter(const JobsFilters(salary: {'negotiable'})),
        _nulls,
      );
    });

    test('filter rỗng → nulls (không có gì để hoist)', () {
      expect(mirrorServerFilter(const JobsFilters()), _nulls);
    });

    test("chip city sentinel 'Chưa cập nhật' → KHÔNG hoist (0 doc nào có "
        'city == sentinel trên Firestore)', () {
      expect(
        mirrorServerFilter(const JobsFilters(cities: {'Chưa cập nhật'})),
        _nulls,
        reason: 'sentinel là fallback display của locationOf cho job thiếu '
            'cả location lẫn city — hoist lên server sẽ where city == '
            "'Chưa cập nhật' → 0 kết quả cho chip sidebar tự quảng cáo count",
      );
    });

    test('wire round-trip: mọi chip sidebar workMode/jobType parse và '
        'enumToWire ngược về đúng giá trị chip', () {
      // Chuỗi khép kín: chip value → parseWorkMode/parseJobType (viewmodel)
      // → enumToWire (repo where clause) phải về đúng giá trị chip — nếu lệch
      // 1 ký tự thì server .where() match 0 doc.
      for (final o in JobFilterOptions.workMode) {
        final parsed = parseWorkMode(o.value);
        expect(
          enumToWire(parsed),
          o.value,
          reason: 'workMode chip ${o.value} phải round-trip qua enumToWire',
        );
      }
      for (final o in JobFilterOptions.jobType) {
        final parsed = parseJobType(o.value);
        expect(
          enumToWire(parsed),
          o.value,
          reason: 'jobType chip ${o.value} phải round-trip qua enumToWire',
        );
      }
    });

    test('enumToWire khớp wire format JobModel.toJson ghi ra Firestore', () {
      // job_model.dart toJson ghi 'workMode': enumToWire(workMode) và
      // 'jobType': enumToWire(jobType) — repo where phải dùng cùng helper.
      expect(enumToWire(WorkMode.onsite), 'ONSITE');
      expect(enumToWire(WorkMode.remote), 'REMOTE');
      expect(enumToWire(WorkMode.hybrid), 'HYBRID');
      expect(enumToWire(JobType.fullTime), 'FULL_TIME');
      expect(enumToWire(JobType.partTime), 'PART_TIME');
      expect(enumToWire(JobType.internship), 'INTERNSHIP');
    });
  });

  group('contract source — repo V15 (server-side facet)', () {
    test('watchPublicJobs/countPublicJobs nhận 4 facet param optional', () {
      for (final sig in const [
        'Stream<List<JobModel>> watchPublicJobs(',
        'Future<int> countPublicJobs(',
      ]) {
        final body = memberBody(repoSrc, sig);
        expect(body, isNotEmpty, reason: 'trích được $sig');
        expect(has(body, 'String? city,'), isTrue,
            reason: '$sig thiếu param city');
        expect(has(body, 'WorkMode? workMode,'), isTrue,
            reason: '$sig thiếu param workMode');
        expect(has(body, 'JobType? jobType,'), isTrue,
            reason: '$sig thiếu param jobType');
        expect(has(body, 'String? categoryName,'), isTrue,
            reason: '$sig thiếu param categoryName (fix "chỉ 2 IT")');
      }
    });

    test('_applyFacetFilter: 4 where clause đúng field + wire value', () {
      final body = memberBody(repoSrc, 'Query<JobModel> _applyFacetFilter(');
      expect(body, isNotEmpty, reason: 'trích được _applyFacetFilter');
      expect(
        pos(body, "where('city', isEqualTo: city)") >= 0,
        isTrue,
        reason: 'phải có where city (field thật đã index trong '
            'firestore.indexes.json)',
      );
      expect(
        pos(body, "where('workMode', isEqualTo: enumToWire(workMode))") >= 0,
        isTrue,
        reason: 'workMode phải so với wire value (ONSITE/REMOTE/HYBRID), '
            'không phải enum name',
      );
      expect(
        pos(body, "where('jobType', isEqualTo: enumToWire(jobType))") >= 0,
        isTrue,
        reason: 'jobType phải so với wire value (FULL_TIME/PART_TIME/…)',
      );
      expect(
        pos(body, "where('categoryName', isEqualTo: categoryName)") >= 0,
        isTrue,
        reason: 'categoryName chạy string equality — index mới '
            '(isApproved,status,categoryName,createdAt)',
      );
    });

    test(
      '_applyFacetFilter: priority city > workMode > jobType > categoryName',
      () {
        final body = memberBody(repoSrc, 'Query<JobModel> _applyFacetFilter(');
        final pIfCity = pos(body, 'if (city != null)');
        final pCity = pos(body, "where('city', isEqualTo: city)");
        final pMode = pos(
          body,
          "where('workMode', isEqualTo: enumToWire(workMode))",
        );
        final pType = pos(
          body,
          "where('jobType', isEqualTo: enumToWire(jobType))",
        );
        final pCat = pos(
          body,
          "where('categoryName', isEqualTo: categoryName)",
        );
        expect(pCity > pIfCity, isTrue,
            reason: 'where city nằm trong nhánh if city != null');
        expect(pMode > pCity, isTrue,
            reason: 'city thắng workMode (áp dụng trước)');
        expect(pType > pMode, isTrue, reason: 'workMode thắng jobType');
        expect(pCat > pType, isTrue, reason: 'jobType thắng categoryName');
      },
    );

    test('_applyFacetFilter: assert chặn caller truyền >1 facet (debug)', () {
      final body = memberBody(repoSrc, 'Query<JobModel> _applyFacetFilter(');
      expect(
        has(
          body,
          '(city != null ? 1 : 0) + (workMode != null ? 1 : 0) + '
          '(jobType != null ? 1 : 0) + (categoryName != null ? 1 : 0) <= 1',
        ),
        isTrue,
        reason: 'assert ≤1 facet — caller sai phải bị bắn ngay ở debug build',
      );
      expect(
        pos(body, 'assert(') < pos(body, 'if (city != null)'),
        isTrue,
        reason: 'assert đứng trước if-chain',
      );
    });

    test('watchPublicJobs: guard unmatchable chạy TRƯỚC facet chain', () {
      final body = memberBody(
        repoSrc,
        'Stream<List<JobModel>> watchPublicJobs(',
      );
      final guard = pos(body, 'if (_isUnmatchableKeyword(keyword))');
      // Chỉ cần facet chain có mặt sau guard — không pin named-args order
      // vì fomatter + 4 param đã break single-line signature match.
      final facet = pos(body, 'q = _applyFacetFilter(');
      expect(guard >= 0, isTrue,
          reason: 'guard #11 phải còn (V13 đã pin — nhắc lại cho layer này)');
      expect(facet >= 0, isTrue,
          reason: 'watchPublicJobs phải gọi _applyFacetFilter');
      expect(facet > guard, isTrue,
          reason: 'facet chain đặt sau guard — keyword "c" vẫn ra stream rỗng '
              'kể cả khi có facet');
    });

    test('countPublicJobs: guard return 0 TRƯỚC facet chain', () {
      final body = memberBody(repoSrc, 'Future<int> countPublicJobs(');
      final guard = pos(body, 'if (_isUnmatchableKeyword(keyword)) return 0;');
      final facet = pos(body, 'q = _applyFacetFilter(');
      expect(guard >= 0, isTrue);
      expect(facet >= 0, isTrue,
          reason: 'countPublicJobs phải cùng chain facet với watch — không '
              'thì header "N việc làm" lại đếm cả bộ khi có facet');
      expect(facet > guard, isTrue);
    });
  });

  group('contract source — viewmodel V16 (hoist 1 facet)', () {
    test('typedef JobsServerFilter + sentinel _noServerFilter', () {
      expect(has(vmSrc, 'typedef JobsServerFilter'), isTrue);
      expect(has(vmSrc, 'static const JobsServerFilter _noServerFilter'), isTrue);
    });

    test('_serverFilter: gate flatten đúng 1 entry + 4 nhánh hoist', () {
      final body = braceBody(vmSrc, 'JobsServerFilter _serverFilter() {');
      expect(body, isNotEmpty, reason: 'trích được _serverFilter');
      expect(has(body, 'final flat = state.filters.flatten();'), isTrue,
          reason: 'phải flatten TOÀN BỘ filter state — nếu chỉ đếm từng set '
              'riêng thì city+salary vẫn hoist được là sai spec');
      expect(has(body, 'if (flat.length != 1) return _noServerFilter;'), isTrue,
          reason: 'đúng 1 chip DUY NHẤT trên 7 loại filter mới được hoist');
      // Record field order không được format pin — chỉ cần field + value có mặt.
      expect(has(body, 'JobFilterKey.cities =>'), isTrue,
          reason: 'nhánh cities phải hoist city param');
      expect(has(body, 'city: value'), isTrue);
      expect(has(body, 'workMode: parseWorkMode(value)'), isTrue,
          reason: 'wire string → enum qua parseWorkMode trước khi xuống repo');
      expect(has(body, 'jobType: parseJobType(value)'), isTrue);
      expect(has(body, 'JobFilterKey.categories =>'), isTrue,
          reason: 'nhánh categories hoist categoryName (fix "chỉ 2 IT")');
      expect(has(body, 'categoryName: value'), isTrue);
      expect(
        has(
          body,
          "JobFilterKey.cities when value == 'Chưa cập nhật' => _noServerFilter",
        ),
        isTrue,
        reason: 'sentinel display không có doc tương ứng trên Firestore — '
            'phải giữ client-side',
      );
      expect(
        has(
          body,
          "JobFilterKey.categories when value == 'Ngành nghề khác' => _noServerFilter",
        ),
        isTrue,
        reason: "bucket 'Ngành nghề khác' là categoryOf fallback — không có "
            'doc nào có categoryName == bucket name',
      );
    });

    test('_resubscribe: pass đủ 4 facet qua repo + track _subscribedFilter', () {
      final body = braceBody(
        vmSrc,
        'void _resubscribe(String keyword, int limit, JobsServerFilter filter) {',
      );
      expect(body, isNotEmpty, reason: 'trích được _resubscribe');
      expect(has(body, '_subscribedFilter = filter;'), isTrue);
      expect(has(body, 'city: filter.city,'), isTrue);
      expect(has(body, 'workMode: filter.workMode,'), isTrue);
      expect(has(body, 'jobType: filter.jobType,'), isTrue);
      expect(has(body, 'categoryName: filter.categoryName,'), isTrue,
          reason: 'repo .watchPublicJobs nhận categoryName để chain '
              '.where("categoryName",==) server-side');
    });

    test('_fetchTotalCount: countPublicJobs nhận cùng facet với stream', () {
      // Signature mở rộng thêm named `attempt` để hỗ trợ retry backoff khi
      // Firestore `.count()` fail (trước đó bị catch nuốt im lặng — chính là
      // một trong các nguyên nhân "tổng 30/60 thay vì 9800").
      final body = braceBody(
        vmSrc,
        'Future<void> _fetchTotalCount(\n'
        '    String keyword,\n'
        '    JobsServerFilter filter, {\n'
        '    int attempt = 0,\n'
        '  }) async {',
      );
      expect(body, isNotEmpty, reason: 'trích được _fetchTotalCount');
      expect(has(body, 'city: filter.city,'), isTrue);
      expect(has(body, 'workMode: filter.workMode,'), isTrue);
      expect(has(body, 'jobType: filter.jobType,'), isTrue);
      expect(has(body, 'categoryName: filter.categoryName,'), isTrue,
          reason: 'count aggregation phải cùng facet set với stream — chip '
              'category hoist cũng cần N việc làm chính xác');
      expect(
        has(body, 'debugPrint('),
        isTrue,
        reason: 'phải log fail (không nuốt silently) để biết vì sao .count() '
            'không bao giờ đến; swallow cũ chính là nguyên nhân "tổng 30/60"',
      );
    });

    test('_reconcileSubscription: so sánh filter + refetch count khi đổi', () {
      final body = braceBody(vmSrc, 'void _reconcileSubscription() {');
      expect(body, isNotEmpty, reason: 'trích được _reconcileSubscription');
      expect(has(body, 'final filter = _serverFilter();'), isTrue);
      expect(
        has(body, 'final filterChanged = filter != _subscribedFilter;'),
        isTrue,
        reason: 'record có == structural — so sánh trực tiếp được',
      );
      expect(
        has(body, 'if (!filterChanged && target == _subscribedLimit) return;'),
        isTrue,
        reason: 'resubscribe khi limit HOẶC filter đổi',
      );
      expect(
        has(body, 'totalCount: filterChanged ? null : _sentinel,'),
        isTrue,
        reason: 'đổi facet phải NULL totalCount (UI hiện "đang đếm…") '
            'KHÔNG preserve stale "9.800" trong khi .count() mới chưa về; '
            'pagination (filterChanged=false) thì preserve qua sentinel — '
            'đó chính là fix cho "lướt sang trang 3 thấy tổng = 60"',
      );
      final resub = pos(
        body,
        '_resubscribe(_subscribedKeyword, target, filter);',
      );
      final count = pos(body, '_fetchTotalCount(_subscribedKeyword, filter);');
      expect(resub >= 0, isTrue);
      expect(count > resub, isTrue,
          reason: 'refetch count đứng sau resubscribe — count phải theo facet '
              'mới, không phải facet cũ');
    });

    test('_onJobs: bỏ mergeWithMocks khi facet server-side active', () {
      final body = braceBody(vmSrc, 'void _onJobs(List<JobModel> jobs) {');
      expect(body, isNotEmpty);
      final facetActive = pos(body, '_subscribedFilter != _noServerFilter');
      final ternary = pos(
        body,
        '? jobs.where((j) => j.jobId.isNotEmpty && j.isPublic)',
      );
      final merge = pos(body, 'JobsRepository.mergeWithMocks(jobs)');
      expect(facetActive >= 0, isTrue,
          reason: 'facet active mà stream <50 doc thì mock SYN- lại được đệm '
              'vào → facet count sai (mục tiêu chính của ĐỢT 5)');
      expect(ternary > facetActive, isTrue);
      expect(merge > ternary, isTrue);
    });

    test('mọi call-site _resubscribe/_fetchTotalCount đều truyền filter', () {
      expect(braceBody(vmSrc, 'void retry() {'), isNotEmpty);
      expect(
        has(
          vmSrc,
          '_resubscribe(_subscribedKeyword, _subscribedLimit, _subscribedFilter);',
        ),
        isTrue,
        reason: 'retry phải replay đúng filter đang subscribe',
      );
      expect(
        has(
          vmSrc,
          "_resubscribe('', JobsRepository.defaultChunk, _noServerFilter);",
        ),
        isTrue,
        reason: 'resetAll phải về trạng thái không-facet',
      );
      expect(
        has(vmSrc, '_resubscribe(trimmed, target, filter);'),
        isTrue,
        reason: 'submitSearch giữ facet hiện tại khi đổi keyword',
      );
      expect(has(vmSrc, '_fetchTotalCount(trimmed, filter);'), isTrue);
      // Không sót call 2 tham số (thiếu filter) của _resubscribe, cũng như
      // call 1 tham số (chỉ keyword) của _fetchTotalCount. Squash xoá trắng
      // nên mỗi tham số = [^,)]+.
      final squashed = squash(vmSrc);
      expect(
        RegExp(r'_resubscribe\([^,()]+,[^,()]+\);').hasMatch(squashed),
        isFalse,
        reason: 'còn lệnh _resubscribe(a, b); thiếu tham số filter thứ 3',
      );
      expect(
        RegExp(r'_fetchTotalCount\([^,()]+\);').hasMatch(squashed),
        isFalse,
        reason: 'còn lệnh _fetchTotalCount(a); thiếu tham số filter thứ 2',
      );
    });
  });
}
