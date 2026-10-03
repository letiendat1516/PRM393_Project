// Unit tests for lib/shared/models/application_model.dart
// (ApplicationModel + ApplicationStatusHistoryItem) and the enum helpers it
// relies on (parseAppStatus / enumToWire / labels).
//
// Timestamp (cloud_firestore) is a pure Dart class, so no Firebase
// initialization is needed in these tests.
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/application_model.dart';

/// Base ApplicationModel used by most groups.
ApplicationModel _model({
  ApplicationStatus status = ApplicationStatus.submitted,
  DateTime? applicationDate,
  List<ApplicationStatusHistoryItem> history = const [],
}) =>
    ApplicationModel(
      applicationId: 'app_1',
      jobId: 'job_7',
      jobSeekerId: 'seeker_42',
      employerId: 'emp_9',
      applicationDate: applicationDate,
      status: status,
      jobTitle: 'Flutter Developer',
      companyName: 'JobHub',
      candidateFullName: 'Nguyen Van A',
      statusHistory: history,
    );

/// Timestamp.toDate() returns a DateTime in the LOCAL timezone, so a value
/// that crossed a Timestamp round-trip must be compared by instant, not ==.
void expectInstant(DateTime? actual, DateTime expected, String reason) {
  expect(actual, isNotNull, reason: reason);
  expect(actual!.isAtSameMomentAs(expected), isTrue, reason: reason);
}

/// Real (non-genesis) history row: oldStatus is always set so `timeline`
/// treats the list as having no genesis row.
ApplicationStatusHistoryItem _historyItem(
  ApplicationStatus oldStatus,
  ApplicationStatus newStatus,
  DateTime changedAt, {
  UserRole role = UserRole.employer,
}) =>
    ApplicationStatusHistoryItem(
      historyId: 'h_${newStatus.name}_$changedAt',
      applicationId: 'app_1',
      oldStatus: oldStatus,
      newStatus: newStatus,
      changedBy: 'emp_9',
      changedByRole: role,
      changedAt: changedAt,
    );

