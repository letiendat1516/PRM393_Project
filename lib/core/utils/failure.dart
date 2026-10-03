import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';

/// Normalised error contract (mirrors frontend/src/services/apiClient.js +
/// backend ApiError): every failure carries a Vietnamese user message, an
/// HTTP-like status, an optional machine code and field errors.
class Failure implements Exception {
  const Failure(
    this.message, {
    this.status = 400,
    this.code,
    this.fieldErrors = const {},
  });

  final String message;
  final int status;
  final String? code;
  final Map<String, String> fieldErrors;

  static const defaultMessage = 'Đã có lỗi xảy ra. Vui lòng thử lại.';
  static const networkMessage = 'Không kết nối được máy chủ. Vui lòng kiểm tra mạng.';
  static const serverMessage = 'Lỗi hệ thống. Vui lòng thử lại sau.';

  const Failure.unauthorized([String message = 'Vui lòng đăng nhập để tiếp tục.'])
      : this(message, status: 401, code: 'UNAUTHORIZED');
  const Failure.forbidden([String message = 'Bạn không có quyền thực hiện thao tác này.'])
      : this(message, status: 403, code: 'FORBIDDEN');
  const Failure.notFound([String message = 'Không tìm thấy dữ liệu.'])
      : this(message, status: 404, code: 'NOT_FOUND');
  const Failure.conflict(String message, [String code = 'CONFLICT'])
      : this(message, status: 409, code: code);
  const Failure.validation(String message, {Map<String, String> fieldErrors = const {}})
      : this(message, status: 400, code: 'VALIDATION_ERROR', fieldErrors: fieldErrors);

  @override
  String toString() => message;

  /// Single mapper used by every ViewModel: unknown exceptions → Failure.
  static Failure from(Object e) {
    if (e is Failure) return e;
    if (e is FirebaseAuthException) return _fromAuth(e);
    if (e is FirebaseException) return _fromFirebase(e);
    if (e is SocketException) {
      return const Failure(networkMessage, status: 0, code: 'NETWORK');
    }
    if (e is FormatException) {
      return const Failure('Dữ liệu trả về không hợp lệ.', status: 502, code: 'BAD_RESPONSE');
    }
    final s = e.toString();
    if (s.contains('network') || s.contains('Failed host lookup')) {
      return const Failure(networkMessage, status: 0, code: 'NETWORK');
    }
    return Failure(defaultMessage, status: 500, code: 'UNKNOWN');
  }

  static Failure _fromAuth(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
      case 'invalid-email':
        return const Failure('Email hoặc mật khẩu không đúng.', status: 401, code: 'INVALID_CREDENTIALS');
      case 'user-disabled':
        return const Failure('Tài khoản đã bị vô hiệu hóa.', status: 403, code: 'ACCOUNT_DISABLED');
      case 'email-already-in-use':
        return const Failure('Email đã được sử dụng.', status: 409, code: 'EMAIL_TAKEN');
      case 'weak-password':
        return const Failure('Mật khẩu phải có ít nhất 8 ký tự.', status: 400, code: 'WEAK_PASSWORD');
      case 'too-many-requests':
        return const Failure('Quá nhiều yêu cầu. Vui lòng thử lại sau.', status: 429, code: 'RATE_LIMITED');
      case 'network-request-failed':
        return const Failure(networkMessage, status: 0, code: 'NETWORK');
      case 'requires-recent-login':
        return const Failure('Vui lòng đăng nhập lại để thực hiện thao tác này.', status: 401, code: 'REAUTH');
      default:
        return Failure(e.message ?? defaultMessage, status: 400, code: e.code);
    }
  }

  static Failure _fromFirebase(FirebaseException e) {
    switch (e.code) {
      case 'permission-denied':
        return const Failure('Bạn không có quyền thực hiện thao tác này.', status: 403, code: 'FORBIDDEN');
      case 'not-found':
        return const Failure('Không tìm thấy dữ liệu.', status: 404, code: 'NOT_FOUND');
      case 'already-exists':
        return const Failure('Dữ liệu đã tồn tại.', status: 409, code: 'CONFLICT');
      case 'unavailable':
        return const Failure(networkMessage, status: 0, code: 'NETWORK');
      case 'failed-precondition':
        return Failure(
          'Truy vấn cần chỉ mục Firestore. Hãy deploy firestore.indexes.json. (${e.message})',
          status: 500,
          code: 'MISSING_INDEX',
        );
      case 'resource-exhausted':
        return const Failure('Đã vượt hạn mức Firebase. Vui lòng thử lại sau.', status: 429, code: 'RATE_LIMITED');
      default:
        return Failure(e.message ?? serverMessage, status: 500, code: e.code);
    }
  }
}
