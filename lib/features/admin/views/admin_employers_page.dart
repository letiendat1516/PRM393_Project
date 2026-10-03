import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../viewmodels/admin_employers_viewmodel.dart';
import '../viewmodels/admin_mutation_notifier.dart';
import '../viewmodels/admin_providers.dart';
import '../viewmodels/admin_users_viewmodel.dart';
import '../widgets/admin_page_shell.dart';

/// UC-18 — Quản lý nhà tuyển dụng (/admin/employers).
class AdminEmployersPage extends ConsumerStatefulWidget {
  const AdminEmployersPage({super.key});

  @override
  ConsumerState<AdminEmployersPage> createState() => _AdminEmployersPageState();
}

class _AdminEmployersPageState extends ConsumerState<AdminEmployersPage> {
  final _keyword = TextEditingController();

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _submitSearch() =>
      ref.read(adminEmployersFilterProvider.notifier).submitKeyword(_keyword.text);

  Future<void> _toggleVerification(AdminEmployerRow e) async {
    final verify = !e.isVerified;
    final label = verify ? 'xác minh' : 'hủy xác minh';
    final ok = await showConfirmDialog(
      context,
      message: 'Bạn có chắc muốn $label nhà tuyển dụng này?',
      confirmLabel: verify ? 'Xác minh' : 'Hủy xác minh',
      danger: !verify,
    );
    // the page may have been disposed (role/auth redirect) while the dialog was open
    if (!ok || !mounted) return;
    final repo = ref.read(adminRepositoryProvider);
    await ref.read(adminEmployersMutationProvider.notifier).run(
          e.id,
          () => repo.setEmployerVerified(uid: e.id, verified: verify),
          fallbackMessage: 'Không thể $label nhà tuyển dụng.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminEmployersFilterProvider);
    final filterNotifier = ref.read(adminEmployersFilterProvider.notifier);
    final page = ref.watch(adminEmployersPageProvider);
    final mutation = ref.watch(adminEmployersMutationProvider);
    final lg = MediaQuery.sizeOf(context).width >= kAdminLgBreakpoint;
    final items = page.valueOrNull?.items ?? const <AdminEmployerRow>[];
    final errorText =
        mutation.error ?? (page.hasError ? Failure.from(page.error!).message : null);

    final keyword = TextField(
      controller: _keyword,
      maxLength: 100,
      textInputAction: TextInputAction.search,
      onSubmitted: (_) => _submitSearch(),
      decoration: const InputDecoration(
        hintText: 'Tìm công ty hoặc email',
        counterText: '',
        prefixIcon: Icon(Icons.search, size: 20),
      ),
    );
    final verification = DropdownButtonFormField<VerificationFilter>(
      initialValue: filter.verification,
      isExpanded: true,
      items: [
        for (final v in VerificationFilter.values) DropdownMenuItem(value: v, child: Text(v.label)),
      ],
      onChanged: (v) {
        if (v != null) filterNotifier.setVerification(v);
      },
    );
    final status = DropdownButtonFormField<AccountStatusFilter>(
      initialValue: filter.status,
      isExpanded: true,
      items: [
        for (final s in AccountStatusFilter.values)
          DropdownMenuItem(value: s, child: Text(s.employerLabel)),
      ],
      onChanged: (v) {
        if (v != null) filterNotifier.setStatus(v);
      },
    );
    final submit = ElevatedButton(onPressed: _submitSearch, child: const Text('Tìm kiếm'));

    return AdminPageShell(
      maxWidth: 1280,
      children: [
        const AdminPageHeader(
          eyebrow: 'UC-18',
          title: 'Quản lý nhà tuyển dụng',
          subtitle:
              'Xác minh thông tin doanh nghiệp. Trạng thái đăng nhập được quản lý riêng tại trang người dùng.',
        ),
        const SizedBox(height: 32),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            border: Border.all(color: AppColors.border),
            borderRadius: BorderRadius.circular(AppRadius.x2l),
          ),
          child: lg
              ? Row(
                  children: [
                    Expanded(child: keyword),
                    const SizedBox(width: 12),
                    SizedBox(width: 200, child: verification),
                    const SizedBox(width: 12),
                    SizedBox(width: 200, child: status),
                    const SizedBox(width: 12),
                    submit,
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    keyword,
                    const SizedBox(height: 12),
                    verification,
                    const SizedBox(height: 12),
                    status,
                    const SizedBox(height: 12),
                    submit,
                  ],
                ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 20),
          AdminErrorBanner(
            message: errorText,
            onDismiss: mutation.error != null
                ? () => ref.read(adminEmployersMutationProvider.notifier).clearError()
                : null,
          ),
        ],
        const SizedBox(height: 20),
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _EmployerCard(
            employer: items[i],
            updating: mutation.isUpdating(items[i].id),
            disabled: mutation.busy,
            onToggle: () => _toggleVerification(items[i]),
          ),
        ],
        // web: the error is only shown in the banner above; the list area just
        // falls back to the empty card.
        if (page.isLoading) ...[
          if (items.isNotEmpty) const SizedBox(height: 16),
          const AdminStateCard(text: 'Đang tải danh sách...', loading: true),
        ] else if (items.isEmpty)
          const AdminStateCard(text: 'Không tìm thấy nhà tuyển dụng phù hợp.'),
        const SizedBox(height: 16),
        AdminPager(
          total: page.valueOrNull?.total ?? 0,
          unit: 'nhà tuyển dụng',
          page: page.valueOrNull?.page ?? filter.page,
          totalPages: page.valueOrNull?.totalPages ?? 1,
          onPageChanged: filterNotifier.setPage,
        ),
      ],
    );
  }
}

