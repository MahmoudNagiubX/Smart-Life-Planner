class PrayerSettings {
  final String prayerCalculationMethod;
  final double? prayerLocationLat;
  final double? prayerLocationLng;
  final String? city;
  final int prayerReminderMinutesBefore;
  final bool athanSoundEnabled;
  final bool ramadanModeEnabled;

  const PrayerSettings({
    required this.prayerCalculationMethod,
    required this.prayerLocationLat,
    required this.prayerLocationLng,
    required this.city,
    required this.prayerReminderMinutesBefore,
    required this.athanSoundEnabled,
    required this.ramadanModeEnabled,
  });

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    return PrayerSettings(
      prayerCalculationMethod:
          json['prayer_calculation_method'] as String? ?? 'MWL',
      prayerLocationLat: (json['prayer_location_lat'] as num?)?.toDouble(),
      prayerLocationLng: (json['prayer_location_lng'] as num?)?.toDouble(),
      city: json['city'] as String?,
      prayerReminderMinutesBefore:
          json['prayer_reminder_minutes_before'] as int? ?? 10,
      athanSoundEnabled: json['athan_sound_enabled'] as bool? ?? false,
      ramadanModeEnabled: json['ramadan_mode_enabled'] as bool? ?? false,
    );
  }
}
