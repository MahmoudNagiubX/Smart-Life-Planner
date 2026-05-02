import 'dart:math' show pi;
import 'package:flutter/material.dart';

/// Animated circular progress ring with sweep gradient fill.
///
/// [value] is 0.0–1.0. Animates from 0 on first render.
class ProgressRing extends StatelessWidget {
  final double value;
  final double size;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradientColors;
  final Widget? child;

  const ProgressRing({
    super.key,
    required this.value,
    required this.size,
    this.strokeWidth = 8,
    this.trackColor = const Color(0xFFEEE9FF),
    this.gradientColors = const [Color(0xFF6A4CFF), Color(0xFFF45DB3)],
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 1100),
      curve: Curves.easeOutCubic,
      builder: (_, v, _) {
        return SizedBox(
          width: size,
          height: size,
          child: CustomPaint(
            painter: _RingPainter(
              value: v,
              strokeWidth: strokeWidth,
              trackColor: trackColor,
              gradientColors: gradientColors,
            ),
            child: child != null ? Center(child: child) : null,
          ),
        );
      },
    );
  }
}

class _RingPainter extends CustomPainter {
  final double value;
  final double strokeWidth;
  final Color trackColor;
  final List<Color> gradientColors;

  const _RingPainter({
    required this.value,
    required this.strokeWidth,
    required this.trackColor,
    required this.gradientColors,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = trackColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    if (value <= 0) return;

    canvas.drawArc(
      rect,
      -pi / 2,
      2 * pi * value,
      false,
      Paint()
        ..shader = SweepGradient(
          startAngle: -pi / 2,
          endAngle: 3 * pi / 2,
          colors: gradientColors,
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.value != value || old.strokeWidth != strokeWidth;
}
