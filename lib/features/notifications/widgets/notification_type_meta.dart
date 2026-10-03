import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../settings/widgets/adaptive_colors.dart';

/// Icon / label / tint per [NotificationType] (shared by the Notification
/// Center list and the per-type toggles in Settings).
extension NotificationTypeMeta on NotificationType {
  String get label => switch (this) {
        NotificationType.applicationStatus => 'Trạng thái hồ sơ',
        NotificationType.newApplication => 'Ứng viên mới',
        NotificationType.jobApproved => 'Duyệt tin',
        NotificationType.jobRejected => 'Tin bị từ chối',
        NotificationType.employerVerified => 'Xác minh nhà tuyển dụng',
        NotificationType.system => 'Hệ thống',
      };

  IconData get icon => switch (this) {
        NotificationType.applicationStatus => Icons.assignment_turned_in_outlined,
        NotificationType.newApplication => Icons.person_add_alt_outlined,
        NotificationType.jobApproved => Icons.check_circle_outline,
        NotificationType.jobRejected => Icons.cancel_outlined,
        NotificationType.employerVerified => Icons.verified_outlined,
        NotificationType.system => Icons.info_outline,
      };

  /// (background, foreground) tint pair — light-mode Tailwind tokens.
  (Color, Color) get tint => switch (this) {
        NotificationType.applicationStatus => (AppColors.blue50, AppColors.blue600),
        NotificationType.newApplication => (AppColors.violet50, AppColors.violet600),
        NotificationType.jobApproved => (AppColors.emerald50, AppColors.emerald600),
        NotificationType.jobRejected => (AppColors.red50, AppColors.red600),
        NotificationType.employerVerified => (AppColors.teal50, AppColors.teal600),
        NotificationType.system => (AppColors.slate100, AppColors.inkSoft),
      };

  /// [tint] adapted to the active theme: in dark mode the pastel `*-50`
  /// background becomes a translucent wash of the accent and the accent is
  /// lightened so it stays legible on dark surfaces.
  (Color, Color) tintOf(BuildContext context) {
    final (bg, fg) = tint;
    if (Theme.of(context).brightness != Brightness.dark) return (bg, fg);
    if (this == NotificationType.system) {
      return (context.chipColor, context.inkSoftColor);
    }
    return (
      fg.withValues(alpha: 0.18),
      Color.lerp(fg, Colors.white, 0.35) ?? fg,
    );
  }

  /// Key of the per-type push toggle (prefs.notificationTypes) that governs
  /// this type. JOB_REJECTED shares the "Duyệt tin" toggle; EMPLOYER_VERIFIED
  /// is a system message.
  String get toggleKey => switch (this) {
        NotificationType.applicationStatus => NotificationToggle.applicationStatus,
        NotificationType.newApplication => NotificationToggle.newApplication,
        NotificationType.jobApproved => NotificationToggle.jobApproved,
        NotificationType.jobRejected => NotificationToggle.jobApproved,
        NotificationType.employerVerified => NotificationToggle.system,
        NotificationType.system => NotificationToggle.system,
      };
}

/// Per-type toggles shown in Settings → Thông báo.
///
/// [key] is the wire value of the primary [NotificationType] the toggle
/// represents; [wireKeys] lists every wire value the toggle governs (the
/// "Duyệt tin" toggle covers JOB_APPROVED + JOB_REJECTED, "Hệ thống" covers
/// SYSTEM + EMPLOYER_VERIFIED). Settings persists ALL of them in
/// `PrefsService.notificationTypes`, because the delivery side
/// (`FcmService._showForeground`, `NotificationNavigator`) looks a payload up
/// by its own wire value via `prefs.isNotificationTypeEnabled(enumToWire(type))`.
class NotificationToggle {
  const NotificationToggle._(this.types, this.label, this.subtitle, this.icon);

  /// Notification types governed by this toggle (first = primary).
  final List<NotificationType> types;
  final String label;
  final String subtitle;
  final IconData icon;

  /// Wire value of the primary type (stable prefs key).
  String get key => enumToWire(types.first);

  /// Every wire value this toggle switches on/off.
  List<String> get wireKeys => [for (final t in types) enumToWire(t)];

  static const applicationStatus = 'APPLICATION_STATUS';
  static const newApplication = 'NEW_APPLICATION';
  static const jobApproved = 'JOB_APPROVED';
  static const system = 'SYSTEM';

  static const List<NotificationToggle> all = [
    NotificationToggle._(
      [NotificationType.applicationStatus],
      'Trạng thái hồ sơ',
      'Khi hồ sơ ứng tuyển của bạn được cập nhật trạng thái.',
      Icons.assignment_turned_in_outlined,
    ),
    NotificationToggle._(
      [NotificationType.newApplication],
      'Ứng viên mới',
      'Khi có ứng viên nộp hồ sơ vào tin tuyển dụng của bạn.',
      Icons.person_add_alt_outlined,
    ),
    NotificationToggle._(
      [NotificationType.jobApproved, NotificationType.jobRejected],
      'Duyệt tin',
      'Khi tin tuyển dụng được duyệt hoặc bị từ chối.',
      Icons.fact_check_outlined,
    ),
    NotificationToggle._(
      [NotificationType.system, NotificationType.employerVerified],
      'Hệ thống',
      'Thông báo chung từ JobHub và xác minh nhà tuyển dụng.',
      Icons.info_outline,
    ),
  ];
}
