import 'dart:math' as math;

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../shared/widgets/section.dart';

/// Two-column page body with a CSS-`sticky top-24`-like side column.
///
/// Wide (≥ [breakpoint]): [header] + body + [footer] scroll in one
/// CustomScrollView while [sidebar] is overlaid at its natural position,
/// pinned [stickyTop] px below the navbar once the page scrolls past it and
/// clamped so it never overlaps the footer. Narrow: everything stacks.
///
/// Pass the same [controller] to `PublicLayout(scrollable: false,
/// scrollController:)` so the navbar shadow still reacts to scrolling.
class StickySidebarLayout extends StatefulWidget {
  const StickySidebarLayout({
    super.key,
    required this.controller,
    required this.sidebar,
    required this.body,
    this.header,
    this.footer,
    this.sidebarOnRight = false,
    this.sidebarFirstWhenStacked = true,
    this.sidebarWidth = 288,
    this.sidebarFraction,
    this.gap = 24,
    this.stickyTop = 24,
    this.breakpoint = 1024,
    this.bodyPadding = const EdgeInsets.symmetric(vertical: 24),
  });

  final ScrollController controller;
  final Widget sidebar;
  final Widget body;
  final Widget? header;
  final Widget? footer;
  final bool sidebarOnRight;
  final bool sidebarFirstWhenStacked;

  /// Fixed sidebar width (`lg:w-72`) …
  final double sidebarWidth;

  /// … or a fraction of the content width minus [gap] (`lg:grid-cols-3`).
  final double? sidebarFraction;
  final double gap;
  final double stickyTop;
  final double breakpoint;
  final EdgeInsets bodyPadding;

  @override
  State<StickySidebarLayout> createState() => _StickySidebarLayoutState();
}

class _StickySidebarLayoutState extends State<StickySidebarLayout> {
  final _headerKey = GlobalKey();
  final _bodyKey = GlobalKey();
  final _sidebarKey = GlobalKey();

  double _headerH = 0;
  double _bodyH = 0;
  double _sidebarH = 0;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_scheduleMeasure);
  }

  @override
  void didUpdateWidget(covariant StickySidebarLayout old) {
    super.didUpdateWidget(old);
    if (old.controller != widget.controller) {
      old.controller.removeListener(_scheduleMeasure);
      widget.controller.addListener(_scheduleMeasure);
    }
  }

  @override
  void dispose() {
    widget.controller.removeListener(_scheduleMeasure);
    super.dispose();
  }

  void _scheduleMeasure() {
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  double _heightOf(GlobalKey k) {
    final ro = k.currentContext?.findRenderObject();
    if (ro is RenderBox && ro.hasSize) return ro.size.height;
    return 0;
  }

  /// CSS `position: sticky` lets wheel events over the aside fall through to
  /// the document. The overlaid sidebar swallows them here, so forward them
  /// to the page scroll view through the pointer-signal resolver: an inner
  /// scrollable that can still move registers first and wins; when its
  /// content fits or it sits at an edge, the page scrolls instead.
  void _onSidebarPointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent || !widget.controller.hasClients) return;
    final position = widget.controller.position;
    final delta = event.scrollDelta.dy;
    if (delta == 0) return;
    final target = (position.pixels + delta).clamp(
      position.minScrollExtent,
      position.maxScrollExtent,
    );
    if (target == position.pixels) return;
    GestureBinding.instance.pointerSignalResolver.register(event, (e) {
      if (!widget.controller.hasClients) return;
      widget.controller.position.pointerScroll(
        (e as PointerScrollEvent).scrollDelta.dy,
      );
    });
  }

  void _measure() {
    if (!mounted) return;
    final h = _heightOf(_headerKey);
    final b = _heightOf(_bodyKey);
    final s = _heightOf(_sidebarKey);
    if ((h - _headerH).abs() > 0.5 ||
        (b - _bodyH).abs() > 0.5 ||
        (s - _sidebarH).abs() > 0.5) {
      setState(() {
        _headerH = h;
        _bodyH = b;
        _sidebarH = s;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    _scheduleMeasure();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final wide = width >= widget.breakpoint;
        final horizontal = width >= 1024 ? 32.0 : (width >= 640 ? 24.0 : 16.0);
        final containerW = math.min(width, kContentMaxWidth);
        final contentW = containerW - horizontal * 2;
        final sideW = widget.sidebarFraction != null
            ? (contentW - widget.gap) * widget.sidebarFraction!
            : widget.sidebarWidth;
        final contentLeft = (width - containerW) / 2 + horizontal;
        final sideLeft = widget.sidebarOnRight
            ? contentLeft + contentW - sideW
            : contentLeft;

        final Widget bodyRow;
        if (wide) {
          bodyRow = Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!widget.sidebarOnRight) ...[
                SizedBox(width: sideW),
                SizedBox(width: widget.gap),
              ],
              Expanded(child: widget.body),
              if (widget.sidebarOnRight) ...[
                SizedBox(width: widget.gap),
                SizedBox(width: sideW),
              ],
            ],
          );
        } else {
          bodyRow = Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: widget.sidebarFirstWhenStacked
                ? [widget.sidebar, SizedBox(height: widget.gap), widget.body]
                : [widget.body, SizedBox(height: widget.gap), widget.sidebar],
          );
        }

        final scroll = CustomScrollView(
          controller: widget.controller,
          slivers: [
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _headerKey,
                child: widget.header ?? const SizedBox.shrink(),
              ),
            ),
            SliverToBoxAdapter(
              child: KeyedSubtree(
                key: _bodyKey,
                child: PageContainer(
                  child: Padding(padding: widget.bodyPadding, child: bodyRow),
                ),
              ),
            ),
            if (widget.footer != null) SliverToBoxAdapter(child: widget.footer),
          ],
        );

        if (!wide) return scroll;

        return Stack(
          children: [
            Positioned.fill(child: scroll),
            AnimatedBuilder(
              animation: widget.controller,
              builder: (context, _) {
                final offset = widget.controller.hasClients
                    ? widget.controller.offset
                    : 0.0;
                final naturalTop = _headerH + widget.bodyPadding.top - offset;
                final bodyBottom =
                    _headerH + _bodyH - widget.bodyPadding.bottom - offset;
                var top = math.max(naturalTop, widget.stickyTop);
                if (_sidebarH > 0) {
                  final maxTop = bodyBottom - _sidebarH;
                  // Body shorter than the sidebar → just scroll with the page.
                  top = maxTop < naturalTop
                      ? naturalTop
                      : math.min(top, maxTop);
                }
                final avail = constraints.maxHeight - top - widget.stickyTop;
                return Positioned(
                  top: top,
                  left: sideLeft,
                  width: sideW,
                  child: Listener(
                    onPointerSignal: _onSidebarPointerSignal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: math.max(avail, 120),
                      ),
                      child: KeyedSubtree(
                        key: _sidebarKey,
                        child: widget.sidebar,
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
