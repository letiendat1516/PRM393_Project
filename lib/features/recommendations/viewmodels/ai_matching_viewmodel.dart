import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/providers.dart';
import '../../../core/services/ai/rule_based_scorer.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/resume_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/recommendations_repository.dart';
import 'sessions_provider.dart';

/// AIScoreModal mode toggle: 'CV đã trích xuất' | 'Tải lên CV mới'.
enum CvMode { preset, upload }

/// Scoring engine: Gemini ('AI'), RuleBasedScorer ('SQL') or both.
enum ScoringMethod {
  ai('ai', 'AI'),
  sql('sql', 'SQL'),
  both('both', 'Cả hai');

  const ScoringMethod(this.wire, this.label);
  final String wire;
  final String label;

  bool get usesAi => this != ScoringMethod.sql;
  bool get usesSql => this != ScoringMethod.ai;

  /// Primary button label ('Chấm điểm với AI' adapts to the method).
  String get buttonLabel => switch (this) {
        ScoringMethod.ai => 'Chấm điểm với AI',
        ScoringMethod.sql => 'Chấm điểm với SQL',
        ScoringMethod.both => 'Chấm điểm với AI + SQL',
      };
}

class AiMatchingState {
  const AiMatchingState({
    this.jobs = const [],
    this.mode = CvMode.preset,
    this.selectedResumeId,
    this.uploadedText = '',
    this.fileName,
    this.method = ScoringMethod.ai,
    this.loading = false,
    this.progressCurrent = 0,
    this.progressTotal = 0,
    this.error,
    this.warning,
    this.results,
    this.cvName = '',
    this.saving = false,
    this.savedSessionId,
  });

  final List<JobModel> jobs;
  final CvMode mode;
  final String? selectedResumeId;
  final String uploadedText;
  final String? fileName;
  final ScoringMethod method;
  final bool loading;
  /// AIScoreModal `progress` — total stays 0 until the AI batches start, so
  /// the button reads 'Đang chấm điểm...' during CV extraction.
  final int progressCurrent;
  final int progressTotal;
  final String? error;
  final String? warning;
  /// jobId → {ai?: JobScore, sql?: JobScore}; null until a run completed.
  final Map<String, Map<String, JobScore>>? results;
  final String cvName;
  final bool saving;
  /// Session id created right after scoring (JobsPage onScored → saveSession).
  final String? savedSessionId;

  bool get hasResults => results != null;

  bool get canScore =>
      !loading &&
      jobs.isNotEmpty &&
      (mode == CvMode.preset ? selectedResumeId != null : uploadedText.trim().isNotEmpty);

  /// Method actually present in the results (drives MethodBadge on save).
  String get effectiveMethod {
    final r = results;
    if (r == null || r.isEmpty) return method.wire;
    final hasAi = r.values.any((m) => m.containsKey('ai'));
    final hasSql = r.values.any((m) => m.containsKey('sql'));
    if (hasAi && hasSql) return 'both';
    if (hasSql) return 'sql';
    return 'ai';
  }

  /// Best score per job, sorted by match_score desc (results list).
  List<(JobModel, JobScore)> get ranked {
    final r = results;
    if (r == null) return const [];
    final out = <(JobModel, JobScore)>[];
    for (final j in jobs) {
      final m = r[j.jobId];
      final s = m?['ai'] ?? m?['sql'];
      if (s != null) out.add((j, s));
    }
    out.sort((a, b) => b.$2.matchScore.compareTo(a.$2.matchScore));
    return out;
  }

