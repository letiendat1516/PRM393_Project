import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';

/// LoginPage form state (submitting / formError / logged-in principal).
class LoginState {
  const LoginState({this.submitting = false, this.error, this.user});

  final bool submitting;
  final String? error;

  /// Set once login succeeds; the view navigates with `NavItems.homeFor`.
  final UserModel? user;

  bool get success => user != null;

  LoginState copyWith({bool? submitting, String? error, UserModel? user}) =>
      LoginState(
        submitting: submitting ?? this.submitting,
        error: error,
        user: user,
      );
}

class LoginViewModel extends StateNotifier<LoginState> {
  LoginViewModel(this._repo) : super(const LoginState());

  final AuthRepository _repo;

  Future<void> submit({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    if (state.submitting) return;
    state = const LoginState(submitting: true);
    try {
      final user = await _repo.login(
        email: email,
        password: password,
        rememberMe: rememberMe,
      );
      if (!mounted) return;
      state = LoginState(user: user);
    } catch (e) {
      if (!mounted) return;
      state = LoginState(error: Failure.from(e).message);
    }
  }

  /// `onChange` in LoginPage.jsx clears the form error while typing.
  void clearError() {
    if (state.error != null) state = state.copyWith(error: null);
  }
}

final loginViewModelProvider =
    StateNotifierProvider.autoDispose<LoginViewModel, LoginState>(
  (ref) => LoginViewModel(ref.watch(authRepositoryProvider)),
);
