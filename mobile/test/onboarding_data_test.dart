import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/onboarding/models/onboarding_data.dart';

void main() {
  test('serializes onboarding payload using backend contract keys', () {
    final data = OnboardingData(
      timezone: 'Africa/Cairo',
      language: 'ar',
      prayerCalculationMethod: 'Egypt',
      country: 'Egypt',
      city: 'Cairo',
      goals: const ['study', 'spiritual_growth'],
      wakeTime: '06:30',
      sleepTime: '22:45',
      workStudyWindows: const [
        OnboardingWorkStudyWindow(
          windowType: 'study',
          label: 'Evening study',
          startTime: '19:00',
          endTime: '21:00',
          days: [0, 1, 2, 3, 4],
        ),
      ],
      notificationsEnabled: false,
      microphoneEnabled: true,
      locationEnabled: true,
    );

    expect(data.toJson(), {
      'timezone': 'Africa/Cairo',
      'language': 'ar',
      'prayer_calculation_method': 'Egypt',
      'country': 'Egypt',
      'city': 'Cairo',
      'goals': ['study', 'spiritual_growth'],
      'wake_time': '06:30',
      'sleep_time': '22:45',
      'work_study_windows': [
        {
          'window_type': 'study',
          'label': 'Evening study',
          'start_time': '19:00',
          'end_time': '21:00',
          'days': [0, 1, 2, 3, 4],
        },
      ],
      'notifications_enabled': false,
      'microphone_enabled': true,
      'location_enabled': true,
    });
  });

  test('hydrates saved onboarding selections for editing later', () {
    final data = OnboardingData.fromJson({
      'timezone': 'Africa/Cairo',
      'language': 'en',
      'prayer_calculation_method': 'MWL',
      'goals': ['fitness'],
      'work_study_windows': [
        {
          'window_type': 'work',
          'start_time': '09:00',
          'end_time': '17:00',
          'days': [0, 1, 2, 3, 4],
        },
      ],
      'notifications_enabled': true,
      'microphone_enabled': false,
      'location_enabled': false,
    });

    expect(data.timezone, 'Africa/Cairo');
    expect(data.goals, ['fitness']);
    expect(data.workStudyWindows.single.windowType, 'work');
    expect(data.workStudyWindows.single.startTime, '09:00');
  });
}
