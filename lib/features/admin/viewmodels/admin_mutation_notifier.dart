import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';

/// Per-row mutation tracking shared by the admin list pages: the web pages keep
/// a single `updatingId` + an `error` banner string.
class AdminMutationState {
  const AdminMutationState({this.updatingId, this.error, this.message});

  final String? updatingId;
  final String? error;
  final String? message;

  bool isUpdating(String id) => updatingId == id;
  bool get busy => updatingId != null;

  AdminMutationState copyWith({
    String? updatingId,
    bool clearUpdating = false,
    String? error,
    bool clearError = false,
    String? message,
    bool clearMessage = false,
  }) =>
      AdminMutationState(
        updatingId: clearUpdating ? null : (updatingId ?? this.updatingId),
        error: clearError ? null : (error ?? this.error),
        message: clearMessage ? null : (message ?? this.message),
      );
}

class AdminMutationNotifier extends StateNotifier<AdminMutationState> {
  AdminMutationNotifier() : super(const AdminMutationState());

  /// Runs [op] for row [id]; returns the Failure (or null on success). The
  /// failure message is also stored in `state.error` unless [silent].
  ///
  /// The providers are autoDispose: if the page is left while the Firestore
  /// op is in flight the notifier is disposed, so every assignment after an
  /// `await` is guarded with [mounted] (StateNotifier throws after dispose).
  Future<Failure?> run(
    String id,
    Future<void> Function() op, {
    String? fallbackMessage,
    String? successMessage,
    bool silent = false,
  }) async {
    if (!mounted || state.busy) return null;
    state = AdminMutationState(updatingId: id);
    try {
      await op();
      _set(AdminMutationState(message: successMessage));
      return null;
    } catch (e) {
      final f = Failure.from(e);
      final message = f.code == 'UNKNOWN' && fallbackMessage != null ? fallbackMessage : f.message;
      _set(AdminMutationState(error: silent ? null : message));
      return Failure(message, status: f.status, code: f.code);
    }
  }

  void clearError() => _set(state.copyWith(clearError: true));
  void clearMessage() => _set(state.copyWith(clearMessage: true));

  void _set(AdminMutationState next) {
    if (mounted) state = next;
  }
}

final adminUsersMutationProvider =
    StateNotifierProvider.autoDispose<AdminMutationNotifier, AdminMutationState>(
        (_) => AdminMutationNotifier());

final adminEmployersMutationProvider =
    StateNotifierProvider.autoDispose<AdminMutationNotifier, AdminMutationState>(
        (_) => AdminMutationNotifier());

final pendingJobsMutationProvider =
    StateNotifierProvider.autoDispose<AdminMutationNotifier, AdminMutationState>(
        (_) => AdminMutationNotifier());
