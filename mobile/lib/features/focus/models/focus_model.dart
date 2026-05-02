class FocusSession {
  final String id;
  final String? taskId;
  final String sessionType;
  final int plannedMinutes;
  final int? actualMinutes;
  final String status;
  final String startedAt;
  final String? endedAt;

  FocusSession({
    required this.id,
    this.taskId,
    required this.sessionType,
    required this.plannedMinutes,
    this.actualMinutes,
    required this.status,
    required this.startedAt,
    this.endedAt,
  });

  factory FocusSession.fromJson(Map<String, dynamic> json) {
    return FocusSession(
      id: json['id'] as String,
      taskId: json['task_id'] as String?,
      sessionType: json['session_type'] as String,
      plannedMinutes: json['planned_minutes'] as int,
      actualMinutes: json['actual_minutes'] as int?,
      status: json['status'] as String,
      startedAt: json['started_at'] as String,
      endedAt: json['ended_at'] as String?,
    );
  }

  FocusSession copyWith({
    String? id,
    String? taskId,
    String? sessionType,
    int? plannedMinutes,
    int? actualMinutes,
    String? status,
    String? startedAt,
    String? endedAt,
  }) {
    return FocusSession(
      id: id ?? this.id,
      taskId: taskId ?? this.taskId,
      sessionType: sessionType ?? this.sessionType,
      plannedMinutes: plannedMinutes ?? this.plannedMinutes,
      actualMinutes: actualMinutes ?? this.actualMinutes,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
    );
  }
}

class FocusAnalytics {
  final int todayMinutes;
  final int todaySessions;
  final int weekMinutes;
  final int weekSessions;
  final int completedSessions;
  final int currentStreakDays;
  final int longestStreakDays;
  final int averageSessionMinutes;
  final int completionRatePercent;
  final String reportSummary;

  FocusAnalytics({
    required this.todayMinutes,
    required this.todaySessions,
    required this.weekMinutes,
    required this.weekSessions,
    required this.completedSessions,
    required this.currentStreakDays,
    required this.longestStreakDays,
    required this.averageSessionMinutes,
    required this.completionRatePercent,
    required this.reportSummary,
  });

  factory FocusAnalytics.fromJson(Map<String, dynamic> json) {
    return FocusAnalytics(
      todayMinutes: json['today_minutes'] as int,
      todaySessions: json['today_sessions'] as int,
      weekMinutes: json['week_minutes'] as int,
      weekSessions: json['week_sessions'] as int,
      completedSessions: json['completed_sessions'] as int? ?? 0,
      currentStreakDays: json['current_streak_days'] as int? ?? 0,
      longestStreakDays: json['longest_streak_days'] as int? ?? 0,
      averageSessionMinutes: json['average_session_minutes'] as int? ?? 0,
      completionRatePercent: json['completion_rate_percent'] as int? ?? 0,
      reportSummary:
          json['report_summary'] as String? ??
          'No completed focus sessions today yet.',
    );
  }
}

class FocusSettings {
  final int defaultFocusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;
  final int sessionsBeforeLongBreak;
  final bool continuousModeEnabled;
  final String ambientSoundKey;
  final bool distractionFreeModeEnabled;

  const FocusSettings({
    this.defaultFocusMinutes = 25,
    this.shortBreakMinutes = 5,
    this.longBreakMinutes = 15,
    this.sessionsBeforeLongBreak = 4,
    this.continuousModeEnabled = false,
    this.ambientSoundKey = 'silence',
    this.distractionFreeModeEnabled = false,
  });

  factory FocusSettings.fromJson(Map<String, dynamic> json) {
    return FocusSettings(
      defaultFocusMinutes: json['default_focus_minutes'] as int? ?? 25,
      shortBreakMinutes: json['short_break_minutes'] as int? ?? 5,
      longBreakMinutes: json['long_break_minutes'] as int? ?? 15,
      sessionsBeforeLongBreak: json['sessions_before_long_break'] as int? ?? 4,
      continuousModeEnabled: json['continuous_mode_enabled'] as bool? ?? false,
      ambientSoundKey: json['ambient_sound_key'] as String? ?? 'silence',
      distractionFreeModeEnabled:
          json['distraction_free_mode_enabled'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'default_focus_minutes': defaultFocusMinutes,
      'short_break_minutes': shortBreakMinutes,
      'long_break_minutes': longBreakMinutes,
      'sessions_before_long_break': sessionsBeforeLongBreak,
      'continuous_mode_enabled': continuousModeEnabled,
      'ambient_sound_key': ambientSoundKey,
      'distraction_free_mode_enabled': distractionFreeModeEnabled,
    };
  }
}

class FocusRecommendation {
  final String? taskId;
  final String? title;
  final int recommendedDurationMinutes;
  final List<String> reasons;
  final String confidence;
  final bool fallbackUsed;
  final String explanation;

  const FocusRecommendation({
    this.taskId,
    this.title,
    required this.recommendedDurationMinutes,
    required this.reasons,
    required this.confidence,
    required this.fallbackUsed,
    required this.explanation,
  });

  bool get hasTask => taskId != null && title != null;

  factory FocusRecommendation.fromJson(Map<String, dynamic> json) {
    return FocusRecommendation(
      taskId: json['task_id'] as String?,
      title: json['title'] as String?,
      recommendedDurationMinutes:
          json['recommended_duration_minutes'] as int? ?? 25,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((reason) => reason.toString())
          .toList(),
      confidence: json['confidence'] as String? ?? 'low',
      fallbackUsed: json['fallback_used'] as bool? ?? true,
      explanation:
          json['explanation'] as String? ??
          'No focus recommendation is available right now.',
    );
  }
}

class FocusReadiness {
  final String predictedFocusReadiness;
  final int readinessScore;
  final List<String> reasons;
  final Map<String, dynamic> signals;

  const FocusReadiness({
    required this.predictedFocusReadiness,
    required this.readinessScore,
    required this.reasons,
    required this.signals,
  });

  factory FocusReadiness.fromJson(Map<String, dynamic> json) {
    return FocusReadiness(
      predictedFocusReadiness:
          json['predicted_focus_readiness'] as String? ?? 'low',
      readinessScore: json['readiness_score'] as int? ?? 0,
      reasons: (json['reasons'] as List<dynamic>? ?? const [])
          .map((reason) => reason.toString())
          .toList(),
      signals: Map<String, dynamic>.from(
        json['signals'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }
}
