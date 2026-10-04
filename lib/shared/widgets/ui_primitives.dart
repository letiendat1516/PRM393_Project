import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/failure.dart';
import '../../core/utils/formatters.dart';
import '../models/recommendation_models.dart';

/// `.card` — rounded-2xl border slate-100 bg-white shadow-card.
class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.onTap,
    this.hoverLift = false,
    this.borderColor,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool hoverLift;
  final Color? borderColor;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    // Theme-aware defaults so AppTheme.dark() renders cards correctly
    // (light theme resolves to the exact Tailwind tokens: white / slate-100).
    final theme = Theme.of(context);
    final bg = color ?? theme.cardColor;
    final border = borderColor ?? theme.dividerColor;
    // Wrap the child content in a transparent Material so any ListTile /
    // RadioListTile / SwitchListTile placed inside the card has a
    // Material ancestor for ink splashes. Without this, Flutter asserts
    // "ListTile background color or ink splashes may be invisible" each
    // build because the Container's BoxDecoration sits between the tile
    // and the next Material up the tree.
    final inner = Material(
      type: MaterialType.transparency,
      child: Padding(padding: padding, child: child),
    );
    final box = Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppRadius.x2l),
        border: Border.all(color: border),
        boxShadow: AppShadows.card,
      ),
      child: inner,
    );
    if (onTap == null && !hoverLift) return box;
    return _Hoverable(
      lift: hoverLift,
      onTap: onTap,
      builder: (hover) => AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        transform: Matrix4.translationValues(0, hover && hoverLift ? -3 : 0, 0),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppRadius.x2l),
          border: Border.all(color: hover ? AppColors.primary100 : border),
          boxShadow: hover ? AppShadows.elevated : AppShadows.card,
        ),
        child: inner,
      ),
    );
  }
}

class _Hoverable extends StatefulWidget {
  const _Hoverable({required this.builder, this.onTap, this.lift = false});
  final Widget Function(bool hover) builder;
  final VoidCallback? onTap;
  final bool lift;
  @override
  State<_Hoverable> createState() => _HoverableState();
}

class _HoverableState extends State<_Hoverable> {
  bool _hover = false;
  @override
  Widget build(BuildContext context) => MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        cursor: widget.onTap != null ? SystemMouseCursors.click : MouseCursor.defer,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: widget.builder(_hover),
        ),
      );
}

/// Company monogram tile (jobMapper createCompanyDisplay) or logo image.
class CompanyLogoTile extends StatelessWidget {
  const CompanyLogoTile({
    super.key,
    required this.name,
    this.logoUrl,
    this.size = 56,
    this.radius = 12,
    this.brand,
  });

  final String name;
  final String? logoUrl;
  final double size;
  final double radius;
  /// Optional Tailwind brand string from mock data ('bg-orange-50 text-orange-600').
  final String? brand;

  @override
  Widget build(BuildContext context) {
    final display = CompanyDisplay.of(name);
    final (bg, fg) = brand != null
        ? CompanyPalette.fromTailwind(brand)
        : CompanyPalette.at(display.paletteIndex);
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(radius)),
      alignment: Alignment.center,
      child: (logoUrl != null && logoUrl!.isNotEmpty)
          ? Image.network(
              logoUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => _text(display.initials, fg),
            )
          : _text(display.initials, fg),
    );
  }

  Widget _text(String s, Color fg) => Text(
        s,
        style: TextStyle(color: fg, fontWeight: FontWeight.w800, fontSize: size * 0.3),
      );
}

/// AIScoreModal ScoreBadge: colour by match_score/10 (≥8 green, ≥6 primary,
/// ≥4 amber, else slate). `size` 36 (list) or 44 (modal).
class ScoreBadge extends StatelessWidget {
  const ScoreBadge({super.key, required this.score, this.size = 36, this.showSuffix = false});
  final JobScore score;
  final double size;
  final bool showSuffix;

