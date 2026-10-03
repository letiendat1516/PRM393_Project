import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/application_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../../chat/data/chat_repository.dart';
import '../data/applications_repository.dart';

/// EmployerApplicationReviewPage mutation state (the detail itself streams
/// from `applicationWithHistoryProvider`).
class ReviewState {
  const ReviewState({
    this.submitting = false,
    this.openingChat = false,
    this.error,
    this.selected,
    this.lastUpdated,
  });

  final bool submitting;
  final bool openingChat;
  final String? error;

  /// Dropdown selection ('' = "Chọn trạng thái").
  final ApplicationStatus? selected;
  final ApplicationStatus? lastUpdated;

  ReviewState copyWith({
    bool? submitting,
    bool? openingChat,
    String? error,
    bool clearError = false,
    ApplicationStatus? selected,
    bool clearSelected = false,
    ApplicationStatus? lastUpdated,
  }) =>
      ReviewState(
        submitting: submitting ?? this.submitting,
        openingChat: openingChat ?? this.openingChat,
        error: clearError ? null : (error ?? this.error),
        selected: clearSelected ? null : (selected ?? this.selected),
        lastUpdated: lastUpdated ?? this.lastUpdated,
      );
}

class ReviewViewModel extends StateNotifier<ReviewState> {
  ReviewViewModel(this._ref, this.applicationId) : super(const ReviewState());

  final Ref _ref;
  final String applicationId;

  ApplicationsRepository get _repo => _ref.read(applicationsRepositoryProvider);

  void select(ApplicationStatus? status) {
    state = state.copyWith(selected: status, clearSelected: status == null, clearError: true);
  }

  /// PATCH status with `expectedCurrentStatus` = the status currently shown.
  /// Returns true on success; the detail stream refreshes the page by itself
  /// and the selection is reset (web `load()` → setNext('')).
  Future<bool> updateStatus({
    required ApplicationModel current,
    required ApplicationStatus next,
    String? note,
  }) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) {
      state = state.copyWith(error: const Failure.unauthorized().message);
      return false;
    }
    state = state.copyWith(submitting: true, clearError: true);
    try {
      await _repo.updateStatus(
        applicationId: applicationId,
        expectedCurrentStatus: current.status,
        newStatus: next,
        actor: me,
        note: note,
      );
      if (!mounted) return true;
      state = state.copyWith(submitting: false, clearSelected: true, lastUpdated: next);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(submitting: false, error: Failure.from(e).message);
      return false;
    }
  }

  /// 'Nhắn tin cho ứng viên' — returns the chatId to push.
  Future<String?> openChatWithCandidate(ApplicationModel app) async {
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me == null) return null;
    state = state.copyWith(openingChat: true, clearError: true);
    try {
      final id = await _ref.read(chatRepositoryProvider).openChatWith(
        otherUid: app.jobSeekerId,
        otherName: app.candidateFullName.isEmpty ? 'Ứng viên' : app.candidateFullName,
        jobId: app.jobId,
        jobTitle: app.jobTitle,
      );
      if (mounted) state = state.copyWith(openingChat: false);
      return id;
    } catch (e) {
      if (mounted) {
        state = state.copyWith(openingChat: false, error: Failure.from(e).message);
      }
      return null;
    }
  }
}

final reviewViewModelProvider =
    StateNotifierProvider.autoDispose.family<ReviewViewModel, ReviewState, String>(
  (ref, applicationId) => ReviewViewModel(ref, applicationId),
);

/// Seeker-side 'Nhắn tin cho nhà tuyển dụng' (ApplicationDetailPage).
final openEmployerChatProvider =
    Provider.autoDispose<Future<String?> Function(ApplicationModel app)>((ref) {
  return (ApplicationModel app) async {
    final me = ref.read(currentUserProvider).valueOrNull;
    if (me == null) return null;
    return ref.read(chatRepositoryProvider).openChatWith(
          otherUid: app.employerId,
          otherName: app.companyName.isEmpty ? 'Nhà tuyển dụng' : app.companyName,
          jobId: app.jobId,
          jobTitle: app.jobTitle,
        );
  };
});
