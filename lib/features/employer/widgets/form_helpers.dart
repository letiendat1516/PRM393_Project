import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

/// `<label class="mb-2 block font-semibold">` + control + hint / error.
class FieldBlock extends StatelessWidget {
  const FieldBlock({
    super.key,
    required this.label,
    required this.child,
    this.hint,
    this.error,
    this.required = false,
  });

  final String label;
  final Widget child;
  final String? hint;
  final String? error;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(
            text: label,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink),
            children: [
              if (required)
                const TextSpan(text: ' *', style: TextStyle(color: AppColors.red600)),
            ],
          ),
        ),
        const SizedBox(height: 8),
        child,
        if (error != null) ...[
          const SizedBox(height: 6),
          Text(error!, style: const TextStyle(fontSize: 12, color: AppColors.red600)),
        ] else if (hint != null) ...[
          const SizedBox(height: 6),
          Text(hint!, style: const TextStyle(fontSize: 12, color: AppColors.inkMuted)),
        ],
      ],
    );
  }
}

/// `grid gap-4 sm:grid-cols-2` — two equal columns from 640px, stacked below.
class TwoColumn extends StatelessWidget {
  const TwoColumn({super.key, required this.left, required this.right, this.gap = 16});
  final Widget left;
  final Widget right;
  final double gap;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        if (c.maxWidth < 560) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [left, SizedBox(height: gap), right],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: left),
            SizedBox(width: gap),
            Expanded(child: right),
          ],
        );
      },
    );
  }
}

/// Form card: rounded-2xl border bg-white p-6 shadow-sm, 20px rhythm.
class FormCard extends StatelessWidget {
  const FormCard({super.key, required this.children, this.padding = const EdgeInsets.all(24)});
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const SizedBox(height: 20),
            children[i],
          ],
        ],
      ),
    );
  }
}

/// Consistent dropdown used across the employer forms.
class AppDropdown<T> extends StatelessWidget {
  const AppDropdown({
    super.key,
    required this.value,
    required this.items,
    required this.labelOf,
    required this.onChanged,
    this.hint,
    this.enabled = true,
  });

  final T? value;
  final List<T> items;
  final String Function(T) labelOf;
  final ValueChanged<T?> onChanged;
  final String? hint;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      key: ValueKey(value),
      initialValue: value,
      isExpanded: true,
      onChanged: enabled ? onChanged : null,
      hint: hint == null ? null : Text(hint!),
      style: const TextStyle(fontSize: 14, color: AppColors.ink),
      items: [
        for (final it in items) DropdownMenuItem<T>(value: it, child: Text(labelOf(it))),
      ],
    );
  }
}
