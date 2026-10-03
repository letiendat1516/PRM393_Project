import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/applications_providers.dart';
import '../widgets/applications_common.dart';
import '../widgets/employer_application_row.dart';

/// pages/EmployerApplicationsPage.jsx — /employer/applications (employer, admin).
class EmployerApplicationsPage extends ConsumerStatefulWidget {
  const EmployerApplicationsPage({super.key});

  @override
  ConsumerState<EmployerApplicationsPage> createState() => _EmployerApplicationsPageState();
}

class _EmployerApplicationsPageState extends ConsumerState<EmployerApplicationsPage> {
  late final TextEditingController _name =
      TextEditingController(text: ref.read(employerApplicationsFilterProvider).candidateName);

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  void _patch(EmployerApplicationsFilter Function(EmployerApplicationsFilter f) fn) {
    ref.read(employerApplicationsFilterProvider.notifier).update(fn);
  }

  Future<void> _pickDate({required bool from}) async {
    final filter = ref.read(employerApplicationsFilterProvider);
    final initial = (from ? filter.submittedFrom : filter.submittedTo) ?? DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: from ? 'Nộp từ ngày' : 'Nộp đến ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked == null) return;
    _patch((f) => from
        ? f.copyWith(submittedFrom: picked, page: 1)
        : f.copyWith(submittedTo: picked, page: 1));
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(employerApplicationsFilterProvider);
    final paged = ref.watch(employerApplicationsProvider);
    final jobOptions = ref.watch(employerApplicationJobOptionsProvider);
    final total = paged.valueOrNull?.total ?? 0;

    return PublicLayout(
      child: ApplicationsPageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // EmployerApplicationsPage.jsx:109 — the eyebrow is static even
            // for admins (the route is role-guarded employer|admin).
            ApplicationsPageHeader(
              eyebrow: 'Nhà tuyển dụng',
              title: 'Hồ sơ ứng tuyển',
              subtitle: '$total hồ sơ đã nhận',
            ),
            const SizedBox(height: 24),
            FilterBar(
              children: [
                TextField(
                  controller: _name,
                  decoration: const InputDecoration(
                    hintText: 'Tên ứng viên',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (v) => _patch((f) => f.copyWith(candidateName: v, page: 1)),
                ),
                FilterDropdown<ApplicationStatus>(
                  value: filter.status,
                  items: [
                    (null, 'Tất cả trạng thái'),
                    for (final s in kExposedStatuses) (s, ApplicationStatusBadge.styleOf(s).$3),
                  ],
                  onChanged: (v) =>
                      _patch((f) => f.copyWith(status: v, clearStatus: v == null, page: 1)),
                ),
                FilterDropdown<ApplicationSort>(
                  value: filter.sort,
                  items: [for (final s in ApplicationSort.values) (s, s.label)],
                  onChanged: (v) =>
                      _patch((f) => f.copyWith(sort: v ?? ApplicationSort.newest)),
                ),
                FilterDropdown<String>(
                  value: jobOptions.any((o) => o.jobId == filter.jobId) ? filter.jobId : null,
                  items: [
                    (null, 'Tất cả tin tuyển dụng'),
                    for (final o in jobOptions) (o.jobId, o.jobTitle),
                  ],
                  onChanged: (v) =>
                      _patch((f) => f.copyWith(jobId: v, clearJobId: v == null, page: 1)),
                ),
                _DateField(
                  label: 'Nộp từ ngày',
                  value: filter.submittedFrom,
                  onTap: () => _pickDate(from: true),
                  onClear: () => _patch((f) => f.copyWith(clearFrom: true, page: 1)),
                ),
                _DateField(
                  label: 'Nộp đến ngày',
                  value: filter.submittedTo,
                  onTap: () => _pickDate(from: false),
                  onClear: () => _patch((f) => f.copyWith(clearTo: true, page: 1)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            paged.when(
              loading: () => const _CenteredCard(text: 'Đang tải...'),
              error: (e, _) => RedBanner(message: Failure.from(e).message),
              data: (page) {
                if (page.items.isEmpty) {
                  return _CenteredCard(
                    text: 'Chưa nhận được hồ sơ ứng tuyển nào.',
                    action: filter.hasActiveFilters
                        ? TextButton(
                            onPressed: () {
                              _name.clear();
                              ref.read(employerApplicationsFilterProvider.notifier).state =
                                  const EmployerApplicationsFilter();
                            },
                            child: const Text('Xóa bộ lọc'),
                          )
                        : null,
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < page.items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 12),
                      EmployerApplicationRow(
                        application: page.items[i],
                        onTap: () => context.push(
                          AppRoutes.employerApplicationReviewOf(page.items[i].applicationId),
                        ),
                      ),
                    ],
                    if (page.total > page.limit) ...[
                      const SizedBox(height: 32),
                      PrevNextPager(
                        page: page.page,
                        hasPrev: page.hasPrev,
                        hasNext: page.hasNext,
                        onChanged: (p) => _patch((f) => f.copyWith(page: p)),
                      ),
                    ],
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// `.card p-10 text-center`.
class _CenteredCard extends StatelessWidget {
  const _CenteredCard({required this.text, this.action});
  final String text;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          Text(text,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, color: AppColors.ink)),
          if (action != null) ...[const SizedBox(height: 8), action!],
        ],
      ),
    );
  }
}

/// Read-only date input (submittedFrom / submittedTo) with a clear button.
class _DateField extends StatelessWidget {
  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.onClear,
  });
  final String label;
  final DateTime? value;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: InputDecorator(
        decoration: InputDecoration(
          hintText: label,
          prefixIcon: const Icon(Icons.calendar_today_outlined, size: 16),
          suffixIcon: value == null
              ? null
              : IconButton(
                  tooltip: 'Xóa',
                  icon: const Icon(Icons.close, size: 16),
                  onPressed: onClear,
                ),
        ),
        isEmpty: value == null,
        child: Text(
          value == null ? '' : Formatters.date(value),
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
        ),
      ),
    );
  }
}
