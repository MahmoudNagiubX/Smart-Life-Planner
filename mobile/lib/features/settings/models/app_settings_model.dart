import 'package:flutter/material.dart';

import '../../prayer/models/prayer_notification_sound.dart';

class AppSettingsModel {
  final String language;
  final String theme;
  final bool notificationsEnabled;
  final String? country;
  final String? city;
  final String timezone;
  final String prayerCalculationMethod;
  final int prayerReminderMinutesBefore;
  final bool athanSoundEnabled;
  final String prayerNotificationSound;
  final String? wakeTime;
  final String? sleepTime;
  final bool microphoneEnabled;
  final bool locationEnabled;
  final Map<String, dynamic> reminderPreferences;

  const AppSettingsModel({
    required this.language,
    required this.theme,
    required this.notificationsEnabled,
    required this.country,
    required this.city,
    required this.timezone,
    required this.prayerCalculationMethod,
    required this.prayerReminderMinutesBefore,
    required this.athanSoundEnabled,
    required this.prayerNotificationSound,
    required this.wakeTime,
    required this.sleepTime,
    required this.microphoneEnabled,
    required this.locationEnabled,
    required this.reminderPreferences,
  });

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) {
    return AppSettingsModel(
      language: json['language'] as String? ?? 'en',
      theme: json['theme'] as String? ?? 'light',
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      country: json['country'] as String?,
      city: json['city'] as String?,
      timezone: json['timezone'] as String? ?? 'UTC',
      prayerCalculationMethod:
          json['prayer_calculation_method'] as String? ?? 'MWL',
      prayerReminderMinutesBefore:
          json['prayer_reminder_minutes_before'] as int? ?? 10,
      athanSoundEnabled: json['athan_sound_enabled'] as bool? ?? false,
      prayerNotificationSound: PrayerNotificationSound.normalize(
        json['prayer_notification_sound'] as String?,
        legacyAthanEnabled: json['athan_sound_enabled'] as bool?,
      ),
      wakeTime: json['wake_time'] as String?,
      sleepTime: json['sleep_time'] as String?,
      microphoneEnabled: json['microphone_enabled'] as bool? ?? false,
      locationEnabled: json['location_enabled'] as bool? ?? false,
      reminderPreferences:
          json['reminder_preferences'] as Map<String, dynamic>? ?? const {},
    );
  }

  ThemeMode get themeMode {
    return switch (theme) {
      'light' => ThemeMode.light,
      'system' => ThemeMode.system,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.light,
    };
  }

  String get languageLabel => language == 'ar' ? 'Arabic' : 'English';

  String get themeLabel {
    return switch (theme) {
      'light' => 'Light',
      'system' => 'System',
      _ => 'Dark',
    };
  }

  String get notificationSummary =>
      notificationsEnabled ? 'Enabled' : 'Disabled';

  String get prayerSummary =>
      '$prayerCalculationMethod, $prayerReminderMinutesBefore min before, '
      '${PrayerNotificationSound.label(prayerNotificationSound)}';

  String get focusSummary {
    final timing = reminderPreferences['timing'];
    if (timing is Map<String, dynamic>) {
      final minutes = timing['focus_prompt_minutes_before'] as int? ?? 10;
      return 'Focus prompt $minutes min before';
    }
    return 'Focus reminder defaults';
  }
}