  static Color colorFor(int matchScore) {
    final s = matchScore / 10;
    if (s >= 8) return AppColors.green500;
    if (s >= 6) return AppColors.primary;
    if (s >= 4) return AppColors.amber500;
    return AppColors.slate400;
  }

  @override
  Widget build(BuildContext context) {
    final value = score.scoreOutOf10;
    final label = value == value.roundToDouble() ? value.toInt().toString() : value.toStringAsFixed(1);
    return Tooltip(
      message: 'Điểm phù hợp ${score.matchScore}/100 (${score.source.toUpperCase()})',
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorFor(score.matchScore),
          borderRadius: BorderRadius.circular(size >= 44 ? 14 : 10),
        ),
        alignment: Alignment.center,
        child: Text(
          showSuffix ? '$label/10' : label,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: size >= 44 ? 14 : 12,
          ),
        ),
      ),
    );
  }
}

/// usePasswordField + Field: obscure toggle with 'Ẩn mật khẩu' / 'Hiện mật khẩu'.
class PasswordField extends StatefulWidget {
  const PasswordField({
    super.key,
    required this.controller,
    this.label = 'Mật khẩu',
    this.hint,
    this.validator,
    this.textInputAction,
    this.onFieldSubmitted,
    this.autofillHints,
    this.enabled = true,
    this.onChanged,
    this.floatingLabel = true,
    this.errorText,
  });

  /// Server-side field error (Field.jsx `error` prop) shown under the input.
  final String? errorText;

  final TextEditingController controller;
  final String label;
  final String? hint;
  final String? Function(String?)? validator;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final Iterable<String>? autofillHints;
  final bool enabled;
  final ValueChanged<String>? onChanged;

  /// false → no Material `labelText`; the caller renders a static label above
  /// the input (web `Field.jsx` layout) and only the placeholder is shown.
  final bool floatingLabel;

  @override
  State<PasswordField> createState() => _PasswordFieldState();
}

class _PasswordFieldState extends State<PasswordField> {
  bool _hidden = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _hidden,
      validator: widget.validator,
      textInputAction: widget.textInputAction,
      onFieldSubmitted: widget.onFieldSubmitted,
      autofillHints: widget.autofillHints,
      enabled: widget.enabled,
      onChanged: widget.onChanged,
      decoration: InputDecoration(
        labelText: widget.floatingLabel ? widget.label : null,
        hintText: widget.hint,
        errorText: widget.errorText,
        prefixIcon: const Icon(Icons.lock_outline, size: 20),
        suffixIcon: IconButton(
          tooltip: _hidden ? 'Hiện mật khẩu' : 'Ẩn mật khẩu',
          icon: Icon(_hidden ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
          onPressed: () => setState(() => _hidden = !_hidden),
        ),
      ),
    );
  }
}

/// components/auth/AlertError.jsx — red banner.
class AlertError extends StatelessWidget {
  const AlertError({super.key, required this.message, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.dangerBg,
        border: Border.all(color: AppColors.dangerBorder),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.dangerText, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(message, style: const TextStyle(color: AppColors.dangerText, fontSize: 13)),
          ),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Thử lại')),
        ],
      ),
    );
  }
}

/// JobsPage status banners (blue loading / amber error).
class InfoBanner extends StatelessWidget {
  const InfoBanner({super.key, required this.message, this.tone = InfoTone.info, this.icon});
  final String message;
  final InfoTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final (bg, border, fg) = switch (tone) {
      InfoTone.info => (AppColors.blue50, AppColors.blue100, AppColors.blue700),
      InfoTone.warning => (AppColors.amber50, AppColors.amber200, AppColors.amber700),
      InfoTone.success => (AppColors.emerald50, AppColors.emerald100, AppColors.emerald700),
      InfoTone.primary => (AppColors.primary50, AppColors.primary100, AppColors.primary),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(color: border),
        borderRadius: BorderRadius.circular(AppRadius.lg),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: fg), const SizedBox(width: 8)],
          Expanded(child: Text(message, style: TextStyle(color: fg, fontSize: 13, height: 1.5))),
        ],
      ),
    );
  }
}

enum InfoTone { info, warning, success, primary }

