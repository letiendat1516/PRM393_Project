import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../config/app_config.dart';
import '../utils/failure.dart';
import 'fcm_service.dart';

/// Thin wrapper over FirebaseAuth + users/{uid} bootstrap (AuthService.js).
class AuthService {
  AuthService(this._auth, this._firestore);

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  Stream<User?> authStateChanges() => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  /// "Ghi nhớ đăng nhập": LOCAL persistence vs SESSION (web only; mobile is
  /// always persistent).
  Future<void> setRememberMe(bool remember) async {
    if (!kIsWeb) return;
    try {
      await _auth.setPersistence(remember ? Persistence.LOCAL : Persistence.SESSION);
    } catch (_) {}
  }

  Future<UserCredential> signIn({required String email, required String password}) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
          email: email.trim().toLowerCase(), password: password);
      // AuthService.login → 403 when is_active = false
      final snap = await _firestore.collection('users').doc(cred.user!.uid).get();
      if (snap.exists && snap.data()?['isActive'] == false) {
        await _auth.signOut();
        throw const Failure('Tài khoản đã bị vô hiệu hóa.', status: 403, code: 'ACCOUNT_DISABLED');
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Failure.from(e);
    }
  }

  Future<UserCredential> register({
    required String email,
    required String password,
    required String fullName,
    required String role, // job_seeker | employer (admins cannot self-register)
    Map<String, dynamic> extra = const {},
  }) async {
    if (role == 'admin') {
      throw const Failure.forbidden('Không thể tự đăng ký tài khoản quản trị.');
    }
    final normalizedEmail = email.trim().toLowerCase();
    // Course-demo convenience: whitelisted emails become admins (see AppConfig.adminEmails).
    final effectiveRole = AppConfig.adminEmails.contains(normalizedEmail) ? 'admin' : role;
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
          email: normalizedEmail, password: password);
      final uid = cred.user!.uid;
      await cred.user!.updateDisplayName(fullName);
      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'email': normalizedEmail,
        'fullName': fullName,
        'role': effectiveRole,
        'isActive': true,
        'isVerified': false,
        'fcmTokens': <String>[],
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        ...extra,
      });
      return cred;
    } on FirebaseAuthException catch (e) {
      throw Failure.from(e);
    }
  }

  /// Google OAuth sign-in via native Google Play Services (Android/iOS) or
  /// `signInWithPopup` on web. First-time users get a `users/{uid}` doc
  /// bootstrapped as job_seeker (or admin if their email is in
  /// [AppConfig.adminEmails]); returning users reuse their row.
  ///
  /// Mobile uses [GoogleSignIn] + [GoogleAuthProvider.credential] rather
  /// than FirebaseAuth's `signInWithProvider`, because the latter wraps
  /// the OAuth flow in a Chrome Custom Tab whose storage is partitioned
  /// away from `jobhub-prm393-g3.firebaseapp.com/__/auth/handler` on
  /// recent Chrome builds, so the handler fails with "Unable to process
  /// request due to missing initial state" after the user approves.
  Future<UserCredential> signInWithGoogle() async {
    try {
      final UserCredential cred;
      if (kIsWeb) {
        final provider = GoogleAuthProvider()
          ..addScope('email')
          ..addScope('profile');
        cred = await _auth.signInWithPopup(provider);
      } else {
        final googleUser = await GoogleSignIn(
          scopes: const ['email', 'profile'],
        ).signIn();
        if (googleUser == null) {
          throw const Failure('Đã huỷ đăng nhập.',
              status: 499, code: 'GOOGLE_CANCELLED');
        }
        final auth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          idToken: auth.idToken,
          accessToken: auth.accessToken,
        );
        cred = await _auth.signInWithCredential(credential);
      }
      final user = cred.user;
      if (user == null) {
        throw const Failure('Đăng nhập Google thất bại.',
            status: 500, code: 'GOOGLE_NO_USER');
      }
      final uid = user.uid;
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) {
        final email = (user.email ?? '').toLowerCase();
        final role = AppConfig.adminEmails.contains(email)
            ? 'admin'
            : 'job_seeker';
        await _firestore.collection('users').doc(uid).set({
          'uid': uid,
          'email': email,
          'fullName': user.displayName ??
              (email.isEmpty ? 'Người dùng' : email.split('@').first),
          if (user.photoURL != null) 'photoUrl': user.photoURL,
          'role': role,
          'isActive': true,
          'isVerified': user.emailVerified,
          'fcmTokens': <String>[],
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else if (doc.data()?['isActive'] == false) {
        await _auth.signOut();
        throw const Failure('Tài khoản đã bị vô hiệu hóa.',
            status: 403, code: 'ACCOUNT_DISABLED');
      }
      return cred;
    } on FirebaseAuthException catch (e) {
      if (e.code == 'operation-not-allowed') {
        throw const Failure(
          'Google chưa được bật cho dự án. Admin vào Firebase Console → Authentication → Sign-in method → bật Google.',
          status: 500,
          code: 'GOOGLE_PROVIDER_DISABLED',
        );
      }
      if (e.code == 'web-context-cancelled' ||
          e.code == 'cancelled' ||
          e.code == 'canceled' ||
          e.code == 'popup-closed-by-user') {
        throw const Failure('Đã huỷ đăng nhập.',
            status: 499, code: 'GOOGLE_CANCELLED');
      }
      throw Failure.from(e);
    }
  }

  Future<void> sendPasswordReset(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim().toLowerCase());
    } on FirebaseAuthException catch (e) {
      throw Failure.from(e);
    }
  }

  /// UC26 Change Password: re-authenticate then update.
  Future<void> changePassword({required String currentPassword, required String newPassword}) async {
    final user = _auth.currentUser;
    if (user == null || user.email == null) throw const Failure.unauthorized();
    try {
      final cred = EmailAuthProvider.credential(email: user.email!, password: currentPassword);
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPassword);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw const Failure('Mật khẩu hiện tại không đúng.', status: 400, code: 'WRONG_PASSWORD');
      }
      throw Failure.from(e);
    }
  }

  /// Sign out — first drops this device's FCM token from users/{uid}.fcmTokens
  /// so the device stops receiving pushes addressed to the previous account,
  /// and asks the Google plugin to clear its cached account so the next
  /// `signInWithGoogle` shows the account picker again instead of silently
  /// reusing the last choice.
  Future<void> signOut() async {
    if (_auth.currentUser != null) {
      try {
        await FcmService.instance.removeTokenForCurrentUser();
      } catch (_) {}
    }
    if (!kIsWeb) {
      try {
        await GoogleSignIn().signOut();
      } catch (_) {}
    }
    await _auth.signOut();
  }
}
