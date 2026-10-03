import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/models/application_model.dart';
import '../../../shared/models/job_model.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../data/employer_repository.dart';
import '../viewmodels/employer_providers.dart';
import '../widgets/applicant_card.dart';
import '../widgets/employer_guard.dart';
import '../widgets/employer_job_card.dart';
import '../widgets/employer_page_header.dart';
import '../widgets/employer_state_banners.dart';

/// Mobile-plan screen "Applicants List": applications where
/// employerId == me && jobId == :id, with status filter, candidate
/// name/email search and client-side pagination (20 / page).
class JobApplicantsPage extends ConsumerWidget {
  const JobApplicantsPage({super.key, required this.jobId});
  final String jobId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return EmployerGuard(
      deniedTitle: 'Bạn không thể xem danh sách ứng viên',
      builder: (context, user) {
        final jobAsync = ref.watch(employerJobProvider(jobId));
        return jobAsync.when(
          loading: () => const EmployerPageShell(
            child: StateCard(text: 'Đang tải tin tuyển dụng...', spinner: true),
          ),
          error: (e, _) => EmployerPageShell(
            child: StateCard.error(text: Failure.from(e).message),
          ),
          data: (job) {
            if (job == null) {
              return EmployerPageShell(
                child: StateCard.error(
                  text: EmployerRepository.msgJobNotFound,
                  action: OutlinedButton(
                    onPressed: () => context.go(AppRoutes.employerJobs),
                    child: const Text('Về danh sách tin'),
                  ),
                ),
              );
            }
            if (job.employerId != user.uid) {
              return const EmployerPageShell(
                maxWidth: 896,
                child: EmployerPageHeader(
                  eyebrow: 'Không có quyền truy cập',
                  eyebrowColor: AppColors.red600,
                  title: 'Bạn không thể xem ứng viên của tin này',
                  subtitle: EmployerRepository.msgForbidden,
                ),
              );
            }
            return _Content(job: job);
          },
        );
      },
    );
  }
}

class _Content extends ConsumerStatefulWidget {
  const _Content({required this.job});
  final JobModel job;

  @override
  ConsumerState<_Content> createState() => _ContentState();
}

class _ContentState extends ConsumerState<_Content> {
  static const _pageSize = 20;

  final _search = TextEditingController();
  ApplicationStatus? _filter;
  String _query = '';
  int _page = 1;

  JobModel get job => widget.job;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _setFilter(ApplicationStatus? s) => setState(() {
        _filter = s;
        _page = 1;
      });

  void _setQuery(String q) => setState(() {
        _query = q;
        _page = 1;
      });

  /// Status filter + case-insensitive name/email search (client-side).
  List<ApplicationModel> _apply(List<ApplicationModel> all) {
    final q = _query.trim().toLowerCase();
    return all.where((a) {
      if (_filter != null && a.status != _filter) return false;
      if (q.isEmpty) return true;
      return a.candidateFullName.toLowerCase().contains(q) ||
          (a.candidateEmail ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 1024;
    final apps = ref.watch(jobApplicantsProvider(job.jobId));
    final all = apps.valueOrNull ?? const <ApplicationModel>[];

    final summary = _JobSummary(job: job);
    final list = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (all.isNotEmpty) ...[
          _SearchField(
            controller: _search,
            query: _query,
            onChanged: _setQuery,
          ),
          const SizedBox(height: 12),
          _StatusChips(apps: all, selected: _filter, onSelect: _setFilter),
          const SizedBox(height: 16),
        ],
        apps.when(
          loading: () => const StateCard(text: 'Đang tải danh sách ứng viên...', spinner: true),
          error: (e, _) => StateCard.error(
            text: Failure.from(e).message,
            action: OutlinedButton.icon(
              onPressed: () => ref.invalidate(jobApplicantsProvider(job.jobId)),
              icon: const Icon(Icons.refresh, size: 16),
              label: const Text('Thử lại'),
            ),
          ),
          data: (items) {
            if (items.isEmpty) {
              return StateCard(
                text: 'Chưa có ứng viên nào ứng tuyển vào tin này.',
                center: true,
                action: job.isPublic
                    ? OutlinedButton.icon(
                        onPressed: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
                        icon: const Icon(Icons.open_in_new, size: 16),
                        label: const Text('Xem tin công khai'),
                      )
                    : null,
              );
            }
            final filtered = _apply(items);
            if (filtered.isEmpty) {
              return StateCard(
                text: _query.trim().isNotEmpty
                    ? 'Không tìm thấy ứng viên phù hợp với từ khoá.'
                    : 'Không có hồ sơ nào ở trạng thái này.',
                center: true,
              );
            }
            final totalPages = (filtered.length / _pageSize).ceil();
            final page = _page.clamp(1, totalPages);
            final start = (page - 1) * _pageSize;
            final end = (start + _pageSize).clamp(0, filtered.length);
            final pageItems = filtered.sublist(start, end);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Hiển thị ${start + 1}–$end trên ${filtered.length} hồ sơ',
                  style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
                ),
                const SizedBox(height: 10),
                for (var i = 0; i < pageItems.length; i++) ...[
                  if (i > 0) const SizedBox(height: 12),
                  ApplicantCard(
                    application: pageItems[i],
                    onOpen: () => context.push(
                        AppRoutes.employerApplicationReviewOf(pageItems[i].applicationId)),
                  ),
                ],
                if (totalPages > 1) ...[
                  const SizedBox(height: 20),
                  Pagination(
                    page: page,
                    totalPages: totalPages,
                    onChanged: (p) => setState(() => _page = p),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );

    return EmployerPageShell(
      maxWidth: 1152,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          EmployerPageHeader(
            eyebrow: 'Ứng viên',
            title: job.jobTitle,
            subtitle: 'Danh sách hồ sơ đã ứng tuyển vào tin tuyển dụng này.',
            action: Wrap(
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () => context.go(AppRoutes.employerJobs),
                  icon: const Icon(Icons.arrow_back, size: 16),
                  label: const Text('Danh sách tin'),
                ),
                ElevatedButton.icon(
                  onPressed: () => context.push(AppRoutes.editJobOf(job.jobId)),
                  icon: const Icon(Icons.edit_outlined, size: 16),
                  label: const Text('Sửa tin'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          if (wide)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(width: 320, child: summary),
                const SizedBox(width: 24),
                Expanded(child: list),
              ],
            )
          else ...[
            summary,
            const SizedBox(height: 16),
            list,
          ],
        ],
      ),
    );
  }
}

/// Candidate name / email search box.
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.query,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String query;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Tìm theo tên hoặc email ứng viên',
        prefixIcon: const Icon(Icons.search, size: 18),
        suffixIcon: query.isEmpty
            ? null
            : IconButton(
                tooltip: 'Xoá tìm kiếm',
                icon: const Icon(Icons.close, size: 16),
                onPressed: () {
                  controller.clear();
                  onChanged('');
                },
              ),
      ),
    );
  }
}

