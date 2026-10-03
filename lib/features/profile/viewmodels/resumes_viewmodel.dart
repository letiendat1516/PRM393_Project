import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/resume_model.dart';
import '../data/profile_repository.dart';
import 'profile_providers.dart';

/// ResumePage upload machine: 'idle' | 'uploading' | 'success' | 'error'.
enum UploadStatus { idle, uploading, success, error }

/// Per-CV AI panel state (analysesMap). `done` is derived from the live
/// resume document (resume.aiAnalysis), so only loading/error live here.
class AnalysisRunState {
  const AnalysisRunState({this.loading = false, this.error});
  final bool loading;
  final String? error;

  static const idle = AnalysisRunState();
}

class ResumesState {
  const ResumesState({
    this.upload = UploadStatus.idle,
    this.uploadError,
    this.storageNotice,
    this.runs = const {},
  });

  final UploadStatus upload;
  final String? uploadError;

  /// Set after an upload whose file could not be persisted (no Storage).
  final String? storageNotice;

  final Map<String, AnalysisRunState> runs;

  bool get uploading => upload == UploadStatus.uploading;

  AnalysisRunState runFor(String resumeId) => runs[resumeId] ?? AnalysisRunState.idle;

  ResumesState copyWith({
    UploadStatus? upload,
    String? uploadError,
    String? storageNotice,
    Map<String, AnalysisRunState>? runs,
    bool clearUploadError = false,
    bool clearStorageNotice = false,
  }) =>
      ResumesState(
        upload: upload ?? this.upload,
        uploadError: clearUploadError ? null : (uploadError ?? this.uploadError),
        storageNotice:
            clearStorageNotice ? null : (storageNotice ?? this.storageNotice),
        runs: runs ?? this.runs,
      );
}

/// A file picked by the user (file_picker PlatformFile shape, platform-free).
class PickedResumeFile {
  const PickedResumeFile({
    required this.name,
    required this.bytes,
    required this.size,
  });
  final String name;
  final Uint8List bytes;
  final int size;

  String get extension {
    final i = name.lastIndexOf('.');
    return i < 0 ? '' : name.substring(i + 1).toLowerCase();
  }

  bool get isPdf => extension == 'pdf';
  bool get isText => extension == 'txt';
}

class ResumesViewModel extends StateNotifier<ResumesState> {
  ResumesViewModel(this._ref) : super(const ResumesState());
  final Ref _ref;

  static const uploadSuccess = 'Tải CV thành công.';
  static const missingFile = 'Vui lòng chọn tệp PDF.';
  static const wrongType = 'Chỉ chấp nhận tệp PDF hoặc .txt.';
  static const tooLarge = 'Tệp CV tối đa 5 MB.';
  static const extractFailed = 'Không thể trích xuất CV';
  static const storageUnavailable =
      'Không thể lưu trữ tệp PDF (Firebase Storage chưa được bật). CV đã được '
      'lưu ở dạng thông tin — hãy dùng "Dán nội dung CV" để AI có thể phân tích.';

  ProfileRepository get _repo => _ref.read(profileRepositoryProvider);

  String _requireUid() {
    final uid = _ref.read(currentUidProvider);
    if (uid == null) throw const Failure.unauthorized();
    return uid;
  }

  /// resumeUpload middleware: PDF (or .txt) ≤ 5 MB.
  static String? validateFile(PickedResumeFile? file) {
    if (file == null) return missingFile;
    if (!AppConfig.resumeExtensions.contains(file.extension)) return wrongType;
    if (file.size > AppConfig.resumeMaxBytes) return tooLarge;
    return null;
  }

  void resetUploadStatus() {
    state = state.copyWith(
      upload: UploadStatus.idle,
      clearUploadError: true,
      clearStorageNotice: true,
    );
  }

  /// Drops every per-account bit of state (upload status + AI runs). Called
  /// when the signed-in uid changes so a previous account's loading/error
  /// strips can never leak into the next session.
  void reset() {
    if (!mounted) return;
    state = const ResumesState();
  }