/// components/ErrorBoundary.jsx fallback: eyebrow 'Đã xảy ra lỗi', h1
/// 'Trang này gặp sự cố', 'Vui lòng tải lại trang hoặc quay lại sau.',
/// button 'Tải lại trang'.
class RouteErrorView extends StatelessWidget {
  const RouteErrorView({super.key, this.error, this.onRetry, this.compact = false});
  final Object? error;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final message = error == null ? null : Failure.from(error!).message;
    return Center(
      child: Padding(
        padding: EdgeInsets.all(compact ? 24 : 48),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.red50,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: const Text('ĐÃ XẢY RA LỖI',
                    style: TextStyle(
                        color: AppColors.red700,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2)),
              ),
              const SizedBox(height: 16),
              Text('Trang này gặp sự cố',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              Text(
                message ?? 'Vui lòng tải lại trang hoặc quay lại sau.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.6),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh, size: 18),
                  label: const Text('Tải lại trang'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// RouteLoader — full-screen centered spinner.
class RouteLoader extends StatelessWidget {
  const RouteLoader({super.key, this.label});
  final String? label;
  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(width: 36, height: 36, child: CircularProgressIndicator(strokeWidth: 3)),
            if (label != null) ...[
              const SizedBox(height: 12),
              Text(label!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
            ],
          ],
        ),
      );
}

/// Breadcrumb "Trang chủ / Việc làm" (text-xs text-ink-muted, last = ink).
class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, required this.items});
  /// (label, onTap) — onTap null for the current page.
  final List<(String, VoidCallback?)> items;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Wrap(
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        for (var i = 0; i < items.length; i++) ...[
          if (i > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Text('/', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
            ),
          InkWell(
            onTap: items[i].$2,
            child: Text(
              items[i].$1,
              style: TextStyle(
                color: items[i].$2 == null ? scheme.onSurface : scheme.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

/// JobsPage/Admin pagination: 36x36 bordered buttons, active bg-primary.
class Pagination extends StatelessWidget {
  const Pagination({super.key, required this.page, required this.totalPages, required this.onChanged});
  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    if (totalPages <= 1) return const SizedBox.shrink();
    final pages = <int?>[];
    for (var p = 1; p <= totalPages; p++) {
      if (p == 1 || p == totalPages || (p - page).abs() <= 1) {
        pages.add(p);
      } else if (pages.isNotEmpty && pages.last != null) {
        pages.add(null);
      }
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _btn(const Icon(Icons.chevron_left, size: 18), page > 1 ? () => onChanged(page - 1) : null),
        for (final p in pages)
          p == null ? _btn(const Text('…'), null) : _btn(Text('$p'), () => onChanged(p), active: p == page),
        _btn(const Icon(Icons.chevron_right, size: 18), page < totalPages ? () => onChanged(page + 1) : null),
      ],
    );
  }

  Widget _btn(Widget child, VoidCallback? onTap, {bool active = false}) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.primary : AppColors.surface,
              border: active ? null : Border.all(color: AppColors.border),
              borderRadius: BorderRadius.circular(10),
            ),
            child: DefaultTextStyle(
              style: TextStyle(
                color: active ? Colors.white : (onTap == null ? AppColors.slate300 : AppColors.inkSoft),
                fontSize: 13,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
              child: IconTheme(
                data: IconThemeData(color: onTap == null ? AppColors.slate300 : AppColors.inkSoft),
                child: child,
              ),
            ),
          ),
        ),
      );
}

/// Small helper to copy text with a snackbar (AI logs / API key).
Future<void> copyToClipboard(BuildContext context, String text, {String message = 'Đã sao chép'}) async {
  await Clipboard.setData(ClipboardData(text: text));
  if (context.mounted) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }
}

/// Shows Failure messages consistently.
void showFailure(BuildContext context, Object error) {
  final f = Failure.from(error);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(f.message), backgroundColor: AppColors.red600),
  );
}

void showSuccess(BuildContext context, String message) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), backgroundColor: AppColors.emerald600),
  );
}
