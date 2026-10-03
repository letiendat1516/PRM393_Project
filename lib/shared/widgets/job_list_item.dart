import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/enums.dart';
import '../../core/utils/formatters.dart';
import '../models/job_model.dart';
import '../models/recommendation_models.dart';
import 'section.dart';
import 'ui_primitives.dart';

/// components/job/JobListItem.jsx — horizontal TopCV-style row used on
/// JobsPage, SessionDetailPage and the homepage featured grid.
class JobListItem extends StatefulWidget {
  const JobListItem({
    super.key,
    required this.job,
    this.score,
    this.saved = false,
    this.onToggleSave,
    this.onApply,
    this.applied = false,
    this.compact = false,
  });

  final JobModel job;
  final JobScore? score;
  final bool saved;
  final VoidCallback? onToggleSave;
  final VoidCallback? onApply;
  final bool applied;
  final bool compact;

  @override
  State<JobListItem> createState() => _JobListItemState();
}

class _JobListItemState extends State<JobListItem> {
  bool _hover = false;
  bool _showDetail = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final score = widget.score;
    final pad = widget.compact ? 16.0 : 20.0;

    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        transform: Matrix4.translationValues(0, _hover ? -2 : 0, 0),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: _hover ? AppColors.primary100 : AppColors.borderMuted),
          boxShadow: _hover ? AppShadows.elevated : AppShadows.card,
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          onTap: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
          child: Padding(
            padding: EdgeInsets.all(pad),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CompanyLogoTile(
                  name: job.employerName,
                  logoUrl: job.employerLogoUrl,
                  size: widget.compact ? 48 : 56,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title + company | score badge or Nổi bật chip
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  job.jobTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: _hover ? AppColors.primary : AppColors.ink,
                                    height: 1.3,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  job.employerName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 13, color: AppColors.inkSoft),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          if (score != null)
                            ScoreBadge(score: score)
                          else if (job.hot)
                            const AppChip(
                              label: 'Nổi bật',
                              variant: AppChipVariant.secondary,
                              compact: true,
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // meta row
                      Wrap(
                        spacing: 16,
                        runSpacing: 6,
                        children: [
                          _meta(
                            Icons.account_balance_wallet_outlined,
                            Formatters.salary(
                              min: job.salaryMin,
                              max: job.salaryMax,
                              currency: job.salaryCurrency,
                              negotiable: job.isSalaryNegotiable,
                            ),
                            color: AppColors.primary,
                            bold: true,
                          ),
                          _meta(Icons.place_outlined, job.location ?? job.city),
                          _meta(Icons.business_center_outlined, job.experienceLevel.jobMapperLabel),
                        ],
                      ),
                      if (score != null) ...[
                        const SizedBox(height: 12),
                        _aiReason(score),
                      ],
                      const SizedBox(height: 12),
                      // tags
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          for (final t in job.tags.take(4)) AppChip(label: t, compact: true),
                          AppChip(
                            label: job.workMode.jobMapperLabel,
                            variant: AppChipVariant.primary,
                            compact: true,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // footer
                      Container(
                        padding: const EdgeInsets.only(top: 12),
                        decoration: const BoxDecoration(
                          border: Border(top: BorderSide(color: AppColors.borderMuted)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                // JobListItem.jsx footer: job.postedAgo (no "Đăng " prefix)
                                Formatters.postedAgo(job.createdAt),
                                style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                              ),
                            ),
                            _bookmark(),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: widget.applied
                                  ? null
                                  : (widget.onApply ??
                                      () => context.push(AppRoutes.jobDetailOf(job.jobId))),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                                minimumSize: const Size(0, 36),
                                textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                              ),
                              child: Text(widget.applied ? 'Đã ứng tuyển' : 'Ứng tuyển'),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _bookmark() {
    final saved = widget.saved;
    return Tooltip(
      message: saved ? 'Bỏ lưu' : 'Lưu tin',
      child: InkWell(
        onTap: widget.onToggleSave,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: saved ? AppColors.primary : AppColors.surface,
            border: Border.all(color: saved ? AppColors.primary : AppColors.border),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            saved ? Icons.bookmark : Icons.bookmark_border,
            size: 18,
            color: saved ? Colors.white : AppColors.inkSoft,
          ),
        ),
      ),
    );
  }

  /// JobListItem.jsx "AI match reason + detail panel": reason strip (tone by
  /// score, 2-line clamp, trailing 'Thiếu: a, b, c'), chevron toggle and the
  /// expandable detail card.
  Widget _aiReason(JobScore s) {
    final (bg, fg) = s.matchScore >= 80
        ? (AppColors.green50, AppColors.green800)
        : s.matchScore >= 60
            ? (AppColors.primary50, AppColors.primary)
            : (AppColors.slate50, AppColors.inkSoft);
    final missing = s.missingSkills;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.auto_awesome, size: 14, color: fg),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  s.recommendationReason,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: fg, height: 1.5),
                ),
              ),
              if (missing.isNotEmpty) ...[
                const SizedBox(width: 8),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 180),
                  child: Text(
                    'Thiếu: ${missing.take(3).join(', ')}',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted, height: 1.5),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => _showDetail = !_showDetail),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedRotation(
                turns: _showDetail ? 0.5 : 0,
                duration: const Duration(milliseconds: 150),
                child: const Icon(Icons.expand_more, size: 12, color: AppColors.primary),
              ),
              const SizedBox(width: 4),
              Text(
                _showDetail ? 'Thu gọn đánh giá' : 'Xem đánh giá chi tiết từ AI',
                style: const TextStyle(fontSize: 12, color: AppColors.primary, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
        if (_showDetail) ...[
          const SizedBox(height: 8),
          _detailPanel(s),
        ],
      ],
    );
  }

  /// JobListItem.jsx `criteria` order (7 tiêu chí).
  static const _criteria = [
    'skills',
    'experience',
    'education',
    'domain',
    'soft_skills',
    'language',
    'career_fit',
  ];

  static const _eyebrow = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    color: AppColors.inkMuted,
    letterSpacing: 0.4,
  );

  Widget _detailPanel(JobScore s) {
    final b = s.breakdown.toMap();
    final w = s.weights.toMap();
    final matchScore = s.matchScore;
    final scoreColor = matchScore >= 70
        ? AppColors.green600
        : matchScore >= 50
            ? AppColors.primary
            : AppColors.amber600;
    final reason = s.recommendationReason;

    // Quy về thang 10, CAP tại 10 (AI có thể trả raw score > weight).
    double? to10(String key) {
      final max = w[key] ?? 0;
      final val = b[key] ?? 0;
      if (max == 0) return null;
      final score10 = ((val / max) * 10 * 10).round() / 10;
      return score10 > 10 ? 10 : score10;
    }

    String fmt10(double v) => v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);

    Widget chips(Iterable<String> items, Color bg) => Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            for (final m in items)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
                child: Text(m, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
              ),
          ],
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Score
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(bottom: 12),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppColors.borderMuted)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('ĐIỂM AI', style: _eyebrow),
                Text.rich(
                  TextSpan(
                    text: (matchScore.round() / 10).toStringAsFixed(1),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: scoreColor, height: 1.3),
                    children: const [
                      TextSpan(text: '/10', style: TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // Score breakdown — thang điểm 10, trọng số động
          const Text.rich(
            TextSpan(
              text: 'PHÂN TÍCH 7 TIÊU CHÍ',
              style: _eyebrow,
              children: [
                TextSpan(
                  text: '  (trọng số thay đổi theo job)',
                  style: TextStyle(fontWeight: FontWeight.w400, letterSpacing: 0),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          for (final key in _criteria)
            if ((w[key] ?? 0) != 0 && to10(key) != null) ...[
              Row(
                children: [
                  Expanded(
                    child: Text.rich(
                      TextSpan(
                        text: ScoreBreakdown.labels[key] ?? key,
                        style: const TextStyle(fontSize: 12, color: AppColors.inkSoft),
                        children: [
                          TextSpan(
                            text: ' (trọng số: ${w[key]}đ)',
                            style: const TextStyle(fontSize: 9, color: AppColors.inkMuted),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Text('${fmt10(to10(key)!)}/10',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary)),
                ],
              ),
              const SizedBox(height: 2),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: (to10(key)! / 10).clamp(0, 1),
                  minHeight: 10,
                  backgroundColor: AppColors.slate100,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 8),
            ],
          // Full reason
          if (reason.isNotEmpty) ...[
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 4),
              padding: const EdgeInsets.only(top: 8),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.borderMuted)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('ĐÁNH GIÁ TỔNG QUAN', style: _eyebrow),
                  const SizedBox(height: 4),
                  Text(reason, style: const TextStyle(fontSize: 12, color: AppColors.inkSoft, height: 1.625)),
                ],
              ),
            ),
            const SizedBox(height: 12),
          ],
          // Missing skills
          if (s.missingSkills.isNotEmpty) ...[
            const Text('⚠ KỸ NĂNG THIẾU', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.red500)),
            const SizedBox(height: 4),
            chips(s.missingSkills, AppColors.red50),
            const SizedBox(height: 12),
          ],
          // Strengths
          if (s.strengths.isNotEmpty) ...[
            const Text('✓ ĐIỂM MẠNH', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.green600)),
            const SizedBox(height: 4),
            chips(s.strengths, AppColors.green50),
          ],
        ],
      ),
    );
  }

  Widget _meta(IconData icon, String text, {Color color = AppColors.inkSoft, bool bold = false}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Text(
          text,
          style: TextStyle(
            fontSize: 13,
            color: color,
            fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

/// components/job/JobCard.jsx — vertical card for the homepage featured grid:
/// logo tile + title/company, hot chip, 2-col meta, tag chips, footer with
/// posted date + bookmark + primary Apply.
class JobCard extends StatelessWidget {
  const JobCard({
    super.key,
    required this.job,
    this.saved = false,
    this.onToggleSave,
    this.onApply,
    this.brand,
  });

  final JobModel job;
  final bool saved;
  final VoidCallback? onToggleSave;
  final VoidCallback? onApply;
  final String? brand;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      hoverLift: true,
      onTap: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogoTile(name: job.employerName, logoUrl: job.employerLogoUrl, size: 48, brand: brand),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.jobTitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.ink, height: 1.3)),
                    const SizedBox(height: 2),
                    Text(job.employerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 13, color: AppColors.inkSoft)),
                  ],
                ),
              ),
              if (job.hot) ...[
                const SizedBox(width: 6),
                const AppChip(label: 'Nổi bật', variant: AppChipVariant.secondary, compact: true),
              ],
            ],
          ),
          const SizedBox(height: 14),
          _metaGrid(),
          const SizedBox(height: 12),
          // JobCard.jsx: tag chips + primary-tinted workType chip.
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in job.tags.take(3)) AppChip(label: t, compact: true),
              AppChip(label: job.workMode.jobMapperLabel, variant: AppChipVariant.primary, compact: true),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.borderMuted))),
            child: Row(
              children: [
                Expanded(
                  child: Text(Formatters.postedText(job.createdAt),
                      style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
                ),
                InkWell(
                  onTap: onToggleSave,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: saved ? AppColors.primary : AppColors.surface,
                      border: Border.all(color: saved ? AppColors.primary : AppColors.border),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(saved ? Icons.bookmark : Icons.bookmark_border,
                        size: 16, color: saved ? Colors.white : AppColors.inkSoft),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: onApply ?? () => context.push(AppRoutes.jobDetailOf(job.jobId)),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: const Size(0, 34),
                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  child: const Text('Ứng tuyển'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _metaGrid() {
    Widget cell(IconData icon, String text) => Row(
          children: [
            Icon(icon, size: 14, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12, color: AppColors.inkSoft)),
            ),
          ],
        );
    return Column(
      children: [
        Row(children: [
          Expanded(
              child: cell(
                  Icons.account_balance_wallet_outlined,
                  Formatters.salary(
                      min: job.salaryMin,
                      max: job.salaryMax,
                      currency: job.salaryCurrency,
                      negotiable: job.isSalaryNegotiable))),
          const SizedBox(width: 8),
          Expanded(child: cell(Icons.place_outlined, job.location ?? job.city)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Expanded(child: cell(Icons.business_center_outlined, job.experienceLevel.jobMapperLabel)),
          const SizedBox(width: 8),
          Expanded(child: cell(Icons.schedule_outlined, job.jobType.label)),
        ]),
      ],
    );
  }
}
