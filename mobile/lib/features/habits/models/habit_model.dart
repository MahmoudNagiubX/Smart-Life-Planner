class HabitModel {
  final String id;
  final String title;
  final String? description;
  final String frequencyType;
  final Map<String, dynamic>? frequencyConfig;
  final String? category;
  final String? reminderTime;
  final bool isActive;
  final int currentStreak;
  final int longestStreak;
  final String createdAt;

  HabitModel({
    required this.id,
    required this.title,
    this.description,
    required this.frequencyType,
    this.frequencyConfig,
    this.category,
    this.reminderTime,
    required this.isActive,
    required this.currentStreak,
    required this.longestStreak,
    required this.createdAt,
  });

  factory HabitModel.fromJson(Map<String, dynamic> json) {
    return HabitModel(
      id: _asString(json['id']),
      title: _asString(json['title'], fallback: 'Untitled habit'),
      description: _asNullableString(json['description']),
      frequencyType: _asString(json['frequency_type'], fallback: 'daily'),
      frequencyConfig: _asMap(json['frequency_config']),
      category: _asNullableString(json['category']),
      reminderTime: _asNullableString(json['reminder_time']),
      isActive: _asBool(json['is_active'], fallback: true),
      currentStreak: _asInt(json['current_streak']),
      longestStreak: _asInt(json['longest_streak']),
      createdAt: _asString(json['created_at']),
    );
  }
}

class HabitLogModel {
  final String id;
  final String habitId;
  final String logDate;
  final bool isCompleted;

  HabitLogModel({
    required this.id,
    required this.habitId,
    required this.logDate,
    required this.isCompleted,
  });

  factory HabitLogModel.fromJson(Map<String, dynamic> json) {
    return HabitLogModel(
      id: _asString(json['id']),
      habitId: _asString(json['habit_id']),
      logDate: _asString(json['log_date']),
      isCompleted: _asBool(json['is_completed'], fallback: true),
    );
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

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
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

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
