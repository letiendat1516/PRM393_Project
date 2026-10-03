import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/employer_profile_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/company_providers.dart';
import '../widgets/job_detail_sections.dart';

/// pages/CompanyDetailPage.jsx — /cong-ty/:id (public).
/// `main.mx-auto.max-w-5xl.px-6.py-28` with two stacked white cards.
class CompanyDetailPage extends ConsumerWidget {
  const CompanyDetailPage({super.key, required this.employerUid});
  final String employerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final company = ref.watch(companyProfileProvider(employerUid));

    return PublicLayout(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1024),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: company.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Column(
                  children: [
                    RouteLoader(),
                    SizedBox(height: 16),
                    Text(
                      'Đang tải thông tin công ty...',
                      style: TextStyle(color: AppColors.inkMuted),
                    ),
                  ],
                ),
              ),
              error: (e, _) => _ErrorCard(
                message: Failure.from(e).message,
                onRetry: () =>
                    ref.invalidate(companyProfileProvider(employerUid)),
              ),
              data: (profile) => profile == null
                  ? const _ErrorCard(message: 'Không tìm thấy công ty.')
                  : _Content(profile: profile, employerUid: employerUid),
            ),
          ),
        ),
      ),
    );
  }
}

/// `rounded-xl border border-red-200 bg-red-50 p-5 text-red-700`.
class _ErrorCard extends StatelessWidget {
  const _ErrorCard({required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.red100),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Lỗi hệ thống',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.red700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            style: const TextStyle(fontSize: 14, color: AppColors.red700),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ],
        ],
      ),
    );
  }
}

class _Content extends ConsumerWidget {
  const _Content({required this.profile, required this.employerUid});
  final EmployerProfile profile;
  final String employerUid;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sm = MediaQuery.sizeOf(context).width >= 640;
    final jobs = ref.watch(companyJobsProvider(employerUid));
    final city = profile.city?.trim() ?? '';
    final website = profile.website?.trim() ?? '';
    final description = profile.companyDescription?.trim() ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Section 1: company profile ──────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _InitialsBadge(
                    name: profile.companyName,
                    logoUrl: profile.logoUrl,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // `text-sm font-semibold uppercase tracking-wide`
                        const Text(
                          'HỒ SƠ CÔNG TY',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: AppColors.blue700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          profile.companyName,
                          style: TextStyle(
                            fontSize: sm ? 30 : 24,
                            fontWeight: FontWeight.w700,
                            color: AppColors.ink,
                            letterSpacing: -0.3,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          city.isEmpty ? 'Chưa cập nhật địa điểm' : city,
                          style: const TextStyle(color: AppColors.inkMuted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: LayoutBuilder(
                  builder: (context, c) {
                    final cols = c.maxWidth >= 640 ? 2 : 1;
                    final w = (c.maxWidth - 16 * (cols - 1)) / cols;
                    return Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: [
                        SizedBox(
                          width: w,
                          child: _MetaCell(
                            label: 'Số điện thoại',
                            value: (profile.phone ?? '').trim().isEmpty
                                ? 'Chưa cập nhật'
                                : profile.phone!,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: _MetaCell(
                            label: 'Website',
                            value: website.isEmpty ? 'Chưa cập nhật' : website,
                            onTap: website.isEmpty
                                ? null
                                : () => openWebsite(website, context: context),
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: _MetaCell(
                            label: 'Người liên hệ',
                            value: (profile.contactName ?? '').trim().isEmpty
                                ? 'Chưa cập nhật'
                                : profile.contactName!,
                          ),
                        ),
                        SizedBox(
                          width: w,
                          child: _MetaCell(
                            label: 'Trạng thái',
                            value: profile.isVerified
                                ? 'Đã xác minh'
                                : 'Chưa xác minh',
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.only(top: 24),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: AppColors.border)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Giới thiệu công ty',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                      ),
                    ),
                    const SizedBox(height: 12),
                    // `whitespace-pre-line leading-7 text-slate-600`
                    Text(
                      description.isEmpty
                          ? 'Công ty chưa cập nhật phần giới thiệu.'
                          : description,
                      style: const TextStyle(
                        fontSize: 15,
                        color: AppColors.inkSoft,
                        height: 1.75,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        // ── Section 2: open jobs ────────────────────────────────────────
        AppCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Việc làm đang tuyển',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 16),
              jobs.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: RouteLoader(),
                ),
                error: (e, _) => AlertError(
                  message: Failure.from(e).message,
                  onRetry: () =>
                      ref.invalidate(companyJobsProvider(employerUid)),
                ),
                data: (list) => list.isEmpty
                    ? const Text(
                        'Công ty hiện chưa có tin tuyển dụng đang mở.',
                        style: TextStyle(color: AppColors.inkMuted),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (var i = 0; i < list.length; i++) ...[
                            if (i > 0) const SizedBox(height: 12),
                            _JobRow(key: ValueKey(list[i].jobId), job: list[i]),
                          ],
                        ],
                      ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// `grid h-20 w-20 place-items-center rounded-xl bg-blue-50 text-xl font-bold
/// text-blue-700` — up to 3 uppercase initials, fallback 'CT'. A stored logo
/// replaces the monogram.
class _InitialsBadge extends StatelessWidget {
  const _InitialsBadge({required this.name, this.logoUrl});
  final String name;
  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim() ?? '';
    final initials = name.trim().isEmpty
        ? 'CT'
        : CompanyDisplay.of(name).initials;
    return Container(
      width: 80,
      height: 80,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.blue50,
        borderRadius: BorderRadius.circular(12),
      ),
      alignment: Alignment.center,
      child: url.isEmpty
          ? Text(
              initials.isEmpty ? 'CT' : initials,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.blue700,
              ),
            )
          : Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Text(
                initials.isEmpty ? 'CT' : initials,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.blue700,
                ),
              ),
            ),
    );
  }
}

/// `block rounded-xl border p-4 transition hover:border-blue-300
/// hover:bg-blue-50` → `/viec-lam/{jobId}`; bold title + slate-500 location.
class _JobRow extends StatefulWidget {
  const _JobRow({super.key, required this.job});
  final JobModel job;

  @override
  State<_JobRow> createState() => _JobRowState();
}

class _JobRowState extends State<_JobRow> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final job = widget.job;
    final location = job.location?.trim() ?? '';
    final city = job.city.trim();
    final subtitle = location.isNotEmpty
        ? location
        : (city.isNotEmpty ? city : 'Chưa cập nhật địa điểm');
    return MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: SystemMouseCursors.click,
      child: InkWell(
        onTap: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _hover ? AppColors.blue50 : Colors.transparent,
            border: Border.all(
              color: _hover ? _blue300 : AppColors.border,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                job.jobTitle,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.inkMuted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Tailwind blue-300 (hover border of the job rows).
const _blue300 = Color(0xFF93C5FD);

/// Meta cell: `text-sm text-slate-500` label over a `mt-1 font-medium` value;
/// the Website value is a blue-700 link opening in the browser.
class _MetaCell extends StatelessWidget {
  const _MetaCell({required this.label, required this.value, this.onTap});
  final String label;
  final String value;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final text = Text(
      value,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: onTap != null ? AppColors.blue700 : AppColors.ink,
        decoration: onTap != null ? TextDecoration.underline : null,
        decorationColor: AppColors.blue700.withValues(alpha: 0.4),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 14, color: AppColors.inkMuted),
        ),
        const SizedBox(height: 4),
        onTap == null ? text : InkWell(onTap: onTap, child: text),
      ],
    );
  }
}