  AiMatchingState copyWith({
    List<JobModel>? jobs,
    CvMode? mode,
    String? selectedResumeId,
    bool clearSelectedResume = false,
    String? uploadedText,
    String? fileName,
    bool clearFileName = false,
    ScoringMethod? method,
    bool? loading,
    int? progressCurrent,
    int? progressTotal,
    String? error,
    bool clearError = false,
    String? warning,
    bool clearWarning = false,
    Map<String, Map<String, JobScore>>? results,
    bool clearResults = false,
    String? cvName,
    bool? saving,
    String? savedSessionId,
    bool clearSaved = false,
  }) =>
      AiMatchingState(
        jobs: jobs ?? this.jobs,
        mode: mode ?? this.mode,
        selectedResumeId:
            clearSelectedResume ? null : (selectedResumeId ?? this.selectedResumeId),
        uploadedText: uploadedText ?? this.uploadedText,
        fileName: clearFileName ? null : (fileName ?? this.fileName),
        method: method ?? this.method,
        loading: loading ?? this.loading,
        progressCurrent: progressCurrent ?? this.progressCurrent,
        progressTotal: progressTotal ?? this.progressTotal,
        error: clearError ? null : (error ?? this.error),
        warning: clearWarning ? null : (warning ?? this.warning),
        results: clearResults ? null : (results ?? this.results),
        cvName: cvName ?? this.cvName,
        saving: saving ?? this.saving,
        savedSessionId: clearSaved ? null : (savedSessionId ?? this.savedSessionId),
      );
}

/// Port of AIScoreModal.jsx handleScore/handleFileChange + JobsPage onScored.
class AiMatchingViewModel extends StateNotifier<AiMatchingState> {
  AiMatchingViewModel(this._ref) : super(const AiMatchingState());

  final Ref _ref;

  static const timeoutMessage =
      'Quá thời gian chờ. AI đang xử lý quá nhiều — thử lại với ít jobs hơn (filter thêm).';
  static const networkMessage =
      'Không kết nối được máy chủ AI. Vui lòng kiểm tra kết nối mạng và thử lại.';
  static const allBatchesFailedMessage =
      'Tất cả batch đều thất bại. Kiểm tra cấu hình GEMINI_API_KEY trong Cấu hình hệ thống.';
  /// Web routes are JWT-protected (`router.use(authenticate)`); here the
  /// Gemini key lives in systemConfigurations which only signed-in users may
  /// read, so a guest asking for AI fails fast instead of retrying 3× per batch.
  static const loginRequiredMessage = 'Vui lòng đăng nhập để chấm điểm bằng AI.';

  // ── Form state ───────────────────────────────────────────────────────
  void setJobs(List<JobModel> jobs) {
    if (state.jobs.length == jobs.length && state.jobs.isNotEmpty) return;
    state = state.copyWith(jobs: jobs);
  }

  void setMode(CvMode mode) => state = state.copyWith(mode: mode, clearError: true);

  void selectResume(String? id) =>
      state = state.copyWith(selectedResumeId: id, clearSelectedResume: id == null, clearError: true);

  void setMethod(ScoringMethod m) => state = state.copyWith(method: m, clearError: true);

  /// Text pasted or extracted from a file — capped at 8000 chars like the web
  /// (`setUploadedText(text.slice(0, 8000))`).
  void setUploadedText(String text, {String? fileName, bool keepFileName = false}) {
    final capped = text.length > AppConfig.aiResumeTextCap
        ? text.substring(0, AppConfig.aiResumeTextCap)
        : text;
    state = state.copyWith(
      uploadedText: capped,
      fileName: fileName,
      clearFileName: fileName == null && !keepFileName,
      clearError: true,
    );
  }

  /// handleFileChange: `setFileName(file.name); setError(null);` before parsing.
  void setFileName(String name) => state = state.copyWith(fileName: name, clearError: true);

  void setError(String message) => state = state.copyWith(error: message);

  /// Back to the CV selection step (keeps the chosen CV/method).
  void reset() => state = state.copyWith(
        clearResults: true,
        clearError: true,
        clearWarning: true,
        clearSaved: true,
        progressCurrent: 0,
        progressTotal: 0,
      );

