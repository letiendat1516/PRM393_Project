import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/models/notification_model.dart';
import '../../auth/viewmodels/current_user_provider.dart';
import '../../settings/viewmodels/settings_viewmodel.dart';
import '../data/notifications_repository.dart';

/// Live notifications of the signed-in user (newest first, 50 max).
/// Keyed on the auth uid so the navbar badge works before users/{uid} loads.
final notificationsStreamProvider = StreamProvider<List<NotificationModel>>((ref) {
  final auth = ref.watch(authStateProvider);
  final uid = auth.valueOrNull?.uid;
  if (uid == null) return Stream.value(const <NotificationModel>[]);
  return ref.watch(notificationsRepositoryProvider).watchForUser(uid);
});

/// Unread badge count (navbar + filter tab).
final unreadCountProvider = Provider<int>((ref) {
  final list = ref.watch(notificationsStreamProvider).valueOrNull ?? const [];
  return list.where((n) => !n.isRead).length;
});

/// Unread-only toggle on the Notification Center. Separate from the
/// category tabs so the user can combine "chỉ chưa đọc" with any category.
enum NotificationFilter { all, unread }

extension NotificationFilterLabel on NotificationFilter {
  String get label => switch (this) {
        NotificationFilter.all => 'Tất cả',
        NotificationFilter.unread => 'Chưa đọc',
      };
}

final notificationFilterProvider =
    StateProvider.autoDispose<NotificationFilter>((_) => NotificationFilter.all);

/// TopCV-style horizontal category tabs on top of the notification list.
/// Each tab maps to a subset of [NotificationType] (see [matches]).
enum NotificationCategory { all, jobs, applicationStatus, connections, system }

extension NotificationCategoryMeta on NotificationCategory {
  String get label => switch (this) {
        NotificationCategory.all => 'Tất cả',
        NotificationCategory.jobs => 'Việc làm',
        NotificationCategory.applicationStatus => 'Trạng thái CV',
        NotificationCategory.connections => 'Kết nối',
        NotificationCategory.system => 'Hệ thống',
      };

  /// Mirror of the Settings → Loại thông báo buckets so the tab filter
  /// agrees with the per-type toggle a user already configured.
  bool matches(NotificationType type) {
    switch (this) {
      case NotificationCategory.all:
        return true;
      case NotificationCategory.jobs:
        return type == NotificationType.jobApproved ||
            type == NotificationType.jobRejected;
      case NotificationCategory.applicationStatus:
        return type == NotificationType.applicationStatus;
      case NotificationCategory.connections:
        return type == NotificationType.newApplication;
      case NotificationCategory.system:
        return type == NotificationType.system ||
            type == NotificationType.employerVerified;
    }
  }
}

final notificationCategoryProvider =
    StateProvider.autoDispose<NotificationCategory>(
        (_) => NotificationCategory.all);

/// Stream filtered by the active tab + unread flag (keeps loading/error).
final filteredNotificationsProvider =
    Provider.autoDispose<AsyncValue<List<NotificationModel>>>((ref) {
  final filter = ref.watch(notificationFilterProvider);
  final category = ref.watch(notificationCategoryProvider);
  return ref.watch(notificationsStreamProvider).whenData(
        (list) => list.where((n) {
          if (filter == NotificationFilter.unread && n.isRead) return false;
          return category.matches(n.type);
        }).toList(),
      );
});

/// Registers the device FCM token whenever there is a signed-in user AND push
/// notifications are enabled in Settings; removes it when the toggle is off.
/// Must be watched by a long-lived widget (NotificationNavigator does this).
///
/// Keyed on the resolved principal (users/{uid} already exists) rather than
/// the raw auth uid: a `set(merge)` of `fcmTokens` on a not-yet-created users
/// doc would become a create and be denied by firestore.rules, leaving the
/// token unregistered until the next refresh. `select` on the uid keeps the
/// provider from re-running (and re-writing) on every users doc change.
final fcmTokenRegistrationProvider = Provider<void>((ref) {
  final uid = ref.watch(currentUserProvider.select((u) => u.valueOrNull?.uid));
  final enabled = ref.watch(settingsProvider.select((s) => s.notificationsEnabled));
  if (uid == null) return;

  final repo = ref.read(notificationsRepositoryProvider);
  final future = enabled ? repo.registerFcmToken(uid) : repo.unregisterFcmToken(uid);
  unawaited(future.catchError((Object e) {
    // Non-fatal: web without VAPID key, permission denied, offline…
    debugPrint('FCM token sync skipped: ${Failure.from(e).message}');
    return null;
  }));
});

/// Mark-as-read actions with busy/error state for the page.
class NotificationsActionState {
  const NotificationsActionState({this.busy = false, this.error});
  final bool busy;
  final Failure? error;

  NotificationsActionState copyWith({bool? busy, Failure? error, bool clearError = false}) =>
      NotificationsActionState(
        busy: busy ?? this.busy,
        error: clearError ? null : (error ?? this.error),
      );
}

class NotificationsController extends StateNotifier<NotificationsActionState> {
  NotificationsController(this._repo) : super(const NotificationsActionState());
  final NotificationsRepository _repo;

  /// Returns true on success; the error is exposed on [state].
  Future<bool> markAsRead(String notificationId) async {
    try {
      await _repo.markAsRead(notificationId);
      return true;
    } catch (e) {
      state = state.copyWith(error: Failure.from(e));
      return false;
    }
  }

  /// Returns the number of notifications marked read (null on failure).
  Future<int?> markAllAsRead(String uid) async {
    if (state.busy) return null;
    state = state.copyWith(busy: true, clearError: true);
    try {
      final n = await _repo.markAllAsRead(uid);
      state = state.copyWith(busy: false);
      return n;
    } catch (e) {
      state = state.copyWith(busy: false, error: Failure.from(e));
      return null;
    }
  }

  void clearError() => state = state.copyWith(clearError: true);
}

final notificationsControllerProvider =
    StateNotifierProvider.autoDispose<NotificationsController, NotificationsActionState>(
  (ref) => NotificationsController(ref.watch(notificationsRepositoryProvider)),
);
