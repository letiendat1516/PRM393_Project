import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/theme/app_colors.dart';

/// JobsPage pagination: `1 2 3 … N-1 N` (compactPages), 36x36 tiles, prev /
/// next arrows, and an ellipsis that turns into a numeric jump input
/// (Enter commits, Esc / blur cancels).
class JobsPagination extends StatefulWidget {
  const JobsPagination({
    super.key,
    required this.page,
    required this.totalPages,
    required this.onChanged,
  });

  final int page;
  final int totalPages;
  final ValueChanged<int> onChanged;

  /// compactPages(current, total) → page numbers with `null` as ellipsis.
  static List<int?> compactPages(int current, int total) {
    if (total <= 7) return [for (var i = 1; i <= total; i++) i];
    final pages = <int?>[1];
    if (current <= 4) {
      for (var i = 2; i <= 5; i++) {
        pages.add(i);
      }
      pages
        ..add(null)
        ..add(total);
    } else if (current >= total - 3) {
      pages.add(null);
      for (var i = total - 4; i <= total; i++) {
        pages.add(i);
      }
    } else {
      pages.add(null);
      for (var i = current - 1; i <= current + 1; i++) {
        pages.add(i);
      }
      pages
        ..add(null)
        ..add(total);
    }
    return pages;
  }

  @override
  State<JobsPagination> createState() => _JobsPaginationState();
}

class _JobsPaginationState extends State<JobsPagination> {
  int? _jumpIndex;
  final _jumpCtrl = TextEditingController();
  final _jumpFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _jumpFocus.addListener(() {
      if (!_jumpFocus.hasFocus && _jumpIndex != null) _cancelJump();
    });
  }

  @override
  void dispose() {
    _jumpCtrl.dispose();
    _jumpFocus.dispose();
    super.dispose();
  }

  void _cancelJump() {
    if (!mounted) return;
    setState(() {
      _jumpIndex = null;
      _jumpCtrl.clear();
    });
  }

  void _commitJump() {
    final parsed = int.tryParse(_jumpCtrl.text) ?? widget.page;
    widget.onChanged(parsed.clamp(1, widget.totalPages));
    _cancelJump();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages <= 1) return const SizedBox.shrink();
    final current = widget.page;
    final pages = JobsPagination.compactPages(current, widget.totalPages);

    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 6,
      runSpacing: 6,
      children: [
        _Tile(
          tooltip: 'Trang trước',
          onTap: current > 1 ? () => widget.onChanged(current - 1) : null,
          child: const Icon(Icons.arrow_back, size: 18),
        ),
        for (var i = 0; i < pages.length; i++)
          if (pages[i] == null)
            _jumpIndex == i
                ? _JumpInput(
                    controller: _jumpCtrl,
                    focusNode: _jumpFocus,
                    max: widget.totalPages,
                    onSubmit: _commitJump,
                    onCancel: _cancelJump,
                  )
                : _Tile(
                    tooltip: 'Nhảy tới trang…',
                    onTap: () {
                      setState(() => _jumpIndex = i);
                      WidgetsBinding.instance.addPostFrameCallback(
                        (_) => _jumpFocus.requestFocus(),
                      );
                    },
                    child: const Text('...'),
                  )
          else
            _Tile(
              active: pages[i] == current,
              onTap: () => widget.onChanged(pages[i]!),
              child: Text('${pages[i]}'),
            ),
        _Tile(
          tooltip: 'Trang sau',
          onTap: current < widget.totalPages
              ? () => widget.onChanged(current + 1)
              : null,
          child: const Icon(Icons.arrow_forward, size: 18),
        ),
      ],
    );
  }
}

class _Tile extends StatefulWidget {
  const _Tile({
    required this.child,
    this.onTap,
    this.active = false,
    this.tooltip,
  });
  final Widget child;
  final VoidCallback? onTap;
  final bool active;
  final String? tooltip;

  @override
  State<_Tile> createState() => _TileState();
}

class _TileState extends State<_Tile> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.onTap == null;
    final fg = widget.active
        ? Colors.white
        : disabled
        ? AppColors.inkSoft.withValues(alpha: 0.4)
        : (_hover ? AppColors.primary : AppColors.inkSoft);
    final border = widget.active
        ? null
        : Border.all(
            color: _hover && !disabled ? AppColors.primary : AppColors.border,
          );

    final tile = MouseRegion(
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      cursor: disabled
          ? SystemMouseCursors.forbidden
          : SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: widget.active ? AppColors.primary : AppColors.surface,
            border: border,
            borderRadius: BorderRadius.circular(AppRadius.lg),
          ),
          child: IconTheme(
            data: IconThemeData(color: fg, size: 18),
            child: DefaultTextStyle(
              style: TextStyle(
                color: fg,
                fontSize: 14,
                fontWeight: widget.active ? FontWeight.w600 : FontWeight.w500,
              ),
              child: widget.child,
            ),
          ),
        ),
      ),
    );
    if (widget.tooltip == null) return tile;
    return Tooltip(message: widget.tooltip!, child: tile);
  }
}

class _JumpInput extends StatelessWidget {
  const _JumpInput({
    required this.controller,
    required this.focusNode,
    required this.max,
    required this.onSubmit,
    required this.onCancel,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final int max;
  final VoidCallback onSubmit;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 44,
      height: 36,
      child: CallbackShortcuts(
        bindings: {const SingleActivator(LogicalKeyboardKey.escape): onCancel},
        child: TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textAlign: TextAlign.center,
          onSubmitted: (_) => onSubmit(),
          style: const TextStyle(fontSize: 14, color: AppColors.ink),
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: AppColors.surface,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 4,
              vertical: 8,
            ),
            hintText: '$max',
            hintStyle: const TextStyle(fontSize: 12, color: AppColors.inkMuted),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(color: AppColors.primary),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
