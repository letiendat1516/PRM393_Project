import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/models/user_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/applications_repository.dart';

/// ApplyModal.jsx state machine.
enum ApplyPhase { idle, validating, ready, submitting, success, error }

/// Why the apply UI is blocked before any context is fetched.
enum ApplyBlocker { none, guest, wrongRole }

class ApplyState {
  const ApplyState({
    this.phase = ApplyPhase.idle,
    this.blocker = ApplyBlocker.none,
    this.context,
    this.error,
    this.coverLetter = '',
    this.selectedResumeId,
    this.result,
  });

  final ApplyPhase phase;
  final ApplyBlocker blocker;
  final ApplyContext? context;
  final String? error;
  final String coverLetter;
  final String? selectedResumeId;
  final ApplicationModel? result;

  static const guestMessage = 'Vui lòng đăng nhập để ứng tuyển.';
  static const wrongRoleMessage = 'Chỉ tài khoản ứng viên mới có thể ứng tuyển.';
  static const noResumeMessage = 'Bạn chưa có CV chính. Hãy tải CV trong hồ sơ cá nhân.';
  static const alreadyAppliedMessage = 'Bạn đã ứng tuyển công việc này.';
  static const coverLetterMax = 5000;

  ResumeModel? get resume => context?.resumeById(selectedResumeId);

  /// `['full_name','headline','city'].filter(k => !profile[k])` — raw keys,
  /// exactly as the web banner prints them.
  List<String> get missingProfile {
    final profile = context?.profile;
    return profile == null ? const [] : missingProfileKeys(profile);
  }

  bool get alreadyApplied => context?.alreadyApplied ?? false;

  /// canSubmit = ready && resume && !alreadyApplied && !missingProfile.length.
  /// A failed submit (phase error with a loaded context) stays retryable.
  bool get canSubmit =>
      (phase == ApplyPhase.ready || (phase == ApplyPhase.error && context != null)) &&
      resume != null &&
      !alreadyApplied &&
      missingProfile.isEmpty &&
      coverLetter.length <= coverLetterMax;

  bool get isBusy => phase == ApplyPhase.validating || phase == ApplyPhase.submitting;

  ApplyState copyWith({
    ApplyPhase? phase,
    ApplyBlocker? blocker,
    ApplyContext? context,
    String? error,
    bool clearError = false,
    String? coverLetter,
    String? selectedResumeId,
    ApplicationModel? result,
  }) =>
      ApplyState(
        phase: phase ?? this.phase,
        blocker: blocker ?? this.blocker,
        context: context ?? this.context,
        error: clearError ? null : (error ?? this.error),
        coverLetter: coverLetter ?? this.coverLetter,
        selectedResumeId: selectedResumeId ?? this.selectedResumeId,
        result: result ?? this.result,
      );
}

