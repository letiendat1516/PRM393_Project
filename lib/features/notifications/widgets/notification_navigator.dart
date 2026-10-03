import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_router.dart';
import '../../../core/router/routes.dart';
import '../../../core/services/fcm_service.dart';
import '../../../core/utils/enums.dart';
import '../../../shared/models/notification_model.dart';
import '../data/notifications_repository.dart';
import '../viewmodels/notifications_providers.dart';

/// Resolves the in-app route for a notification `type` + `data` payload
/// (both the Firestore document and the FCM data message use the same keys).
///
/// APPLICATION_STATUS → /applications/:applicationId
/// NEW_APPLICATION    → /employer/applications/:applicationId
/// JOB_APPROVED / JOB_REJECTED → /employer/jobs
/// EMPLOYER_VERIFIED  → /employer/company-profile
/// anything else      → /notifications
String notificationRouteFor(NotificationType type, Map<String, dynamic> data) {
  String? id(String key) {
    final v = data[key];
    if (v == null) return null;
    final s = v.toString().trim();
    return s.isEmpty ? null : s;
  }

  switch (type) {
    case NotificationType.applicationStatus:
      final appId = id('applicationId');
      return appId == null
          ? AppRoutes.myApplications
          : AppRoutes.applicationDetailOf(appId);
    case NotificationType.newApplication:
      final appId = id('applicationId');
      return appId == null
          ? AppRoutes.employerApplications
          : AppRoutes.employerApplicationReviewOf(appId);
    case NotificationType.jobApproved:
    case NotificationType.jobRejected:
      return AppRoutes.employerJobs;
    case NotificationType.employerVerified:
      return AppRoutes.employerCompanyProfile;
    case NotificationType.system:
      return AppRoutes.notifications;
  }
}

/// Handles a tap on a push notification (FCM `data` payload): marks the
/// Firestore document read when `notificationId` is present, then navigates
/// by type. Safe to call with an arbitrary/incomplete payload.
///
/// [router] must be passed when the caller sits above the `Router` widget
/// (MaterialApp.router `builder`), where `GoRouter.of(context)` is unavailable.
Future<void> handleNotificationTap(
  BuildContext context,
  Map<String, dynamic> data, {
  GoRouter? router,
}) async {
  final type = parseNotifType(data['type']?.toString());
  final route = notificationRouteFor(type, data);

  final notificationId = data['notificationId']?.toString();
  if (notificationId != null && notificationId.isNotEmpty) {
    try {
      final container = ProviderScope.containerOf(context, listen: false);
      // Fire-and-forget: navigation must not wait on the write.
      unawaited(
        container.read(notificationsRepositoryProvider).markAsRead(notificationId).catchError((_) {}),
      );
    } catch (_) {
      // No ProviderScope above us (tests) — just navigate.
    }
  }

  if (!context.mounted) return;
  final r = router ?? GoRouter.maybeOf(context);
  if (r == null) return;
  r.go(route);
}

/// Wraps the app (MaterialApp.router `builder`) and routes push-notification
/// taps (cold start, background → foreground, local-notification taps — all
/// funnelled through [FcmService.onNotificationTap]). Also keeps the FCM token
/// registered for the signed-in user (see [fcmTokenRegistrationProvider]) and
/// surfaces newly arrived Firestore notifications as device notifications while
/// the app is in the foreground (no Cloud Functions on the free plan).
class NotificationNavigator extends ConsumerStatefulWidget {
  const NotificationNavigator({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NotificationNavigator> createState() => _NotificationNavigatorState();
}

class _NotificationNavigatorState extends ConsumerState<NotificationNavigator> {
  StreamSubscription<Map<String, dynamic>>? _tapSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _attach());
  }

  void _attach() {
    if (!mounted) return;
    _tapSub = FcmService.instance.onNotificationTap.listen(_onTap);
    // Cold start: the initial message was consumed in main() before any
    // listener existed — FcmService buffered it.
    final pending = FcmService.instance.takePendingTap();
    if (pending != null) _onTap(pending);
  }

  void _onTap(Map<String, dynamic> data) {
    if (!mounted || data.isEmpty) return;
    // Let the first frame / router settle before deep-linking.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(handleNotificationTap(context, data, router: ref.read(routerProvider)));
    });
  }

  /// Foreground delivery: a notification document appeared for the signed-in
  /// user → show a local notification (mobile) honouring the Settings toggles.
  void _onNotifications(AsyncValue<List<NotificationModel>>? prev, AsyncValue<List<NotificationModel>> next) {
    // Nothing is "new" on the first emission, nor right after a
    // re-subscription (cold start with a signed-in user, sign-in, account
    // switch): the provider passes through AsyncLoading(copyWithPrevious) and
    // the following data event carries the user's whole backlog.
    if (prev == null || prev.isLoading || next.isLoading) return;
    final before = prev.valueOrNull;
    final after = next.valueOrNull;
    if (before == null || after == null) return;
    final seen = before.map((n) => n.notificationId).toSet();
    final prefs = ref.read(prefsServiceProvider);
    if (!prefs.notificationsEnabled) return;
    for (final n in after) {
      if (seen.contains(n.notificationId) || n.isRead) continue;
      if (!prefs.isNotificationTypeEnabled(enumToWire(n.type))) continue;
      unawaited(FcmService.instance.showLocal(
        title: n.title,
        body: n.message,
        data: {
          'type': enumToWire(n.type),
          'notificationId': n.notificationId,
          ...n.data.map((k, v) => MapEntry(k, v?.toString() ?? '')),
        },
      ));
    }
  }

  @override
  void dispose() {
    _tapSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Keeps users/{uid}.fcmTokens in sync with auth + the notifications toggle.
    ref.watch(fcmTokenRegistrationProvider);
    ref.listen(notificationsStreamProvider, _onNotifications);
    return widget.child;
  }
}
