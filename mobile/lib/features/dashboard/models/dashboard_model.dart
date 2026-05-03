const defaultDashboardWidgets = [
  'productivity_score', // 1. Hero summary card
  'next_prayer',        // 2a. Prayer (paired row with focus_shortcut)
  'focus_shortcut',     // 2b. Focus (paired row with next_prayer)
  'top_tasks',          // 3. Today's Tasks
  'habit_snapshot',     // 4a. Habits (paired row with ai_plan)
  'ai_plan',            // 4b. AI Suggestion (paired row with habit_snapshot)
  'journal_prompt',     // 5. Optional journal prompt
  'quran_goal',         // 6. Optional Quran goal
];

class DashboardTopTask {
  final String id;
  final String title;
  final String priority;
  final String? dueAt;
  final String status;

  DashboardTopTask({
    required this.id,
    required this.title,
    required this.priority,
    this.dueAt,
    required this.status,
  });

  factory DashboardTopTask.fromJson(Map<String, dynamic> json) {
    return DashboardTopTask(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled task',
      priority: json['priority'] as String? ?? 'medium',
      dueAt: json['due_at'] as String?,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class PrayerProgress {
  final int completed;
  final int total;

  PrayerProgress({required this.completed, required this.total});

  factory PrayerProgress.fromJson(Map<String, dynamic> json) {
    return PrayerProgress(
      completed: _readInt(json['completed']) ?? 0,
      total: _readInt(json['total']) ?? 5,
    );
  }
}

class DashboardNextPrayer {
  final String? name;
  final String? scheduledAt;
  final bool enabled;

  DashboardNextPrayer({this.name, this.scheduledAt, required this.enabled});

  factory DashboardNextPrayer.fromJson(Map<String, dynamic> json) {
    return DashboardNextPrayer(
      name: json['name'] as String?,
      scheduledAt: json['scheduled_at'] as String?,
      enabled: json['enabled'] as bool? ?? false,
    );
  }
}

class DashboardHabitSnapshot {
  final int activeCount;
  final int completedToday;
  final String highlight;

  DashboardHabitSnapshot({
    required this.activeCount,
    required this.completedToday,
    required this.highlight,
  });

  factory DashboardHabitSnapshot.fromJson(Map<String, dynamic> json) {
    return DashboardHabitSnapshot(
      activeCount: _readInt(json['active_count']) ?? 0,
      completedToday: _readInt(json['completed_today']) ?? 0,
      highlight: json['highlight'] as String? ?? 'No habits yet',
    );
  }
}

class DashboardAiPlanCard {
  final String title;
  final String preview;

  DashboardAiPlanCard({required this.title, required this.preview});

  factory DashboardAiPlanCard.fromJson(Map<String, dynamic> json) {
    return DashboardAiPlanCard(
      title: json['title'] as String? ?? 'Personalized plan',
      preview: json['preview'] as String? ?? 'Build a balanced plan today.',
    );
  }
}

class DashboardFocusShortcut {
  final String label;
  final int suggestedMinutes;

  DashboardFocusShortcut({required this.label, required this.suggestedMinutes});

  factory DashboardFocusShortcut.fromJson(Map<String, dynamic> json) {
    return DashboardFocusShortcut(
      label: json['label'] as String? ?? 'Start focus',
      suggestedMinutes: _readInt(json['suggested_minutes']) ?? 25,
    );
  }
}

class DashboardQuranGoalSummary {
  final bool enabled;
  final int dailyPageTarget;
  final int todayPagesCompleted;
  final int progressPercent;

  DashboardQuranGoalSummary({
    required this.enabled,
    required this.dailyPageTarget,
    required this.todayPagesCompleted,
    required this.progressPercent,
  });

  factory DashboardQuranGoalSummary.fromJson(Map<String, dynamic> json) {
    return DashboardQuranGoalSummary(
      enabled: json['enabled'] as bool? ?? false,
      dailyPageTarget: _readInt(json['daily_page_target']) ?? 0,
      todayPagesCompleted: _readInt(json['today_pages_completed']) ?? 0,
      progressPercent: _readInt(json['progress_percent']) ?? 0,
    );
  }
}

class DashboardRamadanStatus {
  final bool enabled;
  final bool todayLogged;
  final bool? fasted;
  final String label;

  DashboardRamadanStatus({
    required this.enabled,
    required this.todayLogged,
    required this.fasted,
    required this.label,
  });

  factory DashboardRamadanStatus.fromJson(Map<String, dynamic> json) {
    return DashboardRamadanStatus(
      enabled: json['enabled'] as bool? ?? false,
      todayLogged: json['today_logged'] as bool? ?? false,
      fasted: json['fasted'] as bool?,
      label: json['label'] as String? ?? 'Ramadan mode is off',
    );
  }
}

class DashboardQiblaShortcut {
  final bool available;
  final String label;

  DashboardQiblaShortcut({required this.available, required this.label});

  factory DashboardQiblaShortcut.fromJson(Map<String, dynamic> json) {
    return DashboardQiblaShortcut(
      available: json['available'] as bool? ?? false,
      label: json['label'] as String? ?? 'Open Qibla direction',
    );
  }
}

class DashboardSpiritualSummary {
  final DashboardNextPrayer nextPrayer;
  final PrayerProgress prayerProgress;
  final DashboardQuranGoalSummary quranGoal;
  final DashboardRamadanStatus ramadan;
  final DashboardQiblaShortcut qibla;

  DashboardSpiritualSummary({
    required this.nextPrayer,
    required this.prayerProgress,
    required this.quranGoal,
    required this.ramadan,
    required this.qibla,
  });

  factory DashboardSpiritualSummary.fromJson(Map<String, dynamic> json) {
    return DashboardSpiritualSummary(
      nextPrayer: DashboardNextPrayer.fromJson(
        json['next_prayer'] as Map<String, dynamic>? ?? const {},
      ),
      prayerProgress: PrayerProgress.fromJson(
        json['prayer_progress'] as Map<String, dynamic>? ?? const {},
      ),
      quranGoal: DashboardQuranGoalSummary.fromJson(
        json['quran_goal'] as Map<String, dynamic>? ?? const {},
      ),
      ramadan: DashboardRamadanStatus.fromJson(
        json['ramadan'] as Map<String, dynamic>? ?? const {},
      ),
      qibla: DashboardQiblaShortcut.fromJson(
        json['qibla'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

class DashboardPersonalization {
  final List<String> goalTags;
  final List<String> goalLabels;
  final String taskEnvironment;
  final List<String> dailyDashboardWidgets;
  final DashboardNextPrayer nextPrayer;
  final DashboardSpiritualSummary spiritualSummary;
  final DashboardHabitSnapshot habitSnapshot;
  final String journalPrompt;
  final DashboardAiPlanCard aiPlanCard;
  final DashboardFocusShortcut focusShortcut;

  DashboardPersonalization({
    required this.goalTags,
    required this.goalLabels,
    required this.taskEnvironment,
    required this.dailyDashboardWidgets,
    required this.nextPrayer,
    required this.spiritualSummary,
    required this.habitSnapshot,
    required this.journalPrompt,
    required this.aiPlanCard,
    required this.focusShortcut,
  });

  factory DashboardPersonalization.fromJson(Map<String, dynamic> json) {
    final dashboardWidgets = json.containsKey('daily_dashboard_widgets')
        ? _readStringList(json['daily_dashboard_widgets'])
        : defaultDashboardWidgets;
    return DashboardPersonalization(
      goalTags: _readStringList(json['goal_tags']),
      goalLabels: _readStringList(json['goal_labels']),
      taskEnvironment:
          json['task_environment'] as String? ?? 'Balanced daily planning',
      dailyDashboardWidgets: dashboardWidgets,
      nextPrayer: DashboardNextPrayer.fromJson(
        json['next_prayer'] as Map<String, dynamic>? ?? const {},
      ),
      spiritualSummary: DashboardSpiritualSummary.fromJson(
        json['spiritual_summary'] as Map<String, dynamic>? ?? const {},
      ),
      habitSnapshot: DashboardHabitSnapshot.fromJson(
        json['habit_snapshot'] as Map<String, dynamic>? ?? const {},
      ),
      journalPrompt:
          json['journal_prompt'] as String? ??
          'What is one thing worth remembering from today?',
      aiPlanCard: DashboardAiPlanCard.fromJson(
        json['ai_plan_card'] as Map<String, dynamic>? ?? const {},
      ),
      focusShortcut: DashboardFocusShortcut.fromJson(
        json['focus_shortcut'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  factory DashboardPersonalization.empty() {
    return DashboardPersonalization.fromJson(const {});
  }
}

class DashboardData {
  final int pendingCount;
  final int completedToday;
  final PrayerProgress prayerProgress;
  final List<DashboardTopTask> topTasks;
  final DashboardPersonalization personalization;

  DashboardData({
    required this.pendingCount,
    required this.completedToday,
    required this.prayerProgress,
    required this.topTasks,
    required this.personalization,
  });

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      pendingCount: _readInt(json['pending_count']) ?? 0,
      completedToday: _readInt(json['completed_today']) ?? 0,
      prayerProgress: PrayerProgress.fromJson(
        json['prayer_progress'] as Map<String, dynamic>? ?? const {},
      ),
      topTasks: (json['top_tasks'] as List<dynamic>? ?? const [])
          .map((t) => DashboardTopTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      personalization: DashboardPersonalization.fromJson(
        json['personalization'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}

int? _readInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.round();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _readStringList(dynamic value) {
  if (value is! List) return const [];
  return value.whereType<String>().toList();
}
