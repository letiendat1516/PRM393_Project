// Unit tests for lib/shared/models/notification_model.dart
// (NotificationModel) và các enum helpers nó dựa vào
// (parseNotifType / parseUserRole / userRoleToWire / enumToWire).
//
// Timestamp (cloud_firestore) là pure Dart class nên không cần khởi tạo
// Firebase trong các test này.
//
// Test contract với firestore.rules đọc file rules thật (dart:io) để chắc
// chắn whitelist type được phép ghi khớp đúng tập wire value của model —
// nếu một bên đổi mà bên kia quên theo thì test đỏ ngay.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/notification_model.dart';

/// NotificationModel cơ bản dùng chung cho các group.
NotificationModel _model({
  UserRole recipientRole = UserRole.jobSeeker,
  NotificationType type = NotificationType.applicationStatus,
  Map<String, dynamic> data = const {},
  bool isRead = false,
  DateTime? createdAt,
}) =>
    NotificationModel(
      notificationId: 'notif_1',
      recipientId: 'seeker_42',
      recipientRole: recipientRole,
      type: type,
      title: 'Đơn ứng tuyển đã được xem xét',
      message: 'Đơn của bạn cho vị trí Flutter Developer đã chuyển sang Duyệt.',
      data: data,
      isRead: isRead,
      createdAt: createdAt,
    );

/// Timestamp.toDate() trả DateTime theo timezone LOCAL nên giá trị đã đi qua
/// một vòng Timestamp phải so theo instant, không dùng ==.
void expectInstant(DateTime? actual, DateTime expected, String reason) {
  expect(actual, isNotNull, reason: reason);
  expect(actual!.isAtSameMomentAs(expected), isTrue, reason: reason);
}

