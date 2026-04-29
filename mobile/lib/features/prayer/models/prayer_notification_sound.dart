class PrayerNotificationSound {
  static const defaultSound = 'default';
  static const silent = 'silent';
  static const athan = 'athan';
  static const athanAssetPath = 'assets/audio/athan_soft.wav';

  static const values = [defaultSound, silent, athan];
  static const supported = {defaultSound, silent, athan};

  static String normalize(String? value, {bool? legacyAthanEnabled}) {
    if (value != null && supported.contains(value)) return value;
    if (legacyAthanEnabled == true) return athan;
    return defaultSound;
  }

  static String label(String soundKey) {
    return switch (normalize(soundKey)) {
      PrayerNotificationSound.silent => 'Silent',
      PrayerNotificationSound.athan => 'Athan sound',
      _ => 'Default sound',
    };
  }

  static String description(String soundKey) {
    return switch (normalize(soundKey)) {
      PrayerNotificationSound.silent =>
        'No sound for prayer reminders where the device allows it.',
      PrayerNotificationSound.athan =>
        'Use the bundled local Athan notification sound.',
      _ => 'Use the device default notification sound.',
    };
  }
}