/// Shared by ApplyModal (dialog/sheet) and ApplyJobPage (3-step wizard).
class ApplyViewModel extends StateNotifier<ApplyState> {
  /// Mirrors the web `useEffect(..., [isOpen, job, isAuthenticated, role])`:
  /// the gate list re-runs whenever the auth identity/role resolves or
  /// changes. The router lets /viec-lam/:id(/ung-tuyen) build while
  /// users/{uid} is still loading, so a one-shot read here would lock a
  /// signed-in seeker into the guest banner.
  ApplyViewModel(this._ref, this.jobId) : super(const ApplyState()) {
    _ref.listen<AsyncValue<UserModel?>>(
      currentUserProvider,
      (_, next) => _onUser(next),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  final String jobId;

  /// `uid|role|isActive` of the user the current state was computed for.
  String? _userKey;

  ApplicationsRepository get _repo => _ref.read(applicationsRepositoryProvider);

  UserModel? get _me => _ref.read(currentUserProvider).valueOrNull;

  static String _keyOf(UserModel? me) =>
      me == null ? '' : '${me.uid}|${me.role.name}|${me.isActive}';

  void _onUser(AsyncValue<UserModel?> next) {
    if (next.isLoading && !next.hasValue) {
      // Auth still resolving → 'Đang kiểm tra hồ sơ và CV...' (never the
      // guest banner) until users/{uid} arrives.
      if (_userKey == null) {
        state = state.copyWith(
            phase: ApplyPhase.validating, blocker: ApplyBlocker.none, clearError: true);
      }
      return;
    }
    if (next.hasError && !next.hasValue) {
      _userKey = null;
      state = state.copyWith(
        phase: ApplyPhase.error,
        blocker: ApplyBlocker.none,
        error: Failure.from(next.error!).message,
      );
      return;
    }
    final key = _keyOf(next.valueOrNull);
    // users/{uid} re-emits on unrelated writes (fcmTokens, photoUrl…);
    // only identity / role / active changes re-run the gates.
    if (key == _userKey) return;
    _userKey = key;
    load();
  }

  /// idle → validating → ready | error. Guests / non-seekers never fetch.
  Future<void> load() async {
    final me = _me;
    if (me == null) {
      state = state.copyWith(phase: ApplyPhase.idle, blocker: ApplyBlocker.guest, clearError: true);
      return;
    }
    if (!me.isJobSeeker) {
      state = state.copyWith(
          phase: ApplyPhase.idle, blocker: ApplyBlocker.wrongRole, clearError: true);
      return;
    }
    state = state.copyWith(
        phase: ApplyPhase.validating, blocker: ApplyBlocker.none, clearError: true);
    try {
      if (!me.isActive) throw const Failure.forbidden('Tài khoản đã bị vô hiệu hóa.');
      final ctx = await _repo.getApplyContext(seekerUid: me.uid, jobId: jobId);
      if (!mounted) return;
      state = state.copyWith(
        phase: ApplyPhase.ready,
        context: ctx,
        selectedResumeId: state.selectedResumeId ?? ctx.defaultResume?.resumeId,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(phase: ApplyPhase.error, error: Failure.from(e).message);
    }
  }

  void setCoverLetter(String value) {
    final v = value.length > ApplyState.coverLetterMax
        ? value.substring(0, ApplyState.coverLetterMax)
        : value;
    state = state.copyWith(coverLetter: v);
  }

  void selectResume(String? resumeId) {
    if (resumeId == null) return;
    state = state.copyWith(selectedResumeId: resumeId);
  }

  /// Re-run the gate list after an error so the user can retry.
  Future<void> retry() => load();

  /// ready → submitting → success | error.
  Future<bool> submit() async {
    if (!state.canSubmit) return false;
    final me = _me;
    final ctx = state.context;
    final resume = state.resume;
    if (me == null || ctx == null || resume == null) return false;

    state = state.copyWith(phase: ApplyPhase.submitting, clearError: true);
    try {
      final app = await _repo.apply(
        seeker: me,
        profile: ctx.profile,
        job: ctx.job,
        resume: resume,
        coverLetter: state.coverLetter,
      );
      if (!mounted) return true;
      state = state.copyWith(phase: ApplyPhase.success, result: app, clearError: true);
      return true;
    } catch (e) {
      if (!mounted) return false;
      final f = Failure.from(e);
      // Duplicate → reflect it in the context so the banner shows too.
      final ctxNext = f.code == 'DUPLICATE_APPLICATION'
          ? ApplyContext(
              profile: ctx.profile, resumes: ctx.resumes, job: ctx.job, alreadyApplied: true)
          : null;
      state = state.copyWith(phase: ApplyPhase.error, error: f.message, context: ctxNext);
      return false;
    }
  }
}

final applyViewModelProvider =
    StateNotifierProvider.autoDispose.family<ApplyViewModel, ApplyState, String>(
  (ref, jobId) => ApplyViewModel(ref, jobId),
);