class _JobSummary extends StatelessWidget {
  const _JobSummary({required this.job});
  final JobModel job;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CompanyLogoTile(name: job.employerName, logoUrl: job.employerLogoUrl, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(job.employerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    JobStatusBadge(status: job.status, isApproved: job.isApproved),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _row(Icons.place_outlined, job.location ?? job.city),
          _row(Icons.laptop_mac_outlined,
              '${EmployerJobLabels.workMode(job.workMode)} · ${EmployerJobLabels.jobType(job.jobType)}'),
          _row(Icons.account_balance_wallet_outlined, 'Mức lương: ${EmployerJobLabels.salary(job)}'),
          _row(Icons.people_outline, '${job.applicationsCount} hồ sơ · ${job.positionsAvailable} vị trí'),
          _row(Icons.event_outlined, 'Hạn nộp: ${Formatters.deadlineFull(job.applicationDeadline)}'),
          _row(Icons.schedule_outlined, Formatters.postedText(job.createdAt)),
          if (job.tags.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [for (final t in job.tags.take(8)) AppChipSmall(label: t)],
            ),
          ],
          if (job.isPublic) ...[
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => context.push(AppRoutes.jobDetailOf(job.jobId)),
                icon: const Icon(Icons.open_in_new, size: 16),
                label: const Text('Xem tin công khai'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _row(IconData icon, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 15, color: AppColors.inkMuted),
            const SizedBox(width: 8),
            Expanded(
              child: Text(text, style: const TextStyle(fontSize: 13, color: AppColors.inkSoft, height: 1.4)),
            ),
          ],
        ),
      );
}

/// Tiny neutral chip (avoids importing the Section file for one chip).
class AppChipSmall extends StatelessWidget {
  const AppChipSmall({super.key, required this.label});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
            color: AppColors.slate100, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(label, style: const TextStyle(fontSize: 11, color: AppColors.inkSoft)),
      );
}

class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.apps, required this.selected, required this.onSelect});
  final List<ApplicationModel> apps;
  final ApplicationStatus? selected;
  final ValueChanged<ApplicationStatus?> onSelect;

  static const _statuses = [
    ApplicationStatus.submitted,
    ApplicationStatus.underReview,
    ApplicationStatus.accepted,
    ApplicationStatus.rejected,
  ];

  @override
  Widget build(BuildContext context) {
    Widget chip(String label, ApplicationStatus? value) {
      final sel = selected == value;
      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: ChoiceChip(
          label: Text(label),
          selected: sel,
          showCheckmark: false,
          labelStyle: TextStyle(
            color: sel ? AppColors.primary : AppColors.inkSoft,
            fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
            fontSize: 12,
          ),
          onSelected: (_) => onSelect(value),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          chip('Tất cả (${apps.length})', null),
          for (final s in _statuses)
            chip('${ApplicationStatusBadge.styleOf(s).$3} (${apps.where((a) => a.status == s).length})', s),
        ],
      ),
    );
  }
}
