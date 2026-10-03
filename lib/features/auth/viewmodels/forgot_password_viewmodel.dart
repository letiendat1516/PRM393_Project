import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../data/auth_repository.dart';

/// ForgotPasswordPage (mobile-only screen, FLUTTER_REBUILD_PLAN):
/// email form → FirebaseAuth reset mail → success state.
class ForgotPasswordState {
  const ForgotPasswordState({this.submitting = false, this.error, this.sentTo});

  final bool submitting;
  final String? error;

  /// Email the reset link was sent to (non-null = success state).
  final String? sentTo;

  bool get sent => sentTo != null;

  ForgotPasswordState copyWith({bool? submitting, String? error, String? sentTo}) =>
      ForgotPasswordState(
        submitting: submitting ?? this.submitting,
        error: error,
        sentTo: sentTo ?? this.sentTo,
      );
}

class ForgotPasswordViewModel extends StateNotifier<ForgotPasswordState> {
  ForgotPasswordViewModel(this._repo) : super(const ForgotPasswordState());

  final AuthRepository _repo;

  Future<void> submit(String email) async {
    if (state.submitting) return;
    final normalized = email.trim().toLowerCase();
    state = const ForgotPasswordState(submitting: true);
    try {
      await _repo.sendPasswordReset(normalized);
      if (!mounted) return;
      state = ForgotPasswordState(sentTo: normalized);
    } catch (e) {
      if (!mounted) return;
      // Like the backend's generic login error, never leak whether an email
      // exists: Firebase's user-not-found maps to the same generic message.
      final f = Failure.from(e);
      final message = f.code == 'INVALID_CREDENTIALS'
          ? 'Không thể gửi email đặt lại mật khẩu. Vui lòng kiểm tra lại địa chỉ email.'
          : f.message;
      state = ForgotPasswordState(error: message);
    }
  }

  /// "Gửi lại" / "Dùng email khác" → back to the form.
  void reset() => state = const ForgotPasswordState();

  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }
}

final forgotPasswordViewModelProvider = StateNotifierProvider.autoDispose<
    ForgotPasswordViewModel, ForgotPasswordState>(
  (ref) => ForgotPasswordViewModel(ref.watch(authRepositoryProvider)),
);
