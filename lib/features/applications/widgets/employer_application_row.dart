import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import 'applications_common.dart';

/// EmployerApplicationsPage row: `card grid gap-3 p-5 hover:border-primary
/// md:grid-cols-[1fr_1fr_auto]` — candidate | job + date | status badge.
class EmployerApplicationRow extends StatefulWidget {
  const EmployerApplicationRow({super.key, required this.application, required this.onTap});
  final ApplicationModel application;
  final VoidCallback onTap;

  @override
  State<EmployerApplicationRow> createState() => _EmployerApplicationRowState();
}

class _EmployerApplicationRowState extends State<EmployerApplicationRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final headline = (a.candidateHeadline ?? '').trim();

    final candidate = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          a.candidateFullName.isEmpty ? 'Ứng viên' : a.candidateFullName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.ink),
        ),
        const SizedBox(height: 2),
        Text(
          headline.isEmpty ? 'Chưa có tiêu đề' : headline,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
      ],
    );
    final job = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          a.jobTitle,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.ink),
        ),
        const SizedBox(height: 2),
        Text(
          a.applicationDate == null ? '-' : Formatters.localeDateTime(a.applicationDate!),
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );
    final badge = ApplicationStatusBadge(status: a.status);

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: _hover ? AppColors.primary : AppColors.borderMuted),
          boxShadow: AppShadows.card,
        ),
        child: InkWell(
          onTap: widget.onTap,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: LayoutBuilder(builder: (context, c) {
              if (c.maxWidth < kBpMd) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    candidate,
                    const SizedBox(height: 12),
                    job,
                    const SizedBox(height: 12),
                    badge,
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: candidate),
                  const SizedBox(width: 12),
                  Expanded(child: job),
                  const SizedBox(width: 12),
                  badge,
                ],
              );
            }),
          ),
        ),
      ),
    );
  }
}
