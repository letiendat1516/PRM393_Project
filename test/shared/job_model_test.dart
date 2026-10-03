import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';

/// Unit tests cho JobModel / JobDescription / JobSkillRef
/// (lib/shared/models/job_model.dart) — test theo API thực tế của model.
void main() {
  JobModel job({
    String jobTitle = 'Kế toán trưởng',
    String employerName = 'Công ty Cổ phần FPT',
    num? salaryMin = 20000000,
    num? salaryMax,
    DateTime? applicationDeadline,
    JobStatus status = JobStatus.open,
    bool isApproved = false,
    List<JobSkillRef> requiredSkills = const [],
    int applicationsCount = 12,
    DateTime? createdAt,
    ExperienceLevel experienceLevel = ExperienceLevel.mid,
    WorkMode workMode = WorkMode.onsite,
    JobType jobType = JobType.fullTime,
  }) =>
      JobModel(
        jobId: 'job-1',
        employerId: 'emp-1',
        employerName: employerName,
        jobTitle: jobTitle,
        salaryMin: salaryMin,
        salaryMax: salaryMax,
        applicationDeadline: applicationDeadline,
        status: status,
        isApproved: isApproved,
        requiredSkills: requiredSkills,
        applicationsCount: applicationsCount,
        createdAt: createdAt,
        experienceLevel: experienceLevel,
        workMode: workMode,
        jobType: jobType,
      );

  group('JobModel.stripDiacritics', () {
    test('bỏ dấu tiếng Việt: ký tự có dấu thường về base, chữ hoa giữ nguyên', () {
      expect(JobModel.stripDiacritics('Kế toán trưởng'),
          'Ke toan truong',
          reason: 'Ế→e, Á→a, Ư→u, Ở→o; chữ "K" hoa (không dấu) đi qua nguyên vận '
              '— bảng map chỉ chứa chữ thường, tokenize phải toLowerCase() trước');
    });

    test('bảng map phủ đủ và 1-1: from.length == to.length và strip(from) == to', () {
      // Copy nguyên văn bảng map từ cài đặt stripDiacritics trong job_model.dart.
      const from =
          'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ';
      const to =
          'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd';
      expect(from.length, to.length,
          reason: 'hai chuỗi bảng map phải cùng độ dài — nếu lệch, mọi ký tự sau '
              'vị trí lệch sẽ bị thay bằng ký tự base sai');
      expect(JobModel.stripDiacritics(from), to,
          reason: 'mọi ký tự có dấu thường phải map đúng về ký tự base tại đúng '
              'vị trí tương ứng (nhóm a/e/i/o/u/y và đ→d)');
    });

    test('chữ HOA có dấu không bị bỏ dấu (bảng map chỉ chứa chữ thường)', () {
      expect(JobModel.stripDiacritics('KẾ TOÁN'), 'KẾ TOÁN',
          reason: 'hạn chế đã biết: from-map chỉ chứa ký tự thường — '
              'tokenize phải toLowerCase() TRƯỚC khi strip (được test ở group tokenize)');
    });

    test('chuỗi không dấu / rỗng trả về nguyên bản', () {
      expect(JobModel.stripDiacritics('flutter developer 2026'),
          'flutter developer 2026',
          reason: 'chuỗi đã ASCII phải đi qua không đổi');
      expect(JobModel.stripDiacritics(''), '', reason: 'chuỗi rỗng → chuỗi rỗng');
    });
  });

  group('JobModel.tokenize', () {
    test('"Kế toán trưởng" + "Công ty Cổ phần FPT" → words-first then prefixes', () {
      final tokens = JobModel.tokenize('Kế toán trưởng', 'Công ty Cổ phần FPT');
      // Thứ tự mới (bugfix #13): mọi từ đầy đủ của title + company trước
      // (dedupe bằng Set), rồi 2..6-char prefixes của cả hai.
      expect(
        tokens,
        [
          // 1. Full words: title (ke, toan, truong) + company (cong, ty, co, phan, fpt).
          'ke', 'toan', 'truong',
          'cong', 'ty', 'co', 'phan', 'fpt',
          // 2. Prefixes 2..6 for each word in order (co from "cong" dedupes
          //    against the full word "co" already present).
          'to', 'toa',
          'tr', 'tru', 'truo', 'truon',
          'con',
          'ph', 'pha',
          'fp',
        ],
        reason: 'words-first ordering keeps the company name indexed even '
            'when the title is long (previous order dropped it at cap=60)',
      );
    });

    test('mọi token đều thường, ASCII, độ dài >= 2 (không ký tự dấu sót lại)', () {
      final tokens = JobModel.tokenize(
          'Nhân Viên Kinh Doanh', 'Công ty TNHH Đầu Tư XYZ');
      expect(tokens, isNotEmpty, reason: 'phải có token cho input không rỗng');
      expect(tokens.every((t) => t == t.toLowerCase()), isTrue,
          reason: 'token dùng cho Firestore array-contains nên phải là chữ thường');
      expect(tokens.every((t) => t.codeUnits.every((c) => c < 128)), isTrue,
          reason: 'sau stripDiacritics không được còn ký tự Unicode có dấu');
      expect(tokens.every((t) => t.length >= 2), isTrue,
          reason: 'từ 1 ký tự bị lọc bỏ (where length >= 2)');
      expect(tokens, containsAll(<String>['nhan', 'vien', 'kinh', 'doanh', 'xyz']),
          reason: 'các từ khóa chính (đã bỏ dấu) phải xuất hiện trong tokens');
    });

    test('chữ HOA có dấu vẫn tokenize đúng nhờ toLowerCase trước strip', () {
      final tokens = JobModel.tokenize('KẾ TOÁN TRƯỞNG', 'FPT');
      expect(tokens, contains('ke'), reason: 'KẾ → ke');
      expect(tokens, contains('toan'), reason: 'TOÁN → toan');
      expect(tokens, contains('truong'), reason: 'TRƯỞNG → truong');
      expect(tokens, contains('fpt'), reason: 'FPT → fpt');
    });

    test('giữ nguyên +, #, . bên trong từ (C++, C#, React.js)', () {
      expect(
        JobModel.tokenize('C++ Developer'),
        // Words-first: 'c++' and 'developer' before any prefix.
        ['c++', 'developer', 'c+', 'de', 'dev', 'deve', 'devel', 'develo'],
        reason: "regex tách từ [^a-z0-9+#.]+ không cắt +/#/. — 'c++' là 1 từ; "
            'words-first ordering đặt cả 2 từ đầy đủ trước prefix',
      );
      expect(JobModel.tokenize('Lập trình C#'), contains('c#'),
          reason: 'C# phải giữ nguyên dấu # trong token');
      expect(JobModel.tokenize('React.js Engineer'), contains('react.js'),
          reason: 'dấu chấm trong tên công nghệ không bị tách từ');
    });

    test('prefix chỉ sinh cho độ dài 2..6 và nhỏ hơn độ dài từ', () {
      // từ 7 ký tự 'flutter' → prefix 2,3,4,5,6 ký tự (i < w.length && i <= 6)
      final tokens = JobModel.tokenize('flutter', '');
      expect(
        tokens,
        ['flutter', 'fl', 'flu', 'flut', 'flutt', 'flutte'],
        reason: 'từ 7 ký tự sinh đúng 5 prefix (độ dài 2..6), không có prefix '
            '7 ký tự trùng chính từ gốc',
      );
      // từ 2 ký tự không sinh prefix nào
      expect(JobModel.tokenize('IT'), ['it'],
          reason: 'từ 2 ký tự chỉ có chính nó, không có prefix con');
    });

    test('chuỗi rỗng / chỉ ký tự tách / từ 1 ký tự → không token', () {
      expect(JobModel.tokenize(''), isEmpty,
          reason: 'title rỗng, company bỏ trống → không có từ nào >= 2 ký tự');
      expect(JobModel.tokenize('', ''), isEmpty,
          reason: 'cả hai chuỗi rỗng → không token');
      expect(JobModel.tokenize('   , . ; - '), isEmpty,
          reason: 'chỉ chứa ký tự tách từ → token rỗng bị lọc hết');
      expect(JobModel.tokenize('a b c d'), isEmpty,
          reason: 'từ đơn ký tự đều bị lọc (length >= 2)');
    });

    test('giới hạn 60 token (take(60)) — mọi từ đầy đủ qua cap, chỉ prefix đuôi bị cắt', () {
      // Words-first ordering (bugfix #13): 11 full words first (11 slots)
      // then their 5 prefixes each (55 slots) = 66 total; take(60) keeps
      // all 11 full words + 49 prefixes. No full word is ever dropped by
      // the 60-cap any more.
      final words = [
        'baaaaa1', 'caaaaa2', 'daaaaa3', 'eaaaaa4', 'faaaaa5', //
        'gaaaaa6', 'haaaaa7', 'iaaaaa8', 'kaaaaa9', 'laaaa10', 'maaaaa0',
      ];
      final tokens = JobModel.tokenize(words.join(' '));
      expect(tokens.length, 60,
          reason: 'take(60) vẫn cắt ở 60; chỉ phần đuôi của PREFIXES bị bỏ');
      for (final w in words) {
        expect(tokens, contains(w),
            reason: '$w phải nằm trong 60 token — words-first đảm bảo mọi full word qua cap');
      }
    });
  });

  group('JobModel.isExpired', () {
    // Cài đặt mới (khớp web jobMapper.getDeadlineFullLabel + apply gate):
    // so sánh theo NGÀY (day-truncated). Deadline "hôm nay" vẫn còn hiệu lực
    // suốt ngày, chỉ hết hạn khi deadline < today.
    test('deadline null → không hết hạn', () {
      expect(job(applicationDeadline: null).isExpired, isFalse,
          reason: 'không có deadline thì isExpired luôn false');
    });

    test('deadline ngày mai → false', () {
      expect(
        job(applicationDeadline: DateTime.now().add(const Duration(days: 1)))
            .isExpired,
        isFalse,
      );
    });

    test('deadline hôm qua → true', () {
      expect(
        job(applicationDeadline: DateTime.now().subtract(const Duration(days: 1)))
            .isExpired,
        isTrue,
      );
    });

    test('deadline cùng ngày hôm nay (giờ đã trôi) vẫn chưa hết hạn', () {
      // Day comparison: midnight-today truncates to today, == today, not before.
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      expect(
        job(applicationDeadline: today).isExpired,
        isFalse,
        reason: 'web/jobMapper so sánh theo ngày — deadline hôm nay còn hiệu lực '
            'cả ngày (apply mới chặn khi deadline < today).',
      );
    });

    test('deadline tối hôm qua (23:59) → true', () {
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      expect(
        job(applicationDeadline: DateTime(yesterday.year, yesterday.month, yesterday.day, 23, 59))
            .isExpired,
        isTrue,
      );
    });
  });

  group('JobModel.hot', () {
    // Cài đặt thật (bình chẩn theo jobMapper.js): hot = (salaryMax ?? 0) >= 50.000.000
    // KHÔNG phụ thuộc applicationsCount / views / createdAt.
    test('salaryMax đúng ngưỡng 50.000.000 → hot (ranh giới >=)', () {
      expect(job(salaryMax: 50000000).hot, isTrue,
          reason: 'ngưỡng là >= 50000000 nên chính xác 50 triệu đã là hot');
    });

    test('salaryMax 49.999.999 → không hot', () {
      expect(job(salaryMax: 49999999).hot, isFalse,
          reason: 'dưới ngưỡng 50 triệu 1 đồng thôi cũng không hot');
    });

    test('salaryMax trên ngưỡng → hot', () {
      expect(job(salaryMax: 60000000).hot, isTrue,
          reason: '60 triệu > 50 triệu → hot');
    });

    test('salaryMax null → không hot, bất kể số ứng tuyển / ngày đăng', () {
      expect(
        job(
          salaryMax: null,
          applicationsCount: 999,
          createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        ).hot,
        isFalse,
        reason: 'hot chỉ nhìn salaryMax (null → 0); applicationsCount cao hay '
            'đăng gần đây cũng không làm job thành hot',
      );
    });
  });

  group('JobModel.isPublic', () {
    test('isApproved=true && status=OPEN → true', () {
      expect(job(isApproved: true, status: JobStatus.open).isPublic, isTrue,
          reason: 'đủ 2 điều kiện: đã duyệt + đang mở');
    });

    test('isApproved=false && status=OPEN → false', () {
      expect(job(isApproved: false, status: JobStatus.open).isPublic, isFalse,
          reason: 'thiếu isApproved → không công khai');
    });

    test('isApproved=true && status=CLOSED → false', () {
      expect(job(isApproved: true, status: JobStatus.closed).isPublic, isFalse,
          reason: 'thiếu status OPEN → không công khai');
    });

    test('isApproved=true && status=PAUSED → false', () {
      expect(job(isApproved: true, status: JobStatus.paused).isPublic, isFalse,
          reason: 'tạm dừng vẫn chưa công khai dù đã duyệt');
    });
  });

  group('JobModel.acceptsApplications', () {
    final future = DateTime.now().add(const Duration(days: 7));

    test('đã duyệt + OPEN + deadline tương lai → true', () {
      expect(
        job(isApproved: true, status: JobStatus.open, applicationDeadline: future)
            .acceptsApplications,
        isTrue,
        reason: 'isPublic && !isExpired → nhận đơn',
      );
    });

    test('đã duyệt + OPEN + deadline null → vẫn true', () {
      expect(
        job(isApproved: true, status: JobStatus.open, applicationDeadline: null)
            .acceptsApplications,
        isTrue,
        reason: 'deadline null → isExpired false → vẫn nhận đơn vô hạn',
      );
    });

    test('chưa duyệt → false dù còn hạn', () {
      expect(
        job(isApproved: false, status: JobStatus.open, applicationDeadline: future)
            .acceptsApplications,
        isFalse,
        reason: 'thiếu isApproved → !isPublic → không nhận đơn',
      );
    });

    test('status PAUSED → false dù đã duyệt và còn hạn', () {
      expect(
        job(isApproved: true, status: JobStatus.paused, applicationDeadline: future)
            .acceptsApplications,
        isFalse,
        reason: 'thiếu status OPEN → !isPublic → không nhận đơn',
      );
    });

    test('đã duyệt + OPEN nhưng hết hạn → false', () {
      expect(
        job(
          isApproved: true,
          status: JobStatus.open,
          applicationDeadline: DateTime.now().subtract(const Duration(days: 1)),
        ).acceptsApplications,
        isFalse,
        reason: 'isExpired → không nhận đơn dù job công khai',
      );
    });
  });

  group('JobModel.isPendingReview / isRejected', () {
    test('DRAFT && !isApproved → pending review', () {
      expect(job(status: JobStatus.draft, isApproved: false).isPendingReview, isTrue,
          reason: 'nháp chưa duyệt → chờ admin phê duyệt');
    });

    test('DRAFT nhưng đã duyệt → không còn chờ', () {
      expect(job(status: JobStatus.draft, isApproved: true).isPendingReview, isFalse,
          reason: 'isApproved=true loại khỏi hàng chờ');
    });

    test('OPEN && !isApproved → không phải pending (chỉ DRAFT mới chờ)', () {
      expect(job(status: JobStatus.open, isApproved: false).isPendingReview, isFalse,
          reason: 'AdminPendingJobsPage chỉ coi DRAFT && !isApproved là pending');
    });

    test('CLOSED && !isApproved → rejected', () {
      expect(job(status: JobStatus.closed, isApproved: false).isRejected, isTrue,
          reason: 'đóng + chưa duyệt = job đã bị từ chối, cấm mở lại');
    });

    test('CLOSED nhưng đã duyệt → không phải rejected', () {
      expect(job(status: JobStatus.closed, isApproved: true).isRejected, isFalse,
          reason: 'isApproved=true → closed bình thường, không phải bị từ chối');
    });

    test('OPEN && !isApproved → không phải rejected', () {
      expect(job(status: JobStatus.open, isApproved: false).isRejected, isFalse,
          reason: 'rejected yêu cầu status == CLOSED');
    });
  });

  group('JobModel.minExperienceYears', () {
    test('map đúng mỗi ExperienceLevel ra số năm tối thiểu', () {
      const cases = {
        ExperienceLevel.intern: 0.0,
        ExperienceLevel.fresher: 0.5,
        ExperienceLevel.junior: 1.0,
        ExperienceLevel.mid: 3.0,
        ExperienceLevel.senior: 5.0,
        ExperienceLevel.lead: 7.0,
      };
      cases.forEach((level, years) {
        expect(job(experienceLevel: level).minExperienceYears, years,
            reason: '$level → tối thiểu $years năm kinh nghiệm');
      });
    });
  });

  group('JobModel.tags & applicationsLabel', () {
    test('tags = tên các skill bắt buộc, lọc tên rỗng', () {
      final model = job(requiredSkills: const [
        JobSkillRef(skillId: 's1', skillName: 'Flutter'),
        JobSkillRef(skillName: 'REST API', isRequired: false),
        JobSkillRef(skillName: ''), // skill chưa đặt tên → bị lọc
      ]);
      expect(model.tags, ['Flutter', 'REST API'],
          reason: 'lấy skillName của mọi skill, bỏ entry chuỗi rỗng');
    });

    test('không có skill → tags rỗng', () {
      expect(job().tags, isEmpty, reason: 'requiredSkills rỗng → tags rỗng');
    });

    test('applicationsLabel hiển thị kèm đơn vị "người"', () {
      expect(job(applicationsCount: 25).applicationsLabel, '25 người',
          reason: 'label = "\$applicationsCount người"');
    });
  });

  group('JobSkillRef', () {
    test('fromJson đọc đủ trường camelCase', () {
      final s = JobSkillRef.fromJson(const {
        'skillId': 's1',
        'skillName': 'Flutter',
        'isRequired': true,
        'minExperienceYears': 2,
        'weight': 5,
      });
      expect(s.skillId, 's1', reason: 'skillId là String? tùy chọn');
      expect(s.skillName, 'Flutter', reason: 'skillName bắt buộc');
      expect(s.isRequired, isTrue, reason: 'isRequired mặc định true');
      expect(s.minExperienceYears, 2.0, reason: 'num.toDouble() → 2.0');
      expect(s.weight, 5, reason: 'num.toInt() → 5');
    });

    test('fromJson nhận alias name/required/minYears và giá trị mặc định', () {
      final s = JobSkillRef.fromJson(const {
        'name': 'REST API',
        'required': false,
        'minYears': 1.5,
      });
      expect(s.skillName, 'REST API', reason: "alias 'name' cho skillName");
      expect(s.isRequired, isFalse, reason: "alias 'required' cho isRequired");
      expect(s.minExperienceYears, 1.5, reason: "alias 'minYears' cho minExperienceYears");
      expect(s.weight, 1, reason: 'weight mặc định 1 khi thiếu');
      expect(s.skillId, isNull, reason: 'skillId mặc định null khi thiếu');

      final empty = JobSkillRef.fromJson(const {});
      expect(empty.skillName, '', reason: 'skillName mặc định chuỗi rỗng');
      expect(empty.isRequired, isTrue, reason: 'isRequired mặc định true');
      expect(empty.minExperienceYears, 0, reason: 'minExperienceYears mặc định 0');
    });

    test('toJson bỏ skillId khi null; round-trip giữ nguyên các trường', () {
      const s = JobSkillRef(skillName: 'Dart', minExperienceYears: 1.5, weight: 3);
      final json = s.toJson();
      expect(json.containsKey('skillId'), isFalse,
          reason: 'skillId null → không xuất key (tránh ghi null xuống Firestore)');
      final rt = JobSkillRef.fromJson(json);
      expect(rt.skillName, s.skillName, reason: 'round-trip skillName');
      expect(rt.isRequired, s.isRequired, reason: 'round-trip isRequired');
      expect(rt.minExperienceYears, s.minExperienceYears,
          reason: 'round-trip minExperienceYears');
      expect(rt.weight, s.weight, reason: 'round-trip weight');
    });
  });

  group('JobDescription', () {
    test('fromMap đọc key camelCase và key snake_case alias', () {
      final d = JobDescription.fromMap(const {
        'moTaCongViec': ['Xây dựng tính năng'],
        'yeu_cau_ung_vien': ['Biết Dart'],
        'quyen_loi': ['13 tháng lương'],
        'thoi_gian_lam_viec': 'Thứ 2 - Thứ 6',
        'yeuCauKinhNghiem': '1 - 2 năm',
      });
      expect(d.moTaCongViec, ['Xây dựng tính năng'], reason: 'camelCase key');
      expect(d.yeuCauUngVien, ['Biết Dart'], reason: 'snake_case alias yeu_cau_ung_vien');
      expect(d.quyenLoi, ['13 tháng lương'], reason: 'snake_case alias quyen_loi');
      expect(d.thoiGianLamViec, 'Thứ 2 - Thứ 6', reason: 'snake_case alias thoi_gian_lam_viec');
      expect(d.yeuCauKinhNghiem, '1 - 2 năm', reason: 'camelCase key');
      expect(d.yeuCauBangCap, 'Không yêu cầu',
          reason: 'yeuCauBangCap mặc định "Không yêu cầu" khi thiếu');
    });

    test('fromMap nhận chuỗi cho trường danh sách → tự tách dòng', () {
      final d = JobDescription.fromMap(const {
        'moTaCongViec': 'Dòng 1\n- Dòng 2 dạng bullet',
      });
      expect(d.moTaCongViec, ['Dòng 1', 'Dòng 2 dạng bullet'],
          reason: '_lines: String → _splitBullets tách theo dòng và bỏ đầu bullet');
    });

    test('parse văn bản thuần: tách dòng, bỏ marker -/*/•, lọc dòng trống', () {
      final d = JobDescription.parse(
        '- Viết code Flutter\n• Fix bug\n* Code review\n\n   \nĐào tạo interno',
        experienceLabel: '1 - 2 năm',
      );
      expect(
        d.moTaCongViec,
        ['Viết code Flutter', 'Fix bug', 'Code review', 'Đào tạo interno'],
        reason: 'văn bản không phải JSON → toàn bộ vào moTaCongViec, đã bỏ marker '
            'bullet và dòng trống',
      );
      expect(d.yeuCauKinhNghiem, '1 - 2 năm',
          reason: 'experienceLabel được đẩy sang yeuCauKinhNghiem ở nhánh plain text');
    });

    test('parse chuỗi JSON bắt đầu bằng "{" → parse như object', () {
      final d = JobDescription.parse(
        jsonEncode(const {
          'moTaCongViec': ['Làm backend'],
          'quyenLoi': ['Phụ cấp'],
        }),
        experienceLabel: 'Senior',
      );
      expect(d.moTaCongViec, ['Làm backend'], reason: 'chuỗi JSON object → fromMap');
      expect(d.quyenLoi, ['Phụ cấp'], reason: 'đọc đủ trường lồng nhau');
      expect(d.yeuCauKinhNghiem, '',
          reason: 'nhánh Map: experienceLabel bị bỏ qua, lấy giá trị trong map '
              '(mặc định chuỗi rỗng)');
    });

    test('parse chuỗi "{" hỏng cú pháp → fallback tách dòng như plain text', () {
      final d = JobDescription.parse('{json hỏng cú pháp}');
      expect(d.moTaCongViec, ['{json hỏng cú pháp}'],
          reason: 'jsonDecode ném lỗi → bắt lỗi và rơi về nhánh _splitBullets');
    });

    test('parse null → rỗng và giữ experienceLabel', () {
      final d = JobDescription.parse(null, experienceLabel: 'Dưới 1 năm');
      expect(d.isEmpty, isTrue, reason: 'null → cả 3 danh sách đều rỗng');
      expect(d.yeuCauKinhNghiem, 'Dưới 1 năm',
          reason: 'null → kinh nghiệm lấy từ nhãn level truyền vào');
    });

    test('isEmpty đúng ranh giới: chỉ cần 1 trong 3 danh sách có phần tử là false', () {
      expect(const JobDescription().isEmpty, isTrue,
          reason: 'constructor mặc định → rỗng');
      expect(const JobDescription(quyenLoi: ['X']).isEmpty, isFalse,
          reason: 'có quyền lợi → không rỗng');
    });

    test('plainText ghép 3 khối có tiền tố "Yêu cầu:" / "Quyền lợi:"', () {
      const d = JobDescription(
        moTaCongViec: ['Mô tả A', 'Mô tả B'],
        yeuCauUngVien: ['Yêu cầu C'],
        quyenLoi: ['Quyền lợi D'],
      );
      expect(
        d.plainText,
        'Mô tả A\nMô tả B\nYêu cầu: Yêu cầu C\nQuyền lợi: Quyền lợi D',
        reason: 'plainText nối mô tả trước, sau đó 2 khối còn lại có nhãn',
      );
    });

    test('toJson → fromMap round-trip giữ nguyên mọi trường', () {
      const d = JobDescription(
        moTaCongViec: ['A', 'B'],
        yeuCauUngVien: ['C'],
        quyenLoi: ['D'],
        thoiGianLamViec: 'Toàn thời gian',
        yeuCauKinhNghiem: '2 - 4 năm',
        yeuCauBangCap: 'Đại học',
      );
      final rt = JobDescription.fromMap(d.toJson());
      expect(rt.moTaCongViec, d.moTaCongViec, reason: 'round-trip moTaCongViec');
      expect(rt.yeuCauUngVien, d.yeuCauUngVien, reason: 'round-trip yeuCauUngVien');
      expect(rt.quyenLoi, d.quyenLoi, reason: 'round-trip quyenLoi');
      expect(rt.thoiGianLamViec, d.thoiGianLamViec, reason: 'round-trip thoiGianLamViec');
      expect(rt.yeuCauKinhNghiem, d.yeuCauKinhNghiem, reason: 'round-trip yeuCauKinhNghiem');
      expect(rt.yeuCauBangCap, d.yeuCauBangCap, reason: 'round-trip yeuCauBangCap');
    });
  });

  group('JobModel.fromJson', () {
    test('đọc đủ alias khóa (id/title/employerUid/skills/positions/deadline)', () {
      final model = JobModel.fromJson({
        'id': 'job-9',
        'employerUid': 'emp-9',
        'title': 'Senior Flutter Developer',
        'employerName': 'FPT Software',
        'salaryMin': 30000000,
        'salaryMax': 60000000,
        'deadline': Timestamp.fromDate(DateTime.utc(2027, 1, 15)),
        'positions': 5,
        'status': 'CLOSED',
        'isApproved': true,
        'experienceLevel': 'SENIOR',
        'workMode': 'REMOTE',
        'jobType': 'FULL_TIME',
        'skills': const [
          {
            'skillId': 's1',
            'skillName': 'Flutter',
            'isRequired': true,
            'minExperienceYears': 2,
            'weight': 5,
          },
          {'name': 'REST API', 'required': false, 'minYears': 1.5},
        ],
        'applicationsCount': 40,
        'createdAt': '2026-01-01T00:00:00.000Z',
        'description': const {
          'moTaCongViec': ['Xây dựng app'],
          'quyen_loi': ['13 tháng lương'],
        },
      });
      expect(model.jobId, 'job-9', reason: "alias 'id' cho jobId");
      expect(model.employerId, 'emp-9', reason: "alias 'employerUid' cho employerId");
      expect(model.jobTitle, 'Senior Flutter Developer', reason: "alias 'title' cho jobTitle");
      expect(model.applicationDeadline!.isAtSameMomentAs(DateTime.utc(2027, 1, 15)),
          isTrue,
          reason: "alias 'deadline' + Timestamp → DateTime: Timestamp.toDate() "
              'trả DateTime theo giờ local nên phải so cùng thời điểm (instant), '
              'không so == vì khác cờ isUtc');
      expect(model.positionsAvailable, 5, reason: "alias 'positions' cho positionsAvailable");
      expect(model.status, JobStatus.closed, reason: 'wire value CLOSED → enum');
      expect(model.isApproved, isTrue, reason: 'isApproved đọc thẳng');
      expect(model.experienceLevel, ExperienceLevel.senior, reason: 'wire value SENIOR → enum');
      expect(model.workMode, WorkMode.remote, reason: 'wire value REMOTE → enum');
      expect(model.jobType, JobType.fullTime, reason: 'wire value FULL_TIME → enum');
      expect(model.requiredSkills.length, 2, reason: "alias 'skills' cho requiredSkills");
      expect(model.requiredSkills[1].skillName, 'REST API',
          reason: 'skill lồng nhau dùng alias name/required/minYears');
      expect(model.requiredSkills[1].isRequired, isFalse,
          reason: 'skill lồng nhau: required=false');
      expect(model.requiredSkills[1].minExperienceYears, 1.5,
          reason: 'skill lồng nhau: minYears=1.5');
      expect(model.applicationsCount, 40, reason: 'applicationsCount num → int');
      expect(model.createdAt, DateTime.utc(2026, 1, 1),
          reason: 'chuỗi ISO 8601 được DateTime.tryParse');
      expect(model.description.moTaCongViec, ['Xây dựng app'],
          reason: 'description dạng Map → parse cấu trúc');
      expect(model.description.quyenLoi, ['13 tháng lương'],
          reason: 'description lồng nhau dùng key snake_case');
    });

    test('map rỗng → đầy đủ giá trị mặc định an toàn', () {
      final model = JobModel.fromJson(const {});
      expect(model.jobId, '', reason: 'jobId mặc định chuỗi rỗng');
      expect(model.employerId, '', reason: 'employerId mặc định chuỗi rỗng');
      expect(model.employerName, 'Công ty chưa cập nhật',
          reason: 'employerName fallback hiển thị');
      expect(model.jobTitle, 'Tin tuyển dụng chưa có tiêu đề',
          reason: 'jobTitle fallback hiển thị');
      expect(model.status, JobStatus.open, reason: 'parseJobStatus fallback OPEN');
      expect(model.isApproved, isFalse, reason: 'isApproved mặc định false');
      expect(model.experienceLevel, ExperienceLevel.junior,
          reason: 'parseLevel fallback JUNIOR (khác default constructor là INTERN)');
      expect(model.workMode, WorkMode.onsite, reason: 'workMode fallback ONSITE');
      expect(model.jobType, JobType.fullTime, reason: 'jobType fallback FULL_TIME');
      expect(model.salaryCurrency, 'VND', reason: 'tiền tệ mặc định VND');
      expect(model.salaryPeriod, SalaryPeriod.month, reason: 'kỳ lương mặc định MONTH');
      expect(model.positionsAvailable, 1, reason: 'số vị trí mặc định 1');
      expect(model.requiredSkills, isEmpty, reason: 'không skill nào');
      expect(model.applicationsCount, 0, reason: 'số ứng tuyển mặc định 0');
      expect(model.source, 'database', reason: 'nguồn mặc định database');
      expect(model.applicationDeadline, isNull, reason: 'deadline mặc định null');
      expect(model.description.isEmpty, isTrue,
          reason: 'description null → JobDescription rỗng');
      expect(model.description.yeuCauKinhNghiem, '1 - 2 năm',
          reason: 'description null + level fallback JUNIOR → nhãn "1 - 2 năm"');
    });

    test('description dạng chuỗi JSON / plain text được parse đúng', () {
      final asJson = JobModel.fromJson({
        'jobDescription': jsonEncode(const {
          'moTaCongViec': ['Làm frontend'],
        }),
      });
      expect(asJson.description.moTaCongViec, ['Làm frontend'],
          reason: "chuỗi JSON nằm ở key 'jobDescription' (alias) vẫn được parse");
      expect(asJson.rawDescription, isNotNull,
          reason: 'jobDescription là String → giữ nguyên bản gốc vào rawDescription');

      final asText = JobModel.fromJson(const {
        'description': '- Dòng mô tả 1\n- Dòng mô tả 2',
      });
      expect(asText.description.moTaCongViec, ['Dòng mô tả 1', 'Dòng mô tả 2'],
          reason: 'plain text → tách dòng bullet vào moTaCongViec');
    });

    test('mục không phải Map trong requiredSkills bị bỏ qua (whereType<Map>)', () {
      final model = JobModel.fromJson(const {
        'requiredSkills': ['chuỗi lãng phí', 42, {'skillName': 'Dart'}],
      });
      expect(model.requiredSkills.length, 1,
          reason: 'chỉ phần tử Map mới là JobSkillRef hợp lệ');
      expect(model.requiredSkills.single.skillName, 'Dart',
          reason: 'skill hợp lệ vẫn được parse');
    });
  });

  group('JobModel.toJson', () {
    test('bỏ khóa null (ô chọn tùy chọn) và giữ khóa bắt buộc', () {
      final map = job().toJson(); // salaryMax/location/categoryId... đều null
      expect(map.containsKey('salaryMax'), isFalse,
          reason: 'salaryMax null → không ghi key, tránh ghi null xuống Firestore');
      expect(map.containsKey('salaryMin'), isTrue, reason: 'salaryMin có giá trị → có key');
      expect(map.containsKey('location'), isFalse, reason: 'location null → bỏ key');
      expect(map.containsKey('categoryId'), isFalse, reason: 'categoryId null → bỏ key');
      expect(map.containsKey('applicationDeadline'), isFalse,
          reason: 'deadline null → bỏ key');
      expect(map.containsKey('jobDescription'), isFalse,
          reason: 'rawDescription null → bỏ key');
      expect(map['jobId'], 'job-1', reason: 'khóa bắt buộc luôn có');
    });

    test('enum serialize thành wire value UPPER_SNAKE_CASE', () {
      final map = job(
        status: JobStatus.open,
        workMode: WorkMode.onsite,
        jobType: JobType.fullTime,
        experienceLevel: ExperienceLevel.mid,
      ).toJson();
      expect(map['status'], 'OPEN', reason: 'JobStatus.open → OPEN');
      expect(map['workMode'], 'ONSITE', reason: 'WorkMode.onsite → ONSITE');
      expect(map['jobType'], 'FULL_TIME', reason: 'JobType.fullTime → FULL_TIME');
      expect(map['experienceLevel'], 'MID', reason: 'ExperienceLevel.mid → MID');
      expect(map['salaryPeriod'], 'MONTH', reason: 'SalaryPeriod.month → MONTH');
    });

    test('deadline/createdAt thành Timestamp; updatedAt là FieldValue', () {
      final deadline = DateTime.utc(2027, 6, 30, 9, 30);
      final createdAt = DateTime.utc(2026, 1, 1, 8);
      final map = job(applicationDeadline: deadline, createdAt: createdAt).toJson();
      expect(map['applicationDeadline'], isA<Timestamp>(),
          reason: 'deadline lưu xuống Firestore dưới dạng Timestamp');
      expect((map['applicationDeadline'] as Timestamp).toDate().isAtSameMomentAs(deadline),
          isTrue,
          reason: 'Timestamp giữ nguyên microgiây của DateTime gốc (so instant — '
              'toDate() trả local time nên không dùng == với DateTime.utc)');
      expect((map['createdAt'] as Timestamp).toDate().isAtSameMomentAs(createdAt),
          isTrue,
          reason: 'createdAt đã có → Timestamp thay vì serverTimestamp (so instant)');
      expect(map['updatedAt'], isA<FieldValue>(),
          reason: 'updatedAt luôn là FieldValue.serverTimestamp() (đặt bởi server)');
    });

    test('createdAt null → FieldValue.serverTimestamp()', () {
      final map = job(createdAt: null).toJson();
      expect(map['createdAt'], isA<FieldValue>(),
          reason: 'chưa có createdAt để server gán thời điểm tạo');
    });

    test('titleTokens rỗng → tự tokenize(title, employerName)', () {
      final map = job().toJson(); // titleTokens mặc định rỗng
      expect(map['titleTokens'], JobModel.tokenize('Kế toán trưởng', 'Công ty Cổ phần FPT'),
          reason: 'toJson sinh token tìm kiếm khi model chưa có sẵn');
    });

    test('titleTokens có sẵn → giữ nguyên, không tokenize lại', () {
      final map = job().copyWith(jobTitle: 'Kế toán trưởng').toJson();
      // copyWith không nhận titleTokens nên vẫn rỗng → tự sinh; kiểm chứng nhánh
      // "có sẵn" bằng một model dựng trực tiếp:
      final model = JobModel(
        jobId: 'j',
        employerId: 'e',
        employerName: 'FPT',
        jobTitle: 'Kế toán trưởng',
        titleTokens: const ['ke', 'toan'],
      );
      expect(model.toJson()['titleTokens'], ['ke', 'toan'],
          reason: 'token đã có trong model thì dùng lại (không ghi đè)');
      expect(map['titleTokens'], isNotEmpty,
          reason: 'titleTokens rỗng qua copyWith vẫn được sinh ở toJson');
    });

    test('description và requiredSkills serialize lồng nhau', () {
      final map = job(
        requiredSkills: const [
          JobSkillRef(skillId: 's1', skillName: 'Flutter', minExperienceYears: 2),
        ],
      ).toJson();
      expect(map['description'], isA<Map<String, dynamic>>(),
          reason: 'description lưu thành Map (không phải chuỗi JSON)');
      expect((map['description'] as Map)['yeuCauBangCap'], 'Không yêu cầu',
          reason: 'description.toJson có đủ các trường mặc định');
      expect(map['requiredSkills'], const [
        {'skillId': 's1', 'skillName': 'Flutter', 'isRequired': true,
         'minExperienceYears': 2.0, 'weight': 1},
      ], reason: 'mỗi skill thành 1 Map đầy đủ trường');
    });
  });

  group('JobModel fromJson(toJson()) round-trip', () {
    test('giữ nguyên dữ liệu sau khi ghi xuống rồi đọc lại', () {
      final deadline = DateTime.utc(2027, 6, 30, 9, 30);
      final createdAt = DateTime.utc(2026, 1, 1, 8);
      final original = JobModel(
        jobId: 'job-rt',
        employerId: 'emp-rt',
        employerName: 'Công ty TNHH ABC',
        jobTitle: 'Lập trình viên Flutter',
        description: const JobDescription(
          moTaCongViec: ['Viết code', 'Review code'],
          yeuCauUngVien: ['Biết Dart'],
          quyenLoi: ['Lương tháng 13'],
          thoiGianLamViec: 'Thứ 2 - Thứ 6',
          yeuCauKinhNghiem: '2 - 4 năm',
          yeuCauBangCap: 'Đại học',
        ),
        rawDescription: 'Viết code\nReview code',
        salaryMin: 25000000,
        salaryMax: 40000000,
        city: 'Hà Nội',
        workMode: WorkMode.hybrid,
        jobType: JobType.fullTime,
        experienceLevel: ExperienceLevel.senior,
        positionsAvailable: 3,
        applicationDeadline: deadline,
        status: JobStatus.open,
        isApproved: true,
        requiredSkills: const [
          JobSkillRef(skillId: 's1', skillName: 'Flutter', minExperienceYears: 2, weight: 5),
        ],
        applicationsCount: 7,
        source: 'mock',
        createdAt: createdAt,
      );

      final rt = JobModel.fromJson(original.toJson());

      expect(rt.jobId, original.jobId, reason: 'round-trip jobId');
      expect(rt.employerId, original.employerId, reason: 'round-trip employerId');
      expect(rt.employerName, original.employerName, reason: 'round-trip employerName');
      expect(rt.jobTitle, original.jobTitle, reason: 'round-trip jobTitle');
      expect(rt.description.moTaCongViec, original.description.moTaCongViec,
          reason: 'round-trip description.moTaCongViec (list lồng)');
      expect(rt.description.yeuCauUngVien, original.description.yeuCauUngVien,
          reason: 'round-trip description.yeuCauUngVien');
      expect(rt.description.quyenLoi, original.description.quyenLoi,
          reason: 'round-trip description.quyenLoi');
      expect(rt.description.thoiGianLamViec, original.description.thoiGianLamViec,
          reason: 'round-trip description.thoiGianLamViec');
      expect(rt.description.yeuCauBangCap, original.description.yeuCauBangCap,
          reason: 'round-trip description.yeuCauBangCap');
      expect(rt.rawDescription, original.rawDescription, reason: 'round-trip rawDescription');
      expect(rt.salaryMin, original.salaryMin, reason: 'round-trip salaryMin');
      expect(rt.salaryMax, original.salaryMax, reason: 'round-trip salaryMax');
      expect(rt.city, original.city, reason: 'round-trip city (chuỗi có dấu)');
      expect(rt.workMode, original.workMode, reason: 'round-trip workMode');
      expect(rt.jobType, original.jobType, reason: 'round-trip jobType');
      expect(rt.experienceLevel, original.experienceLevel, reason: 'round-trip experienceLevel');
      expect(rt.positionsAvailable, original.positionsAvailable, reason: 'round-trip positionsAvailable');
      expect(rt.applicationDeadline!.isAtSameMomentAs(deadline), isTrue,
          reason: 'round-trip deadline: DateTime → Timestamp → DateTime giữ đúng '
              'thời điểm (so instant vì toDate() trả local time)');
      expect(rt.status, original.status, reason: 'round-trip status');
      expect(rt.isApproved, original.isApproved, reason: 'round-trip isApproved');
      expect(rt.requiredSkills.length, 1, reason: 'round-trip requiredSkills: đủ 1 skill');
      expect(rt.requiredSkills.single.skillId, 's1', reason: 'round-trip skill.skillId');
      expect(rt.requiredSkills.single.skillName, 'Flutter', reason: 'round-trip skill.skillName');
      expect(rt.requiredSkills.single.minExperienceYears, 2,
          reason: 'round-trip skill.minExperienceYears');
      expect(rt.requiredSkills.single.weight, 5, reason: 'round-trip skill.weight');
      expect(rt.applicationsCount, 7, reason: 'round-trip applicationsCount');
      expect(rt.source, 'mock', reason: 'round-trip source');
      expect(rt.createdAt!.isAtSameMomentAs(createdAt), isTrue,
          reason: 'round-trip createdAt: DateTime → Timestamp → DateTime giữ đúng '
              'thời điểm (so instant vì toDate() trả local time)');
      expect(rt.titleTokens, JobModel.tokenize(original.jobTitle, original.employerName),
          reason: 'titleTokens trống khi ghi → được sinh từ title+employer, đọc lại nguyên vẹn');
      expect(rt.acceptsApplications, isTrue,
          reason: 'sau round-trip, job đã duyệt + OPEN + còn hạn vẫn nhận đơn');
    });
  });
}
