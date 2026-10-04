// Regression test cho fix #11 (GLM_REPORT mục 11, FIXED 2026-10-03):
// keyword mà JobModel.tokenize rút gọn về 0 token (ví dụ "c") không được
// phép làm rơi mệnh đề `arrayContainsAny` — trước fix, gõ "c" trả về TOÀN BỘ
// job công khai (9800 kết quả) thay vì 0.
//
// Ba lớp kiểm tra:
// 1. PHÂN LOẠI (group "phân loại keyword"): gọi THẬT `JobModel.tokenize`
//    (public static) cho từng keyword, qua predicate mirror sao chép 1-1
//    logic `_isUnmatchableKeyword`/`_searchTokens` (private, không import
//    được từ test library) — mirror ghi rõ dòng nguồn để đối chiếu khi lib
//    đổi. LƯU Ý: group này KHÔNG thực thi code JobsRepository nào (khởi tạo
//    cần Firestore) nên miễn nhiễm với revert fix — giá trị của nó là chốt
//    chuẩn phân loại keyword mà guard phải dựa vào.
// 2. CONTRACT SOURCE (group "contract source"): đọc file
//    `lib/features/jobs/data/jobs_repository.dart` thật từ đĩa và khẳng định
//    guard `_isUnmatchableKeyword` tồn tại, chạy TRƯỚC khi build query trong
//    `watchPublicJobs`/`countPublicJobs`, và định nghĩa khớp dạng chuẩn
//    `trimmed.isNotEmpty && _searchTokens(trimmed).isEmpty`. Nếu ai đó gỡ
//    guard đi, test đỏ ngay. (Kỹ thuật đã có tiền lệ: notification_model_test
//    đọc firestore.rules làm contract.)
// 3. BONUS FIX (group "_onJobs bỏ mock khi search"): jobs_search_viewmodel
//    bỏ `mergeWithMocks` khi `_subscribedKeyword.isNotEmpty` — nếu không,
//    stream rỗng từ guard lại bị đệm thành 12 dòng SYN- demo → user gõ "c"
//    thấy "12 kết quả" thay vì "0 kết quả".
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';

/// Mirror 1-1 của `JobsRepository._searchTokens`
/// (lib/features/jobs/data/jobs_repository.dart:71-76):
/// `k = keyword.trim(); if (k.isEmpty) return const [];
///  JobModel.tokenize(k).take(10).toList(growable: false)`.
/// Dùng `JobModel.tokenize` THẬT nên mirror tự drift theo lib — chỉ phần
/// trim/take(10) là bản sao cần đối chiếu bằng group contract source dưới.
/// GIỚI HẠN DRIFT: mirror chỉ phát hiện thay đổi lib làm VỠ các substring
/// contract pin ở group dưới; thay đổi additive (thêm lọc sau take(10),
/// thêm guard-clause khác) mà các substring kia còn nguyên sẽ KHÔNG bị phát
/// hiện. Cách triệt để là expose `_isUnmatchableKeyword`/`_searchTokens` qua
/// `@visibleForTesting` trong lib rồi test hàm thật — nằm ngoài phạm vi
/// được phép sửa của phiên GLM (đã đề xuất trong GLM_REPORT ĐỢT 4).
List<String> mirrorSearchTokens(String keyword) {
  final k = keyword.trim();
  if (k.isEmpty) return const [];
  return JobModel.tokenize(k).take(10).toList(growable: false);
}

/// Mirror 1-1 của `JobsRepository._isUnmatchableKeyword`
/// (lib/features/jobs/data/jobs_repository.dart:83-86):
/// `keyword.trim().isNotEmpty && _searchTokens(keyword.trim()).isEmpty`.
bool mirrorIsUnmatchable(String keyword) =>
    keyword.trim().isNotEmpty && mirrorSearchTokens(keyword.trim()).isEmpty;

/// So sánh source bất kể dart format ngắt dòng/thụt lề thế nào: xoá SẠCH mọi
/// whitespace ở CẢ hai phía rồi so chuỗi.
String squash(String s) => s.replaceAll(RegExp(r'\s'), '');
bool has(String haystack, String needle) =>
    squash(haystack).contains(squash(needle));
