import 'package:flutter/material.dart';

/// Spacing tokens — 8 px base grid.
class AppSpacing {
  AppSpacing._();

  static const double s2  = 2;
  static const double s4  = 4;
  static const double s6  = 6;
  static const double s8  = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s28 = 28;
  static const double s32 = 32;
  static const double s40 = 40;

  /// Horizontal screen padding.
  static const double screenH   = s20;
  /// Vertical gap between sections.
  static const double sectionGap = s20;
  /// Gap between cards in a grid.
  static const double cardGap   = s16;
  /// Internal card padding.
  static const double cardPad   = s20;
  /// Gap between list items.
  static const double listGap   = 10;
}

/// Border-radius tokens.
class AppRadius {
  AppRadius._();

  static const double xs   = 6;
  static const double sm   = 10;
  static const double md   = 14;
  static const double lg   = 18;
  static const double xl   = 22;
  static const double xl2  = 26;
  static const double xl3  = 30;
  static const double pill = 999;

  static BorderRadius circular(double r) => BorderRadius.circular(r);

  static BorderRadius get pillBr  => BorderRadius.circular(pill);
  static BorderRadius get cardBr  => BorderRadius.circular(xl2);
  static BorderRadius get sheetBr => const BorderRadius.only(
    topLeft:  Radius.circular(xl3),
    topRight: Radius.circular(xl3),
  );
}

/// Gradient tokens.
class AppGradients {
  AppGradients._();

  static const brand = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF5C49F4), Color(0xFF8A4FFF), Color(0xFFF26AA8)],
    stops: [0.0, 0.48, 1.0],
  );

  static const action = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A4CFF), Color(0xFFF45DB3)],
  );

  static const focus = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF6A4CFF), Color(0xFFFF6CA8)],
  );

  static const prayer = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFEEE9FF), Color(0xFFFFFFFF), Color(0xFFF8F6FF)],
    stops: [0.0, 0.45, 1.0],
  );

  static const ai = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF8F6FF), Color(0xFFFFFFFF), Color(0xFFEEE9FF)],
    stops: [0.0, 0.5, 1.0],
  );

  static const darkHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF151433), Color(0xFF211B4E), Color(0xFF3A215B)],
    stops: [0.0, 0.55, 1.0],
  );

  static const gradWarning = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFB547), Color(0xFFFF7A59)],
  );

  static const gradSuccess = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2ED47A), Color(0xFF7BE7B7)],
  );
}

/// Icon size tokens.
class AppIconSize {
  AppIconSize._();

  static const double nav        = 24;
  static const double cardHeader = 22;
  static const double action     = 24;
  static const double emptyState = 120;
  static const double avatar     = 44;
  static const double logo       = 48;
}

/// Button / input height tokens.
class AppButtonHeight {
  AppButtonHeight._();

  static const double primary   = 54;
  static const double secondary = 50;
  static const double small     = 42;
  static const double icon      = 44;
  static const double input     = 54;
  static const double navBar    = 80;
}
