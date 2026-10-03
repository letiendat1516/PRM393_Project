import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/application_status_badge.dart';

/// EmployerJobsPage labels (verbatim from the web page helpers).
class EmployerJobLabels {
  const EmployerJobLabels._();

  static String workMode(WorkMode m) => switch (m) {
        WorkMode.onsite => 'Làm tại văn phòng',
        WorkMode.remote => 'Làm từ xa',
        WorkMode.hybrid => 'Kết hợp',
      };

  static String jobType(JobType t) => switch (t) {
        JobType.fullTime => 'Toàn thời gian',
        JobType.partTime => 'Bán thời gian',
        JobType.contract => 'Hợp đồng',
        JobType.internship => 'Thực tập',
      };

  static String status(JobModel j) {
    if (j.isPendingReview) return 'Chờ duyệt';
    if (j.isPublic) return 'Đang hiển thị';
    if (j.isRejected) return 'Bị từ chối';
    if (j.status == JobStatus.closed && j.isApproved) return 'Đã đóng';
    return j.status.label;
  }

  static String approval(JobModel j) {
    if (j.isApproved) return 'Đã duyệt';
    if (j.isRejected) return 'Không được duyệt';
    return 'Chờ duyệt';
  }

  static Color approvalColor(JobModel j) {
    if (j.isApproved) return AppColors.green600;
    if (j.isRejected) return AppColors.red600;
    return AppColors.amber700;
  }

  /// "Mức lương: {min} - {max} {currency}" | "Thỏa thuận".
  static String salary(JobModel j) {
    final min = j.salaryMin;
    final max = j.salaryMax;
    if (j.isSalaryNegotiable || ((min ?? 0) == 0 && (max ?? 0) == 0)) return 'Thỏa thuận';
    return '${Formatters.number(min ?? 0)} - ${Formatters.number(max ?? 0)} ${j.salaryCurrency}';
  }
}

/// One row of the "Tin tuyển dụng của tôi" list: info block + action cluster
/// (wraps below the info on narrow widths).
class EmployerJobCard extends StatelessWidget {
  const EmployerJobCard({
    super.key,
    required this.job,
    required this.busy,
    required this.onViewApplicants,
    required this.onEdit,
    required this.onClose,
    required this.onReopen,
    required this.onDelete,
  });

  final JobModel job;
  final bool busy;
  final VoidCallback onViewApplicants;
  final VoidCallback onEdit;
  final VoidCallback onClose;
  final VoidCallback onReopen;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final info = _info();
    final actions = _actions(context);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: wide
          ? Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: info),
                const SizedBox(width: 24),
                ConstrainedBox(constraints: const BoxConstraints(maxWidth: 360), child: actions),
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 16), actions],
            ),
    );
  }

  Widget _info() {
    const meta = TextStyle(fontSize: 13, color: AppColors.inkMuted, height: 1.5);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 6,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              job.jobTitle,
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            JobStatusBadge(status: job.status, isApproved: job.isApproved),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${(job.location ?? '').isEmpty ? 'Chưa cập nhật địa điểm' : job.location} • '
          '${EmployerJobLabels.workMode(job.workMode)} • ${EmployerJobLabels.jobType(job.jobType)}',
          style: meta,
        ),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            style: const TextStyle(fontSize: 13, color: AppColors.ink, height: 1.5),
            children: [
              const TextSpan(text: 'Trạng thái: '),
              TextSpan(
                text: EmployerJobLabels.status(job),
                style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary),
              ),
              const TextSpan(text: ' | Duyệt: '),
              TextSpan(
                text: EmployerJobLabels.approval(job),
                style: TextStyle(fontWeight: FontWeight.w600, color: EmployerJobLabels.approvalColor(job)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Text('Mức lương: ${EmployerJobLabels.salary(job)}', style: meta),
        const SizedBox(height: 8),
        Wrap(
          spacing: 16,
          runSpacing: 4,
          children: [
            _iconMeta(Icons.people_outline, '${job.applicationsCount} hồ sơ ứng tuyển'),
            _iconMeta(Icons.event_outlined, 'Hạn nộp: ${Formatters.deadlineFull(job.applicationDeadline)}'),
            if (job.categoryName != null) _iconMeta(Icons.category_outlined, job.categoryName!),
          ],
        ),
      ],
    );
  }

  Widget _iconMeta(IconData icon, String text) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.inkMuted),
          const SizedBox(width: 4),
          Text(text, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
      );

  Widget _actions(BuildContext context) {
    final canClose = job.isPublic;
    final canReopen = job.status == JobStatus.closed && job.isApproved;
    final btnStyle = OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      minimumSize: const Size(0, 40),
      textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.lg)),
    );
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      alignment: WrapAlignment.end,
      children: [
        OutlinedButton.icon(
          onPressed: busy ? null : onViewApplicants,
          style: btnStyle.copyWith(
            foregroundColor: const WidgetStatePropertyAll(AppColors.primary),
            side: const WidgetStatePropertyAll(BorderSide(color: AppColors.primary100)),
            backgroundColor: const WidgetStatePropertyAll(AppColors.primary50),
          ),
          icon: const Icon(Icons.people_outline, size: 16),
          label: const Text('Xem ứng viên'),
        ),
        OutlinedButton.icon(
          onPressed: busy ? null : onEdit,
          style: btnStyle,
          icon: const Icon(Icons.edit_outlined, size: 16),
          label: const Text('Sửa'),
        ),
        if (canClose)
          OutlinedButton(
            onPressed: busy ? null : onClose,
            style: btnStyle,
            child: const Text('Đóng tin'),
          ),
        if (canReopen)
          OutlinedButton(
            onPressed: busy ? null : onReopen,
            style: btnStyle.copyWith(
              foregroundColor: const WidgetStatePropertyAll(AppColors.emerald700),
              side: const WidgetStatePropertyAll(BorderSide(color: AppColors.emerald100)),
              backgroundColor: const WidgetStatePropertyAll(AppColors.green50),
            ),
            child: const Text('Mở tin'),
          ),
        OutlinedButton(
          onPressed: busy ? null : onDelete,
          style: btnStyle.copyWith(
            foregroundColor: const WidgetStatePropertyAll(AppColors.red600),
            side: const WidgetStatePropertyAll(BorderSide(color: AppColors.red100)),
          ),
          child: busy
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.red600),
                )
              : const Text('Xoá'),
        ),
      ],
    );
  }
}