int pos(String haystack, String needle) =>
    squash(haystack).indexOf(squash(needle));

/// Trích toàn bộ member (signature + thân hàm) khỏi source bằng cách balan
/// `()` của danh sách tham số rồi balan `{}` của thân hàm — không phụ thuộc
/// dart format ngắt dòng/thụt lề. Signature phải kết thúc bằng `(` mở tham số.
/// Hàm thuần (không expect) để gọi được cả ngoài test; không tìm thấy → ''.
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

void main() {
  final repoSrc = File('lib/features/jobs/data/jobs_repository.dart')
      .readAsStringSync();
  final vmSrc = File('lib/features/jobs/viewmodels/jobs_search_viewmodel.dart')
      .readAsStringSync();

  group('phân loại keyword (JobModel.tokenize thật + predicate mirror)', () {
    test("'' → KHÔNG unmatchable (trim rỗng = intent 'xem tất cả')", () {
      expect(mirrorIsUnmatchable(''), isFalse,
          reason: 'keyword rỗng không được coi là unmatchable — nó nghĩa là '
              'không lọc, stream trả cả bộ job công khai');
      expect(mirrorSearchTokens(''), isEmpty,
          reason: "searchTokens('') trả rỗng nhưng đó là empty-intent, "
              'không phải unmatchable');
    });

    test("' ' (toàn khoảng trắng) → KHÔNG unmatchable", () {
      expect(mirrorIsUnmatchable(' '), isFalse,
          reason: 'sau trim là rỗng → cùng nhánh intent với chuỗi rỗng');
      expect(mirrorSearchTokens(' '), isEmpty);
    });

    test("'c' → UNMATCHABLE — đúng lỗi gốc của fix #11", () {
      // Nguyên nhân: split token lọc `w.length >= 2` (job_model.dart:384).
      expect(JobModel.tokenize('c'), isEmpty,
          reason: "tokenize('c') phải rỗng: từ 1 ký tự bị lọc");
      expect(mirrorIsUnmatchable('c'), isTrue,
          reason: "user gõ 'c' → watchPublicJobs/countPublicJobs phải trả "
              'stream rỗng / count 0, KHÔNG PHẢI bỏ filter rồi trả 9800 job');
    });

    test("'ab' → không unmatchable (từ 2 ký tự là token hợp lệ)", () {
      expect(JobModel.tokenize('ab'), isNotEmpty,
          reason: "tokenize('ab') giữ nguyên từ 'ab' (đủ dài >= 2)");
      expect(mirrorSearchTokens('ab'), contains('ab'));
      expect(mirrorIsUnmatchable('ab'), isFalse);
    });

    test("'& #' → UNMATCHABLE (toàn ký tự bị split bỏ, không còn từ nào >= 2)",
        () {
      expect(JobModel.tokenize('& #'), isEmpty,
          reason: "'&' là separator, '#' tuy được giữ trong character class "
              'nhưng chỉ 1 ký tự → bị lọc độ dài');
      expect(mirrorIsUnmatchable('& #'), isTrue);
    });

    test("tech token ngắn 'C#', 'C++' → KHÔNG unmatchable", () {
      // Lý do character class `[a-z0-9+#.]` giữ nguyên 'c#'/'c++' thay vì
      // split — search theo tên công nghệ vẫn hoạt động sau fix.
      expect(JobModel.tokenize('C#'), isNotEmpty,
          reason: "tokenize('C#') giữ 'c#' (dài 2)");
      expect(mirrorSearchTokens('C#'), contains('c#'));
      expect(mirrorIsUnmatchable('C#'), isFalse);
      expect(JobModel.tokenize('C++'), contains('c++'));
      expect(mirrorIsUnmatchable('C++'), isFalse);
    });

    test("'flutter' → không unmatchable (nhiều token + prefix)", () {
      final tokens = mirrorSearchTokens('flutter');
      expect(tokens, containsAll(<String>['fl', 'flutter']),
          reason: 'tokenize sinh cả từ đầy đủ lẫn prefix 2..6 ký tự');
      expect(mirrorIsUnmatchable('flutter'), isFalse);
    });

    test("keyword tiếng Việt 1 ký tự 'đ' → UNMATCHABLE (bỏ dấu vẫn 1 ký tự)",
        () {
      expect(JobModel.tokenize('đ'), isEmpty,
          reason: "stripDiacritics('đ') = 'd' vẫn dài 1 → bị lọc");
      expect(mirrorIsUnmatchable('đ'), isTrue);
    });

    test("'a b' (nhiều từ, mỗi từ 1 ký tự) → UNMATCHABLE", () {
      expect(JobModel.tokenize('a b'), isEmpty,
          reason: 'mọi từ đều ngắn hơn 2 ký tự → 0 token');
      expect(mirrorIsUnmatchable('a b'), isTrue);
    });

    test("ký tự giữ-lại-được nhưng lẻ 1 ('.', '+', '#') → UNMATCHABLE", () {
      // '+', '#', '.' nằm TRONG character class giữ lại của split nên không
      // bị tách bỏ như '&', nhưng length 1 nên vẫn không thành token.
      for (final k in const ['.', '+', '#']) {
        expect(JobModel.tokenize(k), isEmpty, reason: "tokenize('$k') rỗng");
        expect(mirrorIsUnmatchable(k), isTrue, reason: "'$k' unmatchable");
      }
    });

    test('keyword padding khoảng trắng vẫn phân loại như bản đã trim', () {
      expect(mirrorIsUnmatchable('  c  '), isTrue,
          reason: 'trim trước khi tokenize nên "  c  " ≡ "c" → unmatchable');
      expect(mirrorIsUnmatchable(' flutter '), isFalse,
          reason: 'trim xong tokenize ra token → matchable');
    });

    test('searchTokens cap 10 phần tử (mirror ≡ take(10) của lib)', () {
      // 11 từ × (1 full + tối đa 5 prefix) ≈ 46 token >> 10 — mirror phải cắt đúng 10
      // như `JobsRepository._searchTokens` để khớp giới hạn arrayContainsAny.
      final long =
          'lập trình java senior nodejs react php python ruby golang rust';
      expect(mirrorSearchTokens(long), hasLength(10));
      expect(mirrorIsUnmatchable(long), isFalse);
    });
  });

  group('contract source — guard trong JobsRepository (fix #11)', () {
    test('watchPublicJobs: guard unmatchable chạy TRƯỚC khi build query và '
        'trả stream rỗng', () {
      final body =
          memberBody(repoSrc, 'Stream<List<JobModel>> watchPublicJobs(');
      expect(body, isNotEmpty,
          reason: 'trích được watchPublicJobs ra khỏi source');
      final guard = pos(body, 'if (_isUnmatchableKeyword(keyword))');
      final tokens = pos(body, 'final tokens = _searchTokens(keyword);');
      final filter = pos(body, 'arrayContainsAny');

      expect(guard, greaterThanOrEqualTo(0),
          reason: 'watchPublicJobs phải gọi guard `_isUnmatchableKeyword` — '
              'đây chính là fix #11; gỡ đi là regression');
      expect(tokens, greaterThanOrEqualTo(0),
          reason: 'needle "final tokens = _searchTokens(keyword);" phải còn '
              'tồn tại (đổi tên biến trong lib thì cập nhật needle)');
      expect(filter, greaterThanOrEqualTo(0),
          reason: 'needle "arrayContainsAny" phải còn tồn tại trong thân hàm');
      expect(has(body, 'return Stream.value(const <JobModel>[]);'), isTrue,
          reason: 'guard phải trả stream RỖNG (0 kết quả), không phải stream '
              'không-filter (9800 kết quả)');
      expect(tokens, greaterThan(guard),
          reason: 'guard phải đứng trước dòng compute tokens — nếu đứng sau '
              'thì query không-filter đã được build sẵn');
      expect(filter, greaterThan(guard),
          reason: 'mệnh đề arrayContainsAny chỉ được thêm SAU guard');
    });

    test('countPublicJobs: guard unmatchable return 0 trước khi build query',
        () {
      final body = memberBody(repoSrc, 'Future<int> countPublicJobs(');
      expect(body, isNotEmpty,
          reason: 'trích được countPublicJobs ra khỏi source');
      final guard = pos(body, 'if (_isUnmatchableKeyword(keyword)) return 0;');
      final tokens = pos(body, 'final tokens = _searchTokens(keyword);');

      expect(guard, greaterThanOrEqualTo(0),
          reason: 'countPublicJobs phải early-return 0 cho keyword '
              'unmatchable — nếu không, header "N việc làm" vẫn hiện 9800 '
              'khi user gõ "c"');
      expect(tokens, greaterThanOrEqualTo(0),
          reason: 'needle "final tokens = _searchTokens(keyword);" phải còn '
              'tồn tại (đổi tên biến trong lib thì cập nhật needle)');
      expect(tokens, greaterThan(guard),
          reason: 'guard đứng trước compute tokens trong countPublicJobs');
    });

    test('_isUnmatchableKeyword: định nghĩa khớp dạng chuẩn của fix', () {
      final body = memberBody(
        repoSrc,
        'static bool _isUnmatchableKeyword(',
      );
      expect(body, isNotEmpty,
          reason: 'trích được _isUnmatchableKeyword ra khỏi source');
      expect(has(body, 'final trimmed = keyword.trim();'), isTrue,
          reason: 'trim trước khi xét isNotEmpty');
      expect(
        has(body, 'return trimmed.isNotEmpty && _searchTokens(trimmed).isEmpty;'),
        isTrue,
        reason: 'định nghĩa đúng: CHỈ unmatchable khi user có gõ gì đó '
            '(trim không rỗng) mà tokenize không ra token nào — chuỗi rỗng '
            'phải trả false để giữ nguyên intent "xem tất cả"',
      );
    });

    test(
      '_searchTokens: trim → empty guard → tokenize + synonym expand → '
      'take(10)',
      () {
        final body = memberBody(
          repoSrc,
          'static List<String> _searchTokens(',
        );
        expect(body, isNotEmpty,
            reason: 'trích được _searchTokens ra khỏi source');
        expect(has(body, 'final k = keyword.trim();'), isTrue);
        expect(has(body, 'if (k.isEmpty) return const [];'), isTrue);
        expect(has(body, 'JobModel.tokenize(k)'), isTrue,
            reason: 'base tokens vẫn phải từ JobModel.tokenize (fallback khi '
                'không có synonym — mirror ở đầu file dùng chung helper này)');
        expect(has(body, '_searchSynonyms'), isTrue,
            reason: 'synonym map được inject để "IT"/"CNTT" khớp jobs có '
                'title "Backend Developer"/"DevOps Engineer" (catalogue '
                'không có category literal "IT")');
        expect(has(body, '.take(10)'), isTrue,
            reason: 'Firestore arrayContainsAny cap ở 10 — expanded set '
                'cuối cùng phải cắt về 10 token trước khi query');
      },
    );
  });

  group('_onJobs bỏ mock khi search (bonus fix kèm #11)', () {
    test('khi _subscribedKeyword không rỗng thì KHÔNG gọi mergeWithMocks', () {
      final body = memberBody(vmSrc, 'void _onJobs(');
      expect(body, isNotEmpty, reason: 'trích được _onJobs ra khỏi source');
      final guard = pos(body, '_subscribedKeyword.isNotEmpty');
      final ternary =
          pos(body, '? jobs.where((j) => j.jobId.isNotEmpty && j.isPublic)');
      final merge = pos(body, 'JobsRepository.mergeWithMocks(jobs)');

      expect(guard, greaterThanOrEqualTo(0),
          reason: '_onJobs phải rẽ nhánh theo _subscribedKeyword.isNotEmpty');
      expect(ternary, greaterThanOrEqualTo(0),
          reason: 'nhánh search lọc thẳng jobs công khai (bỏ dòng jobId rỗng)');
      expect(merge, greaterThan(ternary),
          reason: 'mergeWithMocks chỉ là nhánh else (không search) — nếu '
              'đứng trước/outside nhánh thì "0 kết quả" lại thành 12 mock');
    });
  });
}
