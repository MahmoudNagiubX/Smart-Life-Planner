class OnboardingWorkStudyWindow {
  final String windowType;
  final String? label;
  final String startTime;
  final String endTime;
  final List<int> days;

  const OnboardingWorkStudyWindow({
    this.windowType = 'custom',
    this.label,
    required this.startTime,
    required this.endTime,
    this.days = const [],
  });

  OnboardingWorkStudyWindow copyWith({
    String? windowType,
    Object? label = OnboardingData._unset,
    String? startTime,
    String? endTime,
    List<int>? days,
  }) {
    return OnboardingWorkStudyWindow(
      windowType: windowType ?? this.windowType,
      label: label == OnboardingData._unset
          ? this.label
          : OnboardingData._emptyToNull(label as String?),
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      days: days ?? this.days,
    );
  }

  factory OnboardingWorkStudyWindow.fromJson(Map<String, dynamic> json) {
    return OnboardingWorkStudyWindow(
      windowType: json['window_type'] as String? ?? 'custom',
      label: OnboardingData._emptyToNull(json['label'] as String?),
      startTime: json['start_time'] as String,
      endTime: json['end_time'] as String,
      days: (json['days'] as List<dynamic>? ?? const [])
          .whereType<int>()
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'window_type': windowType,
      if (OnboardingData._emptyToNull(label) != null)
        'label': OnboardingData._emptyToNull(label),
      'start_time': startTime,
      'end_time': endTime,
      'days': days,
    };
  }
}

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
  final List<OnboardingWorkStudyWindow> workStudyWindows;
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
    List<OnboardingWorkStudyWindow>? workStudyWindows,
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
      'work_study_windows': workStudyWindows
          .map((window) => window.toJson())
          .toList(growable: false),
      'notifications_enabled': notificationsEnabled,
      'microphone_enabled': microphoneEnabled,
      'location_enabled': locationEnabled,
    };
  }

  factory OnboardingData.fromJson(Map<String, dynamic> json) {
    return OnboardingData(
      timezone: json['timezone'] as String? ?? 'UTC',
      language: json['language'] as String? ?? 'en',
      prayerCalculationMethod:
          json['prayer_calculation_method'] as String? ?? 'MWL',
      country: _emptyToNull(json['country'] as String?),
      city: _emptyToNull(json['city'] as String?),
      goals: (json['goals'] as List<dynamic>? ?? const [])
          .whereType<String>()
          .toList(),
      wakeTime: _emptyToNull(json['wake_time'] as String?),
      sleepTime: _emptyToNull(json['sleep_time'] as String?),
      workStudyWindows:
          (json['work_study_windows'] as List<dynamic>? ?? const [])
              .whereType<Map<String, dynamic>>()
              .map(OnboardingWorkStudyWindow.fromJson)
              .toList(),
      notificationsEnabled: json['notifications_enabled'] as bool? ?? true,
      microphoneEnabled: json['microphone_enabled'] as bool? ?? false,
      locationEnabled: json['location_enabled'] as bool? ?? false,
    );
  }

  static String? _emptyToNull(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) return null;
    return trimmed;
  }
}
