import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/services/auth_service.dart';
import '../../../core/services/firestore_refs.dart';
import '../../../core/services/prefs_service.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/jobseeker_profile_model.dart';
import '../../../shared/models/user_model.dart';

/// users/{uid} snapshot + Firestore cache metadata. `fromCache` lets
/// `currentUserProvider` tell "document unknown while offline / cold cache"
/// (keep the cached principal, wait for the server) from "document deleted on
/// the server" (requireActivePrincipal → 401 'Tài khoản không còn tồn tại.').
typedef PrincipalSnapshot = ({UserModel? user, bool fromCache});

/// Normalised email of the account whose sign-in / registration is currently
/// in flight (null when idle). Set by [AuthRepository] around `login()` and
/// the two `register*()` flows.
///
/// Why: FirebaseAuth emits `authStateChanges` as soon as
/// `signInWithEmailAndPassword` / `createUserWithEmailAndPassword` resolves —
/// BEFORE the repository has checked (login) or written (register)
/// users/{uid}. Without this marker `currentUserProvider` would surface an
/// intermediate principal (missing doc → null, blocked account → inactive
/// user) and the router would leave /dang-nhap|/dang-ky mid-flight, disposing
/// the autoDispose form view-model together with its error banner (and the
/// admin-whitelist redirect). `currentUserProvider` watches this provider and
/// stays in its loading state for that account until the flow settles — the
/// web's AuthContext likewise only sets `user` after the API call returns.
final authBootstrappingProvider = StateProvider<String?>((_) => null);

/// Auth module (backend/src/services/AuthService.js + frontend AuthContext):
/// FirebaseAuth session + users/{uid} principal + role profile bootstrap.
///
/// Only repositories touch Firestore; every error is normalised to [Failure].
class AuthRepository {
  AuthRepository(
    this._auth,
    this._refs,
    this._prefs, {
    this.onBootstrapping,
  });

  final AuthService _auth;
  final FirestoreRefs _refs;
  final PrefsService _prefs;

  /// Publishes the in-flight account email (see [authBootstrappingProvider]).
  final void Function(String? email)? onBootstrapping;

  void _setBootstrapping(String? email) => onBootstrapping?.call(email);

  // ── Login ─────────────────────────────────────────────────────────────

  /// `login({ email, password, rememberMe })`:
  /// * rememberMe → persistence LOCAL (7d token) vs SESSION (15m token);
  /// * 401 'Email hoặc mật khẩu không đúng.' (generic) / 403 blocked are
  ///   raised by [AuthService.signIn];
  /// * remembers the email locally for the next visit.
  Future<UserModel> login({
    required String email,
    required String password,
    required bool rememberMe,
  }) async {
    final normalized = email.trim().toLowerCase();
    _setBootstrapping(normalized);
    try {
      await _auth.setRememberMe(rememberMe);
      await _prefs.setRememberMe(rememberMe);
      final cred = await _auth.signIn(email: normalized, password: password);
      final uid = cred.user!.uid;
      final user = await _fetchPrincipal(uid);
      await _prefs.setRememberEmail(rememberMe ? normalized : null);
      await _cacheUser(user);
      return user;
    } catch (e) {
      throw Failure.from(e);
    } finally {
      _setBootstrapping(null);
    }
  }

  // ── Register ──────────────────────────────────────────────────────────

  /// job_seeker payload `{ role:'job_seeker', email, password, fullName }`
  /// → users/{uid} + jobSeekerProfiles/{uid} (fullName, email). Logs in
  /// immediately (register returns `{ user, accessToken }`).
  ///
  /// Order: users/{uid} is written by [AuthService.register]; the principal is
  /// read back FIRST and the role profile is created only for a real
  /// job_seeker — an email promoted to admin by the course-demo whitelist
  /// (AppConfig.adminEmails) gets no seeker profile, like the backend where
  /// admins are never self-registered.
  Future<UserModel> registerJobSeeker({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final name = fullName.trim();
    final preexistingUid = _auth.currentUser?.uid;
    _setBootstrapping(normalized);
    try {
      await _auth.setRememberMe(_prefs.rememberMe);
      final cred = await _auth.register(
        email: normalized,
        password: password,
        fullName: name,
        role: userRoleToWire(UserRole.jobSeeker),
      );
      final uid = cred.user!.uid;
      final user = await _fetchPrincipal(uid);
      if (user.role == UserRole.jobSeeker) {
        await _refs.jobSeekerProfiles().doc(uid).set(
              JobSeekerProfile(uid: uid, fullName: name, email: normalized),
            );
      }
      await _cacheUser(user);
      return user;
    } catch (e) {
      await _rollbackRegistration(normalized, preexistingUid: preexistingUid);
      throw Failure.from(e);
    } finally {
      _setBootstrapping(null);
    }
  }

  /// employer payload `{ role:'employer', email, password, contactName,
  /// gender, phone, companyName, city }` → users/{uid} (+phone) and
  /// employerProfiles/{uid} (company_name, contact_name, gender, phone, city).
  /// Same ordering / admin rule as [registerJobSeeker].
  Future<UserModel> registerEmployer({
    required String contactName,
    required Gender gender,
    required String phone,
    required String companyName,
    required String city,
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    final contact = contactName.trim();
    final tel = phone.trim();
    final preexistingUid = _auth.currentUser?.uid;
    _setBootstrapping(normalized);
    try {
      await _auth.setRememberMe(_prefs.rememberMe);
      final cred = await _auth.register(
        email: normalized,
        password: password,
        fullName: contact,
        role: userRoleToWire(UserRole.employer),
        extra: {'phone': tel},
      );
      final uid = cred.user!.uid;
      final user = await _fetchPrincipal(uid);
      if (user.role == UserRole.employer) {
        await _refs.employerProfiles().doc(uid).set(
              EmployerProfile(
                uid: uid,
                companyName: companyName.trim(),
                email: normalized,
                phone: tel,
                contactName: contact,
                gender: gender,
                city: city.trim(),
                isVerified: false,
                isActive: true,
                openPositions: 0,
              ),
            );
      }
      await _cacheUser(user);
      return user;
    } catch (e) {
      await _rollbackRegistration(normalized, preexistingUid: preexistingUid);
      throw Failure.from(e);
    } finally {
      _setBootstrapping(null);
    }
  }

  // ── Password ──────────────────────────────────────────────────────────

  /// Forgot password (mobile-only screen): FirebaseAuth reset mail.
  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordReset(email);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// UC26 change password: re-authenticate then update (8..128 enforced by
  /// the form via `Validators.password`).
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      await _auth.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
    } catch (e) {
      throw Failure.from(e);
    }
  }

