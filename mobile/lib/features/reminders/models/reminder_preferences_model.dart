class ReminderPreferences {
  final ReminderChannels channels;
  final ReminderTypes types;
  final ReminderQuietHours quietHours;
  final ReminderTiming timing;

  const ReminderPreferences({
    required this.channels,
    required this.types,
    required this.quietHours,
    required this.timing,
  });

  factory ReminderPreferences.defaults() => const ReminderPreferences(
    channels: ReminderChannels(),
    types: ReminderTypes(),
    quietHours: ReminderQuietHours(),
    timing: ReminderTiming(),
  );

  factory ReminderPreferences.fromJson(Map<String, dynamic> json) {
    return ReminderPreferences(
      channels: ReminderChannels.fromJson(_map(json['channels'])),
      types: ReminderTypes.fromJson(_map(json['types'])),
      quietHours: ReminderQuietHours.fromJson(_map(json['quiet_hours'])),
      timing: ReminderTiming.fromJson(_map(json['timing'])),
    );
  }

  ReminderPreferences copyWith({
    ReminderChannels? channels,
    ReminderTypes? types,
    ReminderQuietHours? quietHours,
    ReminderTiming? timing,
  }) {
    return ReminderPreferences(
      channels: channels ?? this.channels,
      types: types ?? this.types,
      quietHours: quietHours ?? this.quietHours,
      timing: timing ?? this.timing,
    );
  }

  Map<String, dynamic> toJson() => {
    'channels': channels.toJson(),
    'types': types.toJson(),
    'quiet_hours': quietHours.toJson(),
    'timing': timing.toJson(),
  };
}

class ReminderChannels {
  final bool local;
  final bool push;
  final bool inApp;
  final bool email;

  const ReminderChannels({
    this.local = true,
    this.push = true,
    this.inApp = true,
    this.email = false,
  });

  factory ReminderChannels.fromJson(Map<String, dynamic> json) {
    return ReminderChannels(
      local: json['local'] as bool? ?? true,
      push: json['push'] as bool? ?? true,
      inApp: json['in_app'] as bool? ?? true,
      email: json['email'] as bool? ?? false,
    );
  }

  ReminderChannels copyWith({
    bool? local,
    bool? push,
    bool? inApp,
    bool? email,
  }) {
    return ReminderChannels(
      local: local ?? this.local,
      push: push ?? this.push,
      inApp: inApp ?? this.inApp,
      email: email ?? this.email,
    );
  }

  Map<String, dynamic> toJson() => {
    'local': local,
    'push': push,
    'in_app': inApp,
    'email': email,
  };
}

class ReminderTypes {
  final bool task;
  final bool habit;
  final bool note;
  final bool quranGoal;
  final bool prayer;
  final bool focusPrompt;
  final bool bedtime;
  final bool aiSuggestion;
  final bool location;
  final bool constantReminders;

  const ReminderTypes({
    this.task = true,
    this.habit = true,
    this.note = true,
    this.quranGoal = true,
    this.prayer = true,
    this.focusPrompt = true,
    this.bedtime = true,
    this.aiSuggestion = true,
    this.location = false,
    this.constantReminders = true,
  });

  factory ReminderTypes.fromJson(Map<String, dynamic> json) {
    return ReminderTypes(
      task: json['task'] as bool? ?? true,
      habit: json['habit'] as bool? ?? true,
      note: json['note'] as bool? ?? true,
      quranGoal: json['quran_goal'] as bool? ?? true,
      prayer: json['prayer'] as bool? ?? true,
      focusPrompt: json['focus_prompt'] as bool? ?? true,
      bedtime: json['bedtime'] as bool? ?? true,
      aiSuggestion: json['ai_suggestion'] as bool? ?? true,
      location: json['location'] as bool? ?? false,
      constantReminders: json['constant_reminders'] as bool? ?? true,
    );
  }

