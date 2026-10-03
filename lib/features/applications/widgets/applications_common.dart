import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../shared/widgets/section.dart';

/// Tailwind breakpoints used by the application pages.
const double kBpSm = 640;
const double kBpMd = 768;
const double kBpLg = 1024;

/// `main.container-page py-12` (py-16 for loading/error shells).
class ApplicationsPageShell extends StatelessWidget {
  const ApplicationsPageShell({super.key, required this.child, this.verticalPadding = 48});
  final Widget child;
  final double verticalPadding;

  @override
  Widget build(BuildContext context) {
    return PageContainer(
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: verticalPadding),
        child: child,
      ),
    );
  }
}

/// eyebrow + h1 text-3xl font-bold + subtitle text-ink-soft.
class ApplicationsPageHeader extends StatelessWidget {
  const ApplicationsPageHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
  });
  final String eyebrow;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Eyebrow(label: eyebrow),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w700,
            color: AppColors.ink,
            letterSpacing: -0.5,
            height: 1.2,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 8),
          Text(subtitle!, style: const TextStyle(fontSize: 16, color: AppColors.inkSoft)),
        ],
      ],
    );
  }
}

/// `rounded-xl bg-red-50 p-4 text-red-700`.
class RedBanner extends StatelessWidget {
  const RedBanner({super.key, required this.message, this.padding = 16});
  final String message;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: AppColors.red50,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.red700, fontSize: 14)),
    );
  }
}

/// Soft tinted note (`rounded-xl bg-amber-50 p-3 text-sm`, primary-50, emerald-50).
class TintedNote extends StatelessWidget {
  const TintedNote({
    super.key,
    required this.child,
    this.background = AppColors.amber50,
    this.padding = 12,
  });
  final Widget child;
  final Color background;
  final double padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: DefaultTextStyle.merge(
        style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5),
        child: child,
      ),
    );
  }
}

/// `← ...` text-sm font-semibold text-primary back link.
class BackTextLink extends StatelessWidget {
  const BackTextLink({super.key, required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}

/// `<dl class="grid gap-4 text-sm sm:grid-cols-2">` — label (muted) over value.
class DefinitionGrid extends StatelessWidget {
  const DefinitionGrid({super.key, required this.items, this.columnsBreakpoint = kBpSm});

  /// (label, value widget). Use [DefinitionGrid.text] for plain strings.
  final List<(String, Widget)> items;
  final double columnsBreakpoint;

  static (String, Widget) text(String label, String value) => (
        label,
        Text(value, style: const TextStyle(fontSize: 14, color: AppColors.ink, height: 1.5)),
      );

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      final two = c.maxWidth >= columnsBreakpoint;
      final cellWidth = two ? (c.maxWidth - 16) / 2 : c.maxWidth;
      return Wrap(
        spacing: 16,
        runSpacing: 16,
        children: [
          for (final (label, value) in items)
            SizedBox(
              width: cellWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: const TextStyle(fontSize: 14, color: AppColors.inkMuted)),
                  const SizedBox(height: 2),
                  value,
                ],
              ),
            ),
        ],
      );
    });
  }
}

/// `.card p-6` heading: `h2 font-bold` (optionally text-lg).
class CardHeading extends StatelessWidget {
  const CardHeading(this.text, {super.key, this.large = false});
  final String text;
  final bool large;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: TextStyle(
          fontSize: large ? 18 : 16,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
      );
}

/// Web MyApplicationsPage pagination: `Trước` · static `Trang {page}` · `Sau`
/// (MyApplicationsPage.jsx:112 — no "/ totalPages").
class PrevNextPager extends StatelessWidget {
  const PrevNextPager({
    super.key,
    required this.page,
    required this.hasPrev,
    required this.hasNext,
    required this.onChanged,
  });
  final int page;
  final bool hasPrev;
  final bool hasNext;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        OutlinedButton(
          onPressed: hasPrev ? () => onChanged(page - 1) : null,
          child: const Text('Trước'),
        ),
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            'Trang $page',
            style: const TextStyle(fontSize: 14, color: AppColors.ink),
          ),
        ),
        OutlinedButton(
          onPressed: hasNext ? () => onChanged(page + 1) : null,
          child: const Text('Sau'),
        ),
      ],
    );
  }
}

/// `select.rounded-xl border p-3 text-sm` with a "Tất cả ..." placeholder.
class FilterDropdown<T> extends StatelessWidget {
  const FilterDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.onChanged,
    this.hint,
  });

  final T? value;

  /// (value, label) — a `null` value renders as the placeholder option.
  final List<(T?, String)> items;
  final ValueChanged<T?> onChanged;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    // Keyed on the value so external resets (e.g. "Xóa bộ lọc") re-sync the
    // form field, which otherwise only honours `initialValue` once.
    return KeyedSubtree(
      key: ValueKey<Object?>(value),
      child: DropdownButtonFormField<T?>(
        initialValue: value,
        isExpanded: true,
        decoration: InputDecoration(hintText: hint),
        style: const TextStyle(fontSize: 14, color: AppColors.ink),
        items: [
          for (final (v, label) in items)
            DropdownMenuItem<T?>(
              value: v,
              child: Text(label, overflow: TextOverflow.ellipsis),
            ),
        ],
        onChanged: onChanged,
      ),
    );
  }
}

/// `grid gap-3 rounded-2xl border bg-white p-4 md:grid-cols-N`.
class FilterBar extends StatelessWidget {
  const FilterBar({super.key, required this.children, this.columns = 3});
  final List<Widget> children;
  final int columns;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        border: Border.all(color: AppColors.border),
      ),
      child: LayoutBuilder(builder: (context, c) {
        final cols = c.maxWidth >= kBpMd ? columns : 1;
        final w = (c.maxWidth - 12 * (cols - 1)) / cols;
        return Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [for (final ch in children) SizedBox(width: w, child: ch)],
        );
      }),
    );
  }
}

/// Two-column `lg:grid-cols-[1.5fr_1fr]` that stacks under 1024px.
class MainAsideLayout extends StatelessWidget {
  const MainAsideLayout({super.key, required this.main, required this.aside, this.gap = 24});
  final Widget main;
  final Widget aside;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      if (c.maxWidth < kBpLg) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [main, SizedBox(height: gap), aside],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 3, child: main),
          SizedBox(width: gap),
          Expanded(flex: 2, child: aside),
        ],
      );
    });
  }
}