  // ── Session ───────────────────────────────────────────────────────────

  Future<void> signOut() async {
    try {
      await _auth.signOut();
      await _prefs.setCachedUser(null);
    } catch (e) {
      throw Failure.from(e);
    }
  }

  /// Live principal (GET /auth/me re-resolved on every request). `null` when
  /// the users/{uid} document does not exist in the snapshot.
  Stream<UserModel?> watchCurrentUser(String uid) =>
      watchPrincipal(uid).map((s) => s.user);

  /// Live principal with cache metadata (see [PrincipalSnapshot]).
  /// `includeMetadataChanges` so the cache → server transition of a missing
  /// document is delivered even when the data itself did not change.
  Stream<PrincipalSnapshot> watchPrincipal(String uid) {
    return _refs
        .users()
        .doc(uid)
        .snapshots(includeMetadataChanges: true)
        .map((s) => (
              user: s.exists ? s.data() : null,
              fromCache: s.metadata.isFromCache,
            ));
  }

  /// One-shot read of users/{uid}.
  Future<UserModel?> fetchUser(String uid) async {
    try {
      final snap = await _refs.users().doc(uid).get();
      return snap.exists ? snap.data() : null;
    } catch (e) {
      throw Failure.from(e);
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Future<UserModel> _fetchPrincipal(String uid) async {
    final user = await fetchUser(uid);
    if (user == null) {
      // requireActivePrincipal: missing row → 401.
      await _auth.signOut();
      throw const Failure.unauthorized('Tài khoản không còn tồn tại.');
    }
    if (!user.isActive) {
      await _auth.signOut();
      throw const Failure(
        'Tài khoản đã bị vô hiệu hóa.',
        status: 403,
        code: 'ACCOUNT_DISABLED',
      );
    }
    return user;
  }

  /// Partial registration (users/{uid} or the role profile write failed
  /// AFTER `createUserWithEmailAndPassword` succeeded) would leave an Auth
  /// account without a usable principal: the next login would end in
  /// 'Tài khoản không còn tồn tại.' and re-registering in 'Email đã được sử
  /// dụng.'. The account is freshly signed in, so `delete()` needs no
  /// re-authentication; if even that fails we at least sign out.
  ///
  /// Only the account created by THIS flow is touched: the signed-in user
  /// must carry the registered email and must not be the session that
  /// existed before the flow started (`preexistingUid`).
  Future<void> _rollbackRegistration(String email, {String? preexistingUid}) async {
    final u = _auth.currentUser;
    if (u == null || u.uid == preexistingUid) return;
    if ((u.email ?? '').trim().toLowerCase() != email) return;
    try {
      await u.delete();
    } catch (_) {
      try {
        await _auth.signOut();
      } catch (_) {}
    }
    try {
      await _prefs.setCachedUser(null);
    } catch (_) {}
  }

  /// Offline start keeps the cached session (AuthContext retry semantics).
  Future<void> _cacheUser(UserModel user) => _prefs.setCachedUser({
        'uid': user.uid,
        'email': user.email,
        'fullName': user.fullName,
        'role': userRoleToWire(user.role),
        'isActive': user.isActive,
        'isVerified': user.isVerified,
      });
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepository(
    ref.watch(authServiceProvider),
    ref.watch(firestoreRefsProvider),
    ref.watch(prefsServiceProvider),
    onBootstrapping: (email) =>
        ref.read(authBootstrappingProvider.notifier).state = email,
  ),
);
