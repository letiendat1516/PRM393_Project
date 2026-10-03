import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/models/catalog_models.dart';
import '../viewmodels/employer_providers.dart';

/// "Ngành nghề": pick an existing category or type a new name (auto-created
/// on submit). Autocomplete over the live categories collection.
class CategoryField extends ConsumerWidget {
  const CategoryField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.selectedId,
    required this.onChanged,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String? selectedId;
  /// (categoryId, name) — id null when the name is new.
  final void Function(String? id, String name) onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cats = ref.watch(jobCategoriesProvider);
    final loading = cats.isLoading;
    final list = cats.valueOrNull ?? const <CategoryModel>[];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RawAutocomplete<CategoryModel>(
          textEditingController: controller,
          focusNode: focusNode,
          displayStringForOption: (c) => c.name,
          optionsBuilder: (v) {
            final q = v.text.trim().toLowerCase();
            if (q.isEmpty) return list.take(12);
            return list.where((c) => c.name.toLowerCase().contains(q)).take(12);
          },
          onSelected: (c) => onChanged(c.categoryId, c.name),
          fieldViewBuilder: (context, textCtrl, focus, onSubmit) => TextFormField(
            controller: textCtrl,
            focusNode: focus,
            enabled: !loading,
            onChanged: (text) {
              final exact = list.where((c) => c.name.toLowerCase() == text.trim().toLowerCase());
              onChanged(exact.isEmpty ? null : exact.first.categoryId, text);
            },
            onFieldSubmitted: (_) => onSubmit(),
            decoration: InputDecoration(
              hintText: loading ? 'Đang tải ngành nghề...' : 'Chọn ngành nghề',
              prefixIcon: const Icon(Icons.category_outlined, size: 18),
              suffixIcon: loading
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                  : Icon(
                      selectedId != null ? Icons.check_circle : Icons.arrow_drop_down,
                      color: selectedId != null ? AppColors.emerald600 : AppColors.inkMuted,
                    ),
            ),
          ),
          optionsViewBuilder: (context, onSelected, options) => Align(
            alignment: Alignment.topLeft,
            child: Material(
              elevation: 6,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240, maxWidth: 480),
                child: ListView.separated(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount: options.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final c = options.elementAt(i);
                    return ListTile(
                      dense: true,
                      title: Text(c.name, style: const TextStyle(fontSize: 14)),
                      trailing: c.jobCount > 0
                          ? Text('${c.jobCount} tin',
                              style: const TextStyle(fontSize: 12, color: AppColors.inkMuted))
                          : null,
                      onTap: () => onSelected(c),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 6),
        if (!loading && list.isEmpty)
          // CreateJobPage.jsx: `<p class="mt-1 text-xs text-red-600">` (verbatim),
          // followed by a muted note on the Flutter-only find-or-create path.
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Chưa có ngành nghề trong hệ thống. Quản trị viên cần thêm ngành nghề trước.',
                style: TextStyle(fontSize: 12, color: AppColors.red600),
              ),
              SizedBox(height: 2),
              Text(
                'Bạn vẫn có thể gõ tên ngành nghề mới — hệ thống sẽ tự tạo khi đăng tin.',
                style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
              ),
            ],
          )
        else if (selectedId == null && controller.text.trim().isNotEmpty)
          Text(
            'Ngành nghề "${controller.text.trim()}" chưa có — sẽ được tạo mới khi đăng tin.',
            style: const TextStyle(fontSize: 12, color: AppColors.amber700),
          )
        else
          const Text(
            'Chọn từ danh sách hoặc gõ tên ngành nghề mới.',
            style: TextStyle(fontSize: 12, color: AppColors.inkMuted),
          ),
      ],
    );
  }
}
