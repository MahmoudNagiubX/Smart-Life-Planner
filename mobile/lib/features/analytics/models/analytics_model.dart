class TodayAnalytics {
  final String date;
  final int tasksCompleted;
  final int tasksPending;
  final int focusMinutes;
  final int focusSessions;
  final int habitsCompleted;
  final int totalHabits;
  final int prayersCompleted;
  final int totalPrayers;
  final int productivityScore;

  TodayAnalytics({
    required this.date,
    required this.tasksCompleted,
    required this.tasksPending,
    required this.focusMinutes,
    required this.focusSessions,
    required this.habitsCompleted,
    required this.totalHabits,
    required this.prayersCompleted,
    required this.totalPrayers,
    required this.productivityScore,
  });

  factory TodayAnalytics.fromJson(Map<String, dynamic> json) {
    return TodayAnalytics(
      date: _readString(json['date']),
      tasksCompleted: _readInt(json['tasks_completed']),
      tasksPending: _readInt(json['tasks_pending']),
      focusMinutes: _readInt(json['focus_minutes']),
      focusSessions: _readInt(json['focus_sessions']),
      habitsCompleted: _readInt(json['habits_completed']),
      totalHabits: _readInt(json['total_habits']),
      prayersCompleted: _readInt(json['prayers_completed']),
      totalPrayers: _readInt(json['total_prayers'], fallback: 5),
      productivityScore: _readInt(json['productivity_score']),
    );
  }
}

class DailyBreakdown {
  final String date;
  final String dayLabel;
  final int tasksCompleted;
  final int focusMinutes;
  final int habitsCompleted;
  final int prayersCompleted;

  DailyBreakdown({
    required this.date,
    required this.dayLabel,
    required this.tasksCompleted,
    required this.focusMinutes,
    required this.habitsCompleted,
    required this.prayersCompleted,
  });

  factory DailyBreakdown.fromJson(Map<String, dynamic> json) {
    return DailyBreakdown(
      date: _readString(json['date']),
      dayLabel: _readString(json['day_label']),
      tasksCompleted: _readInt(json['tasks_completed']),
      focusMinutes: _readInt(json['focus_minutes']),
      habitsCompleted: _readInt(json['habits_completed']),
      prayersCompleted: _readInt(json['prayers_completed']),
    );
  }
}

class WeeklyAnalytics {
  final String weekStart;
  final String weekEnd;
  final int totalTasksCompleted;
  final int totalFocusMinutes;
  final int totalHabitsLogged;
  final int totalPrayersCompleted;
  final int totalNotesCreated;
  final int bestHabitStreak;
  final int avgProductivityScore;
  final List<DailyBreakdown> dailyBreakdown;

  WeeklyAnalytics({
    required this.weekStart,
    required this.weekEnd,
    required this.totalTasksCompleted,
    required this.totalFocusMinutes,
    required this.totalHabitsLogged,
    required this.totalPrayersCompleted,
    required this.totalNotesCreated,
    required this.bestHabitStreak,
    required this.avgProductivityScore,
    required this.dailyBreakdown,
  });

  /// Algorithm: Aggregation Mapping
  /// Used for: Weekly analytics summary hydration.
  /// Complexity: O(n) over daily breakdown rows.
  /// Notes: Converts grouped backend analytics into app-ready summary models.
  factory WeeklyAnalytics.fromJson(Map<String, dynamic> json) {
    return WeeklyAnalytics(
      weekStart: _readString(json['week_start']),
      weekEnd: _readString(json['week_end']),
      totalTasksCompleted: _readInt(json['total_tasks_completed']),
      totalFocusMinutes: _readInt(json['total_focus_minutes']),
      totalHabitsLogged: _readInt(json['total_habits_logged']),
      totalPrayersCompleted: _readInt(json['total_prayers_completed']),
      totalNotesCreated: _readInt(json['total_notes_created']),
      bestHabitStreak: _readInt(json['best_habit_streak']),
      avgProductivityScore: _readInt(json['avg_productivity_score']),
      dailyBreakdown: (json['daily_breakdown'] as List<dynamic>? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(DailyBreakdown.fromJson)
          .toList(),
    );
  }
}

class AnalyticsInsight {
  final String type;
  final String emoji;
  final String title;
  final String message;

  AnalyticsInsight({
    required this.type,
    required this.emoji,
    required this.title,
    required this.message,
  });

  factory AnalyticsInsight.fromJson(Map<String, dynamic> json) {
    return AnalyticsInsight(
      type: _readString(json['type']),
      emoji: _readString(json['emoji']),
      title: _readString(json['title'], fallback: 'Insight'),
      message: _readString(json['message']),
    );
  }
}

int _readInt(dynamic value, {int fallback = 0}) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String _readString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}
