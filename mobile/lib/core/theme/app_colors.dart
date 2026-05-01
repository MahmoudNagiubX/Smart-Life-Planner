import 'package:flutter/material.dart';

/// Design-system color tokens for Smart Life Planner.
///
/// Use the named sections below in new screens.
/// The "Legacy aliases" section preserves backward compat with existing dark-mode screens.
class AppColors {
  AppColors._();

  // ── Brand ──────────────────────────────────────────────────────────────────
  static const brandPrimary     = Color(0xFF6A4CFF);
  static const brandPrimaryDeep = Color(0xFF4F3BEF);
  static const brandViolet      = Color(0xFF8B5CFF);
  static const brandPink        = Color(0xFFF45DB3);
  static const brandPinkSoft    = Color(0xFFFFEAF6);
  static const brandGold        = Color(0xFFFFD45C);
  static const brandCyan        = Color(0xFF39D7E8);

  // ── Light mode — backgrounds ───────────────────────────────────────────────
  static const bgApp            = Color(0xFFF8F6FF);
  static const bgAppAlt         = Color(0xFFF1ECFF);
  static const bgSurface        = Color(0xFFFFFFFF);
  static const bgSurfaceSoft    = Color(0xFFFBFAFF);
  static const bgSurfaceLavender = Color(0xFFF3EFFF);

  // ── Light mode — text ──────────────────────────────────────────────────────
  static const textHeading      = Color(0xFF17163B);
  static const textBody         = Color(0xFF6F6B8E);
  static const textHint         = Color(0xFF9A95B8);

  // ── Light mode — borders / dividers ───────────────────────────────────────
  static const borderSoft       = Color(0xFFEEE9FF);
  static const dividerColor     = Color(0xFFE7E1F7);

  // ── Semantic ───────────────────────────────────────────────────────────────
  static const successColor     = Color(0xFF2ED47A);
  static const successSoft      = Color(0xFFE8FFF3);
  static const warningColor     = Color(0xFFFFB547);
  static const warningSoft      = Color(0xFFFFF4DC);
  static const errorColor       = Color(0xFFFF4D6D);
  static const errorSoft        = Color(0xFFFFE8EE);
  static const infoColor        = Color(0xFF4DA3FF);
  static const infoSoft         = Color(0xFFEAF4FF);

  // ── Feature accents ────────────────────────────────────────────────────────
  static const featTasks        = Color(0xFF6A4CFF);
  static const featTasksSoft    = Color(0xFFF0E9FF);
  static const featNotes        = Color(0xFFFFB547);
  static const featNotesSoft    = Color(0xFFFFF4DC);
  static const featHabits       = Color(0xFF25C68A);
  static const featHabitsSoft   = Color(0xFFE8FFF3);
  static const featFocus        = Color(0xFFF45DB3);
  static const featFocusSoft    = Color(0xFFFFEAF6);
  static const featPrayer       = Color(0xFF8B5CFF);
  static const featPrayerSoft   = Color(0xFFF1ECFF);
  static const featAI           = Color(0xFF7C5CFF);
  static const featAISoft       = Color(0xFFF3EFFF);
  static const featJournal      = Color(0xFF39D7E8);
  static const featJournalSoft  = Color(0xFFE8FBFF);
  static const featAnalytics    = Color(0xFF4DA3FF);
  static const featAnalyticsSoft = Color(0xFFEAF4FF);

  // ── Dark mode tokens (future dark-mode screens) ───────────────────────────
  static const darkBg           = Color(0xFF0F1024);
  static const darkBgAlt        = Color(0xFF141633);
  static const darkSurface      = Color(0xFF191A3A);
  static const darkCard         = Color(0xFF202046);
  static const darkElevated     = Color(0xFF27285A);
  static const darkPrimary      = Color(0xFF8B7CFF);
  static const darkViolet       = Color(0xFFB07CFF);
  static const darkPink         = Color(0xFFFF6DB6);
  static const darkGold         = Color(0xFFFFD96A);
  static const darkTextPrimary  = Color(0xFFF7F4FF);
  static const darkTextSecondary = Color(0xFFC8C2E6);
  static const darkTextMuted    = Color(0xFF918BAE);
  static const darkBorder       = Color(0xFF34345D);
  static const darkDivider      = Color(0xFF2B2B50);
  static const darkSuccess      = Color(0xFF35D98B);
  static const darkWarning      = Color(0xFFFFC15A);
  static const darkError        = Color(0xFFFF6B84);
  static const darkInfo         = Color(0xFF6CB6FF);

  // ── Legacy aliases — kept for backward compat with existing dark screens ──
  /// Use [brandPrimary] in new screens.
  static const primary          = brandPrimary;
  static const primaryDark      = Color(0xFF4B44CC);

  /// Legacy dark backgrounds — existing screens reference these directly.
  static const backgroundDark   = Color(0xFF0F0F14);
  static const surfaceDark      = Color(0xFF1A1A24);
  static const cardDark         = Color(0xFF22222F);

  /// Legacy light backgrounds.
  static const backgroundLight  = Color(0xFFF5F5FA);
  static const surfaceLight     = Color(0xFFFFFFFF);
  static const cardLight        = Color(0xFFEEEEF5);

  /// Legacy text — [textPrimary] was white for dark screens.
  /// Use [textHeading] / [textBody] in new screens.
  static const textPrimary      = Color(0xFFFFFFFF);
  static const textSecondary    = Color(0xFF9E9EAE);
  static const textDark         = Color(0xFF1A1A24);

  /// Legacy semantic.
  static const success          = Color(0xFF4CAF50);
  static const error            = Color(0xFFEF5350);
  static const warning          = Color(0xFFFFB300);

  /// Legacy prayer gold.
  static const prayerGold       = Color(0xFFD4A843);

  /// Legacy note fills.
  static const noteRed          = Color(0xFF5C2A32);
  static const noteOrange       = Color(0xFF5C3A24);
  static const noteYellow       = Color(0xFF4F4320);
  static const noteGreen        = Color(0xFF234632);
  static const noteBlue         = Color(0xFF243E5C);
  static const notePurple       = Color(0xFF3D315C);
}
