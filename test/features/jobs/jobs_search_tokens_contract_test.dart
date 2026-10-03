import 'package:flutter_test/flutter_test.dart';

import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';

/// Contract test giữa WRITE-PATH và READ-PATH của tìm kiếm job bằng
/// titleTokens (Firestore không có ILIKE nên dùng array-contains).
///
/// WRITE PATH — JobModel.toJson (lib/shared/models/job_model.dart):
///   'titleTokens': titleTokens.isNotEmpty
///       ? titleTokens
///       : tokenize(jobTitle, employerName)
///   tokenize: '$title $company'.toLowerCase() → stripDiacritics →
///   split RegExp(r'[^a-z0-9+#.]+') → từ >= 2 ký tự; mỗi từ add chính nó +
///   prefix 2..min(len-1, 6) ký tự; LinkedHashSet giữ thứ tự chèn; take(60).
///
/// READ PATH — JobsRepository (lib/features/jobs/data/jobs_repository.dart):
///   watchPublicJobs / countPublicJobs:
///     tokens = _searchTokens(keyword);
///     if (tokens.isNotEmpty) q.where('titleTokens', arrayContainsAny: tokens)
///   Firestore `arrayContainsAny` match một document khi CÓ ÍT NHẤT 1 token
///   giao với titleTokens đã lưu.
///
/// _searchTokens là PRIVATE method nên file này KHÔNG import
/// jobs_repository.dart (tránh phải dựng FirestoreRefs / riverpod wiring);
/// [searchTokensOf] bên dưới là BẢN SAO 1-1 của _searchTokens
/// (jobs_repository.dart dòng 68-73) — nếu private method đó thay đổi thì
/// phải cập nhật bản sao này theo cho contract không bị "giả xanh".

/// Bản sao 1-1 của JobsRepository._searchTokens (private, dòng 68-73):
/// trim() trước (tokenize KHÔNG tự trim), rỗng thì không lọc, tối đa 10 token
/// cho arrayContainsAny (Firestore giới hạn 10 operand).
List<String> searchTokensOf(String keyword) {
  final k = keyword.trim();
  if (k.isEmpty) return const [];
  return JobModel.tokenize(k).take(10).toList(growable: false);
}

/// Token mà write-path lưu xuống Firestore cho [job] — chính là giá trị
/// toJson()['titleTokens'] khi model chưa có sẵn token (nhánh mặc định).
/// take(60) mirror giới hạn write-side của tokenize.
Set<String> writeTokensOf(JobModel job) =>
    JobModel.tokenize(job.jobTitle, job.employerName).take(60).toSet();

