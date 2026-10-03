import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../shared/models/catalog_models.dart';
import '../shared/models/recommendation_models.dart';
import 'config/app_config.dart';
import 'services/ai/gemini_service.dart';
import 'services/ai_session_store.dart';
import 'services/auth_service.dart';
import 'services/firestore_refs.dart';
import 'services/prefs_service.dart';
import 'services/storage_service.dart';
import 'services/system_config_repository.dart';

// ── Firebase singletons (override in tests) ───────────────────────────
final firebaseAuthProvider = Provider<FirebaseAuth>((_) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((_) => FirebaseFirestore.instance);
final storageProvider = Provider<FirebaseStorage>((_) => FirebaseStorage.instance);

// ── Local persistence ─────────────────────────────────────────────────
final prefsServiceProvider = Provider<PrefsService>((_) => PrefsService.instance);
final aiSessionStoreProvider =
    Provider<AiSessionStore>((ref) => AiSessionStore(ref.watch(prefsServiceProvider).prefs));

// ── Core services ─────────────────────────────────────────────────────
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService(ref.watch(firebaseAuthProvider), ref.watch(firestoreProvider));
});

final firestoreRefsProvider =
    Provider<FirestoreRefs>((ref) => FirestoreRefs(ref.watch(firestoreProvider)));

final storageServiceProvider =
    Provider<StorageService>((ref) => StorageService(ref.watch(storageProvider)));

final systemConfigRepositoryProvider = Provider<SystemConfigRepository>(
    (ref) => SystemConfigRepository(ref.watch(firestoreRefsProvider)));

/// Live system configurations (any signed-in user may read).
final systemConfigsProvider = StreamProvider<List<SystemConfig>>(
    (ref) => ref.watch(systemConfigRepositoryProvider).watchAll());

/// Writes every AI call to aiMatchingLogs (aiLogger.js parity).
final aiLogSinkProvider = Provider<AiLogSink>((ref) {
  final refs = ref.watch(firestoreRefsProvider);
  return (AiMatchingLog log) => refs.aiMatchingLogs().doc(log.logId).set(log);
});

final geminiServiceProvider = Provider<GeminiService>((ref) {
  final configs = ref.watch(systemConfigRepositoryProvider);
  return GeminiService(
    resolveApiKey: () async {
      if (AppConfig.geminiApiKey.isNotEmpty) return AppConfig.geminiApiKey;
      return configs.getString(SystemConfig.keyGeminiApiKey);
    },
    logSink: ref.watch(aiLogSinkProvider),
  );
});

// ── Auth state ────────────────────────────────────────────────────────
final authStateProvider =
    StreamProvider<User?>((ref) => ref.watch(authServiceProvider).authStateChanges());
