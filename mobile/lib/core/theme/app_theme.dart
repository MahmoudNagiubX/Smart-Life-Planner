import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import 'app_tokens.dart';

class AppTheme {
  AppTheme._();

  static ThemeData light() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: AppColors.bgApp,
      primaryColor: AppColors.brandPrimary,
      colorScheme: const ColorScheme.light(
        primary: AppColors.brandPrimary,
        secondary: AppColors.brandViolet,
        surface: AppColors.bgSurface,
        error: AppColors.errorColor,
        onPrimary: Colors.white,
        onSurface: AppColors.textHeading,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(ThemeData.light().textTheme, AppColors.textHeading),
      dividerColor: AppColors.dividerColor,
      cardTheme: CardThemeData(
        color: AppColors.bgSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgApp,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.textHeading),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.textHeading,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.bgSurface,
        indicatorColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.brandPrimary : AppColors.textHint,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.brandPrimary : AppColors.textHint,
            size: AppIconSize.nav,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppButtonHeight.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: 0,
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          minimumSize: const Size(double.infinity, AppButtonHeight.secondary),
          side: const BorderSide(color: AppColors.borderSoft),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandPrimary,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSurfaceSoft,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.borderSoft),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.brandPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.errorColor),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.errorColor, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textHint,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textBody,
        ),
        errorStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.errorColor,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bgSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl3),
            topRight: Radius.circular(AppRadius.xl3),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textHeading,
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static ThemeData dark() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: AppColors.darkBg,
      primaryColor: AppColors.darkPrimary,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.darkPrimary,
        secondary: AppColors.darkViolet,
        surface: AppColors.darkSurface,
        error: AppColors.darkError,
        onPrimary: Colors.white,
        onSurface: AppColors.darkTextPrimary,
        onError: Colors.white,
      ),
      textTheme: _buildTextTheme(ThemeData.dark().textTheme, AppColors.darkTextPrimary),
      dividerColor: AppColors.darkDivider,
      cardTheme: CardThemeData(
        color: AppColors.darkCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          side: const BorderSide(color: AppColors.darkBorder),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.darkBg,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: AppColors.darkTextPrimary),
        titleTextStyle: GoogleFonts.manrope(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: AppColors.darkTextPrimary,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.darkSurface,
        indicatorColor: AppColors.darkPrimary.withValues(alpha: 0.20),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: active ? AppColors.darkPrimary : AppColors.darkTextMuted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final active = states.contains(WidgetState.selected);
          return IconThemeData(
            color: active ? AppColors.darkPrimary : AppColors.darkTextMuted,
            size: AppIconSize.nav,
          );
        }),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.darkPrimary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppButtonHeight.primary),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          elevation: 0,
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          minimumSize: const Size(double.infinity, AppButtonHeight.secondary),
          side: const BorderSide(color: AppColors.darkBorder),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          textStyle: GoogleFonts.manrope(
            fontSize: 15,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.darkPrimary,
          textStyle: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: AppSpacing.s16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.darkBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.darkPrimary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.darkError),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
          borderSide: const BorderSide(color: AppColors.darkError, width: 1.5),
        ),
        hintStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextMuted,
        ),
        labelStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextSecondary,
        ),
        errorStyle: GoogleFonts.manrope(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: AppColors.darkError,
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.darkSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppRadius.xl3),
            topRight: Radius.circular(AppRadius.xl3),
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.darkElevated,
        contentTextStyle: GoogleFonts.manrope(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.darkTextPrimary,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static TextTheme _buildTextTheme(TextTheme base, Color textColor) =>
      GoogleFonts.manropeTextTheme(base).apply(
        bodyColor: textColor,
        displayColor: textColor,
      );
}
