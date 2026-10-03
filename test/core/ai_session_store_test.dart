import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/config/app_config.dart';
import 'package:jobhub_prm393/core/services/ai_session_store.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/job_model.dart';
import 'package:jobhub_prm393/shared/models/recommendation_models.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Unit tests cho [AiSessionStore] (port của utils/aiScores.js):
/// cap 20 + thứ tự mới nhất trước, CRUD session, migrate key cũ
/// 'jobhub.aiScores' và round-trip snapshot/jobFromSnapshot.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    // Mỗi test một bộ giá trị mock mới để cách ly dữ liệu.
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  group('AiSessionStore — cap phiên & thứ tự', () {
    test(
        'lưu 25 phiên → loadSessions chỉ còn 20, mới nhất đứng đầu, 5 cũ nhất bị cắt',
        () async {
      final store = await _newStore();
      for (var i = 1; i <= 25; i++) {
        await store.saveSession(
          cvName: 'CV $i',
          method: 'ai',
          scores: {
            'job_$i': {'ai': _jobScore('job_$i', 50 + i)},
          },
          jobs: const [],
        );
        // saveSession sinh id từ millisecondsSinceEpoch → tách millis
        // để id của 25 phiên khác nhau.
        await _tick();
      }

      final sessions = store.loadSessions();
      expect(
        sessions,
        hasLength(AppConfig.aiSessionCap),
        reason:
            'Cap là ${AppConfig.aiSessionCap}: lưu 25 phiên phải cắt bớt 5 phiên cũ nhất',
      );
      expect(
        sessions.first.cvName,
        'CV 25',
        reason: 'Phiên mới nhất (lưu cuối) phải đứng đầu danh sách',
      );
      expect(
        sessions.last.cvName,
        'CV 6',
        reason: 'CV 1..CV 5 là 5 phiên cũ nhất bị cắt; cũ nhất còn lại là CV 6',
      );

      final names = sessions.map((s) => s.cvName).toSet();
      for (var i = 1; i <= 5; i++) {
        expect(
          names.contains('CV $i'),
          isFalse,
          reason: 'Phiên cũ nhất CV $i phải đã bị xoá khỏi store',
        );
      }
      for (var i = 6; i <= 25; i++) {
        expect(
          names.contains('CV $i'),
          isTrue,
          reason: 'Phiên CV $i vẫn phải được giữ lại',
        );
      }
      expect(
        store.countSessions(),
        AppConfig.aiSessionCap,
        reason: 'countSessions phải khớp độ dài của loadSessions',
      );
    });
  });

  group('AiSessionStore — save/get/delete/clear', () {
    test(
        'saveSession trim cvName + chỉ giữ job có điểm → getSession trả đúng nội dung',
        () async {
      final store = await _newStore();
      final scored = _job(id: 'job_9');
      final unScored = _job(id: 'job_10'); // không có trong scores → bị loại

      final saved = await store.saveSession(
        cvName: '  my_cv.pdf  ',
        method: 'both',
        scores: {
          'job_9': {
            'ai': _jobScore('job_9', 87),
            'sql': _jobScore('job_9', 74, source: 'sql'),
          },
        },
        jobs: [scored, unScored],
      );

      expect(
        saved.cvName,
        'my_cv.pdf',
        reason: 'cvName phải được trim trước khi lưu',
      );
      expect(
        saved.id,
        startsWith('session_'),
        reason: 'Id phiên có dạng session_<millis>',
      );
      expect(
        saved.jobCount,
        1,
        reason: 'jobCount = số jobId trong scores (không tính số job truyền vào)',
      );
      expect(
        saved.jobs.keys,
        ['job_9'],
        reason: 'Chỉ job nằm trong scores mới được giữ snapshot trong phiên',
      );

      final loaded = store.getSession(saved.id);
      expect(
        loaded,
        isNotNull,
        reason: 'getSession phải tìm thấy phiên vừa lưu theo id',
      );
      expect(loaded!.id, saved.id, reason: 'id');
      expect(loaded.cvName, 'my_cv.pdf', reason: 'cvName');
      expect(loaded.method, 'both', reason: 'method');
      expect(
        loaded.scoredAt,
        saved.scoredAt,
        reason: 'scoredAt phải round-trip qua JSON mà không đổi thời điểm',
      );
      expect(loaded.jobCount, 1, reason: 'jobCount sau khi đọc lại');
      final ai = loaded.scores['job_9']!['ai']!;
      expect(ai.matchScore, 87, reason: 'Điểm AI của job_9');
      expect(ai.source, 'ai', reason: 'source của điểm AI');
      expect(
        ai.missingSkills,
        ['Docker', 'K8s'],
        reason: 'missingSkills phải round-trip nguyên vẹn',
      );
      expect(
        loaded.scores['job_9']!['sql']!.matchScore,
        74,
        reason: 'Điểm SQL của job_9',
      );
      expect(
        loaded.jobs['job_9']!['jobTitle'],
        'Flutter Developer',
        reason: 'Snapshot job phải được lưu kèm và đọc lại được',
      );
      expect(
        store.getSession('khong_ton_tai'),
        isNull,
        reason: 'getSession với id lạ phải trả null',
      );
    });

    test('saveSession với cvName rỗng → dùng "Không rõ"', () async {
      final store = await _newStore();
      final saved = await store.saveSession(
        cvName: '   ',
        method: 'ai',
        scores: const {},
        jobs: const [],
      );
      expect(
        saved.cvName,
        'Không rõ',
        reason: 'cvName rỗng/toàn khoảng trắng phải được thay bằng "Không rõ"',
      );
      expect(
        store.getSession(saved.id)!.cvName,
        'Không rõ',
        reason: 'Giá trị thay thế phải được lưu bền vào store',
      );
    });

    test('deleteSession chỉ xoá đúng phiên được chọn', () async {
      final store = await _newStore();
      final ids = <String>[];
      for (var i = 1; i <= 3; i++) {
        final s = await store.saveSession(
          cvName: 'CV $i',
          method: 'ai',
          scores: {
            'job_$i': {'ai': _jobScore('job_$i', i * 10)},
          },
          jobs: const [],
        );
        ids.add(s.id);
        await _tick();
      }

      await store.deleteSession(ids[1]);

      final rest = store.loadSessions();
      expect(rest, hasLength(2), reason: 'Xoá 1 trong 3 phiên → còn đúng 2');
      expect(
        rest.map((s) => s.id),
        isNot(contains(ids[1])),
        reason: 'Phiên bị xoá không còn xuất hiện trong store',
      );
      expect(
        rest.map((s) => s.id),
        containsAll([ids[0], ids[2]]),
        reason: 'Hai phiên còn lại phải nguyên vẹn',
      );
      expect(
        store.getSession(ids[1]),
        isNull,
        reason: 'getSession của phiên đã xoá phải trả null',
      );
    });

    test('clearSessions xoá toàn bộ phiên và remove key trong SharedPreferences',
        () async {
      final store = await _newStore();
      await store.saveSession(
        cvName: 'A.pdf',
        method: 'ai',
        scores: {
          'job_1': {'ai': _jobScore('job_1', 80)},
        },
        jobs: const [],
      );
      await _tick();
      await store.saveSession(
        cvName: 'B.pdf',
        method: 'sql',
        scores: {
          'job_2': {'sql': _jobScore('job_2', 66, source: 'sql')},
        },
        jobs: const [],
      );
      expect(
        store.countSessions(),
        2,
        reason: 'Tiền điều kiện: đã lưu 2 phiên',
      );

      await store.clearSessions();

      expect(
        store.loadSessions(),
        isEmpty,
        reason: 'clearSessions phải xoá mọi phiên',
      );
      expect(store.countSessions(), 0, reason: 'countSessions về 0 sau khi clear');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getString(AiSessionStore.key),
        isNull,
        reason:
            'clearSessions phải remove hẳn key "${AiSessionStore.key}" khỏi SharedPreferences',
      );
    });
  });

  group('AiSessionStore — migrate key cũ "jobhub.aiScores"', () {
    // Định dạng cũ (theo _migrateLegacy trong lib): JSON *Map*
    // jobId → {match_score, source, ...}, không phải list phiên.
    Map<String, Object> legacyInitial() => <String, Object>{
          AiSessionStore.legacyKey: jsonEncode(<String, dynamic>{
            'job_1': {'match_score': 85, 'source': 'ai'},
            'job_2': {'match_score': 42, 'source': 'ai'},
          }),
        };

    test('loadSessions thấy các phiên đã migrate (1 phiên session_legacy)',
        () async {
      final store = await _newStore(legacyInitial());

      final sessions = store.loadSessions();

      expect(
        sessions,
        hasLength(1),
        reason:
            'Dữ liệu cũ là map jobId→điểm nên được gộp thành đúng 1 phiên migrate',
      );
      final migrated = sessions.single;
      expect(migrated.id, 'session_legacy', reason: 'id phiên migrate cố định');
      expect(migrated.cvName, 'Không rõ', reason: 'cvName mặc định khi migrate');
      expect(migrated.method, 'ai', reason: 'method mặc định khi migrate');
      expect(
        migrated.jobCount,
        2,
        reason: 'jobCount = số jobId trong dữ liệu cũ',
      );
      expect(
        migrated.scores['job_1']!['ai']!.jobId,
        'job_1',
        reason: 'job_id được bơm vào JobScore từ key của map cũ',
      );
      expect(migrated.scores['job_1']!['ai']!.matchScore, 85,
          reason: 'matchScore của job_1 giữ nguyên từ dữ liệu cũ');
      expect(migrated.scores['job_2']!['ai']!.matchScore, 42,
          reason: 'matchScore của job_2 giữ nguyên từ dữ liệu cũ');
    });

    test('migrate xong: key mới có dữ liệu, key cũ bị remove', () async {
      final store = await _newStore(legacyInitial());
      store.loadSessions(); // kích hoạt _migrateLegacy

      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(AiSessionStore.key);
      expect(
        raw,
        isNotNull,
        reason: 'Sau migrate, key mới "${AiSessionStore.key}" phải có dữ liệu',
      );
      final list = jsonDecode(raw!) as List;
      expect(list, hasLength(1), reason: 'Key mới chứa đúng 1 phiên đã migrate');
      expect(
        (list.single as Map)['id'],
        'session_legacy',
        reason: 'Phiên trong key mới là session_legacy',
      );
      expect(
        prefs.getString(AiSessionStore.legacyKey),
        isNull,
        reason:
            'Key cũ "${AiSessionStore.legacyKey}" phải bị remove để không migrate lại',
      );
    });

    test('khởi tạo/load lần 2 không nhân đôi phiên migrate', () async {
      final store1 = await _newStore(legacyInitial());
      expect(store1.loadSessions(), hasLength(1),
          reason: 'Lần đầu migrate tạo 1 phiên');

      final prefs = await SharedPreferences.getInstance();
      final store2 = AiSessionStore(prefs); // "khởi tạo store lần 2"
      final second = store2.loadSessions();
      expect(
        second,
        hasLength(1),
        reason: 'Key cũ đã bị remove sau lần đầu → lần 2 không tạo thêm phiên',
      );
      expect(second.single.id, 'session_legacy',
          reason: 'Vẫn là phiên migrate ban đầu, không nhân đôi');
      expect(store1.loadSessions(), hasLength(1),
          reason: 'Store cũ load lại cũng vẫn chỉ có 1 phiên');
    });

    test('đã có session mới thì dữ liệu cũ bị bỏ, không ghi đè key mới', () async {
      final store = await _newStore();
      final kept = await store.saveSession(
        cvName: 'Moi.pdf',
        method: 'sql',
        scores: {
          'job_5': {'sql': _jobScore('job_5', 90, source: 'sql')},
        },
        jobs: const [],
      );

      // Bơm dữ liệu cũ vào key legacy của cùng SharedPreferences mock.
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        AiSessionStore.legacyKey,
        jsonEncode(<String, dynamic>{
          'job_1': {'match_score': 10},
        }),
      );

      final sessions = store.loadSessions();
      expect(
        sessions,
        hasLength(1),
        reason: 'Key mới đã có dữ liệu → legacy bị loại bỏ, không thêm phiên',
      );
      expect(sessions.single.id, kept.id,
          reason: 'Phiên hiện có được giữ nguyên, không bị migrate ghi đè');
      expect(
        prefs.getString(AiSessionStore.legacyKey),
        isNull,
        reason: 'Key cũ vẫn bị dọn dẹp dù không được dùng',
      );
    });
  });

  group('AiSessionStore — snapshot/jobFromSnapshot', () {
    test('job → snapshot → jobFromSnapshot round-trip giữ các field chính', () {
      final job = _job();
      final map = AiSessionStore.snapshot(job);
      final restored = AiSessionStore.jobFromSnapshot(map);

      expect(restored.jobId, job.jobId, reason: 'jobId');
      expect(restored.jobTitle, job.jobTitle, reason: 'jobTitle');
      expect(restored.employerId, job.employerId, reason: 'employerId');
      expect(restored.employerName, job.employerName, reason: 'employerName');
      expect(restored.employerLogoUrl, job.employerLogoUrl,
          reason: 'employerLogoUrl');
      expect(restored.salaryMin, job.salaryMin, reason: 'salaryMin');
      expect(restored.salaryMax, job.salaryMax, reason: 'salaryMax');
      expect(restored.isSalaryNegotiable, job.isSalaryNegotiable,
          reason: 'isSalaryNegotiable');
      expect(restored.city, job.city, reason: 'city');
      expect(restored.location, job.location, reason: 'location');
      expect(
        restored.experienceLevel,
        job.experienceLevel,
        reason: 'experienceLevel round-trip qua chuỗi UPPER_SNAKE (MID)',
      );
      expect(restored.workMode, job.workMode,
          reason: 'workMode round-trip qua chuỗi UPPER_SNAKE (REMOTE)');
      expect(restored.jobType, job.jobType,
          reason: 'jobType round-trip qua chuỗi UPPER_SNAKE (FULL_TIME)');
      expect(restored.categoryName, job.categoryName, reason: 'categoryName');
      expect(restored.status, job.status, reason: 'status');
      expect(restored.isApproved, job.isApproved, reason: 'isApproved');
      expect(
        restored.createdAt,
        job.createdAt,
        reason: 'createdAt round-trip qua ISO-8601 string',
      );
      expect(
        restored.requiredSkills.map((s) => s.skillName),
        ['Flutter', 'REST API'],
        reason: 'requiredSkills giữ nguyên danh sách kỹ năng',
      );
      expect(
        restored.requiredSkills.first.isRequired,
        isTrue,
        reason: 'Thuộc tính isRequired của skill đầu tiên',
      );
      expect(
        restored.requiredSkills.first.minExperienceYears,
        1,
        reason: 'minExperienceYears của skill đầu tiên',
      );
    });

    test('snapshot luôn lưu status OPEN + isApproved true + enum UPPER_SNAKE',
        () {
      final paused = _job().copyWith(status: JobStatus.paused);
      final map = AiSessionStore.snapshot(paused);

      expect(
        map['status'],
        'OPEN',
        reason: 'Snapshot ép cứng status = OPEN bất kể trạng thái gốc',
      );
      expect(
        map['isApproved'],
        isTrue,
        reason: 'Snapshot ép cứng isApproved = true',
      );
      expect(map['experienceLevel'], 'MID',
          reason: 'experienceLevel được viết hoa kiểu wire');
      expect(map['workMode'], 'REMOTE', reason: 'workMode wire value');
      // Snapshot dùng enumToWire (UPPER_SNAKE) giống JobModel.toJson.
      expect(map['jobType'], 'FULL_TIME',
          reason: 'jobType được snapshot bằng enumToWire (FULL_TIME, cùng wire format với JobModel.toJson)');
      expect(
        map['createdAt'],
        paused.createdAt?.toIso8601String(),
        reason: 'createdAt trong snapshot là chuỗi ISO-8601',
      );
    });
  });

  group('AiSessionStore — dữ liệu hỏng', () {
    test('JSON hỏng dưới key mới → loadSessions trả rỗng, không ném exception',
        () async {
      final store = await _newStore(<String, Object>{
        AiSessionStore.key: '{not-valid-json',
      });
      expect(
        store.loadSessions(),
        isEmpty,
        reason: 'Dữ liệu lỗi phải được nuốt lặng (try/catch) và trả về []',
      );
      expect(store.getSession('any'), isNull,
          reason: 'getSession trên store lỗi dữ liệu trả null');
    });
  });
}

