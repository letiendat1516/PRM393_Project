import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';

/// Shared state for RegisterPage (job seeker) and RegisterEmployerPage.
class RegisterState {
  const RegisterState({
    this.submitting = false,
    this.error,
    this.fieldErrors = const {},
    this.user,
  });

  final bool submitting;

  /// Top-of-form `AlertError` message.
  final String? error;

  /// Per-field errors (`err.details.fieldErrors` on the web).
  final Map<String, String> fieldErrors;

  /// Set once registration succeeds (register logs in immediately).
  final UserModel? user;

  bool get success => user != null;

  RegisterState copyWith({
    bool? submitting,
    String? error,
    Map<String, String>? fieldErrors,
    UserModel? user,
  }) =>
      RegisterState(
        submitting: submitting ?? this.submitting,
        error: error,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        user: user,
      );
}

class RegisterViewModel extends StateNotifier<RegisterState> {
  RegisterViewModel(this._repo) : super(const RegisterState());

  final AuthRepository _repo;

  /// `{ role:'job_seeker', fullName, email, password }`.
  Future<void> submitJobSeeker({
    required String fullName,
    required String email,
    required String password,
  }) async {
    if (state.submitting) return;
    state = const RegisterState(submitting: true);
    try {
      final user = await _repo.registerJobSeeker(
        fullName: fullName,
        email: email,
        password: password,
      );
      if (!mounted) return;
      state = RegisterState(user: user);
    } catch (e) {
      if (!mounted) return;
      _fail(e);
    }
  }

  /// `{ role:'employer', email, password, contactName, gender, phone,
  /// companyName, city }`.
  Future<void> submitEmployer({
    required String contactName,
    required Gender gender,
    required String phone,
    required String companyName,
    required String city,
    required String email,
    required String password,
  }) async {
    if (state.submitting) return;
    state = const RegisterState(submitting: true);
    try {
      final user = await _repo.registerEmployer(
        contactName: contactName,
        gender: gender,
        phone: phone,
        companyName: companyName,
        city: city,
        email: email,
        password: password,
      );
      if (!mounted) return;
      state = RegisterState(user: user);
    } catch (e) {
      if (!mounted) return;
      _fail(e);
    }
  }

  /// Client-side form errors raised by the page before submitting (consent
  /// not ticked, gender missing…) — same `formError` slot as API errors.
  void showError(String message, {Map<String, String> fieldErrors = const {}}) {
    state = RegisterState(error: message, fieldErrors: fieldErrors);
  }

  /// `onChange` clears formError + the touched field error.
  void clearError([String? field]) {
    if (state.error == null && state.fieldErrors.isEmpty) return;
    final fe = Map<String, String>.of(state.fieldErrors);
    if (field != null) fe.remove(field);
    state = state.copyWith(error: null, fieldErrors: fe);
  }

  void _fail(Object e) {
    final f = Failure.from(e);
    state = RegisterState(error: f.message, fieldErrors: f.fieldErrors);
  }
}

final registerViewModelProvider =
    StateNotifierProvider.autoDispose<RegisterViewModel, RegisterState>(
  (ref) => RegisterViewModel(ref.watch(authRepositoryProvider)),
);
