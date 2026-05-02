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
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Dhikr reminder'),
      phrase: _asNullableString(json['phrase']),
      scheduleTime: _asString(json['schedule_time'], fallback: '08:00:00'),
      recurrenceRule: _normalizeRecurrence(json['recurrence_rule']),
      timezone: _asString(json['timezone'], fallback: 'UTC'),
      enabled: _asBool(json['enabled'], fallback: true),
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

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

String? _asNullableString(dynamic value) {
  if (value == null) return null;
  if (value is String) return value;
  return value.toString();
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

String _normalizeRecurrence(dynamic value) {
  final recurrence = _asString(value, fallback: 'daily').trim().toLowerCase();
  const allowed = {'once', 'daily', 'weekdays'};
  return allowed.contains(recurrence) ? recurrence : 'daily';
}
