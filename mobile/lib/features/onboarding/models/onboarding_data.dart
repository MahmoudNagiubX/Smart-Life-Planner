class OnboardingData {
  static const Object _unset = Object();

  final String timezone;
  final String language;
  final String prayerCalculationMethod;
  final String? country;
  final String? city;
  final List<String> goals;
  final String? wakeTime;
  final String? sleepTime;
  final List<Map<String, dynamic>> workStudyWindows;
  final bool notificationsEnabled;
  final bool microphoneEnabled;
  final bool locationEnabled;

  const OnboardingData({
    this.timezone = 'UTC',
    this.language = 'en',
    this.prayerCalculationMethod = 'MWL',
    this.country,
    this.city,
    this.goals = const [],
    this.wakeTime,
    this.sleepTime,
    this.workStudyWindows = const [],
    this.notificationsEnabled = true,
    this.microphoneEnabled = false,
    this.locationEnabled = false,
  });

  bool get hasRequiredSelections =>
      language.isNotEmpty &&
      timezone.isNotEmpty &&
      prayerCalculationMethod.isNotEmpty;

  OnboardingData copyWith({
    String? timezone,
    String? language,
    String? prayerCalculationMethod,
    Object? country = _unset,
    Object? city = _unset,
    List<String>? goals,
    Object? wakeTime = _unset,
    Object? sleepTime = _unset,
    List<Map<String, dynamic>>? workStudyWindows,
    bool? notificationsEnabled,
    bool? microphoneEnabled,
    bool? locationEnabled,
  }) {
    return OnboardingData(
      timezone: timezone ?? this.timezone,
      language: language ?? this.language,
      prayerCalculationMethod:
          prayerCalculationMethod ?? this.prayerCalculationMethod,
      country: country == _unset
          ? this.country
          : _emptyToNull(country as String?),
      city: city == _unset ? this.city : _emptyToNull(city as String?),
      goals: goals ?? this.goals,
      wakeTime: wakeTime == _unset
          ? this.wakeTime
          : _emptyToNull(wakeTime as String?),
      sleepTime: sleepTime == _unset
          ? this.sleepTime
          : _emptyToNull(sleepTime as String?),
      workStudyWindows: workStudyWindows ?? this.workStudyWindows,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      microphoneEnabled: microphoneEnabled ?? this.microphoneEnabled,
      locationEnabled: locationEnabled ?? this.locationEnabled,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'timezone': timezone,
      'language': language,
      'prayer_calculation_method': prayerCalculationMethod,
      if (_emptyToNull(country) != null) 'country': _emptyToNull(country),
      if (_emptyToNull(city) != null) 'city': _emptyToNull(city),
      'goals': goals,
      if (wakeTime != null) 'wake_time': wakeTime,
      if (sleepTime != null) 'sleep_time': sleepTime,
      'work_study_windows': workStudyWindows,
      'notifications_enabled': notificationsEnabled,
      'microphone_enabled': microphoneEnabled,
      'location_enabled': locationEnabled,
    };
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
