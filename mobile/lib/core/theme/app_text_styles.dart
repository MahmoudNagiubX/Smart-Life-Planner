import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// English text styles — Manrope.
///
/// Use the named convenience getters (e.g. [AppTextStyles.h1Light]) directly
/// in new screens. Pass a [Color] to the method variants for custom colours.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle _m(
    double size,
    FontWeight weight,
    Color color,
    double lineHeight,
  ) =>
      GoogleFonts.manrope(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: lineHeight / size,
      );

  static TextStyle displayLarge(Color c) => _m(34, FontWeight.w800, c, 40);
  static TextStyle h1(Color c)           => _m(28, FontWeight.w800, c, 34);
  static TextStyle h2(Color c)           => _m(24, FontWeight.w800, c, 30);
  static TextStyle h3(Color c)           => _m(20, FontWeight.w700, c, 26);
  static TextStyle h4(Color c)           => _m(17, FontWeight.w700, c, 23);
  static TextStyle bodyLarge(Color c)    => _m(16, FontWeight.w500, c, 24);
  static TextStyle body(Color c)         => _m(14, FontWeight.w500, c, 21);
  static TextStyle bodySmall(Color c)    => _m(13, FontWeight.w500, c, 18);
  static TextStyle caption(Color c)      => _m(12, FontWeight.w500, c, 16);
  static TextStyle label(Color c)        => _m(12, FontWeight.w700, c, 16);
  static TextStyle button(Color c)       => _m(15, FontWeight.w700, c, 20);
  static TextStyle navLabel(Color c)     => _m(11, FontWeight.w600, c, 14);
  static TextStyle timerNumber(Color c)  => _m(32, FontWeight.w800, c, 38);
  static TextStyle metricNumber(Color c) => _m(30, FontWeight.w800, c, 36);

  // Light-mode convenience styles
  static TextStyle get displayLargeLight => displayLarge(AppColors.textHeading);
  static TextStyle get h1Light           => h1(AppColors.textHeading);
  static TextStyle get h2Light           => h2(AppColors.textHeading);
  static TextStyle get h3Light           => h3(AppColors.textHeading);
  static TextStyle get h4Light           => h4(AppColors.textHeading);
  static TextStyle get bodyLargeLight    => bodyLarge(AppColors.textBody);
  static TextStyle get bodyLight         => body(AppColors.textBody);
  static TextStyle get bodySmallLight    => bodySmall(AppColors.textBody);
  static TextStyle get captionLight      => caption(AppColors.textHint);
  static TextStyle get labelLight        => label(AppColors.brandPrimary);
  static TextStyle get buttonLight       => button(Colors.white);
  static TextStyle get navLabelLight     => navLabel(AppColors.textHint);

  // Dark-mode convenience styles
  static TextStyle get h1Dark      => h1(AppColors.darkTextPrimary);
  static TextStyle get h2Dark      => h2(AppColors.darkTextPrimary);
  static TextStyle get h3Dark      => h3(AppColors.darkTextPrimary);
  static TextStyle get bodyDark    => body(AppColors.darkTextSecondary);
  static TextStyle get captionDark => caption(AppColors.darkTextMuted);
}

/// Arabic text styles — Cairo.
///
/// Arabic line-heights are +2 px compared with English equivalents.
class AppTextStylesAr {
  AppTextStylesAr._();

  static TextStyle _c(
    double size,
    FontWeight weight,
    Color color,
    double lineHeight,
  ) =>
      GoogleFonts.cairo(
        fontSize: size,
        fontWeight: weight,
        color: color,
        height: lineHeight / size,
      );

  static TextStyle h1(Color c)       => _c(28, FontWeight.w800, c, 38);
  static TextStyle h2(Color c)       => _c(24, FontWeight.w800, c, 34);
  static TextStyle h3(Color c)       => _c(20, FontWeight.w700, c, 30);
  static TextStyle body(Color c)     => _c(15, FontWeight.w500, c, 24);
  static TextStyle bodySmall(Color c) => _c(13, FontWeight.w500, c, 21);
  static TextStyle caption(Color c)  => _c(12, FontWeight.w500, c, 18);
  static TextStyle button(Color c)   => _c(15, FontWeight.w700, c, 22);

  // Light-mode convenience styles
  static TextStyle get h1Light      => h1(AppColors.textHeading);
  static TextStyle get h2Light      => h2(AppColors.textHeading);
  static TextStyle get bodyLight    => body(AppColors.textBody);
  static TextStyle get captionLight => caption(AppColors.textHint);
}