void main() {
  final t1 = DateTime.utc(2026, 1, 5, 9);
  final t2 = DateTime.utc(2026, 1, 6, 10);
  final t3 = DateTime.utc(2026, 1, 7, 11);

  group('ApplicationStatus transitions (transitions / allowedTransitions)', () {
    test('SUBMITTED cho phép đúng {UNDER_REVIEW, ACCEPTED, REJECTED}', () {
      final next = ApplicationModel.transitions[ApplicationStatus.submitted];
      expect(next, isNotNull,
          reason: 'transitions phải có entry cho submitted');
      expect(
        next,
        unorderedEquals([
          ApplicationStatus.underReview,
          ApplicationStatus.accepted,
          ApplicationStatus.rejected,
        ]),
        reason:
            'SUBMITTED chỉ được chuyển sang UNDER_REVIEW / ACCEPTED / REJECTED',
      );
      expect(next, hasLength(3),
          reason: 'SUBMITTED có đúng 3 chuyển tiếp, không thêm không bớt');
    });

    test('UNDER_REVIEW cho phép đúng {ACCEPTED, REJECTED}', () {
      final next = ApplicationModel.transitions[ApplicationStatus.underReview];
      expect(
        next,
        unorderedEquals([
          ApplicationStatus.accepted,
          ApplicationStatus.rejected,
        ]),
        reason: 'UNDER_REVIEW chỉ được chuyển sang ACCEPTED / REJECTED',
      );
      expect(next, hasLength(2),
          reason: 'UNDER_REVIEW có đúng 2 chuyển tiếp');
    });

    test('ACCEPTED là trạng thái terminal (tập rỗng)', () {
      final next = ApplicationModel.transitions[ApplicationStatus.accepted];
      expect(next, isEmpty,
          reason: 'ACCEPTED là terminal, không có chuyển tiếp nào');
    });

    test('REJECTED là trạng thái terminal (tập rỗng)', () {
      final next = ApplicationModel.transitions[ApplicationStatus.rejected];
      expect(next, isEmpty,
          reason: 'REJECTED là terminal, không có chuyển tiếp nào');
    });

    test('allowedTransitions của model khớp bảng transitions theo status', () {
      expect(
        _model(status: ApplicationStatus.submitted).allowedTransitions,
        unorderedEquals([
          ApplicationStatus.underReview,
          ApplicationStatus.accepted,
          ApplicationStatus.rejected,
        ]),
        reason: 'model SUBMITTED phải expose đúng 3 chuyển tiếp',
      );
      expect(
        _model(status: ApplicationStatus.underReview).allowedTransitions,
        unorderedEquals(
            [ApplicationStatus.accepted, ApplicationStatus.rejected]),
        reason: 'model UNDER_REVIEW phải expose đúng 2 chuyển tiếp',
      );
      expect(
        _model(status: ApplicationStatus.accepted).allowedTransitions,
        isEmpty,
        reason: 'model ACCEPTED không còn chuyển tiếp',
      );
      expect(
        _model(status: ApplicationStatus.rejected).allowedTransitions,
        isEmpty,
        reason: 'model REJECTED không còn chuyển tiếp',
      );
    });

    test('isTerminal: đúng với terminal, sai với trạng thái còn mở', () {
      expect(_model(status: ApplicationStatus.accepted).isTerminal, isTrue,
          reason: 'ACCEPTED là terminal');
      expect(_model(status: ApplicationStatus.rejected).isTerminal, isTrue,
          reason: 'REJECTED là terminal');
      expect(_model(status: ApplicationStatus.submitted).isTerminal, isFalse,
          reason: 'SUBMITTED còn chuyển tiếp nên không terminal');
      expect(_model(status: ApplicationStatus.underReview).isTerminal, isFalse,
          reason: 'UNDER_REVIEW còn chuyển tiếp nên không terminal');
    });

    test(
        'status ngoài bảng transitions (interview/offer/withdrawn) fallback tập rỗng',
        () {
      // transitions chỉ expose 4 status; getter trả const [] cho key thiếu,
      // nên các status này bị coi là terminal theo isTerminal.
      expect(
          _model(status: ApplicationStatus.interview).allowedTransitions,
          isEmpty,
          reason:
              'interview không có trong transitions map, getter fallback tập rỗng');
      expect(_model(status: ApplicationStatus.offer).allowedTransitions, isEmpty,
          reason:
              'offer không có trong transitions map, getter fallback tập rỗng');
      expect(
          _model(status: ApplicationStatus.withdrawn).allowedTransitions,
          isEmpty,
          reason:
              'withdrawn không có trong transitions map, getter fallback tập rỗng');
    });
  });

  group('ApplicationModel.docIdFor', () {
    test('ghép chuỗi đúng định dạng "<jobSeekerId>_<jobId>"', () {
      expect(ApplicationModel.docIdFor('seeker_42', 'job_7'),
          'seeker_42_job_7',
          reason: 'docId phải là jobSeekerId + "_" + jobId theo comment model');
    });

    test('deterministic: 2 lần gọi với input bằng nhau cho kết quả bằng nhau',
        () {
      final a = ApplicationModel.docIdFor('seeker_42', 'job_7');
      final b = ApplicationModel.docIdFor('seeker_42', 'job_7');
      expect(a, b,
          reason: 'docIdFor phải deterministic để enforce UNIQUE(seeker, job)');
    });

    test('đổi jobSeekerId → docId khác; đổi jobId → docId khác', () {
      final base = ApplicationModel.docIdFor('seeker_42', 'job_7');
      expect(ApplicationModel.docIdFor('seeker_99', 'job_7'), isNot(base),
          reason: 'seeker khác phải ra docId khác');
      expect(ApplicationModel.docIdFor('seeker_42', 'job_8'), isNot(base),
          reason: 'jobId khác phải ra docId khác');
      expect(
          ApplicationModel.docIdFor('seeker_99', 'job_8'), isNot(base),
          reason:
              'đổi cả hai tham số dĩ nhiên phải ra docId khác');
    });
  });

  group('ApplicationModel.timeline', () {
    test(
        'không có genesis row + có applicationDate → prepend node SUBMITTED tổng hợp',
        () {
      final model = _model(
        applicationDate: t1,
        history: [
          _historyItem(ApplicationStatus.submitted,
              ApplicationStatus.underReview, t2),
          _historyItem(
              ApplicationStatus.underReview, ApplicationStatus.accepted, t3),
        ],
      );

      final tl = model.timeline;

      expect(tl, hasLength(3),
          reason: '2 history row thật + 1 node SUBMITTED tổng hợp = 3 node');
      final genesis = tl.first;
      expect(genesis.newStatus, ApplicationStatus.submitted,
          reason: 'node tổng hợp phải là SUBMITTED (trạng thái khởi tạo)');
      expect(genesis.changedAt, t1,
          reason: 'node tổng hợp lấy applicationDate làm mốc thời gian');
      expect(genesis.changedBy, 'seeker_42',
          reason: 'node tổng hợp gắn changedBy = jobSeekerId');
      expect(genesis.changedByRole, UserRole.jobSeeker,
          reason: 'node tổng hợp gắn vai trò ứng viên');
      expect(genesis.oldStatus, isNull,
          reason: 'node tổng hợp không có trạng thái trước đó');
      expect(genesis.historyId, isNull,
          reason: 'node tổng hợp không tương ứng subcollection row thật');
      expect(genesis.applicationId, isNull,
          reason: 'node tổng hợp không mang applicationId');
      expect(genesis.note, isNull, reason: 'node tổng hợp không có note');
    });

    test('timeline sắp xếp các node theo thứ tự thời gian tăng dần', () {
      // History truyền vào cố ý sai thứ tự để kiểm tra sort bên trong timeline.
      final model = _model(
        applicationDate: t1,
        history: [
          _historyItem(
              ApplicationStatus.underReview, ApplicationStatus.accepted, t3),
          _historyItem(ApplicationStatus.submitted,
              ApplicationStatus.underReview, t2),
        ],
      );

      final tl = model.timeline;

      expect(tl.map((e) => e.newStatus).toList(),
          [
            ApplicationStatus.submitted,
            ApplicationStatus.underReview,
            ApplicationStatus.accepted
          ],
          reason: 'thứ tự phải là SUBMITTED(t1) → UNDER_REVIEW(t2) → ACCEPTED(t3)');
      for (var i = 1; i < tl.length; i++) {
        expect(tl[i - 1].changedAt.isBefore(tl[i].changedAt), isTrue,
            reason:
                'node ${i - 1} (${tl[i - 1].newStatus}) phải xảy ra trước node $i (${tl[i].newStatus})');
      }
    });

    test('đã có genesis row (oldStatus == null) → không thêm node tổng hợp',
        () {
      final model = _model(
        applicationDate: t1,
        history: [
          _historyItem(ApplicationStatus.submitted,
              ApplicationStatus.underReview, t2),
          ApplicationStatusHistoryItem(
            historyId: 'h_genesis',
            applicationId: 'app_1',
            newStatus: ApplicationStatus.submitted,
            changedBy: 'seeker_42',
            changedAt: t1,
          ),
        ],
      );

      final tl = model.timeline;

      expect(tl, hasLength(2),
          reason: 'history đã chứa genesis SUBMITTED nên không prepend thêm');
      expect(tl.first.historyId, 'h_genesis',
          reason: 'node đầu phải là genesis row thật từ subcollection');
      expect(tl.map((e) => e.newStatus).toList(),
          [ApplicationStatus.submitted, ApplicationStatus.underReview],
          reason: 'genesis(t1) đứng trước UNDER_REVIEW(t2)');
    });

    test('applicationDate null + không genesis → không thêm node tổng hợp', () {
      final model = _model(
        applicationDate: null,
        history: [
          _historyItem(ApplicationStatus.submitted,
              ApplicationStatus.underReview, t2),
        ],
      );

      final tl = model.timeline;
      expect(tl, hasLength(1),
          reason: 'không có applicationDate nên không dựng node SUBMITTED');
      expect(tl.single.newStatus, ApplicationStatus.underReview,
          reason: 'chỉ còn đúng history row cho trước');
    });

    test('timeline không làm biến đổi list statusHistory gốc của model', () {
      final history = [
        _historyItem(
            ApplicationStatus.underReview, ApplicationStatus.accepted, t3),
        _historyItem(ApplicationStatus.submitted,
            ApplicationStatus.underReview, t2),
      ];
      final model = _model(applicationDate: t1, history: history);

      model.timeline;

      expect(model.statusHistory, same(history),
          reason: 'timeline phải sort trên bản copy, không sort tại chỗ');
      expect(model.statusHistory.first.newStatus, ApplicationStatus.accepted,
          reason: 'thứ tự list gốc phải được giữ nguyên (ACCEPTED vẫn đầu)');
    });
  });

  group('ApplicationStatusHistoryItem JSON', () {
    test('toJson → fromJson round-trip giữ đủ các trường', () {
      final item = ApplicationStatusHistoryItem(
        historyId: 'h_1',
        applicationId: 'app_1',
        oldStatus: ApplicationStatus.submitted,
        newStatus: ApplicationStatus.underReview,
        changedBy: 'emp_9',
        changedByRole: UserRole.employer,
        changedAt: t2,
        note: 'Chuyển sang xem xét',
      );

      final back = ApplicationStatusHistoryItem.fromJson(item.toJson());

      expect(back.historyId, 'h_1', reason: 'historyId phải round-trip');
      expect(back.applicationId, 'app_1',
          reason: 'applicationId phải round-trip');
      expect(back.oldStatus, ApplicationStatus.submitted,
          reason: 'oldStatus phải round-trip');
      expect(back.newStatus, ApplicationStatus.underReview,
          reason: 'newStatus phải round-trip');
      expect(back.changedBy, 'emp_9', reason: 'changedBy phải round-trip');
      expect(back.changedByRole, UserRole.employer,
          reason: 'changedByRole phải round-trip');
      expectInstant(back.changedAt, t2,
          'changedAt (UTC) phải round-trip qua Timestamp (so theo instant)');
      expect(back.note, 'Chuyển sang xem xét',
          reason: 'note phải round-trip');
    });

    test('toJson ghi đúng wire format cho enum + Timestamp', () {
      final wire = _historyItem(ApplicationStatus.submitted,
              ApplicationStatus.underReview, t2)
          .toJson();

      expect(wire['newStatus'], 'UNDER_REVIEW',
          reason: 'enum serialize thành UPPER_SNAKE_CASE như web backend');
      expect(wire['oldStatus'], 'SUBMITTED',
          reason: 'oldStatus serialize thành SUBMITTED');
      expect(wire['changedByRole'], 'employer',
          reason: 'role employer giữ nguyên wire value');
      expect(wire['changedAt'], Timestamp.fromDate(t2),
          reason: 'changedAt serialize thành Firestore Timestamp');
    });

    test('toJson bỏ qua các trường null (mặc định)', () {
      final wire = ApplicationStatusHistoryItem(
        newStatus: ApplicationStatus.submitted,
        changedAt: t1,
      ).toJson();

      // oldStatus null is now dropped from the map (consistency fix with
      // the other nullable fields: historyId / applicationId / changedBy /
      // note). The genesis row therefore writes only the three required
      // fields.
      expect(
          wire.keys,
          unorderedEquals(
              ['newStatus', 'changedByRole', 'changedAt']),
          reason:
              'newStatus/changedByRole/changedAt bắt buộc; oldStatus null bị bỏ khỏi map');
      expect(wire.containsKey('oldStatus'), isFalse,
          reason: 'oldStatus null bị bỏ khỏi toJson');
      expect(wire.containsKey('historyId'), isFalse,
          reason: 'historyId null bị bỏ khỏi toJson');
      expect(wire.containsKey('applicationId'), isFalse,
          reason: 'applicationId null bị bỏ khỏi toJson');
      expect(wire.containsKey('changedBy'), isFalse,
          reason: 'changedBy null bị bỏ khỏi toJson');
      expect(wire.containsKey('note'), isFalse,
          reason: 'note null bị bỏ khỏi toJson');
      expect(wire['changedByRole'], 'job_seeker',
          reason: 'changedByRole mặc định job_seeker');
    });

    test('fromJson đọc được key alias id/status và default role', () {
      final back = ApplicationStatusHistoryItem.fromJson({
        'id': 'h_9',
        'status': 'REJECTED',
        'changedAt': Timestamp.fromDate(t3),
      });

      expect(back.historyId, 'h_9',
          reason: "fromJson nhận alias 'id' cho historyId");
      expect(back.newStatus, ApplicationStatus.rejected,
          reason: "fromJson nhận alias 'status' cho newStatus");
      expect(back.changedByRole, UserRole.jobSeeker,
          reason: 'changedByRole fallback về jobSeeker khi thiếu');
      expectInstant(back.changedAt, t3,
          'changedAt đọc từ Timestamp (so theo instant)');
    });

    test('actorLabel map đúng vai trò tiếng Việt', () {
      expect(
          ApplicationStatusHistoryItem(
                  newStatus: ApplicationStatus.submitted,
                  changedAt: t1,
                  changedByRole: UserRole.jobSeeker)
              .actorLabel,
          'Ứng viên',
          reason: 'jobSeeker → "Ứng viên"');
      expect(
          ApplicationStatusHistoryItem(
                  newStatus: ApplicationStatus.submitted,
                  changedAt: t1,
                  changedByRole: UserRole.employer)
              .actorLabel,
          'Nhà tuyển dụng',
          reason: 'employer → "Nhà tuyển dụng"');
      expect(
          ApplicationStatusHistoryItem(
                  newStatus: ApplicationStatus.submitted,
                  changedAt: t1,
                  changedByRole: UserRole.admin)
              .actorLabel,
          'Quản trị viên',
          reason: 'admin → "Quản trị viên"');
    });
  });

  group('ApplicationModel JSON', () {
    test('fromJson đọc đủ field chính + alias (id/jobSeekerUid/appliedAt/jobSeekerName)',
        () {
      final m = ApplicationModel.fromJson({
        'id': 'app_9',
        'jobId': 'job_7',
        'jobSeekerUid': 'seeker_42',
        'employerUid': 'emp_9',
        'appliedAt': Timestamp.fromDate(t1),
        'status': 'UNDER_REVIEW',
        'updatedAt': Timestamp.fromDate(t2),
        'jobSeekerName': 'Nguyen Van A',
        'matchScore': 88, // int — phải được đưa về double
        'statusHistory': [
          {
            'id': 'h_1',
            'status': 'UNDER_REVIEW',
            'oldStatus': 'SUBMITTED',
            'changedAt': Timestamp.fromDate(t2),
          },
        ],
      });

      expect(m.applicationId, 'app_9', reason: "alias 'id' cho applicationId");
      expect(m.jobSeekerId, 'seeker_42',
          reason: "alias 'jobSeekerUid' cho jobSeekerId");
      expect(m.employerId, 'emp_9',
          reason: "alias 'employerUid' cho employerId");
      expectInstant(m.applicationDate, t1,
          "alias 'appliedAt' cho applicationDate (so theo instant)");
      expect(m.status, ApplicationStatus.underReview,
          reason: 'status parse từ wire value UNDER_REVIEW');
      expectInstant(m.updatedAt, t2,
          'updatedAt đọc từ Timestamp (so theo instant)');
      expect(m.candidateFullName, 'Nguyen Van A',
          reason: "alias 'jobSeekerName' cho candidateFullName");
      expect(m.matchScore, 88.0,
          reason: 'matchScore int phải normalize thành double 88.0');
      expect(m.statusHistory, hasLength(1),
          reason: 'statusHistory list parse được từ JSON');
      expect(m.statusHistory.single.newStatus, ApplicationStatus.underReview,
          reason: 'history item trong statusHistory parse đúng newStatus');
      expect(m.jobTitle, '', reason: 'jobTitle thiếu → chuỗi rỗng');
    });

    test('fromJson fallback: thiếu status → submitted, thiếu statusHistory → []',
        () {
      final m = ApplicationModel.fromJson({
        'applicationId': 'app_1',
        'jobId': 'job_7',
        'jobSeekerId': 'seeker_42',
        'employerId': 'emp_9',
      });

      expect(m.status, ApplicationStatus.submitted,
          reason: 'parseAppStatus(null) fallback về submitted');
      expect(m.statusHistory, isEmpty,
          reason: 'statusHistory thiếu → list rỗng');
    });

    test('toJson: wire format cho status, Timestamp cho applicationDate, FieldValue cho updatedAt',
        () {
      final wire = _model(applicationDate: t1).toJson();

      expect(wire['applicationId'], 'app_1',
          reason: 'applicationId ghi thẳng vào JSON');
      expect(wire['status'], 'SUBMITTED',
          reason: 'status mặc định serialize thành SUBMITTED');
      expect(wire['applicationDate'], Timestamp.fromDate(t1),
          reason: 'applicationDate serialize thành Timestamp');
      expect(wire['updatedAt'], isA<FieldValue>(),
          reason:
              'updatedAt dùng FieldValue.serverTimestamp() để Firestore gán giờ server');
      expect(wire.containsKey('statusHistory'), isFalse,
          reason:
              'toJson không ghi statusHistory (thiết kế load riêng từ subcollection)');
    });

    test('toJson bỏ qua các field tùy chọn khi null', () {
      final wire = _model().toJson();

      for (final key in [
        'resumeId',
        'resumeFileName',
        'resumeUrl',
        'coverLetter',
        'candidateHeadline',
        'candidateCity',
        'candidateEmail',
        'matchScore',
        'recommendationReason',
      ]) {
        expect(wire.containsKey(key), isFalse,
            reason: 'model cơ bản không có $key nên toJson phải bỏ qua');
      }
      expect(wire['applicationDate'], isA<FieldValue>(),
          reason:
              'applicationDate null → FieldValue.serverTimestamp() cho lần ghi đầu');
    });

    test('toJson → fromJson round-trip (patch updatedAt vì FieldValue không phải Timestamp)',
        () {
      final original = ApplicationModel(
        applicationId: 'app_1',
        jobId: 'job_7',
        jobSeekerId: 'seeker_42',
        employerId: 'emp_9',
        resumeId: 'resume_3',
        resumeFileName: 'cv.pdf',
        resumeUrl: 'https://cdn/jobhub/cv.pdf',
        coverLetter: 'Tôi rất mong được làm việc tại JobHub',
        applicationDate: t1,
        status: ApplicationStatus.underReview,
        jobTitle: 'Flutter Developer',
        companyName: 'JobHub',
        candidateFullName: 'Nguyen Van A',
        candidateHeadline: 'Flutter dev',
        candidateCity: 'Hà Nội',
        candidateEmail: 'a@example.com',
        matchScore: 91.5,
        recommendationReason: 'Match CV cao',
      );

      final wire = original.toJson();
      // Firestore sẽ thay serverTimestamp() bằng Timestamp thật khi ghi;
      // mô phỏng điều đó trước khi đọc lại.
      wire['updatedAt'] = Timestamp.fromDate(t3);

      final back = ApplicationModel.fromJson(wire);

      expect(back.applicationId, original.applicationId,
          reason: 'applicationId round-trip');
      expect(back.jobId, original.jobId, reason: 'jobId round-trip');
      expect(back.jobSeekerId, original.jobSeekerId,
          reason: 'jobSeekerId round-trip');
      expect(back.employerId, original.employerId,
          reason: 'employerId round-trip');
      expect(back.resumeId, original.resumeId, reason: 'resumeId round-trip');
      expect(back.resumeFileName, original.resumeFileName,
          reason: 'resumeFileName round-trip');
      expect(back.resumeUrl, original.resumeUrl,
          reason: 'resumeUrl round-trip');
      expect(back.coverLetter, original.coverLetter,
          reason: 'coverLetter round-trip');
      expectInstant(back.applicationDate, original.applicationDate!,
          'applicationDate (UTC) round-trip qua Timestamp (so theo instant)');
      expect(back.status, original.status,
          reason: 'status round-trip qua wire value');
      expectInstant(back.updatedAt, t3,
          'updatedAt nhận giá trị Timestamp đã patch (so theo instant)');
      expect(back.jobTitle, original.jobTitle, reason: 'jobTitle round-trip');
      expect(back.companyName, original.companyName,
          reason: 'companyName round-trip');
      expect(back.candidateFullName, original.candidateFullName,
          reason: 'candidateFullName round-trip');
      expect(back.candidateHeadline, original.candidateHeadline,
          reason: 'candidateHeadline round-trip');
      expect(back.candidateCity, original.candidateCity,
          reason: 'candidateCity round-trip');
      expect(back.candidateEmail, original.candidateEmail,
          reason: 'candidateEmail round-trip');
      expect(back.matchScore, original.matchScore,
          reason: 'matchScore round-trip');
      expect(back.recommendationReason, original.recommendationReason,
          reason: 'recommendationReason round-trip');
      expect(back.statusHistory, isEmpty,
          reason:
              'statusHistory không nằm trong toJson nên round-trip cho list rỗng');
    });
  });

  group('ApplicationStatus enum parse/label (core/utils/enums.dart)', () {
    test('enumToWire → parseAppStatus round-trip cho mọi status', () {
      for (final s in ApplicationStatus.values) {
        final wire = enumToWire(s);
        expect(wire, wire.toUpperCase(),
            reason: 'wire value phải là UPPER_SNAKE_CASE cho $s');
        expect(parseAppStatus(wire), s,
            reason: 'parse(enumToWire($s)) phải trả lại đúng $s');
      }
    });

    test('parseAppStatus chấp nhận lowercase và dấu gạch ngang', () {
      expect(parseAppStatus('under_review'), ApplicationStatus.underReview,
          reason: 'chấp nhận wire value thường');
      expect(parseAppStatus('under-review'), ApplicationStatus.underReview,
          reason: 'chấp nhận kebab-case như JSON từ web');
      expect(parseAppStatus('accepted'), ApplicationStatus.accepted,
          reason: 'chấp nhận tên thường không tiền tố');
    });

    test('parseAppStatus fallback submitted cho null/rỗng/giá trị lạ', () {
      expect(parseAppStatus(null), ApplicationStatus.submitted,
          reason: 'null → fallback submitted');
      expect(parseAppStatus(''), ApplicationStatus.submitted,
          reason: 'chuỗi rỗng → fallback submitted');
      expect(parseAppStatus('TELEPORTED'), ApplicationStatus.submitted,
          reason: 'giá trị không hợp lệ → fallback submitted');
    });

    test('label tiếng Việt cho các status chính', () {
      expect(ApplicationStatus.submitted.label, 'Đã nộp',
          reason: 'label SUBMITTED');
      expect(ApplicationStatus.underReview.label, 'Đang xem xét',
          reason: 'label UNDER_REVIEW');
      expect(ApplicationStatus.accepted.label, 'Được nhận',
          reason: 'label ACCEPTED');
      expect(ApplicationStatus.rejected.label, 'Từ chối',
          reason: 'label REJECTED');
      expect(ApplicationStatus.withdrawn.label, 'Đã rút',
          reason: 'label WITHDRAWN');
    });

    test('UserRole wire value round-trip', () {
      expect(userRoleToWire(UserRole.jobSeeker), 'job_seeker',
          reason: 'jobSeeker wire value là job_seeker');
      expect(parseUserRole('job_seeker'), UserRole.jobSeeker,
          reason: 'parse job_seeker');
      expect(parseUserRole('employer'), UserRole.employer,
          reason: 'parse employer');
      expect(parseUserRole('admin'), UserRole.admin, reason: 'parse admin');
      expect(parseUserRole(null), UserRole.jobSeeker,
          reason: 'null → fallback jobSeeker');
    });
  });
}