/// Tạo store với bộ giá trị mock riêng của test (cách ly dữ liệu).
Future<AiSessionStore> _newStore([Map<String, Object> initial = const {}]) async {
  SharedPreferences.setMockInitialValues(initial);
  final prefs = await SharedPreferences.getInstance();
  return AiSessionStore(prefs);
}

/// Chờ 2ms để các saveSession liên tiếp có id (millis) khác nhau.
Future<void> _tick() => Future<void>.delayed(const Duration(milliseconds: 2));

JobScore _jobScore(String jobId, int value, {String source = 'ai'}) => JobScore(
      jobId: jobId,
      matchScore: value,
      recommendationReason: 'Diem $value cho $jobId',
      missingSkills: const ['Docker', 'K8s'],
      matchedSkills: const ['Flutter', 'REST API'],
      strengths: const ['Kinh nghiem tot'],
      source: source,
    );

JobModel _job({String id = 'job_9'}) => JobModel(
      jobId: id,
      employerId: 'emp_1',
      employerName: 'Cong ty JobHub',
      employerLogoUrl: 'https://logo.example.com/jh.png',
      jobTitle: 'Flutter Developer',
      salaryMin: 15000000,
      salaryMax: 30000000,
      isSalaryNegotiable: false,
      city: 'Ha Noi',
      location: 'Cau Giay, Ha Noi',
      experienceLevel: ExperienceLevel.mid,
      workMode: WorkMode.remote,
      jobType: JobType.fullTime,
      categoryName: 'Cong nghe thong tin',
      status: JobStatus.open,
      isApproved: true,
      requiredSkills: const [
        JobSkillRef(
          skillId: 'sk_1',
          skillName: 'Flutter',
          isRequired: true,
          minExperienceYears: 1,
          weight: 5,
        ),
        JobSkillRef(skillId: 'sk_2', skillName: 'REST API', isRequired: false),
      ],
      createdAt: DateTime(2026, 1, 15, 10, 30),
    );
