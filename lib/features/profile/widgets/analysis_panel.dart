import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/resume_model.dart';
import '../../../shared/widgets/app_icons.dart';
import 'profile_form_widgets.dart';

/// ResumePage `AnalysisPanel({ data })` — rendered under a CV row when the
/// latest AI extraction exists.
class AnalysisPanel extends StatelessWidget {
  const AnalysisPanel({super.key, required this.data, this.onOpenDetail});

  final AiAnalysis data;
  final VoidCallback? onOpenDetail;

  @override
  Widget build(BuildContext context) {
    final years = data.totalExperienceYears ?? 0;
    final edu = (data.educationLevel ?? '').trim();
    final hasLangs = data.languages.isNotEmpty;
    final hasCerts = data.certifications.isNotEmpty;
    final summary = (data.summary ?? '').trim();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: const BoxDecoration(
        color: Color(0x99F8FAFC), // bg-slate-50/60
        border: Border(top: BorderSide(color: AppColors.borderMuted)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(AppIcons.of('sparkles'), size: 13, color: AppColors.primary),
              const SizedBox(width: 6),
              const Text('Kết quả trích xuất bằng AI',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary)),
              const Spacer(),
              if (data.analyzedAt != null)
                Text(Formatters.localeDateTime(data.analyzedAt!),
                    style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
              if (onOpenDetail != null) ...[
                const SizedBox(width: 8),
                InkWell(
                  onTap: onOpenDetail,
                  child: const Text('Xem chi tiết →',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ],
          ),
          const SizedBox(height: 8),
          LayoutBuilder(
            builder: (context, c) {
              final two = c.maxWidth >= 640 - 40;
              final cellWidth = two ? (c.maxWidth - 8) / 2 : c.maxWidth;
              final cells = <Widget>[
                if (data.skills.isNotEmpty)
                  _ChipGroup(
                    caption: 'Kỹ năng',
                    items: data.skills,
                    bg: AppColors.primary50,
                    fg: AppColors.primary,
                  ),
                if (data.softSkills.isNotEmpty)
                  _ChipGroup(
                    caption: 'Kỹ năng mềm',
                    items: data.softSkills,
                    bg: AppColors.slate100,
                    fg: AppColors.inkSoft,
                  ),
                Wrap(
                  spacing: 16,
                  runSpacing: 4,
                  children: [
                    if (years > 0)
                      Text.rich(TextSpan(children: [
                        TextSpan(
                            text: _years(years),
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: AppColors.ink)),
                        const TextSpan(
                            text: ' năm kinh nghiệm',
                            style: TextStyle(color: AppColors.inkMuted)),
                      ]), style: const TextStyle(fontSize: 12)),
                    if (edu.isNotEmpty)
                      Text(edu,
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.ink)),
                  ],
                ),
                if (hasLangs || hasCerts)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (hasLangs)
                        Text('Ngôn ngữ: ${data.languages.join(', ')}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkMuted)),
                      if (hasCerts)
                        Text('Chứng chỉ: ${data.certifications.join(', ')}',
                            style: const TextStyle(
                                fontSize: 12, color: AppColors.inkMuted)),
                    ],
                  ),
              ];
              return Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final cell in cells) SizedBox(width: cellWidth, child: cell),
                ],
              );
            },
          ),
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              summary,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.inkSoft, height: 1.5),
            ),
          ],
        ],
      ),
    );
  }

  static String _years(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toStringAsFixed(1);
}

class _ChipGroup extends StatelessWidget {
  const _ChipGroup({
    required this.caption,
    required this.items,
    required this.bg,
    required this.fg,
  });
  final String caption;
  final List<String> items;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MicroCaption(caption),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: [
            for (final s in items) Pill(label: s, bg: bg, fg: fg, compact: true),
          ],
        ),
      ],
    );
  }
}

/// `text-[11px] font-semibold text-ink-muted uppercase tracking-wide`.
class MicroCaption extends StatelessWidget {
  const MicroCaption(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: AppColors.inkMuted,
          letterSpacing: 0.6,
        ),
      );
}
