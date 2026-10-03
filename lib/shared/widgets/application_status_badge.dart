import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/enums.dart';

/// components/application/ApplicationStatusBadge.jsx — SUBMITTED blue,
/// UNDER_REVIEW amber, ACCEPTED emerald, REJECTED red (others fall back).
class ApplicationStatusBadge extends StatelessWidget {
  const ApplicationStatusBadge({super.key, required this.status, this.compact = false});
  final ApplicationStatus status;
  final bool compact;

  static (Color bg, Color fg, String label) styleOf(ApplicationStatus s) => switch (s) {
        ApplicationStatus.submitted => (AppColors.blue50, AppColors.blue700, 'Đã nộp'),
        ApplicationStatus.underReview => (AppColors.amber50, AppColors.amber700, 'Đang xem xét'),
        ApplicationStatus.accepted => (AppColors.emerald50, AppColors.emerald700, 'Đã chấp nhận'),
        ApplicationStatus.rejected => (AppColors.red50, AppColors.red700, 'Đã từ chối'),
        ApplicationStatus.interview => (AppColors.violet50, AppColors.violet600, 'Phỏng vấn'),
        ApplicationStatus.offer => (AppColors.teal50, AppColors.teal600, 'Đã có offer'),
        ApplicationStatus.withdrawn => (AppColors.slate100, AppColors.inkMuted, 'Đã rút'),
      };

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = styleOf(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 2 : 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: fg.withValues(alpha: 0.2)),
      ),
      child: Text(
        label,
        style: TextStyle(color: fg, fontSize: compact ? 11 : 12, fontWeight: FontWeight.w600),
      ),
    );
  }
}

/// EmployerJobsPage status badges (job_status + approval).
class JobStatusBadge extends StatelessWidget {
  const JobStatusBadge({super.key, required this.status, required this.isApproved});
  final JobStatus status;
  final bool isApproved;

  @override
  Widget build(BuildContext context) {
    final (bg, fg, label) = _style();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }

  (Color, Color, String) _style() {
    if (status == JobStatus.draft && !isApproved) {
      return (AppColors.amber50, AppColors.amber700, 'Chờ duyệt');
    }
    if (status == JobStatus.closed && !isApproved) {
      return (AppColors.red50, AppColors.red700, 'Bị từ chối');
    }
    return switch (status) {
      JobStatus.open => (AppColors.emerald50, AppColors.emerald700, 'Đang tuyển'),
      JobStatus.closed => (AppColors.slate100, AppColors.inkMuted, 'Đã đóng'),
      JobStatus.paused => (AppColors.amber50, AppColors.amber700, 'Tạm dừng'),
      JobStatus.draft => (AppColors.slate100, AppColors.inkSoft, 'Nháp'),
      JobStatus.expired => (AppColors.red50, AppColors.red700, 'Hết hạn'),
    };
  }
}

/// Generic active/blocked, verified/pending pills (admin tables).
class BoolBadge extends StatelessWidget {
  const BoolBadge({
    super.key,
    required this.value,
    required this.trueLabel,
    required this.falseLabel,
    this.trueTone = const (AppColors.emerald50, AppColors.emerald700),
    this.falseTone = const (AppColors.red50, AppColors.red700),
  });
  final bool value;
  final String trueLabel;
  final String falseLabel;
  final (Color, Color) trueTone;
  final (Color, Color) falseTone;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = value ? trueTone : falseTone;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
      child: Text(value ? trueLabel : falseLabel,
          style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
