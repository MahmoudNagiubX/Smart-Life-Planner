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
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String?,
      frequencyType: json['frequency_type'] as String,
      frequencyConfig: json['frequency_config'] as Map<String, dynamic>?,
      category: json['category'] as String?,
      reminderTime: json['reminder_time'] as String?,
      isActive: json['is_active'] as bool,
      currentStreak: json['current_streak'] as int,
      longestStreak: json['longest_streak'] as int,
      createdAt: json['created_at'] as String,
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
      id: json['id'] as String,
      habitId: json['habit_id'] as String,
      logDate: json['log_date'] as String,
      isCompleted: json['is_completed'] as bool,
    );
  }
}
