import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import 'admin_page_shell.dart';

class CatalogItem {
  const CatalogItem({required this.id, required this.name});
  final String id;
  final String name;
}

/// One "Ngành nghề" / "Kỹ năng" card: header + count pill + inline add form +
/// scrollable list. Each row is name + 'Xoá' only — the web has no rename UI
/// and no per-row metadata.
class CatalogCard extends StatefulWidget {
  const CatalogCard({
    super.key,
    required this.title,
    required this.countLabel,
    required this.placeholder,
    required this.items,
    required this.loading,
    required this.loadingText,
    required this.emptyText,
    required this.saving,
    required this.onAdd,
    required this.onDelete,
    required this.isRowBusy,
  });

  final String title;
  final String countLabel;
  final String placeholder;
  final List<CatalogItem> items;
  final bool loading;
  final String loadingText;
  final String emptyText;
  final bool saving;
  final Future<bool> Function(String name) onAdd;
  final Future<void> Function(CatalogItem item) onDelete;
  final bool Function(String id) isRowBusy;

  @override
  State<CatalogCard> createState() => _CatalogCardState();
}

class _CatalogCardState extends State<CatalogCard> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (widget.saving) return;
    final ok = await widget.onAdd(_controller.text);
    if (ok && mounted) _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(widget.title,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700, color: AppColors.ink)),
              ),
              const SizedBox(width: 16),
              CountPill(label: widget.countLabel),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  enabled: !widget.saving,
                  maxLength: 100,
                  textInputAction: TextInputAction.done,
                  onSubmitted: (_) => _submit(),
                  decoration: InputDecoration(
                    hintText: widget.placeholder,
                    counterText: '',
                    fillColor: widget.saving ? AppColors.slate100 : AppColors.surface,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: widget.saving ? null : _submit,
                child: Text(widget.saving ? 'Đang thêm...' : 'Thêm'),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildList(),
        ],
      ),
    );
  }

  /// Load errors are reported by the page banner; the list simply shows the
  /// loading / empty line like the web.
  Widget _buildList() {
    const muted = TextStyle(fontSize: 14, color: AppColors.inkMuted);
    if (widget.loading) return Text(widget.loadingText, style: muted);
    if (widget.items.isEmpty) return Text(widget.emptyText, style: muted);

    return ConstrainedBox(
      constraints: const BoxConstraints(maxHeight: 520),
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.only(right: 4),
        itemCount: widget.items.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, i) {
          final it = widget.items[i];
          final busy = widget.isRowBusy(it.id);
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(AppRadius.lg),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(it.name,
                      style: const TextStyle(
                          fontSize: 14, color: AppColors.ink, fontWeight: FontWeight.w500)),
                ),
                const SizedBox(width: 12),
                TextButton(
                  onPressed: busy ? null : () => widget.onDelete(it),
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.red600,
                    disabledForegroundColor: AppColors.red600.withValues(alpha: 0.5),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    minimumSize: Size.zero,
                    textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                  ),
                  child: Text(busy ? 'Đang xoá...' : 'Xoá'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
