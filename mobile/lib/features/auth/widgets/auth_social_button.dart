import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';

/// White pill button used for social login (Google, Apple).
class AuthSocialButton extends StatefulWidget {
  final Widget icon;
  final String label;
  final VoidCallback? onTap;
  final bool isLoading;

  const AuthSocialButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.isLoading = false,
  });

  @override
  State<AuthSocialButton> createState() => _AuthSocialButtonState();
}

class _AuthSocialButtonState extends State<AuthSocialButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.onTap != null
          ? (_) {
              HapticFeedback.lightImpact();
              setState(() => _pressed = true);
            }
          : null,
      onTapUp: widget.onTap != null
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 110),
        curve: Curves.easeOut,
        child: Container(
          height: AppButtonHeight.secondary,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            border: Border.all(color: AppColors.borderSoft, width: 1),
            boxShadow: [
              BoxShadow(
                color: AppColors.textHeading.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: widget.isLoading
              ? Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.textBody,
                      ),
                    ),
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: widget.icon),
                    const SizedBox(width: 10),
                    Text(
                      widget.label,
                      style: GoogleFonts.manrope(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                        height: 1.0,
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

class GoogleGMark extends StatelessWidget {
  const GoogleGMark({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(painter: _GoogleGMarkPainter()),
    );
  }
}

class _GoogleGMarkPainter extends CustomPainter {
  const _GoogleGMarkPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final stroke = size.width * 0.18;
    final center = rect.center;
    final radius = size.width * 0.34;
    final arcRect = Rect.fromCircle(center: center, radius: radius);

    Paint arcPaint(Color color) => Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;

    canvas.drawArc(
      arcRect,
      -0.12,
      1.30,
      false,
      arcPaint(const Color(0xFF4285F4)),
    );
    canvas.drawArc(
      arcRect,
      1.18,
      1.16,
      false,
      arcPaint(const Color(0xFF34A853)),
    );
    canvas.drawArc(
      arcRect,
      2.34,
      0.92,
      false,
      arcPaint(const Color(0xFFFBBC05)),
    );
    canvas.drawArc(
      arcRect,
      3.26,
      1.38,
      false,
      arcPaint(const Color(0xFFEA4335)),
    );

    final blue = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.square;
    canvas.drawLine(
      Offset(center.dx, center.dy),
      Offset(size.width * 0.82, center.dy),
      blue,
    );
    canvas.drawLine(
      Offset(size.width * 0.82, center.dy),
      Offset(size.width * 0.82, size.height * 0.42),
      blue,
    );
  }

  @override
  bool shouldRepaint(_GoogleGMarkPainter oldDelegate) => false;
}
