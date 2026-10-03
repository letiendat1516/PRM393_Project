import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/widgets/application_status_badge.dart';

/// One applicant row on JobApplicantsPage / dashboard recent list.
class ApplicantCard extends StatelessWidget {
  const ApplicantCard({
    super.key,
    required this.application,
    required this.onOpen,
    this.showJobTitle = false,
    this.compact = false,
  });

  final ApplicationModel application;
  final VoidCallback onOpen;
  final bool showJobTitle;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final a = application;
    final name = a.candidateFullName.trim().isEmpty ? 'Ứng viên' : a.candidateFullName.trim();
    final initial = name[0].toUpperCase();
    final wide = MediaQuery.sizeOf(context).width >= 640;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(AppRadius.x2l),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        onTap: onOpen,
        child: Container(
          padding: EdgeInsets.all(compact ? 14 : 20),
          decoration: BoxDecoration(
            border: Border.all(color: AppColors.borderMuted),
            borderRadius: BorderRadius.circular(AppRadius.x2l),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: compact ? 18 : 22,
                backgroundColor: AppColors.primary50,
                child: Text(initial,
                    style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                        fontSize: compact ? 13 : 15)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: compact ? 14 : 16,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.ink)),
                        ),
                        const SizedBox(width: 8),
                        ApplicationStatusBadge(status: a.status, compact: compact),
                      ],
                    ),
                    if ((a.candidateHeadline ?? '').isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(a.candidateHeadline!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    ],
                    if (showJobTitle && a.jobTitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('Ứng tuyển: ${a.jobTitle}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                    ],
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 14,
                      runSpacing: 4,
                      children: [
                        _meta(Icons.schedule_outlined,
                            'Nộp ${Formatters.relative(a.applicationDate)}'),
                        if ((a.candidateCity ?? '').isNotEmpty)
                          _meta(Icons.place_outlined, a.candidateCity!),
                        if ((a.candidateEmail ?? '').isNotEmpty && wide)
                          _meta(Icons.mail_outline, a.candidateEmail!),
                        if (a.resumeId != null || (a.resumeFileName ?? '').isNotEmpty)
                          _meta(Icons.description_outlined,
                              a.resumeFileName ?? 'Có đính kèm CV'),
                        if (a.matchScore != null)
                          _meta(Icons.auto_awesome_outlined,
                              'Phù hợp ${a.matchScore!.round()}/100',
                              color: AppColors.primary),
                      ],
                    ),
                  ],
                ),
              ),
              if (!compact) ...[
                const SizedBox(width: 8),
                const Icon(Icons.chevron_right, color: AppColors.slate400),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color color = AppColors.inkMuted}) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 4),
          Text(text, style: TextStyle(fontSize: 12, color: color)),
        ],
      );
}
