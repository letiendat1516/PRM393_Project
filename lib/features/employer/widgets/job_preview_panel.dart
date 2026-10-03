import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/job_list_item.dart';
import '../../../shared/widgets/ui_primitives.dart';

/// Live preview of the job as candidates will see it (JobListItem) plus a
/// summary of the fields that are not visible on the card.
class JobPreviewPanel extends StatelessWidget {
  const JobPreviewPanel({
    super.key,
    required this.job,
    required this.requireApproval,
    required this.editing,
  });

  final JobModel job;
  final bool requireApproval;
  final bool editing;

  @override
  Widget build(BuildContext context) {
    final desc = job.description;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text('Xem trước',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink)),
            ),
            if (!editing) JobStatusBadge(status: job.status, isApproved: job.isApproved),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          editing
              ? 'Thay đổi sẽ áp dụng ngay cho tin hiện tại; trạng thái duyệt được giữ nguyên.'
              : requireApproval
                  ? 'Tin tuyển dụng mới sẽ ở trạng thái chờ duyệt trước khi được hiển thị công khai.'
                  : 'Tin tuyển dụng sẽ được hiển thị công khai ngay sau khi đăng.',
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.5),
        ),
        const SizedBox(height: 12),
        AbsorbPointer(child: JobListItem(job: job, compact: true)),
        const SizedBox(height: 12),
        AppCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Ngành nghề', job.categoryName ?? 'Chưa chọn'),
              _row('Hình thức', '${job.workMode.label} · ${job.jobType.label}'),
              _row('Kinh nghiệm', job.experienceLevel.label),
              _row('Số lượng tuyển', '${job.positionsAvailable}'),
              _row('Hạn nộp hồ sơ',
                  job.applicationDeadline == null ? 'Mặc định theo hệ thống' : Formatters.deadlineFull(job.applicationDeadline)),
              _row('Kỹ năng', job.tags.isEmpty ? 'Chưa có' : job.tags.join(', ')),
              if (desc.thoiGianLamViec.isNotEmpty) _row('Thời gian làm việc', desc.thoiGianLamViec),
              _row('Bằng cấp', desc.yeuCauBangCap),
              _row('Mô tả', '${desc.moTaCongViec.length} ý · Yêu cầu ${desc.yeuCauUngVien.length} ý · Quyền lợi ${desc.quyenLoi.length} ý'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 120,
              child: Text(k, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
            ),
            Expanded(
              child: Text(v,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.ink, fontWeight: FontWeight.w500, height: 1.4)),
            ),
          ],
        ),
      );
}