void main() {
  final t1 = DateTime.utc(2026, 3, 1, 8);
  final t2 = DateTime.utc(2026, 3, 2, 9, 30);

  group('Contract wire values với firestore.rules', () {
    test('enumToWire cho đúng 6 giá trị UPPER_SNAKE của NotificationType', () {
      // Tập wire value model ghi ra Firestore — phải khớp bảng PostgreSQL
      // enum notification_type của web backend (docs/08_DATABASE.md).
      const expected = {
        'APPLICATION_STATUS', // applicationStatus
        'NEW_APPLICATION', // newApplication
        'JOB_APPROVED', // jobApproved
        'JOB_REJECTED', // jobRejected
        'EMPLOYER_VERIFIED', // employerVerified
        'SYSTEM', // system
      };
      final actual = NotificationType.values.map(enumToWire).toSet();
      expect(actual, expected,
          reason: 'wire values phải đúng 6 chuỗi UPPER_SNAKE, không thêm bớt');
      expect(NotificationType.values, hasLength(6),
          reason: 'enum NotificationType phải có đúng 6 giá trị');
    });

    test('whitelist type trong firestore.rules khớp tập wire value của model',
        () {
      // Đọc rules thật từ đĩa và trích danh sách trong
      // `request.resource.data.type in [...]` (match /notifications) —
      // đây mới là contract thật sự: toJson() ghi gì thì rules phải chấp nhận.
      final rules = File('firestore.rules').readAsStringSync();
      final match = RegExp(r'type in \[([^\]]+)\]').firstMatch(rules);
      expect(match, isNotNull,
          reason: 'firestore.rules phải chứa whitelist type cho notifications');
      final whitelist = match!
          .group(1)!
          .split(',')
          .map((s) => s.trim().replaceAll("'", '').replaceAll('"', ''))
          .toSet();

      final wireValues = NotificationType.values.map(enumToWire).toSet();
      expect(wireValues, whitelist,
          reason:
              'mọi type model ghi ra phải nằm trong whitelist rules (và ngược lại '
              'không có giá trị rules chết mà model không tạo nổi)');
    });
  });

  group('Constructor mặc định', () {
    test('recipientRole/isRead/data/createdAt nhận default đúng', () {
      final m = NotificationModel(
        notificationId: 'notif_1',
        recipientId: 'seeker_42',
        type: NotificationType.system,
        title: 'Bảo trì hệ thống',
        message: 'Hệ thống bảo trì 0h-2h.',
      );

      expect(m.recipientRole, UserRole.jobSeeker,
          reason: 'recipientRole mặc định jobSeeker');
      expect(m.isRead, false, reason: 'isRead mặc định false (chưa đọc)');
      expect(m.data, isEmpty, reason: 'data mặc định map rỗng (const {})');
      expect(m.createdAt, isNull, reason: 'createdAt mặc định null');
      expect(m.notificationId, 'notif_1', reason: 'notificationId bắt buộc');
      expect(m.recipientId, 'seeker_42', reason: 'recipientId bắt buộc');
      expect(m.type, NotificationType.system, reason: 'type bắt buộc');
      expect(m.title, 'Bảo trì hệ thống', reason: 'title bắt buộc');
      expect(m.message, 'Hệ thống bảo trì 0h-2h.', reason: 'message bắt buộc');
    });
  });

  group('NotificationModel.fromJson', () {
    test('đọc đủ các field chính từ JSON chuẩn của Firestore', () {
      final m = NotificationModel.fromJson({
        'notificationId': 'notif_9',
        'recipientId': 'emp_9',
        'recipientRole': 'employer',
        'type': 'NEW_APPLICATION',
        'title': 'Có ứng viên mới',
        'message': 'Nguyen Van A vừa nộp đơn cho Flutter Developer.',
        'data': {'applicationId': 'app_5', 'jobId': 'job_7'},
        'isRead': true,
        'createdAt': Timestamp.fromDate(t1),
      });

      expect(m.notificationId, 'notif_9', reason: 'notificationId đọc đúng');
      expect(m.recipientId, 'emp_9', reason: 'recipientId đọc đúng');
      expect(m.recipientRole, UserRole.employer,
          reason: "recipientRole 'employer' parse đúng");
      expect(m.type, NotificationType.newApplication,
          reason: 'type NEW_APPLICATION parse đúng');
      expect(m.title, 'Có ứng viên mới', reason: 'title đọc đúng');
      expect(m.message, 'Nguyen Van A vừa nộp đơn cho Flutter Developer.',
          reason: 'message đọc đúng');
      expect(m.data['applicationId'], 'app_5', reason: 'data đọc đúng nested');
      expect(m.data['jobId'], 'job_7', reason: 'data đọc đúng nested');
      expect(m.isRead, true, reason: 'isRead đọc đúng');
      expectInstant(m.createdAt, t1, 'createdAt Timestamp → toDate (so instant)');
    });

    test("nhận key dự phòng 'id' cho notificationId và 'recipientUid' cho recipientId",
        () {
      final m = NotificationModel.fromJson({
        'id': 'notif_77',
        'recipientUid': 'seeker_42',
        'type': 'SYSTEM',
        'title': 'Chào mừng',
        'message': 'Chào bạn đến với JobHub!',
      });

      expect(m.notificationId, 'notif_77', reason: "alias 'id' cho notificationId");
      expect(m.recipientId, 'seeker_42', reason: "alias 'recipientUid' cho recipientId");
    });

    test('type null hoặc chuỗi lạ → fallback system', () {
      expect(
          NotificationModel.fromJson({
            'type': null,
            'title': '',
            'message': '',
          }).type,
          NotificationType.system,
          reason: 'type null → fallback system');
      expect(
          NotificationModel.fromJson({
            'type': 'TELEPORTED',
            'title': '',
            'message': '',
          }).type,
          NotificationType.system,
          reason: 'type lạ → fallback system (không ném exception)');
    });

    test('recipientRole lạ hoặc thiếu → fallback jobSeeker', () {
      expect(
          NotificationModel.fromJson({'recipientRole': 'ninja'})
              .recipientRole,
          UserRole.jobSeeker,
          reason: 'recipientRole lạ → jobSeeker');
      expect(
          NotificationModel.fromJson({}).recipientRole,
          UserRole.jobSeeker,
          reason: 'recipientRole thiếu → jobSeeker (default constructor)');
      expect(
          NotificationModel.fromJson({'recipientRole': 'admin'}).recipientRole,
          UserRole.admin,
          reason: "recipientRole 'admin' parse đúng");
    });

    test('isRead thiếu → false', () {
      expect(NotificationModel.fromJson({}).isRead, false,
          reason: 'isRead không có trong JSON → false');
    });

    test('createdAt null → null; Timestamp → DateTime theo instant', () {
      expect(NotificationModel.fromJson({}).createdAt, isNull,
          reason: 'createdAt thiếu/null → null');
      expectInstant(
          NotificationModel.fromJson({'createdAt': Timestamp.fromDate(t2)})
              .createdAt,
          t2,
          'createdAt từ Timestamp → DateTime (so instant)');
    });

    test('data null → map rỗng; map thường → đọc được các entry', () {
      expect(NotificationModel.fromJson({'data': null}).data, isEmpty,
          reason: 'data null → const {} thay vì crash');
      final m = NotificationModel.fromJson({
        'data': {'jobTitle': 'BA', 'oldStatus': 'PENDING'},
      });
      expect(m.data, {'jobTitle': 'BA', 'oldStatus': 'PENDING'},
          reason: 'data map đọc nguyên vẹn các cặp key-value');
    });
  });

  group('NotificationModel.toJson', () {
    test('ghi đúng wire format: recipientRole lowercase snake, type UPPER_SNAKE',
        () {
      final wire = _model(
        recipientRole: UserRole.jobSeeker,
        type: NotificationType.applicationStatus,
      ).toJson();

      expect(wire['recipientRole'], 'job_seeker',
          reason:
              'recipientRole dùng userRoleToWire (lowercase snake) chứ KHÔNG phải '
              'enumToWire UPPER_SNAKE — phải khớp backend');
      expect(wire['type'], 'APPLICATION_STATUS',
          reason: 'type dùng enumToWire UPPER_SNAKE');
      expect(wire['notificationId'], 'notif_1', reason: 'notificationId ghi thẳng');
      expect(wire['recipientId'], 'seeker_42', reason: 'recipientId ghi thẳng');
      expect(wire['title'], 'Đơn ứng tuyển đã được xem xét', reason: 'title ghi thẳng');
      expect(wire['message'], contains('Flutter Developer'),
          reason: 'message ghi thẳng');
      expect(wire['isRead'], false, reason: 'isRead ghi thẳng');
    });

    test('recipientRole: cả 3 role đều ra wire value lowercase đúng', () {
      expect(_model(recipientRole: UserRole.employer).toJson()['recipientRole'],
          'employer',
          reason: 'employer → "employer"');
      expect(_model(recipientRole: UserRole.admin).toJson()['recipientRole'],
          'admin',
          reason: 'admin → "admin"');
      expect(_model(recipientRole: UserRole.jobSeeker).toJson()['recipientRole'],
          'job_seeker',
          reason: 'jobSeeker → "job_seeker"');
    });

    test('createdAt null → sentinel FieldValue (không phải Timestamp/null)', () {
      final wire = _model(createdAt: null).toJson();

      // FieldValue.serverTimestamp() là sentinel không so sánh giá trị được,
      // chỉ khẳng định type — Firestore sẽ thay bằng giờ server khi ghi.
      expect(wire['createdAt'], isA<FieldValue>(),
          reason:
              'createdAt null → FieldValue.serverTimestamp() để Firestore gán giờ server');
    });

    test('createdAt có giá trị → Timestamp.fromDate', () {
      final wire = _model(createdAt: t1).toJson();

      expect(wire['createdAt'], Timestamp.fromDate(t1),
          reason: 'createdAt serialize thành Firestore Timestamp');
    });

    test('data được ghi nguyên vẹn vào JSON', () {
      final wire = _model(data: {'applicationId': 'app_5'}).toJson();

      expect(wire['data'], {'applicationId': 'app_5'},
          reason: 'data payload ghi thẳng để screen đọc context khi tap');
    });
  });

  group('toJson → fromJson round-trip', () {
    test('round-trip giữ đủ các trường (patch createdAt vì FieldValue không đọc lại được)',
        () {
      final original = _model(
        recipientRole: UserRole.employer,
        type: NotificationType.jobApproved,
        data: {'jobId': 'job_7', 'jobTitle': 'Flutter Developer'},
        isRead: true,
        createdAt: t2,
      );

      final wire = original.toJson();
      // Firestore sẽ thay serverTimestamp() bằng Timestamp thật khi ghi;
      // với createdAt đã có thì wire đã là Timestamp — giữ nguyên để đọc lại.
      expect(wire['createdAt'], isA<Timestamp>(),
          reason: 'wire có createdAt dạng Timestamp trước khi đọc lại');

      final back = NotificationModel.fromJson(wire);

      expect(back.notificationId, original.notificationId,
          reason: 'notificationId round-trip');
      expect(back.recipientId, original.recipientId, reason: 'recipientId round-trip');
      expect(back.recipientRole, original.recipientRole,
          reason: 'recipientRole round-trip qua "employer"');
      expect(back.type, original.type,
          reason: 'type round-trip qua "JOB_APPROVED"');
      expect(back.title, original.title, reason: 'title round-trip');
      expect(back.message, original.message, reason: 'message round-trip');
      expect(back.data, original.data, reason: 'data round-trip');
      expect(back.isRead, original.isRead, reason: 'isRead round-trip');
      expectInstant(back.createdAt, original.createdAt!,
          'createdAt round-trip qua Timestamp (so instant)');
    });

    test('round-trip với createdAt null: patch sentinel thành Timestamp như Firestore',
        () {
      final original = _model(
        type: NotificationType.employerVerified,
        isRead: false,
      );

      final wire = original.toJson();
      // Mô phỏng Firestore: serverTimestamp() → Timestamp thật sau khi ghi.
      wire['createdAt'] = Timestamp.fromDate(t1);

      final back = NotificationModel.fromJson(wire);

      expect(back.notificationId, original.notificationId,
          reason: 'notificationId round-trip');
      expect(back.type, original.type,
          reason: 'type round-trip qua "EMPLOYER_VERIFIED"');
      expect(back.isRead, original.isRead, reason: 'isRead round-trip');
      expectInstant(back.createdAt, t1,
          'createdAt nhận giá trị Timestamp đã patch (so instant)');
    });
  });

  group('parseNotifType (core/utils/enums.dart)', () {
    test('enumToWire → parseNotifType round-trip cho mọi NotificationType', () {
      for (final t in NotificationType.values) {
        final wire = enumToWire(t);
        expect(wire, wire.toUpperCase(),
            reason: 'wire value phải là UPPER_SNAKE_CASE cho $t');
        expect(parseNotifType(wire), t,
            reason: 'parse(enumToWire($t)) phải trả lại đúng $t');
      }
    });

    test('case-insensitive và chấp nhận dấu gạch ngang (kebab-case)', () {
      expect(parseNotifType('application_status'), NotificationType.applicationStatus,
          reason: 'chấp nhận lowercase wire value');
      expect(parseNotifType('Application-Status'), NotificationType.applicationStatus,
          reason: 'chấp nhận PascalCase + kebab-case (dash → underscore)');
      expect(parseNotifType('APPLICATION-STATUS'), NotificationType.applicationStatus,
          reason: 'chấp nhận UPPER-KEBAB: dash được chuẩn hóa thành underscore');
      expect(parseNotifType('system'), NotificationType.system,
          reason: 'chấp nhận tên thường không prefix');
    });

    test('fallback system cho null/rỗng/giá trị lạ', () {
      expect(parseNotifType(null), NotificationType.system,
          reason: 'null → fallback system');
      expect(parseNotifType(''), NotificationType.system,
          reason: 'chuỗi rỗng → fallback system');
      expect(parseNotifType('PROMOTION'), NotificationType.system,
          reason: 'giá trị không hợp lệ → fallback system');
    });

    test('parseUserRole ↔ userRoleToWire round-trip cho cả 3 role', () {
      for (final r in UserRole.values) {
        expect(parseUserRole(userRoleToWire(r)), r,
            reason: 'parse(userRoleToWire($r)) phải trả lại đúng $r');
      }
      expect(userRoleToWire(UserRole.jobSeeker), 'job_seeker',
          reason: 'wire value jobSeeker là "job_seeker" (lowercase snake)');
      expect(userRoleToWire(UserRole.employer), 'employer',
          reason: 'wire value employer giữ nguyên "employer"');
      expect(userRoleToWire(UserRole.admin), 'admin',
          reason: 'wire value admin giữ nguyên "admin"');
    });
  });
}
