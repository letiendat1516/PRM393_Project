// Regression test cho fix #14 (GLM_REPORT mục 14, FIXED 2026-10-03):
// `AdminRepository.moderateJob` phải bọc CẢ update job lẫn create
// notification trong MỘT `runTransaction` — trước fix, update `jobs` xong
// mới `create` notification riêng, nên notification fail → job đã đổi trạng
// thái nhưng NTD không bao giờ nhận được thông báo.
//
// Hạn chế (theo phương án của TASKS_FOR_GLM ĐỢT 4): unit test thuần không
// instantiate được `FirebaseFirestore` (constructor private, cần
// Firebase.initializeApp → platform channel; `fake_cloud_firestore` không có
// trong pubspec và bị cấm thêm). Do đó kiểm tra bằng 2 lớp thay thế:
// 1. CONTRACT SOURCE (trace): đọc `lib/features/admin/data/admin_repository.dart`
//    thật từ đĩa, trích body `moderateJob` và khẳng định: đúng MỘT
//    `runTransaction`, `tx.get` kiểm tra tồn tại, `tx.update` (jobs) và
//    `tx.set` (notifications) đều nằm trong transaction theo đúng thứ tự,
//    đúng payload, đúng guard employerId rỗng. Revert về 2 call riêng rẽ →
//    test đỏ ngay. (Kỹ thuật đã có tiền lệ: notification_model_test đọc
//    firestore.rules.)
// 2. PAYLOAD (model thật): dựng lại NotificationModel đúng như moderateJob
//    dựng (ghi rõ dòng nguồn) cho 2 nhánh approve/reject, verify wire format
//    + whitelist type trong firestore.rules.
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/services/firestore_refs.dart';
import 'package:jobhub_prm393/core/utils/enums.dart';
import 'package:jobhub_prm393/shared/models/notification_model.dart';

/// Mirror 1-1 cách `moderateJob` dựng NotificationModel
/// (lib/features/admin/data/admin_repository.dart:166-183):
/// recipientId = employerId, role employer, type theo approve, title/message
/// tiếng Việt, data chứa jobId + decision.
NotificationModel moderateJobNotifMirror({
  required String notifId,
  required String jobId,
  required String jobTitle,
  required String employerId,
  required bool approve,
}) =>
    NotificationModel(
      notificationId: notifId,
      recipientId: employerId,
      recipientRole: UserRole.employer,
      type: approve
          ? NotificationType.jobApproved
          : NotificationType.jobRejected,
      title: approve
          ? 'Tin tuyển dụng đã được duyệt'
          : 'Tin tuyển dụng bị từ chối',
      message: approve
          ? 'Tin tuyển dụng "$jobTitle" đã được duyệt và hiển thị công khai.'
          : 'Tin tuyển dụng "$jobTitle" đã bị từ chối.',
      data: {
        'jobId': jobId,
        'decision': approve ? 'Approved' : 'Rejected',
      },
    );

