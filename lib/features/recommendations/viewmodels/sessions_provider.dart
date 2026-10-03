import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/models/resume_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../data/recommendations_repository.dart';

/// Scoring sessions shown on /de-xuat.
///
/// Source of truth is the local store (web localStorage parity). When the
/// user is signed in we also subscribe to `users/{uid}/aiSessions` and merge
/// any session saved on another device into the local list.
class SessionsNotifier extends StateNotifier<AsyncValue<List<AiSession>>> {
  SessionsNotifier(this._ref) : super(const AsyncValue.loading()) {
    _reloadLocal();
    _ref.listen<String?>(
      currentUserProvider.select((u) => u.valueOrNull?.uid),
      (_, uid) => _bindRemote(uid),
      fireImmediately: true,
    );
  }

  final Ref _ref;
  StreamSubscription<List<AiSession>>? _remoteSub;
  String? _uid;

  RecommendationsRepository get _repo => _ref.read(recommendationsRepositoryProvider);

  void _reloadLocal() {
    try {
      state = AsyncValue.data(_repo.loadLocalSessions());
    } catch (e, st) {
      state = AsyncValue.error(Failure.from(e), st);
    }
  }

  void _bindRemote(String? uid) {
    _remoteSub?.cancel();
    _remoteSub = null;
    _uid = uid;
    if (uid == null) {
      _reloadLocal();
      return;
    }
    _remoteSub = _repo.watchRemoteSessions(uid).listen(
      (remote) async {
        try {
          final merged = await _repo.mergeRemoteIntoLocal(remote);
          if (mounted) state = AsyncValue.data(merged);
        } catch (_) {
          if (mounted) _reloadLocal();
        }
      },
      onError: (_) {
        // Mirror unavailable (offline / rules) → keep showing local data.
        if (mounted) _reloadLocal();
      },
    );
  }

  /// Re-reads the local store (after the AI sheet saved a session).
  void refresh() => _reloadLocal();

  /// clearSessions() + confirm handled by the view.
  Future<void> clearAll() async {
    await _repo.clearSessions(uid: _uid);
    _reloadLocal();
  }

  Future<void> delete(String id) async {
    await _repo.deleteSession(id, uid: _uid);
    _reloadLocal();
  }

  @override
  void dispose() {
    _remoteSub?.cancel();
    super.dispose();
  }
}

final sessionsProvider =
    StateNotifierProvider<SessionsNotifier, AsyncValue<List<AiSession>>>(
  (ref) => SessionsNotifier(ref),
);

/// One session by id (null → "Không tìm thấy phiên").
final sessionByIdProvider = Provider.family<AsyncValue<AiSession?>, String>((ref, id) {
  return ref.watch(sessionsProvider).whenData((list) {
    for (final s in list) {
      if (s.id == id) return s;
    }
    return null;
  });
});

/// The signed-in seeker's resumes that already have an AI analysis.
final analyzedResumesProvider = StreamProvider.autoDispose<List<ResumeModel>>((ref) {
  final me = ref.watch(currentUserProvider).valueOrNull;
  if (me == null || !me.isJobSeeker) return Stream.value(const []);
  return ref.watch(recommendationsRepositoryProvider).watchAnalyzedResumes(me.uid);
});
