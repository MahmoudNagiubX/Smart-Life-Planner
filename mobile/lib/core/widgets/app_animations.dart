import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════════════════════
// AppFadeSlide
// ════════════════════════════════════════════════════════════════════════════

/// Fades and slides a [child] in from slightly below on first build.
///
/// - Duration : 280 ms (default), customisable via [duration].
/// - Curve    : [Curves.easeOutCubic]
/// - Slide    : Offset(0, 0.04) → Offset(0, 0)  (4 % of widget height)
/// - Delay    : optional [delay] for staggered lists
///
/// The animation starts automatically in [initState] and never repeats.
class AppFadeSlide extends StatefulWidget {
  const AppFadeSlide({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 280),
    this.delay = Duration.zero,
    this.slideOffset = const Offset(0, 0.04),
  });

  final Widget child;
  final Duration duration;
  final Duration delay;
  final Offset slideOffset;

  @override
  State<AppFadeSlide> createState() => _AppFadeSlideState();
}

class _AppFadeSlideState extends State<AppFadeSlide>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: widget.duration);
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    _slide = Tween<Offset>(
      begin: widget.slideOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));

    if (widget.delay == Duration.zero) {
      _ctrl.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _ctrl.forward();
      });
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// AppPressable
// ════════════════════════════════════════════════════════════════════════════

/// Wraps a [child] with a subtle scale-down on press (0.97×, 120 ms).
///
/// Purely gesture-driven — no rebuilds except on tap state change.
/// Use this around buttons, cards, and tappable rows.
class AppPressable extends StatefulWidget {
  const AppPressable({
    super.key,
    required this.child,
    this.onTap,
    this.scale = 0.97,
    this.duration = const Duration(milliseconds: 120),
  });

  final Widget child;
  final VoidCallback? onTap;
  final double scale;
  final Duration duration;

  @override
  State<AppPressable> createState() => _AppPressableState();
}

class _AppPressableState extends State<AppPressable> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap?.call();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(
          begin: 1.0,
          end: _pressed ? widget.scale : 1.0,
        ),
        duration: widget.duration,
        curve: Curves.easeOutCubic,
        builder: (context, value, child) =>
            Transform.scale(scale: value, child: child),
        child: widget.child,
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// AppStaggeredList
// ════════════════════════════════════════════════════════════════════════════

/// Wraps a list of [children] in [AppFadeSlide] with a per-item stagger.
///
/// Only the first [maxAnimatedItems] entries are animated; the rest render
/// immediately (performance guard for long lists).
class AppStaggeredList extends StatelessWidget {
  const AppStaggeredList({
    super.key,
    required this.children,
    this.staggerMs = 40,
    this.maxAnimatedItems = 8,
    this.itemDuration = const Duration(milliseconds: 280),
  });

  final List<Widget> children;
  final int staggerMs;
  final int maxAnimatedItems;
  final Duration itemDuration;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < children.length; i++)
          if (i < maxAnimatedItems)
            AppFadeSlide(
              duration: itemDuration,
              delay: Duration(milliseconds: i * staggerMs),
              child: children[i],
            )
          else
            children[i],
      ],
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// AppAnimatedCounter
// ════════════════════════════════════════════════════════════════════════════

/// Animates a numeric value change from [value]'s old → new value.
///
/// Displayed as an integer. Duration 600 ms, curve easeOutCubic.
/// Wrap around stat numbers for a smooth counting effect.
class AppAnimatedCounter extends StatelessWidget {
  const AppAnimatedCounter({
    super.key,
    required this.value,
    this.style,
    this.duration = const Duration(milliseconds: 600),
    this.prefix = '',
    this.suffix = '',
  });

  final double value;
  final TextStyle? style;
  final Duration duration;
  final String prefix;
  final String suffix;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animValue, _) => Text(
        '$prefix${animValue.round()}$suffix',
        style: style,
      ),
    );
  }
}
