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
            borderRadius: BorderRadius.circular(AppRadius.lg),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
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
