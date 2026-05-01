class DhikrReminderModel {
  final String id;
  final String title;
  final String? phrase;
  final String scheduleTime;
  final String recurrenceRule;
  final String timezone;
  final bool enabled;

  const DhikrReminderModel({
    required this.id,
    required this.title,
    this.phrase,
    required this.scheduleTime,
    required this.recurrenceRule,
    required this.timezone,
    required this.enabled,
  });

  factory DhikrReminderModel.fromJson(Map<String, dynamic> json) {
    return DhikrReminderModel(
      id: json['id'] as String,
      title: json['title'] as String,
      phrase: json['phrase'] as String?,
      scheduleTime: json['schedule_time'] as String,
      recurrenceRule: json['recurrence_rule'] as String? ?? 'daily',
      timezone: json['timezone'] as String? ?? 'UTC',
      enabled: json['enabled'] as bool? ?? true,
    );
  }
}

class DhikrReminderDraft {
  final String title;
  final String? phrase;
  final String scheduleTime;
  final String recurrenceRule;
  final String timezone;
  final bool enabled;

  const DhikrReminderDraft({
    required this.title,
    this.phrase,
    required this.scheduleTime,
    this.recurrenceRule = 'daily',
    this.timezone = 'UTC',
    this.enabled = true,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      if (phrase != null && phrase!.trim().isNotEmpty) 'phrase': phrase,
      'schedule_time': scheduleTime,
      'recurrence_rule': recurrenceRule,
      'timezone': timezone,
      'enabled': enabled,
    };
  }
}
