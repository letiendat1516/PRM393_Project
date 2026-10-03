import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/public_layout.dart';

/// Breakpoints shared by the admin pages (web md/lg).
const double kAdminMdBreakpoint = 768;
const double kAdminLgBreakpoint = 1024;

/// `main.mx-auto.max-w-*.px-6.py-28` inside PublicLayout (navbar + footer).
class AdminPageShell extends StatelessWidget {
  const AdminPageShell({
    super.key,
    required this.children,
    this.maxWidth = 1152,
    this.scrollable = true,
  });

  final List<Widget> children;
  final double maxWidth;
  /// false → caller provides its own scroll view (e.g. a big ListView).
  final bool scrollable;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final horizontal = width >= 1024 ? 32.0 : (width >= 640 ? 24.0 : 16.0);
    final body = Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        ),
      ),
    );
    return PublicLayout(scrollable: scrollable, child: body);
  }
}

/// Optional eyebrow (uppercase blue-700) + H1 + subtitle, optional trailing
/// action. The AI pages (AiLogs / AiStats) have no eyebrow on the web.
class AdminPageHeader extends StatelessWidget {
  const AdminPageHeader({
    super.key,
    this.eyebrow,
    required this.title,
    this.subtitle,
    this.titleIcon,
    this.trailing,
  });

  final String? eyebrow;
  final String title;
  final String? subtitle;
  final IconData? titleIcon;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= kAdminMdBreakpoint;
    final text = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[
          Text(
            eyebrow!.toUpperCase(),
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: AppColors.blue700,
            ),
          ),
          const SizedBox(height: 8),
        ],
        Row(
          children: [
            if (titleIcon != null) ...[
              Icon(titleIcon, size: 28, color: AppColors.primary),
              const SizedBox(width: 8),
            ],
            Flexible(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: wide ? 30 : 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.ink,
                  letterSpacing: -0.4,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(color: AppColors.inkMuted, fontSize: 15, height: 1.5)),
        ],
      ],
    );
    if (trailing == null) return text;
    if (!wide) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [text, const SizedBox(height: 12), trailing!],
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [Expanded(child: text), const SizedBox(width: 16), trailing!],
    );
  }
}

/// `rounded-xl border-red-200 bg-red-50 p-4 text-red-700` (+ optional bold title).
class AdminErrorBanner extends StatelessWidget {
  const AdminErrorBanner({super.key, required this.message, this.title, this.onDismiss});
  final String message;
  final String? title;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.red50,
        border: Border.all(color: AppColors.dangerBorder),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null) ...[
                  Text(title!,
                      style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.red700)),
                  const SizedBox(height: 4),
                ],
                Text(message,
                    style: const TextStyle(color: AppColors.red700, fontSize: 14, height: 1.5)),
              ],
            ),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18, color: AppColors.red700),
              tooltip: 'Đóng',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// `rounded-xl border-green-200 bg-green-50 p-4 text-green-700`.
class AdminSuccessBanner extends StatelessWidget {
  const AdminSuccessBanner({super.key, required this.message, this.onDismiss});
  final String message;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.green50,
        border: Border.all(color: AppColors.secondary200),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, size: 18, color: AppColors.emerald700),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.emerald700, fontSize: 14, height: 1.5)),
          ),
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, size: 18, color: AppColors.emerald700),
              tooltip: 'Đóng',
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

/// White rounded card used for the loading / empty text states
/// (`rounded-2xl border bg-white p-8 text-center text-slate-500`).
class AdminStateCard extends StatelessWidget {
  const AdminStateCard({
    super.key,
    required this.text,
    this.center = true,
    this.loading = false,
    this.padding = const EdgeInsets.all(32),
  });

  final String text;
  final bool center;
  final bool loading;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final label = Text(
      text,
      textAlign: center ? TextAlign.center : TextAlign.start,
      style: const TextStyle(color: AppColors.inkMuted, fontSize: 14),
    );
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
      ),
      child: loading
          ? Row(
              mainAxisAlignment: center ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                const SizedBox(
                    width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                const SizedBox(width: 12),
                Flexible(child: label),
              ],
            )
          : label,
    );
  }
}

/// `{total} <unit>` · "Trước" / "Trang x/y" / "Sau".
class AdminPager extends StatelessWidget {
  const AdminPager({
    super.key,
    required this.total,
    required this.unit,
    required this.page,
    required this.totalPages,
    required this.onPageChanged,
  });

  final int total;
  final String unit;
  final int page;
  final int totalPages;
  final ValueChanged<int> onPageChanged;

  @override
  Widget build(BuildContext context) {
    const muted = TextStyle(color: AppColors.inkMuted, fontSize: 14);
    return Row(
      children: [
        Expanded(child: Text('$total $unit', style: muted)),
        _PagerButton(label: 'Trước', onTap: page > 1 ? () => onPageChanged(page - 1) : null),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Text('Trang $page/$totalPages', style: muted),
        ),
        _PagerButton(
            label: 'Sau', onTap: page < totalPages ? () => onPageChanged(page + 1) : null),
      ],
    );
  }
}

class _PagerButton extends StatelessWidget {
  const _PagerButton({required this.label, this.onTap});
  final String label;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.4 : 1,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, 38),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
        child: Text(label),
      ),
    );
  }
}

/// window.confirm(...) port — returns true when confirmed.
Future<bool> showConfirmDialog(
  BuildContext context, {
  required String message,
  String? title,
  String confirmLabel = 'OK',
  String cancelLabel = 'Huỷ',
  bool danger = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.x2l)),
      title: title == null ? null : Text(title),
      content: Text(message, style: const TextStyle(height: 1.5)),
      actions: [
        TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(cancelLabel)),
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(true),
          style: danger
              ? ElevatedButton.styleFrom(backgroundColor: AppColors.red600)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// Small count pill `rounded-full bg-slate-100 px-3 py-1 text-xs font-semibold`.
class CountPill extends StatelessWidget {
  const CountPill({super.key, required this.label, this.bg = AppColors.slate100, this.fg = AppColors.inkSoft});
  final String label;
  final Color bg;
  final Color fg;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(AppRadius.pill)),
        child: Text(label, style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600)),
      );
}

/// Filter pill (tabs on AdminUsers, task filter on AiLogs).
class FilterPill extends StatelessWidget {
  const FilterPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.compact = false,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? AppColors.primary : (compact ? AppColors.slate100 : AppColors.surface),
      borderRadius: BorderRadius.circular(compact ? AppRadius.pill : AppRadius.lg),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(compact ? AppRadius.pill : AppRadius.lg),
        child: Container(
          padding: compact
              ? const EdgeInsets.symmetric(horizontal: 12, vertical: 5)
              : const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(compact ? AppRadius.pill : AppRadius.lg),
            border: selected || compact ? null : Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: compact ? 12 : 14,
              fontWeight: compact ? FontWeight.w500 : FontWeight.w600,
              color: selected ? Colors.white : AppColors.inkSoft,
            ),
          ),
        ),
      ),
    );
  }
}