  ReminderTypes copyWith({
    bool? task,
    bool? habit,
    bool? note,
    bool? quranGoal,
    bool? prayer,
    bool? focusPrompt,
    bool? bedtime,
    bool? aiSuggestion,
    bool? location,
    bool? constantReminders,
  }) {
    return ReminderTypes(
      task: task ?? this.task,
      habit: habit ?? this.habit,
      note: note ?? this.note,
      quranGoal: quranGoal ?? this.quranGoal,
      prayer: prayer ?? this.prayer,
      focusPrompt: focusPrompt ?? this.focusPrompt,
      bedtime: bedtime ?? this.bedtime,
      aiSuggestion: aiSuggestion ?? this.aiSuggestion,
      location: location ?? this.location,
      constantReminders: constantReminders ?? this.constantReminders,
    );
  }

  bool isEnabled(String type) {
    switch (type) {
      case 'task':
        return task;
      case 'habit':
        return habit;
      case 'note':
        return note;
      case 'quran_goal':
        return quranGoal;
      case 'prayer':
        return prayer;
      case 'focus_prompt':
        return focusPrompt;
      case 'bedtime':
        return bedtime;
      case 'ai_suggestion':
        return aiSuggestion;
      case 'location':
        return location;
      case 'constant_reminders':
        return constantReminders;
      default:
        return true;
    }
  }

  Map<String, dynamic> toJson() => {
    'task': task,
    'habit': habit,
    'note': note,
    'quran_goal': quranGoal,
    'prayer': prayer,
    'focus_prompt': focusPrompt,
    'bedtime': bedtime,
    'ai_suggestion': aiSuggestion,
    'location': location,
    'constant_reminders': constantReminders,
  };
}

class ReminderQuietHours {
  final bool enabled;
  final String start;
  final String end;

  const ReminderQuietHours({
    this.enabled = false,
    this.start = '22:00',
    this.end = '07:00',
  });

  factory ReminderQuietHours.fromJson(Map<String, dynamic> json) {
    return ReminderQuietHours(
      enabled: json['enabled'] as bool? ?? false,
      start: json['start'] as String? ?? '22:00',
      end: json['end'] as String? ?? '07:00',
    );
  }

  ReminderQuietHours copyWith({bool? enabled, String? start, String? end}) {
    return ReminderQuietHours(
      enabled: enabled ?? this.enabled,
      start: start ?? this.start,
      end: end ?? this.end,
    );
  }

  Map<String, dynamic> toJson() => {
    'enabled': enabled,
    'start': start,
    'end': end,
  };
}

class ReminderTiming {
  final int prayerMinutesBefore;
  final int bedtimeMinutesBefore;
  final int focusPromptMinutesBefore;

  const ReminderTiming({
    this.prayerMinutesBefore = 10,
    this.bedtimeMinutesBefore = 30,
    this.focusPromptMinutesBefore = 10,
  });

  factory ReminderTiming.fromJson(Map<String, dynamic> json) {
    return ReminderTiming(
      prayerMinutesBefore: json['prayer_minutes_before'] as int? ?? 10,
      bedtimeMinutesBefore: json['bedtime_minutes_before'] as int? ?? 30,
      focusPromptMinutesBefore:
          json['focus_prompt_minutes_before'] as int? ?? 10,
    );
  }

  ReminderTiming copyWith({
    int? prayerMinutesBefore,
    int? bedtimeMinutesBefore,
    int? focusPromptMinutesBefore,
  }) {
    return ReminderTiming(
      prayerMinutesBefore: prayerMinutesBefore ?? this.prayerMinutesBefore,
      bedtimeMinutesBefore: bedtimeMinutesBefore ?? this.bedtimeMinutesBefore,
      focusPromptMinutesBefore:
          focusPromptMinutesBefore ?? this.focusPromptMinutesBefore,
    );
  }

  Map<String, dynamic> toJson() => {
    'prayer_minutes_before': prayerMinutesBefore,
    'bedtime_minutes_before': bedtimeMinutesBefore,
    'focus_prompt_minutes_before': focusPromptMinutesBefore,
  };
}

Map<String, dynamic> _map(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}
