import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';

/// `btn-primary w-full py-3`: full-width primary CTA with trailing
/// `arrowRight` icon; while submitting the label swaps and the icon hides.
class AuthSubmitButton extends StatelessWidget {
  const AuthSubmitButton({
    super.key,
    required this.label,
    required this.loadingLabel,
    required this.submitting,
    required this.onPressed,
    this.icon = Icons.arrow_forward,
  });

  final String label;
  final String loadingLabel;
  final bool submitting;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: submitting ? null : onPressed,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.6),
          disabledForegroundColor: Colors.white,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (submitting) ...[
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              const SizedBox(width: 10),
            ],
            Text(submitting ? loadingLabel : label),
            if (!submitting && icon != null) ...[
              const SizedBox(width: 8),
              Icon(icon, size: 18),
            ],
          ],
        ),
      ),
    );
  }
}

/// `font-semibold text-primary hover:underline` inline link.
class AuthLink extends StatefulWidget {
  const AuthLink({
    super.key,
    required this.text,
    this.route,
    this.onTap,
    this.fontSize = 14,
    this.fontWeight = FontWeight.w600,
  });

  final String text;
  final String? route;
  final VoidCallback? onTap;
  final double fontSize;
  final FontWeight fontWeight;

  @override
  State<AuthLink> createState() => _AuthLinkState();
}

class _AuthLinkState extends State<AuthLink> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap ??
            (widget.route == null ? null : () => context.go(widget.route!)),
        child: Text(
          widget.text,
          style: TextStyle(
            color: AppColors.primary,
            fontSize: widget.fontSize,
            fontWeight: widget.fontWeight,
            decoration: _hover ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.primary,
          ),
        ),
      ),
    );
  }
}

/// AuthShell footer line: "Đã có tài khoản? Đăng nhập".
class AuthFooterText extends StatelessWidget {
  const AuthFooterText({
    super.key,
    required this.prefix,
    required this.linkText,
    required this.route,
  });

  final String prefix;
  final String linkText;
  final String route;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      spacing: 4,
      children: [
        Text(
          prefix,
          style: const TextStyle(fontSize: 14, color: AppColors.inkSoft, height: 1.5),
        ),
        AuthLink(text: linkText, route: route),
      ],
    );
  }
}
