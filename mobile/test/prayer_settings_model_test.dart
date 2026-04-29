import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/prayer_notification_sound.dart';
import 'package:smart_life_planner/features/prayer/models/prayer_settings_model.dart';

void main() {
  test('PrayerSettings parses supported prayer notification sound', () {
    final settings = PrayerSettings.fromJson({
      'prayer_notification_sound': PrayerNotificationSound.silent,
    });

    expect(settings.prayerNotificationSound, PrayerNotificationSound.silent);
    expect(settings.athanSoundEnabled, isFalse);
  });

  test('PrayerSettings uses legacy Athan boolean as fallback', () {
    final settings = PrayerSettings.fromJson({'athan_sound_enabled': true});

    expect(settings.prayerNotificationSound, PrayerNotificationSound.athan);
    expect(settings.athanSoundEnabled, isTrue);
  });
}
