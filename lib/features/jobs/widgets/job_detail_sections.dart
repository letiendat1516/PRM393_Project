import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/section.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/jobs_search_viewmodel.dart';

String salaryLabelOf(JobModel job) => Formatters.salary(
  min: job.salaryMin,
  max: job.salaryMax,
  currency: job.salaryCurrency,
  negotiable: job.isSalaryNegotiable,
);

/// Opens an external website, adding https:// when the scheme is missing.
/// Launch failures (no browser, malformed URL, PlatformException) are caught
/// and surfaced through a snackbar when a [context] is given.
Future<void> openWebsite(String url, {BuildContext? context}) async {
  final normalized = url.startsWith(RegExp(r'https?://'))
      ? url
      : 'https://$url';
  final uri = Uri.tryParse(normalized);
  var ok = uri != null;
  if (ok) {
    try {
      ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
  }
  if (!ok && context != null && context.mounted) {
    showFailure(context, const Failure('Không thể mở liên kết website.'));
  }
}

/// B1 — Job header card: monogram/logo, title, company link, chips and the
/// 2×2 / 1×4 quick-meta grid.
class JobHeaderCard extends StatelessWidget {
  const JobHeaderCard({super.key, required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sm = width >= 640;
    final hasCompany = job.employerId.isNotEmpty;

    return AppCard(
      padding: EdgeInsets.all(sm ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CompanyLogoTile(
                name: job.employerName,
                logoUrl: job.employerLogoUrl,
                size: sm ? 80 : 64,
                radius: 14,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.jobTitle,
                      style: TextStyle(
                        fontSize: sm ? 24 : 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        height: 1.25,
                      ),
                    ),
                    const SizedBox(height: 6),
                    InkWell(
                      onTap: hasCompany
                          ? () => context.push(
                              AppRoutes.companyDetailOf(job.employerId),
                            )
                          : null,
                      child: Text(
                        job.employerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: sm ? 16 : 14,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                          decoration: hasCompany
                              ? TextDecoration.underline
                              : null,
                          decorationColor: AppColors.primary.withValues(
                            alpha: 0.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (job.hot)
                          const AppChip(
                            label: 'Nổi bật',
                            variant: AppChipVariant.secondary,
                          ),
                        AppChip(
                          label: job.workMode.jobMapperLabel,
                          variant: AppChipVariant.primary,
                        ),
                        AppChip(label: job.jobType.label),
                        AppChip(label: JobsSearchState.categoryOf(job)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.only(top: 20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppColors.borderMuted)),
            ),
            child: _MetaGrid(
              columns: sm ? 4 : 2,
              items: [
                _MetaItem(
                  Icons.account_balance_wallet_outlined,
                  'Mức lương',
                  salaryLabelOf(job),
                  highlight: true,
                ),
                _MetaItem(
                  Icons.place_outlined,
                  'Địa điểm',
                  JobsSearchState.locationOf(job),
                ),
                _MetaItem(
                  Icons.business_center_outlined,
                  'Kinh nghiệm',
                  job.experienceLevel.jobMapperLabel,
                ),
                _MetaItem(
                  Icons.schedule_outlined,
                  'Hạn nộp',
                  Formatters.date(job.applicationDeadline),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaItem {
  const _MetaItem(this.icon, this.label, this.value, {this.highlight = false});
  final IconData icon;
  final String label;
  final String value;
  final bool highlight;
}

class _MetaGrid extends StatelessWidget {
  const _MetaGrid({required this.columns, required this.items});
  final int columns;
  final List<_MetaItem> items;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        const gap = 16.0;
        final w = (c.maxWidth - gap * (columns - 1)) / columns;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final m in items)
              SizedBox(
                width: w,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(m.icon, size: 15, color: AppColors.inkMuted),
                        const SizedBox(width: 6),
                        Text(
                          m.label,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.inkMuted,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      m.value,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: m.highlight ? AppColors.primary : AppColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}

/// B2 — 'Kỹ năng / Chuyên môn' chips (hidden when the job has no tags).
class JobSkillsCard extends StatelessWidget {
  const JobSkillsCard({super.key, required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    if (job.tags.isEmpty) return const SizedBox.shrink();
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Kỹ năng / Chuyên môn',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [for (final t in job.tags) AppChip(label: t)],
          ),
        ],
      ),
    );
  }
}

/// B3 — structured description sections with primary dot bullets.
class JobContentCard extends StatelessWidget {
  const JobContentCard({super.key, required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final sm = width >= 640;
    final d = job.description;

    if (d.isEmpty) {
      return AppCard(
        padding: EdgeInsets.all(sm ? 24 : 20),
        child: const Text(
          'Chi tiết công việc đang được cập nhật.',
          style: TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
      );
    }

    final sections = <Widget>[
      if (d.moTaCongViec.isNotEmpty)
        _ListSection(
          icon: Icons.description_outlined,
          title: 'Mô tả công việc',
          items: d.moTaCongViec,
        ),
      if (d.yeuCauUngVien.isNotEmpty)
        _ListSection(
          icon: Icons.check_circle_outline,
          title: 'Yêu cầu ứng viên',
          items: d.yeuCauUngVien,
        ),
      if (d.quyenLoi.isNotEmpty)
        _ListSection(
          icon: Icons.auto_awesome_outlined,
          title: 'Quyền lợi',
          items: d.quyenLoi,
        ),
      // Web order: mo_ta / yeu_cau / quyen_loi lists, 'Thời gian làm việc',
      // 'Cách thức ứng tuyển'. yeu_cau_kinh_nghiem / yeu_cau_bang_cap only
      // appear in the sidebar summary rows.
      if (d.thoiGianLamViec.trim().isNotEmpty)
        _TextSection(
          icon: Icons.schedule_outlined,
          title: 'Thời gian làm việc',
          text: d.thoiGianLamViec,
        ),
      const _TextSection(
        icon: Icons.send_outlined,
        title: 'Cách thức ứng tuyển',
        text: 'Ứng viên nộp hồ sơ trực tuyến bằng cách bấm ',
        strong: 'Ứng tuyển ngay',
        tail: ' dưới đây.',
      ),
    ];

    return AppCard(
      padding: EdgeInsets.all(sm ? 24 : 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            if (i > 0) const SizedBox(height: 32),
            sections[i],
          ],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.icon, required this.title});
  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    final sm = MediaQuery.sizeOf(context).width >= 640;
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: sm ? 18 : 16,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
      ],
    );
  }
}

class _ListSection extends StatelessWidget {
  const _ListSection({
    required this.icon,
    required this.title,
    required this.items,
  });
  final IconData icon;
  final String title;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 12),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 10),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: const EdgeInsets.only(top: 7),
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  items[i],
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.inkSoft,
                    height: 1.6,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

class _TextSection extends StatelessWidget {
  const _TextSection({
    required this.icon,
    required this.title,
    required this.text,
    this.strong,
    this.tail,
  });
  final IconData icon;
  final String title;
  final String text;
  final String? strong;
  final String? tail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(icon: icon, title: title),
        const SizedBox(height: 12),
        Text.rich(
          TextSpan(
            text: text,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.inkSoft,
              height: 1.6,
            ),
            children: [
              if (strong != null)
                TextSpan(
                  text: strong,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
              if (tail != null) TextSpan(text: tail),
            ],
          ),
        ),
      ],
    );
  }
}