class _EmployerCard extends StatelessWidget {
  const _EmployerCard({
    required this.employer,
    required this.updating,
    required this.disabled,
    required this.onToggle,
  });

  final AdminEmployerRow employer;
  final bool updating;
  final bool disabled;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final md = MediaQuery.sizeOf(context).width >= kAdminMdBreakpoint;
    final e = employer;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 8,
          runSpacing: 6,
          children: [
            Text(
              e.companyName.isEmpty ? 'Công ty chưa cập nhật' : e.companyName,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.ink),
            ),
            BoolBadge(
              value: e.isVerified,
              trueLabel: 'Đã xác minh',
              falseLabel: 'Chờ xác minh',
              trueTone: (AppColors.blue50, AppColors.blue700),
              falseTone: (AppColors.amber50, AppColors.amber700),
            ),
            BoolBadge(
              value: e.isActive,
              trueLabel: 'Tài khoản hoạt động',
              falseLabel: 'Tài khoản đã khóa',
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          '${e.email.isEmpty ? 'Chưa cập nhật email' : e.email} · ${(e.city ?? '').isEmpty ? 'Chưa cập nhật địa điểm' : e.city}',
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft),
        ),
        const SizedBox(height: 4),
        Text(
          'Người liên hệ: ${(e.contactName ?? '').isEmpty ? 'Chưa cập nhật' : e.contactName} · ID: ${e.id}',
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
        ),
      ],
    );

    final label = updating ? 'Đang xử lý...' : (e.isVerified ? 'Hủy xác minh' : 'Xác minh doanh nghiệp');
    final button = e.isVerified
        ? OutlinedButton(
            onPressed: disabled ? null : onToggle,
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.inkSoft,
              side: const BorderSide(color: AppColors.slate300),
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          )
        : ElevatedButton(
            onPressed: disabled ? null : onToggle,
            style: ElevatedButton.styleFrom(
              minimumSize: const Size(0, 42),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            child: Text(label),
          );

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: md
          ? Row(
              children: [
                Expanded(child: info),
                const SizedBox(width: 20),
                button,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [info, const SizedBox(height: 20), button],
            ),
    );
  }
}
