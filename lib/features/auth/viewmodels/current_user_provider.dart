import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/prefs_service.dart';
import '../../../shared/models/user_model.dart';
import '../data/auth_repository.dart';

/// AuthContext.jsx equivalent: FirebaseAuth session + live users/{uid}
/// principal. Emits `null` when signed out.
///
/// Offline semantics (AuthContext: "any network error keeps the token and
/// retries up to 3 times every 2s and still treats the user as logged in"):
/// while FirebaseAuth has a user but Firestore cannot deliver users/{uid},
/// the last cached principal from [PrefsService.cachedUser] is emitted.
///
/// Bootstrap window ([authBootstrappingProvider]): while `AuthRepository` is
/// still logging in / registering the signed-in email, the provider stays in
/// its loading state instead of surfacing an intermediate snapshot (doc not
/// yet written → null, blocked account → inactive principal). The router
/// treats "loading" as "wait", so the auth page — and its error banner — stays
/// mounted until the repository settles the session; the provider rebuilds
/// (and subscribes to users/{uid}) when the marker resets.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final auth = ref.watch(authStateProvider);
  final repo = ref.watch(authRepositoryProvider);
  final prefs = ref.watch(prefsServiceProvider);
  final bootstrapping = ref.watch(authBootstrappingProvider);

  return auth.when(
    loading: () => _pending(ref),
    error: (_, _) => Stream<UserModel?>.value(null),
    data: (user) {
      if (user == null) return Stream<UserModel?>.value(null);
      final email = (user.email ?? '').trim().toLowerCase();
      if (bootstrapping != null && bootstrapping == email) return _pending(ref);
      return _watchWithOfflineFallback(repo, prefs, user.uid);
    },
  );
});

/// Convenience: the signed-in user's uid (null when signed out / loading).
final currentUidProvider = Provider<String?>(
  (ref) => ref.watch(authStateProvider).valueOrNull?.uid,
);

/// A stream that never emits: keeps the provider in its loading state until
/// it is rebuilt (FirebaseAuth settles / bootstrap marker resets).
Stream<UserModel?> _pending(Ref ref) {
  final pending = StreamController<UserModel?>();
  ref.onDispose(pending.close);
  return pending.stream;
}

const _maxRetries = 3;
const _retryDelay = Duration(seconds: 2);

Stream<UserModel?> _watchWithOfflineFallback(
  AuthRepository repo,
  PrefsService prefs,
  String uid,
) async* {
  var attempt = 0;
  while (true) {
    try {
      await for (final snap in repo.watchPrincipal(uid)) {
        attempt = 0;
        final user = snap.user;
        if (user != null) {
          yield user;
          continue;
        }
        if (snap.fromCache) {
          // Cache-only "missing" (offline / cold cache after reinstall): the
          // document is unknown, not deleted. Keep the cached principal of
          // the same uid if we have one, otherwise wait for the server.
          final cached = _cachedUser(prefs, uid);
          if (cached != null) yield cached;
          continue;
        }
        // Server-confirmed missing document → account deleted
        // (requireActivePrincipal 401; app.dart signs out + snackbar).
        yield null;
      }
      return;
    } catch (e) {
      final cached = _cachedUser(prefs, uid);
      if (cached != null) yield cached;
      attempt++;
      if (attempt > _maxRetries) {
        if (cached == null) rethrow;
        return; // keep the cached session, stop hammering Firestore
      }
      await Future<void>.delayed(_retryDelay);
    }
  }
}

UserModel? _cachedUser(PrefsService prefs, String uid) {
  final raw = prefs.cachedUser;
  if (raw == null) return null;
  final cached = UserModel.fromJson(raw);
  return cached.uid == uid ? cached : null;
}
