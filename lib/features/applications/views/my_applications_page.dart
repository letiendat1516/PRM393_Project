import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../../../shared/widgets/public_layout.dart';
import '../../../shared/widgets/ui_primitives.dart';
import '../viewmodels/applications_providers.dart';
import '../widgets/application_list_card.dart';
import '../widgets/applications_common.dart';

/// pages/MyApplicationsPage.jsx — /applications (job seeker).
class MyApplicationsPage extends ConsumerStatefulWidget {
  const MyApplicationsPage({super.key});

  @override
  ConsumerState<MyApplicationsPage> createState() => _MyApplicationsPageState();
}

class _MyApplicationsPageState extends ConsumerState<MyApplicationsPage> {
  late final TextEditingController _keyword =
      TextEditingController(text: ref.read(myApplicationsFilterProvider).keyword);

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _patch(MyApplicationsFilter Function(MyApplicationsFilter f) fn) {
    ref.read(myApplicationsFilterProvider.notifier).update(fn);
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(myApplicationsFilterProvider);
    final paged = ref.watch(myApplicationsProvider);
    final total = paged.valueOrNull?.total ?? 0;

    return PublicLayout(
      child: ApplicationsPageShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ApplicationsPageHeader(
              eyebrow: 'Ứng viên',
              title: 'Hồ sơ đã ứng tuyển',
              subtitle: '$total hồ sơ',
            ),
            const SizedBox(height: 32),
            FilterBar(
              children: [
                TextField(
                  controller: _keyword,
                  decoration: const InputDecoration(
                    hintText: 'Tên công việc hoặc công ty',
                    prefixIcon: Icon(Icons.search, size: 18),
                  ),
                  onChanged: (v) => _patch((f) => f.copyWith(keyword: v, page: 1)),
                ),
                FilterDropdown<ApplicationStatus>(
                  value: filter.status,
                  items: [
                    (null, 'Tất cả trạng thái'),
                    for (final s in kExposedStatuses) (s, ApplicationStatusBadge.styleOf(s).$3),
                  ],
                  onChanged: (v) => _patch(
                    (f) => f.copyWith(status: v, clearStatus: v == null, page: 1),
                  ),
                ),
                FilterDropdown<ApplicationSort>(
                  value: filter.sort,
                  items: [for (final s in ApplicationSort.values) (s, s.label)],
                  onChanged: (v) =>
                      _patch((f) => f.copyWith(sort: v ?? ApplicationSort.newest)),
                ),
              ],
            ),
            const SizedBox(height: 24),
            paged.when(
              loading: () => const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text('Đang tải hồ sơ...', style: TextStyle(color: AppColors.inkMuted)),
              ),
              error: (e, _) => RedBanner(message: Failure.from(e).message),
              data: (page) {
                if (page.items.isEmpty) return const _EmptyCard();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    for (var i = 0; i < page.items.length; i++) ...[
                      if (i > 0) const SizedBox(height: 16),
                      ApplicationListCard(
                        application: page.items[i],
                        onTap: () => context.push(
                          AppRoutes.applicationDetailOf(page.items[i].applicationId),
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

/// `.card p-10 text-center` — 'Bạn chưa có hồ sơ phù hợp bộ lọc.' + CTA.
class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(40),
      child: Column(
        children: [
          const Text(
            'Bạn chưa có hồ sơ phù hợp bộ lọc.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => context.go(AppRoutes.jobs),
            child: const Text('Khám phá việc làm'),
          ),
        ],
      ),
    );
  }
}
