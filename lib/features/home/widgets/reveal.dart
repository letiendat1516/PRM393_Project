import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

/// components/ui/Reveal.jsx — fade + slide-up (24px, 550ms,
/// cubic-bezier(.22,1,.36,1)) once the child is ≥25% visible. Plays once.
/// Honours `MediaQuery.disableAnimations` (prefers-reduced-motion).
///
/// [immediate] plays on mount (Hero.jsx uses `animate` instead of `whileInView`).
class Reveal extends StatefulWidget {
  const Reveal({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 24,
    this.amount = 0.25,
    this.immediate = false,
  });

  final Widget child;
  final Duration delay;
  final double offsetY;
  /// Fraction of the element that must be visible to trigger.
  final double amount;
  final bool immediate;

  @override
  State<Reveal> createState() => _RevealState();
}

class _RevealState extends State<Reveal> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 550),
  );
  late final Animation<double> _t = CurvedAnimation(
    parent: _controller,
    curve: const Cubic(0.22, 1, 0.36, 1),
  );
  final Key _visibilityKey = UniqueKey();
  bool _started = false;
  bool _reduceMotion = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reduceMotion = MediaQuery.disableAnimationsOf(context);
    if (_reduceMotion && !_started) {
      _started = true;
      _controller.value = 1;
    } else if (widget.immediate) {
      _start();
    }
  }

  void _start() {
    if (_started) return;
    _started = true;
    if (widget.delay == Duration.zero) {
      _controller.forward();
      return;
    }
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  void _onVisibility(VisibilityInfo info) {
    if (_started) return;
    final tallEnough = info.visibleBounds.height >= 200;
    if (info.visibleFraction >= widget.amount || (info.visibleFraction > 0 && tallEnough)) {
      _start();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final animated = AnimatedBuilder(
      animation: _t,
      child: widget.child,
      builder: (_, child) => Opacity(
        opacity: _t.value.clamp(0.0, 1.0),
        child: Transform.translate(
          offset: Offset(0, (1 - _t.value) * widget.offsetY),
          child: child,
        ),
      ),
    );
    if (_reduceMotion || widget.immediate) return animated;
    return VisibilityDetector(
      key: _visibilityKey,
      onVisibilityChanged: _onVisibility,
      child: animated,
    );
  }
}
