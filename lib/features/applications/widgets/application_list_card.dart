import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/widgets/application_status_badge.dart';

/// MyApplicationsPage link-card: `.card block p-5 hover:border-primary`,
/// title (text-lg bold) / company / "Nộp ngày … · CV: …" and the status pill.
class ApplicationListCard extends StatefulWidget {
  const ApplicationListCard({super.key, required this.application, required this.onTap});
  final ApplicationModel application;
  final VoidCallback onTap;

  @override
  State<ApplicationListCard> createState() => _ApplicationListCardState();
}

class _ApplicationListCardState extends State<ApplicationListCard> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final a = widget.application;
    final cv = (a.resumeFileName ?? '').trim().isNotEmpty ? a.resumeFileName! : 'Không còn khả dụng';
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
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.start,
              spacing: 16,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 720),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        a.jobTitle.isEmpty ? 'Tin tuyển dụng' : a.jobTitle,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: AppColors.ink,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        a.companyName,
                        style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Nộp ngày ${Formatters.date(a.applicationDate)} · CV: $cv',
                        style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                      ),
                    ],
                  ),
                ),
                ApplicationStatusBadge(status: a.status),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
