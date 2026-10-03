import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import '../../../core/utils/failure.dart';
import '../../../shared/widgets/application_status_badge.dart';
import '../viewmodels/admin_mutation_notifier.dart';
import '../viewmodels/admin_providers.dart';
import '../viewmodels/admin_users_viewmodel.dart';
import '../widgets/admin_page_shell.dart';

/// UC-17 — Quản lý người dùng (/admin/users).
class AdminUsersPage extends ConsumerStatefulWidget {
  const AdminUsersPage({super.key});

  @override
  ConsumerState<AdminUsersPage> createState() => _AdminUsersPageState();
}

class _AdminUsersPageState extends ConsumerState<AdminUsersPage> {
  final _keyword = TextEditingController();

  static const _accountTypes = [
    (UserRole.jobSeeker, 'Ứng viên'),
    (UserRole.employer, 'Nhà tuyển dụng'),
  ];

  @override
  void dispose() {
    _keyword.dispose();
    super.dispose();
  }

  void _submitSearch() =>
      ref.read(adminUsersFilterProvider.notifier).submitKeyword(_keyword.text);

  Future<void> _toggleStatus(AdminAccountRow row) async {
    final label = row.isActive ? 'khóa' : 'kích hoạt';
    final ok = await showConfirmDialog(
      context,
      message: 'Bạn có chắc muốn $label tài khoản này?',
      confirmLabel: row.isActive ? 'Khóa' : 'Kích hoạt',
      danger: row.isActive,
    );
    // the page may have been disposed (role/auth redirect) while the dialog was open
    if (!ok || !mounted) return;
    final repo = ref.read(adminRepositoryProvider);
    await ref.read(adminUsersMutationProvider.notifier).run(
          row.id,
          () => repo.setAccountActive(uid: row.id, role: row.role, active: !row.isActive),
          fallbackMessage: 'Không thể $label tài khoản.',
        );
  }

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(adminUsersFilterProvider);
    final filterNotifier = ref.read(adminUsersFilterProvider.notifier);
    final page = ref.watch(adminUsersPageProvider);
    final mutation = ref.watch(adminUsersMutationProvider);
    final width = MediaQuery.sizeOf(context).width;
    final md = width >= kAdminMdBreakpoint;
    final table = width >= 900;

    final errorText = mutation.error ??
        (page.hasError ? Failure.from(page.error!).message : null);

    return AdminPageShell(
      maxWidth: 1280,
      children: [
        const AdminPageHeader(
          eyebrow: 'UC-17',
          title: 'Quản lý người dùng',
          subtitle:
              'Theo dõi và khóa hoặc kích hoạt tài khoản. Việc xác minh nhà tuyển dụng được quản lý riêng.',
        ),
        const SizedBox(height: 32),
        Semantics(
          label: 'Loại tài khoản',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (role, label) in _accountTypes)
                FilterPill(
                  label: label,
                  selected: filter.role == role,
                  onTap: () => filterNotifier.setRole(role),
                ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        _FilterCard(
          wide: md,
          keyword: TextField(
            controller: _keyword,
            maxLength: 100,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _submitSearch(),
            decoration: const InputDecoration(
              hintText: 'Tìm theo tên hoặc email',
              counterText: '',
              prefixIcon: Icon(Icons.search, size: 20),
            ),
          ),
          status: DropdownButtonFormField<AccountStatusFilter>(
            initialValue: filter.status,
            isExpanded: true,
            items: [
              for (final s in AccountStatusFilter.values)
                DropdownMenuItem(value: s, child: Text(s.label)),
            ],
            onChanged: (v) {
              if (v != null) filterNotifier.setStatus(v);
            },
          ),
          submit: ElevatedButton(onPressed: _submitSearch, child: const Text('Tìm kiếm')),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 20),
          AdminErrorBanner(
            message: errorText,
            onDismiss: mutation.error != null
                ? () => ref.read(adminUsersMutationProvider.notifier).clearError()
                : null,
          ),
        ],
        const SizedBox(height: 20),
        _TableCard(
          page: page,
          table: table,
          mutation: mutation,
          onToggle: _toggleStatus,
        ),
        const SizedBox(height: 16),
        AdminPager(
          total: page.valueOrNull?.total ?? 0,
          unit: 'tài khoản',
          page: page.valueOrNull?.page ?? filter.page,
          totalPages: page.valueOrNull?.totalPages ?? 1,
          onPageChanged: filterNotifier.setPage,
        ),
      ],
    );
  }
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.wide,
    required this.keyword,
    required this.status,
    required this.submit,
  });
  final bool wide;
  final Widget keyword;
  final Widget status;
  final Widget submit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: wide
          ? Row(
              children: [
                Expanded(child: keyword),
                const SizedBox(width: 12),
                SizedBox(width: 220, child: status),
                const SizedBox(width: 12),
                submit,
              ],
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [keyword, const SizedBox(height: 12), status, const SizedBox(height: 12), submit],
            ),
    );
  }
}

class _TableCard extends StatelessWidget {
  const _TableCard({
    required this.page,
    required this.table,
    required this.mutation,
    required this.onToggle,
  });

