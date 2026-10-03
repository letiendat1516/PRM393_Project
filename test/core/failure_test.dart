import 'dart:async';
import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jobhub_prm393/core/utils/failure.dart';

/// Tests cho lib/core/utils/failure.dart — message strings lấy verbatim từ lib.
/// Mọi expectation đều theo mapping THẬT của code (xem Failure.from/_fromAuth/_fromFirebase).
void main() {
  group('Failure constructor & constants', () {
    test('constructor mặc định: status 400, code null, fieldErrors rỗng', () {
      const f = Failure('Lỗi gì đó');
      expect(f.message, 'Lỗi gì đó');
      expect(f.status, 400, reason: 'status mặc định là 400.');
      expect(f.code, isNull, reason: 'code mặc định là null.');
      expect(f.fieldErrors, isEmpty, reason: 'fieldErrors mặc định rỗng.');
    });

    test('constructor đầy đủ giữ nguyên các giá trị truyền vào', () {
      const f = Failure('msg', status: 418, code: 'TEAPOT', fieldErrors: {'x': 'bắt buộc'});
      expect(f.status, 418);
      expect(f.code, 'TEAPOT');
      expect(f.fieldErrors, {'x': 'bắt buộc'});
    });

    test('defaultMessage có giá trị chuỗi chuẩn của lib', () {
      expect(Failure.defaultMessage, 'Đã có lỗi xảy ra. Vui lòng thử lại.');
    });

    test('networkMessage có giá trị chuỗi chuẩn của lib', () {
      expect(Failure.networkMessage, 'Không kết nối được máy chủ. Vui lòng kiểm tra mạng.');
    });

    test('serverMessage có giá trị chuỗi chuẩn của lib', () {
      expect(Failure.serverMessage, 'Lỗi hệ thống. Vui lòng thử lại sau.');
    });

    test('toString() trả về đúng message', () {
      const f = Failure('Thông báo lỗi cho người dùng');
      expect(f.toString(), 'Thông báo lỗi cho người dùng');
    });
  });

  group('Failure named constructors', () {
    test('Failure.unauthorized() → 401 UNAUTHORIZED + message mặc định', () {
      const f = Failure.unauthorized();
      expect(f.message, 'Vui lòng đăng nhập để tiếp tục.');
      expect(f.status, 401);
      expect(f.code, 'UNAUTHORIZED');
    });

    test('Failure.unauthorized(message tuỳ chỉnh) → giữ message tuỳ chỉnh', () {
      const f = Failure.unauthorized('Phiên đăng nhập hết hạn.');
      expect(f.message, 'Phiên đăng nhập hết hạn.');
      expect(f.status, 401);
      expect(f.code, 'UNAUTHORIZED');
    });

    test('Failure.forbidden() → 403 FORBIDDEN + message mặc định', () {
      const f = Failure.forbidden();
      expect(f.message, 'Bạn không có quyền thực hiện thao tác này.');
      expect(f.status, 403);
      expect(f.code, 'FORBIDDEN');
    });

    test('Failure.notFound() → 404 NOT_FOUND + message mặc định', () {
      const f = Failure.notFound();
      expect(f.message, 'Không tìm thấy dữ liệu.');
      expect(f.status, 404);
      expect(f.code, 'NOT_FOUND');
    });

    test('Failure.conflict(message) → 409 CONFLICT (code mặc định)', () {
      const f = Failure.conflict('Dữ liệu bị trùng.');
      expect(f.message, 'Dữ liệu bị trùng.');
      expect(f.status, 409);
      expect(f.code, 'CONFLICT');
    });

    test('Failure.conflict(message, code) → cho phép ghi đè code', () {
      const f = Failure.conflict('Email đã được sử dụng.', 'EMAIL_TAKEN');
      expect(f.status, 409);
      expect(f.code, 'EMAIL_TAKEN');
    });

    test('Failure.validation(message) → 400 VALIDATION_ERROR, fieldErrors rỗng', () {
      const f = Failure.validation('Dữ liệu không hợp lệ.');
      expect(f.status, 400);
      expect(f.code, 'VALIDATION_ERROR');
      expect(f.fieldErrors, isEmpty);
    });

    test('Failure.validation(message, fieldErrors) → giữ nguyên fieldErrors', () {
      const f = Failure.validation(
        'Dữ liệu không hợp lệ.',
        fieldErrors: {'email': 'Email không hợp lệ.', 'password': 'Mật khẩu yếu.'},
      );
      expect(f.status, 400);
      expect(f.code, 'VALIDATION_ERROR');
      expect(f.fieldErrors['email'], 'Email không hợp lệ.');
      expect(f.fieldErrors['password'], 'Mật khẩu yếu.');
    });
  });

  group('Failure.from — Failure passthrough', () {
    test('Failure.from(Failure) → trả về chính instance đó (identical)', () {
      const original = Failure('Giữ nguyên tôi', status: 422, code: 'UNPROCESSABLE');
      final result = Failure.from(original);
      expect(identical(result, original), isTrue,
          reason: 'from() phải idempotent, trả về đúng instance ban đầu.');
      expect(result, original, reason: 'Identical thì đương nhiên bằng nhau.');
    });
  });

  group('Failure.from — FirebaseAuthException', () {
    Failure map(String code, [String? message]) =>
        Failure.from(FirebaseAuthException(code: code, message: message));

    test('invalid-credential → 401 INVALID_CREDENTIALS', () {
      final f = map('invalid-credential', 'Sai thông tin đăng nhập.');
      expect(f.status, 401);
      expect(f.code, 'INVALID_CREDENTIALS');
      expect(f.message, 'Email hoặc mật khẩu không đúng.');
    });

    test('wrong-password → 401 INVALID_CREDENTIALS', () {
      final f = map('wrong-password');
      expect(f.status, 401);
      expect(f.code, 'INVALID_CREDENTIALS');
      expect(f.message, 'Email hoặc mật khẩu không đúng.');
    });

    test('user-not-found → 401 INVALID_CREDENTIALS', () {
      final f = map('user-not-found');
      expect(f.status, 401);
      expect(f.code, 'INVALID_CREDENTIALS');
      expect(f.message, 'Email hoặc mật khẩu không đúng.');
    });

    test('invalid-email → 401 INVALID_CREDENTIALS', () {
      final f = map('invalid-email');
      expect(f.status, 401);
      expect(f.code, 'INVALID_CREDENTIALS');
      expect(f.message, 'Email hoặc mật khẩu không đúng.');
    });

    test('user-disabled → 403 ACCOUNT_DISABLED', () {
      final f = map('user-disabled');
      expect(f.status, 403);
      expect(f.code, 'ACCOUNT_DISABLED');
      expect(f.message, 'Tài khoản đã bị vô hiệu hóa.');
    });

    test('email-already-in-use → 409 EMAIL_TAKEN', () {
      final f = map('email-already-in-use');
      expect(f.status, 409);
      expect(f.code, 'EMAIL_TAKEN');
      expect(f.message, 'Email đã được sử dụng.');
    });

    test('weak-password → 400 WEAK_PASSWORD', () {
      final f = map('weak-password');
      expect(f.status, 400);
      expect(f.code, 'WEAK_PASSWORD');
      expect(f.message, 'Mật khẩu phải có ít nhất 8 ký tự.');
    });

    test('too-many-requests → 429 RATE_LIMITED', () {
      final f = map('too-many-requests');
      expect(f.status, 429);
      expect(f.code, 'RATE_LIMITED');
      expect(f.message, 'Quá nhiều yêu cầu. Vui lòng thử lại sau.');
    });

    test('network-request-failed → status 0 NETWORK + networkMessage', () {
      final f = map('network-request-failed');
      expect(f.status, 0);
      expect(f.code, 'NETWORK');
      expect(f.message, Failure.networkMessage);
    });

    test('requires-recent-login → 401 REAUTH', () {
      final f = map('requires-recent-login');
      expect(f.status, 401);
      expect(f.code, 'REAUTH');
      expect(f.message, 'Vui lòng đăng nhập lại để thực hiện thao tác này.');
    });

    test('code lạ → 400, pass-through code + e.message', () {
      final f = map('custom-auth-code', 'Lỗi xác thực lạ.');
      expect(f.status, 400);
      expect(f.code, 'custom-auth-code');
      expect(f.message, 'Lỗi xác thực lạ.');
    });

    test('code lạ + message null → dùng defaultMessage', () {
      final f = map('custom-auth-code', null);
      expect(f.status, 400);
      expect(f.code, 'custom-auth-code');
      expect(f.message, Failure.defaultMessage);
    });
  });

  group('Failure.from — FirebaseException (Firestore)', () {
    Failure map(String code, [String? message]) =>
        Failure.from(FirebaseException(plugin: 'cloud_firestore', code: code, message: message));

    test('permission-denied → 403 FORBIDDEN', () {
      final f = map('permission-denied', 'The caller does not have permission');
      expect(f.status, 403);
      expect(f.code, 'FORBIDDEN');
      expect(f.message, 'Bạn không có quyền thực hiện thao tác này.');
    });

    test('not-found → 404 NOT_FOUND', () {
      final f = map('not-found');
      expect(f.status, 404);
      expect(f.code, 'NOT_FOUND');
      expect(f.message, 'Không tìm thấy dữ liệu.');
    });

    test('already-exists → 409 CONFLICT', () {
      final f = map('already-exists');
      expect(f.status, 409);
      expect(f.code, 'CONFLICT');
      expect(f.message, 'Dữ liệu đã tồn tại.');
    });

    test('unavailable → status 0 NETWORK', () {
      final f = map('unavailable');
      expect(f.status, 0);
      expect(f.code, 'NETWORK');
      expect(f.message, Failure.networkMessage);
    });

    test('failed-precondition → 500 MISSING_INDEX (đề gốc ghi INDEX_MISSING là sai)', () {
      final f = map('failed-precondition', 'The query requires an index.');
      expect(f.status, 500);
      expect(f.code, 'MISSING_INDEX',
          reason: 'Code thật dùng MISSING_INDEX, không phải INDEX_MISSING như đề bài gốc.');
      expect(f.message, contains('Truy vấn cần chỉ mục Firestore'));
      expect(f.message, contains('The query requires an index.'),
          reason: 'e.message gốc được nhúng trong ngoặc ở cuối.');
    });

    test('resource-exhausted → 429 RATE_LIMITED', () {
      final f = map('resource-exhausted');
      expect(f.status, 429);
      expect(f.code, 'RATE_LIMITED');
      expect(f.message, 'Đã vượt hạn mức Firebase. Vui lòng thử lại sau.');
    });

    test('code lạ "xyz" → 500, pass-through code + e.message', () {
      final f = map('xyz', 'Chi tiết lỗi lạ từ Firestore');
      expect(f.status, 500);
      expect(f.code, 'xyz');
      expect(f.message, 'Chi tiết lỗi lạ từ Firestore');
    });

    test('code lạ + message null → dùng serverMessage', () {
      final f = map('xyz', null);
      expect(f.status, 500);
      expect(f.code, 'xyz');
      expect(f.message, Failure.serverMessage);
    });
  });

  group('Failure.from — exception khác', () {
    test('SocketException → status 0 NETWORK (dart:io chạy OK trên VM test)', () {
      final f = Failure.from(const SocketException('Connection refused'));
      expect(f.status, 0);
      expect(f.code, 'NETWORK');
      expect(f.message, Failure.networkMessage);
    });

    test('FormatException → 502 BAD_RESPONSE', () {
      final f = Failure.from(const FormatException('Bad JSON'));
      expect(f.status, 502);
      expect(f.code, 'BAD_RESPONSE');
      expect(f.message, 'Dữ liệu trả về không hợp lệ.');
    });

    test('TimeoutException → KHÔNG có nhánh riêng → 500 UNKNOWN + defaultMessage', () {
      // Đề bài gốc kỳ vọng code 'TIMEOUT' nhưng lib không có nhánh TimeoutException
      // trong from() → rơi vào default. Test theo behaviour thật của code.
      final f = Failure.from(TimeoutException('Hết thời gian chờ'));
      expect(f.status, 500);
      expect(f.code, 'UNKNOWN',
          reason: 'Lib không map riêng TimeoutException — đề bài gốc ghi TIMEOUT là không đúng.');
      expect(f.message, Failure.defaultMessage);
    });

    test('Exception toString chứa "network" → status 0 NETWORK', () {
      final f = Failure.from(Exception('boom network'));
      expect(f.status, 0);
      expect(f.code, 'NETWORK');
      expect(f.message, Failure.networkMessage);
    });

    test('Exception "Failed host lookup: x" → status 0 NETWORK', () {
      final f = Failure.from(Exception('Failed host lookup: x'));
      expect(f.status, 0);
      expect(f.code, 'NETWORK');
      expect(f.message, Failure.networkMessage);
    });

    test('Exception thường "boom" → 500 UNKNOWN + defaultMessage (KHÔNG giữ message gốc)', () {
      // Đề bài gốc ghi "giữ message gốc" là sai: nhánh default luôn dùng defaultMessage.
      final f = Failure.from(Exception('boom'));
      expect(f.status, 500);
      expect(f.code, 'UNKNOWN');
      expect(f.message, Failure.defaultMessage,
          reason: 'Message gốc "boom" bị thay bằng defaultMessage theo code thật.');
      expect(f.message.contains('boom'), isFalse);
    });

    test('Heuristic network phân biệt hoa thường: "Network" (chữ N hoa) → UNKNOWN', () {
      // s.contains('network') là case-sensitive nên "Network error" không khớp.
      final f = Failure.from(Exception('Network error'));
      expect(f.status, 500);
      expect(f.code, 'UNKNOWN');
      expect(f.message, Failure.defaultMessage);
    });
  });
}