/// Đếm số lần `needle` xuất hiện (so thẳng chuỗi, không dùng regex).
int countOf(String haystack, String needle) =>
    needle.allMatches(haystack).length;

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
/// Giới hạn: balan đếm cả brace/paren trong string literal — an toàn với
/// source hiện tại (các `${...}` tự cân bằng) nhưng chuỗi chứa brace LẺ trong
/// literal tương lai sẽ làm extraction lệch (test đỏ oan → kiểm tra lại đây).
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
  final adminSrc =
      File('lib/features/admin/data/admin_repository.dart').readAsStringSync();
  // Trace body moderateJob cho mọi assert contract source dưới đây.
  final body = memberBody(adminSrc, 'Future<void> moderateJob(');

  group('contract source — moderateJob bọc transaction (fix #14)', () {
    test('đúng MỘT runTransaction bọc toàn bộ (không 2 call riêng rẽ)', () {
      expect(has(body, 'Future<void> moderateJob('), isTrue,
          reason: 'sentinel: extraction không trả rỗng (moderateJob còn tồn '
              'tại trong source)');
      expect(countOf(body, 'runTransaction'), 1,
          reason: 'moderateJob phải gọi `_refs.db.runTransaction` đúng 1 lần '
              '— đây chính là fix #14; tách update + notify thành 2 call '
              'riêng (pattern cũ) là regression');
      expect(
        has(body, 'await _refs.db.runTransaction<void>((tx) async {'),
        isTrue,
        reason: 'dùng runTransaction<void> giống updateStatus trong '
            'ApplicationsRepository',
      );
      // Nếu revert về pattern cũ (update + notify ngoài transaction) sẽ có
      // thêm await ngoài → tổng await > 2. Tripwire đếm chuỗi thô (kể cả
      // trong comment) — đổi đỏ oan thì đọc lại moderateJob trước.
      expect(countOf(body, 'await '), 2,
          reason: 'chỉ 2 await cho phép: mở transaction + tx.get — mọi ghi '
              'đều phải qua tx.* (không await update/set riêng rẽ)');
    });

    test('tx.get kiểm tra doc tồn tại trong transaction, thiếu → NOT_FOUND',
        () {
      expect(has(body, 'await tx.get(ref);'), isTrue,
          reason: 'đọc lại doc trong transaction để kiểm tra tồn tại');
      expect(
        has(body,
            "throw const Failure.notFound('Không tìm thấy tin tuyển dụng.');"),
        isTrue,
        reason: 'job đã bị xoá giữa chừng → fail transaction thay vì update '
            'âm thầm lên doc không tồn tại',
      );
      expect(pos(body, 'await tx.get(ref);'),
          lessThan(pos(body, 'tx.update(')),
          reason: 'phải kiểm tra tồn tại TRƯỚC khi update');
      expect(pos(body, 'throw const Failure.notFound'),
          lessThan(pos(body, 'tx.update(')),
          reason: 'throw NOT_FOUND phải nằm trước update — nếu bị đẩy xuống '
              'sau thì doc không tồn tại vẫn bị ghi đè trước khi fail');
    });

    test('update job qua tx.update (không phải update trực tiếp trên ref)', () {
      expect(countOf(body, 'update('), 1,
          reason: 'chỉ 1 lệnh update duy nhất trong moderateJob');
      expect(has(body, 'tx.update(ref, {'), isTrue,
          reason: 'update jobs/{id} phải qua transaction handle `tx`');
      expect(
        has(body,
            "'status': enumToWire(approve ? JobStatus.open : JobStatus.closed),"),
        isTrue,
        reason: 'approve → OPEN, reject → CLOSED (wire UPPER_SNAKE)',
      );
      expect(has(body, "'isApproved': approve,"), isTrue,
          reason: 'đổi cờ duyệt');
      expect(has(body, "'moderatedAt': FieldValue.serverTimestamp(),"), isTrue,
          reason: 'ghi mốc thời gian duyệt');
      expect(has(body, "'updatedAt': FieldValue.serverTimestamp(),"), isTrue);
    });

    test('notification ghi bằng tx.set vào FirestoreRefs.colNotifications', () {
      expect(countOf(body, 'set('), 1,
          reason: 'chỉ 1 lệnh set duy nhất trong moderateJob');
      expect(
        has(body, '_refs.db.collection(FirestoreRefs.colNotifications).doc()'),
        isTrue,
        reason: 'lấy doc-id mới trong collection notifications qua hằng số '
            'FirestoreRefs (không qua NotificationsRepository nữa)',
      );
      expect(has(body, 'tx.set(notifRef, notif.toJson());'), isTrue,
          reason: 'ghi notification bằng tx.set trong CÙNG transaction với '
              'update job → notification fail thì job update rollback');
      // Ràng buộc PAYLOAD với source thật (chống mirror trong test tự nói
      // đúng riêng): sửa wording/decision trong lib mà quên mirror → đỏ ở đây.
      expect(
        has(body,
            "'Tin tuyển dụng \"\${job.jobTitle}\" đã được duyệt và hiển thị công khai.'"),
        isTrue,
        reason: 'message approve phải nguyên văn như moderateJob dựng',
      );
      expect(
        has(body, "'Tin tuyển dụng \"\${job.jobTitle}\" đã bị từ chối.'"),
        isTrue,
        reason: 'message reject phải nguyên văn như moderateJob dựng',
      );
      expect(
        has(body, "'decision': approve ? 'Approved' : 'Rejected',"),
        isTrue,
        reason: 'data.decision phải theo nhánh approve như moderateJob dựng',
      );
    });

    test('thứ tự: mở transaction → get → update → guard employerId → set', () {
      final iTx = pos(body, 'runTransaction');
      final iGet = pos(body, 'await tx.get(ref);');
      final iUpdate = pos(body, 'tx.update(ref, {');
      final iGuard = pos(body, 'if (job.employerId.isEmpty) return;');
      final iNotif = pos(body, 'final notif = NotificationModel(');
      final iSet = pos(body, 'tx.set(notifRef, notif.toJson());');

      expect(iNotif, greaterThanOrEqualTo(0),
          reason: 'needle "final notif = NotificationModel(" phải còn tồn tại '
              '(đổi tên biến trong lib thì cập nhật needle)');
      expect(iSet, greaterThanOrEqualTo(0),
          reason: 'needle "tx.set(notifRef, notif.toJson());" phải còn tồn tại');
      expect(iTx, lessThan(iGet), reason: 'transaction mở trước tx.get');
      expect(iGet, lessThan(iUpdate), reason: 'get trước update');
      expect(
        iUpdate,
        lessThan(iGuard),
        reason: 'job vẫn được duyệt ngay cả khi employerId rỗng — guard chỉ '
            'bỏ phần thông báo',
      );
      expect(iGuard, greaterThanOrEqualTo(0),
          reason: 'phải có guard `if (job.employerId.isEmpty) return;` — '
              'job crawl/seed thiếu employerId không được crash transaction');
      expect(iGuard, lessThan(iNotif),
          reason: 'guard employerId rỗng phải chặn trước cả khi DỰNG '
              'NotificationModel');
      expect(iNotif, lessThan(iSet),
          reason: 'dựng notif xong mới tx.set — không set trước khi dựng');
    });

    test('AdminRepository không còn phụ thuộc NotificationsRepository', () {
      expect(has(adminSrc, 'AdminRepository(this._refs, this._configs);'),
          isTrue,
          reason: 'constructor chỉ nhận FirestoreRefs + SystemConfigRepository '
              '(field `_notifications` + param đã bị gỡ kèm fix #14)');
      expect(adminSrc.contains('_notifications'), isFalse,
          reason: 'field `_notifications` phải đã được remove hoàn toàn');
      expect(adminSrc.contains('notificationsRepositoryProvider'), isFalse,
          reason: 'adminRepositoryProvider không watch notifications repo nữa');
      expect(has(adminSrc, 'ref.watch(firestoreRefsProvider)'), isTrue);
      expect(has(adminSrc, 'ref.watch(systemConfigRepositoryProvider)'), isTrue);
    });
  });

  group('payload notification dựng đúng như moderateJob (model thật)', () {
    final rules = File('firestore.rules').readAsStringSync();

    test('approve → JOB_APPROVED cho NTD, nội dung duyệt', () {
      final n = moderateJobNotifMirror(
        notifId: 'notif_auto_1',
        jobId: 'job_7',
        jobTitle: 'Flutter Developer',
        employerId: 'emp_9',
        approve: true,
      );

      expect(n.recipientId, 'emp_9', reason: 'người nhận là chủ tin (NTD)');
      expect(n.recipientRole, UserRole.employer);
      expect(n.type, NotificationType.jobApproved);
      expect(n.title, 'Tin tuyển dụng đã được duyệt');
      expect(n.message,
          'Tin tuyển dụng "Flutter Developer" đã được duyệt và hiển thị công khai.');
      expect(n.data, {'jobId': 'job_7', 'decision': 'Approved'});
      expect(n.isRead, isFalse, reason: 'thông báo mới sinh luôn chưa đọc');
    });

    test('reject → JOB_REJECTED cho NTD, nội dung từ chối', () {
      final n = moderateJobNotifMirror(
        notifId: 'notif_auto_2',
        jobId: 'job_8',
        jobTitle: 'Backend Engineer',
        employerId: 'emp_10',
        approve: false,
      );

      expect(n.type, NotificationType.jobRejected);
      expect(n.title, 'Tin tuyển dụng bị từ chối');
      expect(n.message, 'Tin tuyển dụng "Backend Engineer" đã bị từ chối.');
      expect(n.data, {
        'jobId': 'job_8',
        'decision': 'Rejected',
      }, reason: 'decision mirror wire value ApprovalStatus của backend');
    });

    test('toJson wire format: type UPPER_SNAKE, recipientRole lowercase snake, '
        'createdAt sentinel', () {
      final wire = moderateJobNotifMirror(
        notifId: 'notif_auto_3',
        jobId: 'job_9',
        jobTitle: 'QA Engineer',
        employerId: 'emp_11',
        approve: true,
      ).toJson();

      expect(wire['type'], 'JOB_APPROVED');
      expect(wire['recipientRole'], 'employer',
          reason: 'userRoleToWire — lowercase snake, KHÔNG phải UPPER_SNAKE');
      expect(wire['recipientId'], 'emp_11');
      expect(wire['notificationId'], 'notif_auto_3',
          reason: 'id khớp doc-id `notifications/{notifRef.id}` đã set bằng '
              'tx.set — đây là điều kiện để detail screen đọc lại được');
      expect(wire['isRead'], false);
      expect(wire['createdAt'], isA<FieldValue>(),
          reason: 'createdAt null → FieldValue.serverTimestamp() sentinel, '
              'Firestore gán giờ server khi tx.commit');
    });

    test('JOB_APPROVED/JOB_REJECTED nằm trong whitelist type của rules', () {
      // Neo regex vào đúng block `match /notifications/...` (file rules còn
      // các whitelist `in [...]` khác cho role/status — không được lấy nhầm).
      final blockStart = rules.indexOf('match /notifications/');
      expect(blockStart, greaterThanOrEqualTo(0),
          reason: 'firestore.rules phải còn block match /notifications');
      final blockEnd = rules.indexOf(RegExp('match /'), blockStart + 1) >= 0
          ? rules.indexOf(RegExp('match /'), blockStart + 1)
          : rules.length;
      final block = rules.substring(blockStart, blockEnd);
      final match = RegExp(r'type in \[([^\]]+)\]').firstMatch(block);
      expect(match, isNotNull,
          reason: 'block match /notifications phải chứa whitelist type');
      final whitelist = match!
          .group(1)!
          .split(',')
          .map((s) => s.trim().replaceAll("'", '').replaceAll('"', ''))
          .toSet();
      expect(whitelist, containsAll(const ['JOB_APPROVED', 'JOB_REJECTED']),
          reason: '2 type moderateJob ghi ra phải được rules chấp nhận — '
              'nếu không transaction sẽ bị deny NGAY CẢ KHI đã bọc đúng '
              '(và đó là lý do fix #14 cần cả 2 phía khớp nhau)');
    });

    test('status wire: approve → OPEN, reject → CLOSED', () {
      expect(enumToWire(JobStatus.open), 'OPEN');
      expect(enumToWire(JobStatus.closed), 'CLOSED');
    });

    test('FirestoreRefs hằng số collection moderateJob ghi vào', () {
      expect(FirestoreRefs.colNotifications, 'notifications');
      expect(FirestoreRefs.colJobs, 'jobs');
    });
  });
}