  // ── Scoring (handleScore) ────────────────────────────────────────────
  Future<void> score() async {
    if (state.loading) return;
    final jobs = state.jobs;
    state = state.copyWith(
      loading: true,
      clearError: true,
      clearWarning: true,
      clearResults: true,
      clearSaved: true,
      progressCurrent: 0,
      progressTotal: 0,
    );
    try {
      if (jobs.isEmpty) throw const Failure('Danh sách jobs không được rỗng');
      if (jobs.length > AppConfig.aiMaxJobsPerScoring) {
        throw Failure(
          'Giới hạn ${AppConfig.aiMaxJobsPerScoring} jobs/lần gọi (nhận ${jobs.length}). Hãy filter thêm.',
        );
      }

      final method = state.method;
      final uid = _ref.read(currentUserProvider).valueOrNull?.uid;
      if (method.usesAi && uid == null && AppConfig.geminiApiKey.isEmpty) {
        throw const Failure(loginRequiredMessage, status: 401, code: 'AUTH_REQUIRED');
      }

      final (cv, cvName) = await _resolveCv();
      final results = <String, Map<String, JobScore>>{};

      // SQL: deterministic + instant.
      if (method.usesSql) {
        for (final s in RuleBasedScorer.scoreJobs(cv, jobs)) {
          (results[s.jobId] ??= {})['sql'] = s;
        }
      }

      // AI: batches of 10, 2 in parallel, 2 retries with 5s/10s backoff.
      var batchErrors = 0;
      Object? lastAiError;
      if (method.usesAi) {
        state = state.copyWith(progressCurrent: 0, progressTotal: jobs.length);
        final batches = <List<JobModel>>[
          for (var i = 0; i < jobs.length; i += AppConfig.aiBatchSize)
            jobs.sublist(i, math.min(i + AppConfig.aiBatchSize, jobs.length)),
        ];
        final gemini = _ref.read(geminiServiceProvider);
        var completed = 0;
        final aiScores = <JobScore>[];

        await _runConcurrent(
          [
            for (final batch in batches)
              () async {
                try {
                  final r = await _withRetry(() => gemini.scoreJobs(cv, batch, jobSeekerId: uid));
                  aiScores.addAll(r);
                } catch (e) {
                  batchErrors++;
                  lastAiError = e;
                  if (e is Failure && e.code == 'AI_KEY_MISSING') rethrow;
                } finally {
                  completed += batch.length;
                  if (mounted) state = state.copyWith(progressCurrent: completed);
                }
              },
          ],
          AppConfig.aiMaxConcurrency,
        );

        for (final s in aiScores) {
          (results[s.jobId] ??= {})['ai'] = s;
        }
        final aiCount = aiScores.length;
        if (aiCount == 0) {
          if (!method.usesSql) {
            final le = lastAiError;
            if (le is Failure && le.code == 'AI_KEY_MISSING') throw le;
            throw Failure(le == null ? allBatchesFailedMessage : _mapError(le));
          }
        } else if (batchErrors > 0) {
          state = state.copyWith(
            warning:
                '$batchErrors batch thất bại, đã chấm được $aiCount/${jobs.length} việc làm',
          );
        }
      }

      if (results.isEmpty) throw const Failure(allBatchesFailedMessage);
      if (method == ScoringMethod.both && !results.values.any((m) => m.containsKey('ai'))) {
        state = state.copyWith(warning: 'AI không trả về kết quả — chỉ hiển thị điểm SQL.');
      }

      state = state.copyWith(results: results, cvName: cvName);
      // onScored(scoreMap, cvName) → JobsPage saveSession(...) right away; the
      // session exists even if the user closes without 'Lưu kết quả'.
      await _persistSession();
    } catch (e) {
      if (mounted) state = state.copyWith(error: _mapError(e));
    } finally {
      if (mounted) {
        state = state.copyWith(loading: false, progressCurrent: 0, progressTotal: 0);
      }
    }
  }

