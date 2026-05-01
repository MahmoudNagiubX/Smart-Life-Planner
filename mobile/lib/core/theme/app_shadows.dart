import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Design-system shadow tokens.
class AppShadows {
  AppShadows._();

  /// Standard dashboard card shadow.
  static List<BoxShadow> get card => [
    BoxShadow(
      color: AppColors.brandPrimary.withValues(alpha: 0.10),
      blurRadius: 24,
      offset: const Offset(0, 10),
    ),
  ];

  /// Subtle soft shadow for small cards and inputs.
  static List<BoxShadow> get soft => [
    BoxShadow(
      color: AppColors.textHeading.withValues(alpha: 0.06),
      blurRadius: 22,
      offset: const Offset(0, 8),
    ),
  ];

  /// Floating nav / FAB shadow.
  static List<BoxShadow> get floating => [
    BoxShadow(
      color: AppColors.brandPrimary.withValues(alpha: 0.22),
      blurRadius: 28,
      offset: const Offset(0, 12),
    ),
  ];

  /// Purple glow for active/pressed primary components.
  static List<BoxShadow> get glowPurple => [
    BoxShadow(
      color: AppColors.brandPrimary.withValues(alpha: 0.30),
      blurRadius: 26,
      offset: const Offset(0, 10),
    ),
  ];

  /// Pink glow for CTA and focus components.
  static List<BoxShadow> get glowPink => [
    BoxShadow(
      color: AppColors.brandPink.withValues(alpha: 0.20),
      blurRadius: 30,
      offset: const Offset(0, 10),
    ),
  ];

  /// Dark mode card shadow.
  static List<BoxShadow> get dark => [
    BoxShadow(
      color: Colors.black.withValues(alpha: 0.28),
      blurRadius: 26,
      offset: const Offset(0, 12),
    ),
  ];
}
