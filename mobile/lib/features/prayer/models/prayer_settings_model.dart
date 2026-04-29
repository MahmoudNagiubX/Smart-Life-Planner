import 'prayer_notification_sound.dart';

class PrayerSettings {
  final String prayerCalculationMethod;
  final double? prayerLocationLat;
  final double? prayerLocationLng;
  final String? city;
  final int prayerReminderMinutesBefore;
  final bool athanSoundEnabled;
  final String prayerNotificationSound;
  final bool ramadanModeEnabled;

  const PrayerSettings({
    required this.prayerCalculationMethod,
    required this.prayerLocationLat,
    required this.prayerLocationLng,
    required this.city,
    required this.prayerReminderMinutesBefore,
    required this.athanSoundEnabled,
    required this.prayerNotificationSound,
    required this.ramadanModeEnabled,
  });

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    final athanSoundEnabled = json['athan_sound_enabled'] as bool? ?? false;
    final prayerNotificationSound = PrayerNotificationSound.normalize(
      json['prayer_notification_sound'] as String?,
      legacyAthanEnabled: athanSoundEnabled,
    );
    return PrayerSettings(
      prayerCalculationMethod:
          json['prayer_calculation_method'] as String? ?? 'MWL',
      prayerLocationLat: (json['prayer_location_lat'] as num?)?.toDouble(),
      prayerLocationLng: (json['prayer_location_lng'] as num?)?.toDouble(),
      city: json['city'] as String?,
      prayerReminderMinutesBefore:
          json['prayer_reminder_minutes_before'] as int? ?? 10,
      athanSoundEnabled:
          prayerNotificationSound == PrayerNotificationSound.athan,
      prayerNotificationSound: prayerNotificationSound,
      ramadanModeEnabled: json['ramadan_mode_enabled'] as bool? ?? false,
    );
  }
}