  final AsyncValue<PagedResult<AdminAccountRow>> page;
  final bool table;
  final AdminMutationState mutation;
  final Future<void> Function(AdminAccountRow) onToggle;

  @override
  Widget build(BuildContext context) {
    final items = page.valueOrNull?.items ?? const <AdminAccountRow>[];
    const stateStyle = TextStyle(color: AppColors.inkMuted, fontSize: 14);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (table) const _HeaderRow(),
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0 || table) const Divider(height: 1),
            table
                ? _TableRow(row: items[i], mutation: mutation, onToggle: onToggle)
                : _MobileRow(row: items[i], mutation: mutation, onToggle: onToggle),
          ],
          // web: the error is only shown in the banner above; the table just
          // falls back to the empty text.
          if (page.isLoading)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Đang tải danh sách...', textAlign: TextAlign.center, style: stateStyle),
            )
          else if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text('Không tìm thấy tài khoản phù hợp.',
                  textAlign: TextAlign.center, style: stateStyle),
            ),
        ],
      ),
    );
  }
}

const _flexAccount = 4;
const _flexContact = 4;
const _flexStatus = 2;
const _flexAction = 3;

class _HeaderRow extends StatelessWidget {
  const _HeaderRow();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.inkSoft);
    return Container(
      color: AppColors.slate50,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: const Row(
        children: [
          Expanded(flex: _flexAccount, child: Text('Tài khoản', style: style)),
          Expanded(flex: _flexContact, child: Text('Liên hệ', style: style)),
          Expanded(flex: _flexStatus, child: Text('Trạng thái', style: style)),
          Expanded(
              flex: _flexAction,
              child: Text('Thao tác', style: style, textAlign: TextAlign.right)),
        ],
      ),
    );
  }
}

class _TableRow extends StatelessWidget {
  const _TableRow({required this.row, required this.mutation, required this.onToggle});
  final AdminAccountRow row;
  final AdminMutationState mutation;
  final Future<void> Function(AdminAccountRow) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          Expanded(flex: _flexAccount, child: _AccountCell(row: row)),
          Expanded(flex: _flexContact, child: _ContactCell(row: row)),
          Expanded(
            flex: _flexStatus,
            child: Align(alignment: Alignment.centerLeft, child: _StatusBadge(active: row.isActive)),
          ),
          Expanded(
            flex: _flexAction,
            child: Align(
              alignment: Alignment.centerRight,
              child: _ActionButton(
                active: row.isActive,
                updating: mutation.isUpdating(row.id),
                disabled: mutation.busy,
                onPressed: () => onToggle(row),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MobileRow extends StatelessWidget {
  const _MobileRow({required this.row, required this.mutation, required this.onToggle});
  final AdminAccountRow row;
  final AdminMutationState mutation;
  final Future<void> Function(AdminAccountRow) onToggle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _AccountCell(row: row)),
              const SizedBox(width: 12),
              _StatusBadge(active: row.isActive),
            ],
          ),
          const SizedBox(height: 10),
          _ContactCell(row: row),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: _ActionButton(
              active: row.isActive,
              updating: mutation.isUpdating(row.id),
              disabled: mutation.busy,
              onPressed: () => onToggle(row),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountCell extends StatelessWidget {
  const _AccountCell({required this.row});
  final AdminAccountRow row;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.name.isEmpty ? 'Chưa cập nhật tên' : row.name,
              style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink, fontSize: 14)),
          const SizedBox(height: 4),
          Text('ID: ${row.id}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
      );
}

class _ContactCell extends StatelessWidget {
  const _ContactCell({required this.row});
  final AdminAccountRow row;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(row.email,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14, color: AppColors.inkSoft)),
          const SizedBox(height: 4),
          Text(
            (row.city ?? '').isEmpty ? 'Chưa cập nhật địa điểm' : row.city!,
            style: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
        ],
      );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) =>
      BoolBadge(value: active, trueLabel: 'Đang hoạt động', falseLabel: 'Đã khóa');
}

/// Lock (outlined danger) / activate (solid emerald) — 'Đang xử lý...' while
/// this row is updating.
class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.active,
    required this.updating,
    required this.disabled,
    required this.onPressed,
  });
  final bool active;
  final bool updating;
  final bool disabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = updating ? 'Đang xử lý...' : (active ? 'Khóa tài khoản' : 'Kích hoạt');
    final onTap = disabled ? null : onPressed;
    const shape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)));
    const padding = EdgeInsets.symmetric(horizontal: 16, vertical: 10);
    const textStyle = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

    if (active) {
      return OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.red700,
          side: const BorderSide(color: AppColors.dangerBorder),
          backgroundColor: AppColors.surface,
          minimumSize: const Size(0, 40),
          padding: padding,
          shape: shape,
          textStyle: textStyle,
        ),
        child: Text(label),
      );
    }
    return ElevatedButton(
      onPressed: onTap,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald600,
        disabledBackgroundColor: AppColors.emerald600.withValues(alpha: 0.5),
        minimumSize: const Size(0, 40),
        padding: padding,
        shape: shape,
        textStyle: textStyle,
      ),
      child: Text(label),
    );
  }
}
