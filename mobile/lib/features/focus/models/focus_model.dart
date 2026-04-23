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
}

class FocusAnalytics {
  final int todayMinutes;
  final int todaySessions;
  final int weekMinutes;
  final int weekSessions;

  FocusAnalytics({
    required this.todayMinutes,
    required this.todaySessions,
    required this.weekMinutes,
    required this.weekSessions,
  });

  factory FocusAnalytics.fromJson(Map<String, dynamic> json) {
    return FocusAnalytics(
      todayMinutes: json['today_minutes'] as int,
      todaySessions: json['today_sessions'] as int,
      weekMinutes: json['week_minutes'] as int,
      weekSessions: json['week_sessions'] as int,
    );
  }
}