class QuranGoal {
  final String id;
  final String userId;
  final int dailyPageTarget;
  final String createdAt;
  final String updatedAt;

  const QuranGoal({
    required this.id,
    required this.userId,
    required this.dailyPageTarget,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuranGoal.fromJson(Map<String, dynamic> json) {
    return QuranGoal(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      dailyPageTarget: json['daily_page_target'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class QuranProgress {
  final String id;
  final String userId;
  final String progressDate;
  final int pagesCompleted;
  final String createdAt;
  final String updatedAt;

  const QuranProgress({
    required this.id,
    required this.userId,
    required this.progressDate,
    required this.pagesCompleted,
    required this.createdAt,
    required this.updatedAt,
  });

  factory QuranProgress.fromJson(Map<String, dynamic> json) {
    return QuranProgress(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      progressDate: json['progress_date'] as String,
      pagesCompleted: json['pages_completed'] as int,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class QuranWeeklyProgressItem {
  final String progressDate;
  final int pagesCompleted;
  final bool targetMet;

  const QuranWeeklyProgressItem({
    required this.progressDate,
    required this.pagesCompleted,
    required this.targetMet,
  });

  factory QuranWeeklyProgressItem.fromJson(Map<String, dynamic> json) {
    return QuranWeeklyProgressItem(
      progressDate: json['progress_date'] as String,
      pagesCompleted: json['pages_completed'] as int,
      targetMet: json['target_met'] as bool,
    );
  }
}

class QuranGoalSummary {
  final QuranGoal? goal;
  final QuranProgress? today;
  final int todayPagesCompleted;
  final int progressPercent;
  final int weeklyTotalPages;
  final int weeklyTargetPages;
  final List<QuranWeeklyProgressItem> weeklySummary;

  const QuranGoalSummary({
    required this.goal,
    required this.today,
    required this.todayPagesCompleted,
    required this.progressPercent,
    required this.weeklyTotalPages,
    required this.weeklyTargetPages,
    required this.weeklySummary,
  });

  int get dailyPageTarget => goal?.dailyPageTarget ?? 0;

  factory QuranGoalSummary.fromJson(Map<String, dynamic> json) {
    return QuranGoalSummary(
      goal: json['goal'] == null
          ? null
          : QuranGoal.fromJson(json['goal'] as Map<String, dynamic>),
      today: json['today'] == null
          ? null
          : QuranProgress.fromJson(json['today'] as Map<String, dynamic>),
      todayPagesCompleted: json['today_pages_completed'] as int? ?? 0,
      progressPercent: json['progress_percent'] as int? ?? 0,
      weeklyTotalPages: json['weekly_total_pages'] as int? ?? 0,
      weeklyTargetPages: json['weekly_target_pages'] as int? ?? 0,
      weeklySummary: (json['weekly_summary'] as List<dynamic>? ?? [])
          .map(
            (item) =>
                QuranWeeklyProgressItem.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
    );
  }
}
