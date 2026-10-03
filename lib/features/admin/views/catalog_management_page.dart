import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/failure.dart';
import '../viewmodels/admin_providers.dart';
import '../viewmodels/catalog_viewmodel.dart';
import '../widgets/admin_page_shell.dart';
import '../widgets/catalog_card.dart';

/// Quản lý ngành nghề và kỹ năng (/admin/catalog).
class CatalogManagementPage extends ConsumerWidget {
  const CatalogManagementPage({super.key});

  /// getErrorMessage(err, 'Không thể tải danh mục ngành nghề và kỹ năng.') —
  /// the real message when there is one, the fallback otherwise.
  static String? _loadError(Object? categoriesError, Object? skillsError) {
    final err = categoriesError ?? skillsError;
    if (err == null) return null;
    final f = Failure.from(err);
    return f.code == 'UNKNOWN' ? 'Không thể tải danh mục ngành nghề và kỹ năng.' : f.message;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(adminCategoriesProvider);
    final skills = ref.watch(adminSkillsProvider);
    final state = ref.watch(catalogNotifierProvider);
    final notifier = ref.read(catalogNotifierProvider.notifier);
    final lg = MediaQuery.sizeOf(context).width >= kAdminLgBreakpoint;

    final categoryCard = CatalogCard(
      title: 'Ngành nghề',
      countLabel: '${categories.valueOrNull?.length ?? 0} ngành',
      placeholder: 'Nhập ngành nghề mới',
      items: [
        for (final c in categories.valueOrNull ?? const [])
          CatalogItem(id: c.categoryId, name: c.name),
      ],
      loading: categories.isLoading && !categories.hasValue,
      loadingText: 'Đang tải ngành nghề...',
      emptyText: 'Chưa có ngành nghề nào.',
      saving: state.isSaving(CatalogKind.category),
      isRowBusy: (id) => state.isBusy(CatalogKind.category, id),
      onAdd: notifier.addCategory,
      onDelete: (it) async {
        final ok = await showConfirmDialog(
          context,
          message: 'Bạn có chắc muốn xoá ngành nghề "${it.name}" không?',
          confirmLabel: 'Xoá',
          danger: true,
        );
        if (ok && context.mounted) await notifier.deleteCategory(it.id, it.name);
      },
    );

    final skillCard = CatalogCard(
      title: 'Kỹ năng',
      countLabel: '${skills.valueOrNull?.length ?? 0} kỹ năng',
      placeholder: 'Nhập kỹ năng mới',
      items: [
        for (final s in skills.valueOrNull ?? const [])
          CatalogItem(id: s.skillId, name: s.skillName),
      ],
      loading: skills.isLoading && !skills.hasValue,
      loadingText: 'Đang tải kỹ năng...',
      emptyText: 'Chưa có kỹ năng nào.',
      saving: state.isSaving(CatalogKind.skill),
      isRowBusy: (id) => state.isBusy(CatalogKind.skill, id),
      onAdd: notifier.addSkill,
      onDelete: (it) async {
        final ok = await showConfirmDialog(
          context,
          message: 'Bạn có chắc muốn xoá kỹ năng "${it.name}" không?',
          confirmLabel: 'Xoá',
          danger: true,
        );
        if (ok && context.mounted) await notifier.deleteSkill(it.id, it.name);
      },
    );

    final loadError = _loadError(categories.error, skills.error);

    return AdminPageShell(
      children: [
        const AdminPageHeader(
          eyebrow: 'Quản lý danh mục',
          title: 'Quản lý ngành nghề và kỹ năng',
          subtitle:
              'Quản trị viên có thể thêm hoặc xoá ngành nghề, kỹ năng dùng trong tin tuyển dụng.',
        ),
        if (state.error != null || loadError != null) ...[
          const SizedBox(height: 24),
          AdminErrorBanner(
            title: 'Lỗi hệ thống',
            message: state.error ?? loadError!,
            onDismiss: state.error != null ? notifier.dismissError : null,
          ),
        ],
        if (state.message != null) ...[
          const SizedBox(height: 24),
          AdminSuccessBanner(message: state.message!, onDismiss: notifier.dismissMessage),
        ],
        const SizedBox(height: 32),
        if (lg)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: categoryCard),
              const SizedBox(width: 24),
              Expanded(child: skillCard),
            ],
          )
        else ...[
          categoryCard,
          const SizedBox(height: 24),
          skillCard,
        ],
      ],
    );
  }
}
