import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/recommendation_models.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/ui_primitives.dart';
import 'applications_common.dart';

/// CARD 1 — candidate / application summary (`.card p-6`).
class CandidateCard extends StatelessWidget {
  const CandidateCard({
    super.key,
    required this.app,
    required this.onChat,
    this.openingChat = false,
  });
  final ApplicationModel app;
  final VoidCallback onChat;
  final bool openingChat;

  @override
  Widget build(BuildContext context) {
    final headline = (app.candidateHeadline ?? '').trim();
    final city = (app.candidateCity ?? '').trim();
    final email = (app.candidateEmail ?? '').trim();
    final cvName = (app.resumeFileName ?? '').trim();
    final cvUrl = (app.resumeUrl ?? '').trim();
    final letter = (app.coverLetter ?? '').trim();

    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      app.candidateFullName.isEmpty ? 'Ứng viên' : app.candidateFullName,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    if (headline.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(headline, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 16),
              ApplicationStatusBadge(status: app.status),
            ],
          ),
          const SizedBox(height: 24),
          DefinitionGrid(items: [
            DefinitionGrid.text('Vị trí', app.jobTitle),
            DefinitionGrid.text('Địa điểm', city.isEmpty ? 'Chưa cập nhật' : city),
            (
              'CV',
              cvUrl.isNotEmpty
                  ? InkWell(
                      onTap: () => launchUrl(Uri.parse(cvUrl), mode: LaunchMode.externalApplication),
                      child: Text(
                        cvName.isEmpty ? 'Xem CV' : cvName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    )
                  : Text(
                      cvName.isEmpty ? 'Không còn khả dụng' : cvName,
                      style: const TextStyle(fontSize: 14, color: AppColors.ink),
                    ),
            ),
            DefinitionGrid.text(
              'Ngày nộp',
              app.applicationDate == null ? '-' : Formatters.localeDateTime(app.applicationDate!),
            ),
            if (email.isNotEmpty)
              (
                'Email',
                InkWell(
                  onTap: () => copyToClipboard(context, email, message: 'Đã sao chép email'),
                  child: Text(
                    email,
                    style: const TextStyle(fontSize: 14, color: AppColors.primary),
                  ),
                ),
              ),
          ]),
          const SizedBox(height: 28),
          const CardHeading('Thư giới thiệu'),
          const SizedBox(height: 8),
          SelectableText(
            letter.isEmpty ? 'Không có.' : letter,
            style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6),
          ),
          const SizedBox(height: 24),
          Align(
            alignment: Alignment.centerLeft,
            child: OutlinedButton.icon(
              onPressed: openingChat ? null : onChat,
              icon: openingChat
                  ? const SizedBox(
                      width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.chat_bubble_outline, size: 18),
              label: const Text('Nhắn tin cho ứng viên'),
            ),
          ),
        ],
      ),
    );
  }
}

/// CARD 2 — "Thông tin phù hợp": latest job_recommendation or placeholder.
class MatchInfoCard extends StatelessWidget {
  const MatchInfoCard({super.key, required this.recommendation, required this.app});
  final AsyncValue<JobRecommendation?> recommendation;
  final ApplicationModel app;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CardHeading('Thông tin phù hợp'),
          const SizedBox(height: 12),
          recommendation.when(
            loading: () => const Text('Đang tải...',
                style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
            error: (_, _) => _body(app.matchScore, app.recommendationReason),
            data: (r) => _body(
              r?.matchScore ?? app.matchScore,
              r?.recommendationReason ?? app.recommendationReason,
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(double? score, String? reason) {
    if (score == null) {
      return const Text(
        'Thông tin phù hợp hiện chưa có.',
        style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
      );
    }
    final pct = score == score.roundToDouble() ? score.toInt().toString() : score.toStringAsFixed(1);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$pct%',
          style: const TextStyle(fontSize: 30, fontWeight: FontWeight.w700, color: AppColors.primary),
        ),
        if ((reason ?? '').trim().isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(reason!.trim(),
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.6)),
        ],
      ],
    );
  }
}

/// CARD 3 — "Cập nhật trạng thái" (EmployerApplicationsPage.jsx:281-305):
/// `<select>` with the 'Chọn trạng thái' placeholder + one option per
/// allowedTransitions, then a full-width primary 'Cập nhật' button disabled
/// until a selection. No confirmation dialog, no spinner, no toast; the
/// terminal note and the inline red error live in the same card.
class StatusUpdateCard extends StatelessWidget {
  const StatusUpdateCard({
    super.key,
    required this.app,
    required this.selected,
    required this.submitting,
    required this.error,
    required this.onSelect,
    required this.onUpdate,
  });
  final ApplicationModel app;

  /// Current `<select>` value (`null` = 'Chọn trạng thái').
  final ApplicationStatus? selected;
  final bool submitting;
  final String? error;
  final ValueChanged<ApplicationStatus?> onSelect;

  /// 'Cập nhật' — PATCH with the selected status (web `update()`).
  final VoidCallback onUpdate;

  @override
  Widget build(BuildContext context) {
    final allowed = app.allowedTransitions;
    // A stale selection (status changed under us) falls back to the placeholder.
    final value = selected != null && allowed.contains(selected) ? selected : null;
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const CardHeading('Cập nhật trạng thái'),
          if (allowed.isEmpty) ...[
            const SizedBox(height: 12),
            const Text(
              'Trạng thái này là trạng thái cuối.',
              style: TextStyle(fontSize: 14, color: AppColors.inkMuted),
            ),
          ] else ...[
            const SizedBox(height: 16),
            FilterDropdown<ApplicationStatus>(
              value: value,
              items: [
                (null, 'Chọn trạng thái'),
                for (final s in allowed) (s, ApplicationStatusBadge.styleOf(s).$3),
              ],
              onChanged: onSelect,
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: value == null || submitting ? null : onUpdate,
                child: const Text('Cập nhật'),
              ),
            ),
          ],
          if (error != null) ...[
            const SizedBox(height: 12),
            Text(error!, style: const TextStyle(fontSize: 14, color: AppColors.red600)),
          ],
        ],
      ),
    );
  }
}
