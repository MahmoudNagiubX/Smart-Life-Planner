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
      date: json['date'] as String,
      tasksCompleted: json['tasks_completed'] as int,
      tasksPending: json['tasks_pending'] as int,
      focusMinutes: json['focus_minutes'] as int,
      focusSessions: json['focus_sessions'] as int,
      habitsCompleted: json['habits_completed'] as int,
      totalHabits: json['total_habits'] as int,
      prayersCompleted: json['prayers_completed'] as int,
      totalPrayers: json['total_prayers'] as int,
      productivityScore: json['productivity_score'] as int,
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
      date: json['date'] as String,
      dayLabel: json['day_label'] as String,
      tasksCompleted: json['tasks_completed'] as int,
      focusMinutes: json['focus_minutes'] as int,
      habitsCompleted: json['habits_completed'] as int,
      prayersCompleted: json['prayers_completed'] as int,
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
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalTasksCompleted: json['total_tasks_completed'] as int,
      totalFocusMinutes: json['total_focus_minutes'] as int,
      totalHabitsLogged: json['total_habits_logged'] as int,
      totalPrayersCompleted: json['total_prayers_completed'] as int,
      totalNotesCreated: json['total_notes_created'] as int? ?? 0,
      bestHabitStreak: json['best_habit_streak'] as int,
      avgProductivityScore: json['avg_productivity_score'] as int,
      dailyBreakdown: (json['daily_breakdown'] as List<dynamic>)
          .map((d) => DailyBreakdown.fromJson(d as Map<String, dynamic>))
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
      type: json['type'] as String,
      emoji: json['emoji'] as String,
      title: json['title'] as String,
      message: json['message'] as String,
    );
  }
}
