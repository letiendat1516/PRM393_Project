import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/utils/failure.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/employer_repository.dart';
import '../data/job_form_input.dart';

/// CreateJobPage error banner (title / message / deduped reasons).
class CreateJobError {
  const CreateJobError({
    this.title = 'Lỗi hệ thống',
    required this.message,
    this.reasons = const [],
  });
  final String title;
  final String message;
  final List<String> reasons;

  factory CreateJobError.fromFailure(Failure f, {required bool editing}) {
    final reasons = <String>[];
    f.fieldErrors.forEach((field, msg) {
      final label = JobFormInput.fieldLabels[field] ?? field;
      final clean = msg.trim();
      reasons.add(clean.toLowerCase().contains(label.toLowerCase()) ? clean : '$label: $clean');
    });
    final fallback = editing ? 'Không thể cập nhật tin tuyển dụng.' : 'Không thể tạo tin tuyển dụng.';
    return CreateJobError(
      message: f.message.isEmpty ? fallback : f.message,
      reasons: reasons.toSet().toList(),
    );
  }
}

class CreateJobState {
  const CreateJobState({
    this.input = const JobFormInput(),
    this.step = 0,
    this.loading = false,
    this.saving = false,
    this.error,
    this.fieldErrors = const {},
    this.hasDraft = false,
    this.draftSavedAt,
    this.maxSkills = AppConfig.defaultMaxSkillsPerJob,
    this.requireApproval = AppConfig.defaultRequireJobApproval,
    this.syncVersion = 0,
    this.loadError,
    this.done = false,
  });

  final JobFormInput input;
  final int step;
  /// Loading the job for edit mode.
  final bool loading;
  final bool saving;
  final CreateJobError? error;
  final Map<String, String> fieldErrors;
  /// A local draft exists and has not been restored/discarded yet.
  final bool hasDraft;
  final DateTime? draftSavedAt;
  final int maxSkills;
  final bool requireApproval;
  /// Incremented whenever the input was replaced from outside the form
  /// (draft restored / job loaded) so text controllers re-sync.
  final int syncVersion;
  final Object? loadError;
  /// Submit succeeded → page navigates back to /employer/jobs.
  final bool done;

  static const stepTitles = ['Thông tin', 'Lương & địa điểm', 'Kỹ năng & xem trước'];

  CreateJobState copyWith({
    JobFormInput? input,
    int? step,
    bool? loading,
    bool? saving,
    Object? error = _unset,
    Map<String, String>? fieldErrors,
    bool? hasDraft,
    Object? draftSavedAt = _unset,
    int? maxSkills,
    bool? requireApproval,
    int? syncVersion,
    Object? loadError = _unset,
    bool? done,
  }) =>
      CreateJobState(
        input: input ?? this.input,
        step: step ?? this.step,
        loading: loading ?? this.loading,
        saving: saving ?? this.saving,
        error: identical(error, _unset) ? this.error : error as CreateJobError?,
        fieldErrors: fieldErrors ?? this.fieldErrors,
        hasDraft: hasDraft ?? this.hasDraft,
        draftSavedAt:
            identical(draftSavedAt, _unset) ? this.draftSavedAt : draftSavedAt as DateTime?,
        maxSkills: maxSkills ?? this.maxSkills,
        requireApproval: requireApproval ?? this.requireApproval,
        syncVersion: syncVersion ?? this.syncVersion,
        loadError: identical(loadError, _unset) ? this.loadError : loadError,
        done: done ?? this.done,
      );
}

const Object _unset = Object();

/// Multi-step create/edit job form. `editJobId == null` → create mode with
/// local draft autosave (PrefsService.jobDraft).
class CreateJobViewModel extends StateNotifier<CreateJobState> {
  CreateJobViewModel(this._ref, this.editJobId) : super(const CreateJobState()) {
    _init();
  }

  final Ref _ref;
  final String? editJobId;
  Timer? _debounce;

  bool get isEditing => editJobId != null;

  EmployerRepository get _repo => _ref.read(employerRepositoryProvider);