  /// Returns (cvPayload, cvName) for the selected mode.
  Future<(Map<String, dynamic>, String)> _resolveCv() async {
    if (state.mode == CvMode.preset) {
      final resumes = _ref.read(analyzedResumesProvider).valueOrNull ?? const <ResumeModel>[];
      ResumeModel? found;
      for (final r in resumes) {
        if (r.resumeId == state.selectedResumeId) found = r;
      }
      final analysis = found?.aiAnalysis;
      if (found == null || analysis == null) throw const Failure('Vui lòng chọn CV');
      // AIScoreModal: `education_level: analysis.education_level ?? 'Bachelor'`.
      final cv = analysis.toCvPayload();
      if ((cv['education_level'] as String? ?? '').isEmpty) cv['education_level'] = 'Bachelor';
      return (cv, found.title.isNotEmpty ? found.title : found.fileName);
    }

    final text = state.uploadedText.trim();
    if (text.isEmpty) throw const Failure('Vui lòng tải lên CV');
    if (text.length <= 20) throw const Failure('resumeText quá ngắn hoặc thiếu');
    final cvName = (state.fileName?.trim().isNotEmpty ?? false) ? state.fileName!.trim() : 'Uploaded CV';

    final uid = _ref.read(currentUserProvider).valueOrNull?.uid;
    try {
      final analysis = await _ref.read(geminiServiceProvider).extractResume(text, jobSeekerId: uid);
      return (analysis.toCvPayload(), cvName);
    } catch (e) {
      // SQL scoring is free/offline on the web; keep it usable (incl. guests)
      // without a Gemini key by falling back to a keyword-based extraction.
      if (state.method == ScoringMethod.sql) {
        state = state.copyWith(
          warning: 'Không trích xuất được CV bằng AI — dùng trích xuất từ khoá cơ bản cho SQL.',
        );
        return (_naiveCv(text, state.jobs), cvName);
      }
      rethrow;
    }
  }

  // ── Persistence ──────────────────────────────────────────────────────
  /// JobsPage onScored → `saveSession({cvName: cvName || 'Phiên chấm điểm', …})`.
  /// Local store first (+ best-effort users/{uid}/aiSessions mirror), then the
  /// /de-xuat list is refreshed. No-op when this run was already stored.
  Future<void> _persistSession() async {
    final results = state.results;
    if (results == null || results.isEmpty || state.savedSessionId != null) return;
    try {
      final me = _ref.read(currentUserProvider).valueOrNull;
      final repo = _ref.read(recommendationsRepositoryProvider);
      final cvName = state.cvName.trim().isEmpty ? 'Phiên chấm điểm' : state.cvName;
      final session = await repo.saveSession(
        cvName: cvName,
        method: state.effectiveMethod,
        scores: results,
        jobs: state.jobs,
        uid: me?.uid,
      );
      _ref.read(sessionsProvider.notifier).refresh();
      if (mounted) state = state.copyWith(savedSessionId: session.id);
    } catch (e) {
      if (mounted) state = state.copyWith(error: Failure.from(e).message);
    }
  }

  /// 'Lưu kết quả' (AIScoreModal): `recommendationService.saveScores(...)
  /// .catch(() => {}); close();` — the session was already created when
  /// scoring finished, so this only retries that if it failed and then
  /// upserts jobRecommendations/{uid_jobId} for job seekers (fire-and-forget,
  /// like the web). The caller closes the sheet afterwards.
  Future<void> saveResults() async {
    final results = state.results;
    if (results == null || results.isEmpty || state.saving) return;
    state = state.copyWith(saving: true, clearError: true);
    if (state.savedSessionId == null) await _persistSession();
    if (!mounted) return;
    final me = _ref.read(currentUserProvider).valueOrNull;
    if (me != null && me.isJobSeeker) {
      _ref
          .read(recommendationsRepositoryProvider)
          .upsertRecommendations(
            seekerUid: me.uid,
            scores: results,
            jobs: state.jobs,
            resumeId: state.mode == CvMode.preset ? state.selectedResumeId : null,
          )
          .ignore(); // best-effort denormalisation; the session is already saved
    }
    state = state.copyWith(saving: false);
  }

  // ── helpers ──────────────────────────────────────────────────────────
  /// withRetry(): up to MAX_RETRIES extra attempts with 5s/10s backoff.
  Future<T> _withRetry<T>(Future<T> Function() fn) async {
    for (var attempt = 0;; attempt++) {
      try {
        return await fn();
      } catch (e) {
        if (e is Failure && (e.code == 'AI_KEY_MISSING' || e.code == 'TOO_MANY_JOBS')) rethrow;
        if (attempt >= AppConfig.aiMaxRetries) rethrow;
        final backoff = AppConfig.aiRetryBackoff[
            math.min(attempt, AppConfig.aiRetryBackoff.length - 1)];
        await Future<void>.delayed(backoff);
      }
    }
  }