  /// POST /resumes. Returns the created resume or null on failure.
  ///
  /// Mirrors ResumeService.uploadResume: once the document is stored the
  /// AI extraction is kicked off in the background (fire-and-forget) — its
  /// outcome lands in [ResumesState.runs] and never affects the upload result.
  Future<ResumeModel?> upload({
    required PickedResumeFile? file,
    required String title,
  }) async {
    final invalid = validateFile(file);
    if (invalid != null) {
      state = state.copyWith(upload: UploadStatus.error, uploadError: invalid);
      return null;
    }
    state = state.copyWith(
      upload: UploadStatus.uploading,
      clearUploadError: true,
      clearStorageNotice: true,
    );
    try {
      String? rawText;
      if (file!.isText) {
        rawText = _decodeText(file.bytes);
      }
      final result = await _repo.createResume(
        uid: _requireUid(),
        title: title,
        fileName: file.name,
        bytes: file.bytes,
        rawText: rawText,
      );
      state = state.copyWith(
        upload: UploadStatus.success,
        storageNotice:
            (!result.fileStored && file.isPdf) ? storageUnavailable : null,
      );
      // UC-AI-01: background analysis right after upload (web backend
      // `ResumeService.analyzeResume(...).catch(log)`), only when there is
      // text for the model to read. `analyze()` stores failures per-CV.
      if ((result.resume.rawText ?? '').trim().isNotEmpty) {
        unawaited(analyze(result.resume));
      }
      return result.resume;
    } catch (e) {
      state = state.copyWith(
        upload: UploadStatus.error,
        uploadError: Failure.from(e).message,
      );
      return null;
    }
  }

  static String _decodeText(Uint8List bytes) {
    try {
      return utf8.decode(bytes);
    } on FormatException {
      return latin1.decode(bytes);
    }
  }

  Future<void> setPrimary(String resumeId) async {
    try {
      await _repo.setPrimary(uid: _requireUid(), resumeId: resumeId);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> delete(ResumeModel resume) async {
    try {
      await _repo.deleteResume(uid: _requireUid(), resume: resume);
      final runs = Map<String, AnalysisRunState>.from(state.runs)..remove(resume.resumeId);
      state = state.copyWith(runs: runs);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  Future<void> rename(String resumeId, String title) async {
    try {
      await _repo.rename(resumeId: resumeId, title: title);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// 'Dán nội dung CV' — stores the pasted text as rawText.
  Future<void> saveRawText(String resumeId, String text) async {
    try {
      await _repo.saveRawText(resumeId: resumeId, text: text);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// POST /resumes/:id/analyze (per-CV optimistic loading state).
  Future<AiAnalysis?> analyze(ResumeModel resume) async {
    _setRun(resume.resumeId, const AnalysisRunState(loading: true));
    try {
      final analysis =
          await _repo.analyzeResume(uid: _requireUid(), resume: resume);
      _setRun(resume.resumeId, AnalysisRunState.idle);
      return analysis;
    } catch (e) {
      final msg = Failure.from(e).message;
      _setRun(
        resume.resumeId,
        AnalysisRunState(error: msg.isEmpty ? extractFailed : msg),
      );
      return null;
    }
  }

  void _setRun(String resumeId, AnalysisRunState run) {
    if (!mounted) return;
    final runs = Map<String, AnalysisRunState>.from(state.runs);
    if (run.loading || run.error != null) {
      runs[resumeId] = run;
    } else {
      runs.remove(resumeId);
    }
    state = state.copyWith(runs: runs);
  }
}

/// Kept alive (not autoDispose) so in-flight AI runs survive navigation
/// between /ho-so and /ho-so/phan-tich/:id. State is reset whenever the
/// signed-in uid changes (logout / login as someone else).
final resumesViewModelProvider =
    StateNotifierProvider<ResumesViewModel, ResumesState>((ref) {
  final vm = ResumesViewModel(ref);
  ref.listen<String?>(currentUidProvider, (previous, next) {
    if (previous != next) vm.reset();
  });
  return vm;
});