  Future<void> _init() async {
    // Config (non-blocking for the form).
    unawaited(_repo.maxSkillsPerJob().then((v) {
      if (mounted) state = state.copyWith(maxSkills: v);
    }));
    unawaited(_repo.requireJobApproval().then((v) {
      if (mounted) state = state.copyWith(requireApproval: v);
    }));

    if (isEditing) {
      await _loadForEdit();
    } else {
      final draft = _ref.read(prefsServiceProvider).jobDraft;
      if (draft != null) {
        state = state.copyWith(hasDraft: true, draftSavedAt: JobFormInput.savedAtOf(draft));
      }
    }
  }

  Future<void> _loadForEdit() async {
    state = state.copyWith(loading: true, loadError: null);
    try {
      final me = _ref.read(currentUserProvider).valueOrNull;
      if (me == null) throw const Failure.unauthorized();
      final job = await _repo.getOwnedJob(me.uid, editJobId!);
      if (!mounted) return;
      state = state.copyWith(
        input: JobFormInput.fromJob(job),
        loading: false,
        syncVersion: state.syncVersion + 1,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(loading: false, loadError: Failure.from(e));
    }
  }

  // ── Draft ─────────────────────────────────────────────────────────────
  void restoreDraft() {
    final raw = _ref.read(prefsServiceProvider).jobDraft;
    if (raw == null) {
      state = state.copyWith(hasDraft: false);
      return;
    }
    state = state.copyWith(
      input: JobFormInput.fromJson(raw),
      hasDraft: false,
      syncVersion: state.syncVersion + 1,
      fieldErrors: const {},
      error: null,
    );
  }

  Future<void> discardDraft() async {
    await _ref.read(prefsServiceProvider).setJobDraft(null);
    if (mounted) state = state.copyWith(hasDraft: false, draftSavedAt: null);
  }

  void _scheduleDraftSave() {
    if (isEditing) return;
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 600), () async {
      final input = state.input;
      final prefs = _ref.read(prefsServiceProvider);
      if (input.isBlank) return;
      await prefs.setJobDraft(input.toJson());
      if (mounted) state = state.copyWith(draftSavedAt: DateTime.now());
    });
  }

  // ── Field updates ─────────────────────────────────────────────────────
  void update(JobFormInput Function(JobFormInput current) fn) {
    final next = fn(state.input);
    final errors = Map<String, String>.from(state.fieldErrors);
    // Clear errors of fields that changed.
    if (next.title != state.input.title) errors.remove('title');
    if (next.moTaCongViec != state.input.moTaCongViec) errors.remove('description');
    if (next.categoryName != state.input.categoryName || next.categoryId != state.input.categoryId) {
      errors.remove('category');
    }
    if (next.salaryMin != state.input.salaryMin || next.salaryMax != state.input.salaryMax ||
        next.isSalaryNegotiable != state.input.isSalaryNegotiable) {
      errors..remove('salaryMin')..remove('salaryMax');
    }
    if (next.currency != state.input.currency) errors.remove('currency');
    if (next.location != state.input.location) errors.remove('location');
    if (next.city != state.input.city) errors.remove('city');
    if (next.positions != state.input.positions) errors.remove('positionsAvailable');
    if (next.deadline != state.input.deadline) errors.remove('applicationDeadline');
    if (next.skills != state.input.skills) errors.remove('skills');
    state = state.copyWith(input: next, fieldErrors: errors, error: null);
    _scheduleDraftSave();
  }

  /// Returns false (and sets the error banner) when the cap is reached.
  bool addSkill(String raw) {
    final name = raw.trim();
    if (name.isEmpty) return false;
    final lower = name.toLowerCase();
    if (state.input.skills.any((s) => s.toLowerCase() == lower)) return true;
    if (state.input.skills.length >= state.maxSkills) {
      state = state.copyWith(
        error: CreateJobError(
          message: 'Không thể chọn thêm kỹ năng.',
          reasons: ['Một tin tuyển dụng không được có quá ${state.maxSkills} kỹ năng.'],
        ),
      );
      return false;
    }
    update((i) => i.copyWith(skills: [...i.skills, name]));
    return true;
  }

  void removeSkill(String name) {
    update((i) => i.copyWith(skills: i.skills.where((s) => s != name).toList()));
  }

  void toggleSkill(String name) {
    if (state.input.skills.any((s) => s.toLowerCase() == name.toLowerCase())) {
      update((i) => i.copyWith(
          skills: i.skills.where((s) => s.toLowerCase() != name.toLowerCase()).toList()));
    } else {
      addSkill(name);
    }
  }

  // ── Steps ─────────────────────────────────────────────────────────────
  Map<String, String> _validateStep(int step) => switch (step) {
        0 => state.input.validateInfo(),
        1 => state.input.validateSalaryLocation(),
        _ => state.input.validateSkills(state.maxSkills),
      };

  /// Validates the current step; advances when clean.
  bool next() {
    final errors = _validateStep(state.step);
    if (errors.isNotEmpty) {
      state = state.copyWith(fieldErrors: errors);
      return false;
    }
    if (state.step < CreateJobState.stepTitles.length - 1) {
      state = state.copyWith(step: state.step + 1, fieldErrors: const {});
    }
    return true;
  }

  void back() {
    if (state.step > 0) state = state.copyWith(step: state.step - 1, fieldErrors: const {});
  }

  /// Jump to a previous (or already validated) step from the step header.
  void goTo(int step) {
    if (step < 0 || step >= CreateJobState.stepTitles.length) return;
    if (step < state.step) {
      state = state.copyWith(step: step, fieldErrors: const {});
      return;
    }
    for (var s = state.step; s < step; s++) {
      final errors = _validateStep(s);
      if (errors.isNotEmpty) {
        state = state.copyWith(step: s, fieldErrors: errors);
        return;
      }
    }
    state = state.copyWith(step: step, fieldErrors: const {});
  }

  // ── Submit ────────────────────────────────────────────────────────────
  Future<bool> submit() async {
    final all = state.input.validateAll(state.maxSkills);
    if (all.isNotEmpty) {
      final firstStep = all.keys.any((k) => const ['title', 'description', 'category'].contains(k))
          ? 0
          : all.keys.any((k) => k == 'skills')
              ? 2
              : 1;
      // Same formatter as the backend path (formatValidationError parity):
      // the field label is only prefixed when the message does not already
      // name the field.
      state = state.copyWith(
        step: firstStep,
        fieldErrors: all,
        error: CreateJobError.fromFailure(
          Failure.validation(
            isEditing
                ? 'Không thể cập nhật tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung sau:'
                : 'Không thể tạo tin tuyển dụng. Vui lòng kiểm tra và sửa các nội dung sau:',
            fieldErrors: all,
          ),
          editing: isEditing,
        ),
      );
      return false;
    }

    state = state.copyWith(saving: true, error: null);
    try {
      final me = _ref.read(currentUserProvider).valueOrNull;
      if (me == null) throw const Failure.unauthorized();
      if (isEditing) {
        await _repo.updateJob(employerId: me.uid, jobId: editJobId!, input: state.input);
      } else {
        await _repo.createJob(employerId: me.uid, input: state.input);
        _debounce?.cancel();
        await _ref.read(prefsServiceProvider).setJobDraft(null);
      }
      if (mounted) state = state.copyWith(saving: false, done: true);
      return true;
    } catch (e) {
      final f = Failure.from(e);
      if (mounted) {
        state = state.copyWith(
          saving: false,
          fieldErrors: f.fieldErrors,
          error: CreateJobError.fromFailure(f, editing: isEditing),
        );
      }
      return false;
    }
  }

  void clearError() => state = state.copyWith(error: null);

  @override
  void dispose() {
    _debounce?.cancel();
    super.dispose();
  }
}

final createJobViewModelProvider = StateNotifierProvider.autoDispose
    .family<CreateJobViewModel, CreateJobState, String?>(
  (ref, editJobId) => CreateJobViewModel(ref, editJobId),
);