  /// runBatchesConcurrent(): simple worker pool with [limit] parallelism.
  /// Each task handles its own errors; an AI_KEY_MISSING failure aborts all.
  Future<void> _runConcurrent(List<Future<void> Function()> tasks, int limit) async {
    var next = 0;
    Future<void> worker() async {
      while (true) {
        final i = next++;
        if (i >= tasks.length) return;
        await tasks[i]();
      }
    }

    await Future.wait([for (var w = 0; w < math.min(limit, tasks.length); w++) worker()]);
  }

  static String _mapError(Object e) {
    if (e is TimeoutException) return timeoutMessage;
    final raw = e is Failure ? e.message : e.toString();
    final lower = raw.toLowerCase();
    if (lower.contains('timeout') || lower.contains('exceeded')) return timeoutMessage;
    final f = Failure.from(e);
    if (f.code == 'NETWORK' ||
        lower.contains('network') ||
        lower.contains('socketexception') ||
        lower.contains('clientexception') ||
        lower.contains('failed to fetch')) {
      return networkMessage;
    }
    if (e is Failure) return e.message;
    return f.message.isEmpty ? 'Lỗi khi chấm điểm' : f.message;
  }

  /// Keyword-based CV extraction used only as a SQL fallback when Gemini is
  /// unavailable. Matches skill names required by the listed jobs.
  static Map<String, dynamic> _naiveCv(String text, List<JobModel> jobs) {
    final lower = text.toLowerCase();
    final skills = <String>{};
    for (final j in jobs) {
      for (final s in j.requiredSkills) {
        final name = s.skillName.trim();
        if (name.length >= 2 && lower.contains(name.toLowerCase())) skills.add(name);
      }
    }
    double years = 0;
    for (final m in RegExp(r'(\d+(?:[.,]\d+)?)\s*\+?\s*(năm|year)').allMatches(lower)) {
      final v = double.tryParse(m.group(1)!.replaceAll(',', '.')) ?? 0;
      if (v > years && v <= 50) years = v;
    }
    String edu = 'Other';
    if (lower.contains('tiến sĩ') || lower.contains('phd') || lower.contains('doctor')) {
      edu = 'PhD';
    } else if (lower.contains('thạc sĩ') || lower.contains('master')) {
      edu = 'Master';
    } else if (lower.contains('cử nhân') ||
        lower.contains('bachelor') ||
        lower.contains('đại học') ||
        lower.contains('university')) {
      edu = 'Bachelor';
    }
    const langs = {
      'english': 'English', 'tiếng anh': 'English', 'ielts': 'English', 'toeic': 'English',
      'japanese': 'Japanese', 'tiếng nhật': 'Japanese', 'jlpt': 'Japanese',
      'korean': 'Korean', 'tiếng hàn': 'Korean', 'chinese': 'Chinese', 'tiếng trung': 'Chinese',
      'french': 'French', 'tiếng pháp': 'French', 'german': 'German', 'tiếng đức': 'German',
    };
    final languages = <String>{for (final e in langs.entries) if (lower.contains(e.key)) e.value};
    const soft = {
      'teamwork': 'Teamwork', 'làm việc nhóm': 'Teamwork', 'communication': 'Communication',
      'giao tiếp': 'Communication', 'leadership': 'Leadership', 'lãnh đạo': 'Leadership',
      'problem solving': 'Problem solving', 'giải quyết vấn đề': 'Problem solving',
      'time management': 'Time management', 'quản lý thời gian': 'Time management',
    };
    final softSkills = <String>{for (final e in soft.entries) if (lower.contains(e.key)) e.value};
    return {
      'skills': skills.toList(),
      'soft_skills': softSkills.toList(),
      'experience_years': years,
      'education_level': edu,
      'languages': languages.toList(),
      'certifications': const <String>[],
      'work_experience': const <Map<String, dynamic>>[],
      'summary': text.length > 300 ? text.substring(0, 300) : text,
    };
  }
}

final aiMatchingViewModelProvider =
    StateNotifierProvider.autoDispose<AiMatchingViewModel, AiMatchingState>(
  (ref) => AiMatchingViewModel(ref),
);
