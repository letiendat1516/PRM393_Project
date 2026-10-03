import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../viewmodels/jobs_search_viewmodel.dart';
import 'job_detail_sections.dart';

/// B4 — sticky 'Tóm tắt tin tuyển dụng' card: exactly the 7 SummaryRow items
/// of JobDetailPage.jsx, apply + save actions, posted line and the back link.
class JobSummaryCard extends StatelessWidget {
  const JobSummaryCard({
    super.key,
    required this.job,
    required this.applied,
    required this.saved,
    required this.onApply,
    required this.onToggleSave,
    required this.onBack,
  });

  final JobModel job;
  final bool applied;
  final bool saved;
  final VoidCallback onApply;
  final VoidCallback onToggleSave;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final d = job.description;
    final rows = <_SummaryRow>[
      _SummaryRow(
        Icons.account_balance_wallet_outlined,
        'Mức lương',
        salaryLabelOf(job),
        highlight: true,
      ),
      _SummaryRow(
        Icons.place_outlined,
        'Địa điểm',
        JobsSearchState.locationOf(job),
      ),
      _SummaryRow(
        Icons.business_center_outlined,
        'Kinh nghiệm',
        d.yeuCauKinhNghiem.trim().isNotEmpty
            ? d.yeuCauKinhNghiem
            : job.experienceLevel.jobMapperLabel,
      ),
      _SummaryRow(
        Icons.description_outlined,
        'Bằng cấp',
        d.yeuCauBangCap.trim().isNotEmpty ? d.yeuCauBangCap : 'Không yêu cầu',
      ),
      _SummaryRow(
        Icons.schedule_outlined,
        'Hình thức',
        '${job.workMode.jobMapperLabel} • ${job.jobType.label}',
      ),
      _SummaryRow(
        Icons.calendar_today_outlined,
        'Hạn nộp',
        Formatters.deadlineFull(job.applicationDeadline),
      ),
      _SummaryRow(Icons.people_outline, 'Đã ứng tuyển', job.applicationsLabel),
    ];

    final rowsColumn = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < rows.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          rows[i],
        ],
      ],
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final bounded = constraints.hasBoundedHeight;
        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppRadius.x2l),
            border: Border.all(color: AppColors.borderMuted),
            boxShadow: AppShadows.card,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Tóm tắt tin tuyển dụng',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              if (bounded)
                Flexible(
                  child: SingleChildScrollView(
                    primary: false,
                    child: rowsColumn,
                  ),
                )
              else
                rowsColumn,
              const SizedBox(height: 20),
              // Web: `disabled={applied}` only — the deadline is enforced by
              // the apply flow ('Công việc đã hết hạn ứng tuyển.'), never by
              // disabling this button.
              ElevatedButton.icon(
                onPressed: applied ? null : onApply,
                icon: Icon(
                  applied ? Icons.check : Icons.send_outlined,
                  size: 18,
                ),
                label: Text(applied ? 'Đã ứng tuyển' : 'Ứng tuyển ngay'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  disabledBackgroundColor: applied ? AppColors.green600 : null,
                  disabledForegroundColor: applied ? Colors.white : null,
                ),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: onToggleSave,
                icon: Icon(
                  saved ? Icons.bookmark : Icons.bookmark_border,
                  size: 18,
                ),
                label: Text(saved ? 'Đã lưu tin' : 'Lưu tin'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  foregroundColor: saved ? AppColors.primary : AppColors.ink,
                  backgroundColor: saved
                      ? AppColors.primary50
                      : AppColors.surface,
                  side: BorderSide(
                    color: saved ? AppColors.primary : AppColors.border,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Đăng ${Formatters.postedAgo(job.createdAt)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 12),
              InkWell(
                onTap: onBack,
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.arrow_back,
                        size: 14,
                        color: AppColors.inkMuted,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Quay lại danh sách',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.inkMuted,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow(
    this.icon,
    this.label,
    this.value, {
    this.highlight = false,
  });
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 16, color: AppColors.inkMuted),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: highlight ? AppColors.primary : AppColors.ink,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
