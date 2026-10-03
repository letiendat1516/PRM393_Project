import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/enums.dart';
import 'auth_buttons.dart';

/// Section heading in RegisterEmployerPage:
/// `text-sm font-semibold uppercase tracking-wide text-ink-muted`.
class FormSectionEyebrow extends StatelessWidget {
  const FormSectionEyebrow(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.8,
        color: AppColors.inkMuted,
      ),
    );
  }
}

/// `border-t border-slate-100 pt-6` section divider.
class FormSectionDivider extends StatelessWidget {
  const FormSectionDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24, bottom: 24),
      child: Divider(color: AppColors.borderMuted, height: 1),
    );
  }
}

/// Field.jsx label: `text-sm font-medium text-ink-soft` + primary `*`.
class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(
          text: text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.inkSoft,
          ),
          children: [
            if (required)
              const TextSpan(
                text: ' *',
                style: TextStyle(color: AppColors.primary),
              ),
          ],
        ),
      ),
    );
  }
}

/// Field.jsx / SelectField.jsx layout: the static [FieldLabel] sits ABOVE the
/// input and the input itself only carries the web placeholder (no Material
/// floating `labelText`). Every field on Login / Register / RegisterEmployer
/// is `required` on the web, hence the default.
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.child,
    this.required = true,
  });

  final String label;
  final Widget child;
  final bool required;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(label, required: required),
        child,
      ],
    );
  }
}

/// `mt-1.5 text-xs text-red-600` inline error line.
class FieldErrorText extends StatelessWidget {
  const FieldErrorText(this.message, {super.key});
  final String? message;

  @override
  Widget build(BuildContext context) {
    if (message == null || message!.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Text(
        message!,
        style: const TextStyle(fontSize: 12, color: AppColors.red600),
      ),
    );
  }
}

/// RegisterEmployerPage gender toggle pair (Nam / Nữ):
/// active = `border-primary bg-primary-50 text-primary ring-2 ring-primary/20`.
class GenderPicker extends StatelessWidget {
  const GenderPicker({
    super.key,
    required this.value,
    required this.onChanged,
    this.error,
    this.enabled = true,
  });

  final Gender? value;
  final ValueChanged<Gender> onChanged;
  final String? error;
  final bool enabled;

  static const options = [Gender.male, Gender.female];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Giới tính', required: true),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 12),
              Expanded(
                child: _GenderButton(
                  label: options[i].label,
                  active: value == options[i],
                  onTap: enabled ? () => onChanged(options[i]) : null,
                ),
              ),
            ],
          ],
        ),
        FieldErrorText(error),
      ],
    );
  }
}

class _GenderButton extends StatefulWidget {
  const _GenderButton({required this.label, required this.active, this.onTap});
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  State<_GenderButton> createState() => _GenderButtonState();
}

class _GenderButtonState extends State<_GenderButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final active = widget.active;
    final borderColor = active
        ? AppColors.primary
        : (_hover ? AppColors.primary.withValues(alpha: 0.5) : AppColors.border);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Semantics(
        button: true,
        selected: active,
        label: widget.label,
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary50 : AppColors.surface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: borderColor),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Text(
              widget.label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: active ? AppColors.primary : AppColors.inkSoft,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// components/auth/Checkbox.jsx — 16px checkbox + `text-sm leading-5
/// text-ink-soft` label (rich) + optional `text-xs text-ink-muted` hint.
class AuthCheckbox extends StatelessWidget {
  const AuthCheckbox({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.hint,
    this.enabled = true,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  });

  final bool value;
  final ValueChanged<bool> onChanged;
  final InlineSpan label;
  final String? hint;
  final bool enabled;
  final CrossAxisAlignment crossAxisAlignment;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: enabled ? SystemMouseCursors.click : MouseCursor.defer,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? () => onChanged(!value) : null,
        child: Row(
          crossAxisAlignment: crossAxisAlignment,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: crossAxisAlignment == CrossAxisAlignment.start ? 2 : 0,
              ),
              child: SizedBox(
                width: 18,
                height: 18,
                child: Checkbox(
                  value: value,
                  onChanged: enabled ? (v) => onChanged(v ?? false) : null,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  visualDensity: VisualDensity.compact,
                  activeColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.slate300, width: 1.2),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text.rich(
                    label,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  if (hint != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      hint!,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// RegisterPage employer callout:
/// `rounded-xl border border-primary/20 bg-primary-50/60 px-4 py-3 text-center`
/// "Bạn là **nhà tuyển dụng**? Đăng ký tại đây".
class EmployerCallout extends StatelessWidget {
  const EmployerCallout({super.key, required this.route});
  final String route;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary50.withValues(alpha: 0.6),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        borderRadius: BorderRadius.circular(AppRadius.xl),
      ),
      child: Wrap(
        alignment: WrapAlignment.center,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 4,
        children: [
          const Text.rich(
            TextSpan(
              text: 'Bạn là ',
              style: TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
              children: [
                TextSpan(
                  text: 'nhà tuyển dụng',
                  style: TextStyle(fontWeight: FontWeight.w600, color: AppColors.ink),
                ),
                TextSpan(text: '?'),
              ],
            ),
          ),
          AuthLink(text: 'Đăng ký tại đây', route: route),
        ],
      ),
    );
  }
}