void main() {
  group('contract: keyword tìm thấy job có title chứa keyword', () {
    // (keyword người dùng gõ, jobTitle chứa keyword, employerName)
    const cases = <(String, String, String)>[
      ('flutter', 'Flutter Developer tại Hà Nội', 'FPT Software'),
      ('nodejs', 'NodeJS Backend Engineer', 'VNG Corporation'),
      ('lập trình java', 'Lập trình Java Senior', 'Viettel Solutions'),
      ('C++', 'C++ Game Programmer', 'Gameloft'),
      ('React.js', 'React.js Frontend Developer', 'Tiki Việt Nam'),
      ('senior developer', 'Senior Developer (Full-stack)', 'Shopee'),
      // khoảng trắng thừa + HOA thường lẫn lộn + có dấu tiếng Việt
      (' Nhân viên KINH DOANH ', 'Tuyển Nhân viên KINH DOANH ',
          'Công ty TNHH Thương mại Việt'),
    ];

    for (var i = 0; i < cases.length; i++) {
      final (keyword, jobTitle, employerName) = cases[i];
      test('keyword "${keyword.trim()}" match job "$jobTitle"', () {
        // 1. Job public thực tế (đủ điều kiện lọt _publicQuery: OPEN + duyệt).
        final job = JobModel(
          jobId: 'job-contract-$i',
          employerId: 'employer-contract-$i',
          employerName: employerName,
          jobTitle: jobTitle,
          status: JobStatus.open,
          isApproved: true,
        );
        expect(job.isPublic, isTrue,
            reason: 'bối cảnh hợp lệ: job đã duyệt + OPEN mới nằm trong kết quả '
                'tìm kiếm của watchPublicJobs');
        // sanity: title thật sự chứa keyword (bỏ khoảng trắng thừa, thường hoá)
        expect(
          job.jobTitle.toLowerCase().contains(keyword.trim().toLowerCase()),
          isTrue,
          reason: 'tiền đề của case: title phải chứa keyword (sau thường hoá)',
        );

        // 2. Write path: token được index khi lưu job.
        final writeTokens = writeTokensOf(job);
        expect(writeTokens.length, lessThanOrEqualTo(60),
            reason: 'write path giới hạn 60 token (take(60) trong tokenize)');

        // 3. Read path: token đưa vào arrayContainsAny (bản sao _searchTokens).
        final searchTokens = searchTokensOf(keyword);
        expect(searchTokens, isNotEmpty,
            reason: 'keyword không rỗng và có từ >= 2 ký tự nên phải sinh '
                'được token tìm kiếm');
        expect(searchTokens.length, lessThanOrEqualTo(10),
            reason: 'Firestore arrayContainsAny tối đa 10 operand');

        // 4. arrayContainsAny: match khi >= 1 token giao nhau.
        final intersection = writeTokens.intersection(searchTokens.toSet());
        expect(intersection, isNotEmpty,
            reason: 'LỖI CONTRACT: title "$jobTitle" + employer '
                '"$employerName" không giao với token tìm kiếm của keyword '
                '"$keyword"\n  write : $writeTokens\n  search: $searchTokens');
      });
    }
  });

  group('contract qua toJson (write path thật, không qua bản sao)', () {
    test('titleTokens trong toJson() giao với token tìm kiếm của keyword', () {
      const cases = <(String, String, String)>[
        ('flutter', 'Flutter Developer', 'FPT Software'),
        ('nodejs', 'NodeJS Backend Engineer', 'VNG'),
        ('lập trình java', 'Lập trình Java Senior', 'Viettel'),
        ('C++', 'C++ Game Programmer', 'Gameloft'),
        ('React.js', 'React.js Frontend', 'Tiki'),
        ('senior developer', 'Senior Developer', 'Shopee'),
        (' Nhân viên KINH DOANH ', 'Tuyển Nhân viên KINH DOANH ', 'TNHH ABC'),
      ];
      for (final (keyword, jobTitle, employerName) in cases) {
        final job = JobModel(
          jobId: 'job-json-contract',
          employerId: 'employer-json-contract',
          employerName: employerName,
          jobTitle: jobTitle,
          status: JobStatus.open,
          isApproved: true,
        );
        // Nhánh write-path thật: titleTokens rỗng (mặc định) → toJson tự
        // tokenize(jobTitle, employerName).
        final persisted = job.toJson()['titleTokens'] as List<String>;
        expect(persisted, writeTokensOf(job).toList(),
            reason: 'toJson phải persist đúng tokenize(jobTitle, employerName) '
                '(đã cap 60) cho "$jobTitle"');
        final intersection =
            persisted.toSet().intersection(searchTokensOf(keyword).toSet());
        expect(intersection, isNotEmpty,
            reason: 'LỖI CONTRACT (qua toJson): token lưu xuống Firestore của '
                '"$jobTitle" không match keyword "$keyword"');
      }
    });
  });

  group('read path: take(10) của _searchTokens', () {
    test(
        '(a) keyword nhiều từ: full token của từ đầu vẫn giữ, từ về sau bị cắt',
        () {
      // 6 từ → sinh ra stream (thứ tự chèn LinkedHashSet):
      //   lap, la | trinh, tr, tri, trin | java, ja, jav | senior, se, seni,
      //   senio | nodejs, no, nod, node, nodej | react, re, rea, reac
      // take(10) giữ đúng 10 token đầu → "senior" (token thứ 10) vừa kịp,
      // còn full token của "nodejs" và "react" BỊ CẮT MẤT.
      // Bugfix #12 (words-first ordering): 6 keyword words emit full
      // tokens before any prefix. take(10) now keeps ALL 6 full words +
      // the first 4 prefixes, so "nodejs" / "react" at keyword position
      // 5-6 are no longer silently dropped.
      final tokens = searchTokensOf('lập trình java senior nodejs react');
      expect(tokens.length, 10);
      expect(
        tokens,
        containsAll(['lap', 'trinh', 'java', 'senior', 'nodejs', 'react']),
        reason: 'cả 6 full word của 6 keyword lọt vào 10 token đầu',
      );
      // A job titled "Nodejs React Developer" now intersects the query
      // tokens → arrayContainsAny matches it.
      final lateWordsOnlyJob = JobModel(
        jobId: 'job-late-words',
        employerId: 'employer-late-words',
        employerName: 'Startup ABC',
        jobTitle: 'Nodejs React Developer',
        status: JobStatus.open,
        isApproved: true,
      );
      expect(
        writeTokensOf(lateWordsOnlyJob).intersection(tokens.toSet()),
        isNotEmpty,
        reason: 'bugfix #12: job chứa "nodejs"/"react" nay match được khi '
            'user gõ cả câu dài (words-first ordering)',
      );
    });
  });

  group('write path: take(60) của tokenize', () {
    test('(b) title + company dài: words-first đảm bảo cả title và company qua cap',
        () {
      // Bugfix #13 (words-first + title/company separation): 30 title
      // words + 2 company words = 32 full words first, then prefixes. cap
      // 60 keeps ALL 32 full words + 28 prefixes. Previous order crowded
      // company tokens out when title was long.
      const alphabet = 'abcdefghijklmnopqrstuvwxyz0123';
      final titleWords = [
        for (var i = 0; i < 30; i++) '${alphabet[i]}xlongword$i',
      ];
      final job = JobModel(
        jobId: 'job-long-title',
        employerId: 'employer-long-title',
        employerName: 'Công ty TNHH',
        jobTitle: titleWords.join(' '),
        status: JobStatus.open,
        isApproved: true,
      );
      final writeTokens = writeTokensOf(job);
      expect(writeTokens.length, 60,
          reason: 'take(60) vẫn giới hạn; chỉ phần đuôi prefixes bị cắt');
      for (final w in titleWords) {
        expect(writeTokens, contains(w),
            reason: '$w phải nằm trong 60 token — mọi full word của title đều qua cap');
      }
      // Company tokens cũng vào vì chúng xếp sau 30 title full words
      // (position 31+ trong Set, trước mọi prefix).
      expect(writeTokens, containsAll(['cong', 'ty', 'tnhh']),
          reason: 'words-first fix #13: company tokens không còn bị crowd-out khi title dài');
    });
  });

  group('keyword 1 ký tự và keyword rỗng', () {
    test('(c) từ 1 ký tự bị lọc (w.length >= 2) → "c" không match job "C++"', () {
      final job = JobModel(
        jobId: 'job-cpp',
        employerId: 'employer-cpp',
        employerName: 'Gameloft',
        jobTitle: 'C++ Developer',
        status: JobStatus.open,
        isApproved: true,
      );
      final writeTokens = writeTokensOf(job);
      expect(writeTokens, containsAll(['c++', 'c+']),
          reason: 'write side giữ nguyên "c++" (3 ký tự >= 2, ký tự + không '
              'phải separator) và prefix "c+"');

      final searchTokens = searchTokensOf('c');
      expect(searchTokens, isEmpty,
          reason: 'từ 1 ký tự bị where length >= 2 lọc bỏ → không còn token nào');

      // Mức token: giao rỗng → không match job "C++" bằng từ khóa "c".
      expect(writeTokens.intersection(searchTokens.toSet()), isEmpty,
          reason: 'HẠN CHẾ: gõ "c" không tìm thấy job "C++" vì "c" bị lọc trước '
              'khi so giao');

      // LƯU Ý hành vi repository (không test trực tiếp được vì private):
      // từ fix #11 (Đợt 4), keyword trim không rỗng mà searchTokens rỗng bị
      // guard `_isUnmatchableKeyword` chặn TRƯỚC khi build query → trả stream
      // rỗng / count 0 (xem jobs_repository_search_test.dart). Nhánh "bỏ filter
      // rồi trả tất cả" giờ chỉ còn cho keyword rỗng thuần (case (d) dưới).
    });

    test('(d) keyword rỗng / chỉ khoảng trắng → searchTokens rỗng → không filter',
        () {
      for (final k in ['', '   ', ' \t\n ']) {
        expect(searchTokensOf(k), isEmpty,
            reason: '_searchTokens trim trước rồi mới kiểm tra rỗng → keyword '
                '"$k" sinh 0 token');
      }
      // Hệ quả: tokens.isEmpty → watchPublicJobs KHÔNG gắn
      // where('titleTokens', arrayContainsAny) → trả tất cả job public
      // (đúng chủ đích: chưa gõ từ khóa thì xem toàn bộ danh sách).
    });
  });
}
