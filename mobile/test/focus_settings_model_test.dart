import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/focus/models/focus_model.dart';

void main() {
  test('FocusSettings parses and serializes backend contract', () {
    final settings = FocusSettings.fromJson(const {
      'default_focus_minutes': 45,
      'short_break_minutes': 7,
      'long_break_minutes': 20,
      'sessions_before_long_break': 3,
      'continuous_mode_enabled': true,
      'ambient_sound_key': 'rain',
      'distraction_free_mode_enabled': true,
    });

    expect(settings.defaultFocusMinutes, 45);
    expect(settings.shortBreakMinutes, 7);
    expect(settings.longBreakMinutes, 20);
    expect(settings.sessionsBeforeLongBreak, 3);
    expect(settings.continuousModeEnabled, isTrue);
    expect(settings.ambientSoundKey, 'rain');
    expect(settings.distractionFreeModeEnabled, isTrue);
    expect(settings.toJson()['default_focus_minutes'], 45);
    expect(settings.toJson()['ambient_sound_key'], 'rain');
  });
}
