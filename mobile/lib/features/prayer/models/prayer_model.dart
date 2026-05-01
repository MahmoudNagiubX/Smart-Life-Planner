class PrayerTime {
  final String prayerName;
  final String? scheduledAt;
  final bool completed;
  final String? completedAt;
  final String? status;

  PrayerTime({
    required this.prayerName,
    this.scheduledAt,
    required this.completed,
    this.completedAt,
    this.status,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      prayerName: json['prayer_name'] as String,
      scheduledAt: json['scheduled_at'] as String?,
      completed: json['completed'] as bool,
      completedAt: json['completed_at'] as String?,
      status: json['status'] as String?,
    );
  }
}

class DailyPrayers {
  final String date;
  final List<PrayerTime> prayers;
  final int completedCount;
  final int totalCount;
  final int missedCount;

  DailyPrayers({
    required this.date,
    required this.prayers,
    required this.completedCount,
    required this.totalCount,
    required this.missedCount,
  });

  factory DailyPrayers.fromJson(Map<String, dynamic> json) {
    return DailyPrayers(
      date: json['date'] as String,
      prayers: (json['prayers'] as List<dynamic>)
          .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
          .toList(),
      completedCount: json['completed_count'] as int,
      totalCount: json['total_count'] as int,
      missedCount: json['missed_count'] as int? ?? 0,
    );
  }
}

class PrayerDaySummary {
  final String prayerDate;
  final int total;
  final int completed;
  final int missed;
  final int late;
  final int excused;

  PrayerDaySummary({
    required this.prayerDate,
    required this.total,
    required this.completed,
    required this.missed,
    required this.late,
    required this.excused,
  });

  factory PrayerDaySummary.fromJson(Map<String, dynamic> json) {
    return PrayerDaySummary(
      prayerDate: json['prayer_date'] as String,
      total: json['total'] as int,
      completed: json['completed'] as int,
      missed: json['missed'] as int,
      late: json['late'] as int,
      excused: json['excused'] as int,
    );
  }
}

class PrayerWeeklySummary {
  final String weekStart;
  final String weekEnd;
  final int totalMissed;
  final int totalCompleted;
  final int totalPrayers;
  final int todayMissed;
  final List<PrayerDaySummary> days;

  PrayerWeeklySummary({
    required this.weekStart,
    required this.weekEnd,
    required this.totalMissed,
    required this.totalCompleted,
    required this.totalPrayers,
    required this.todayMissed,
    required this.days,
  });

  factory PrayerWeeklySummary.fromJson(Map<String, dynamic> json) {
    return PrayerWeeklySummary(
      weekStart: json['week_start'] as String,
      weekEnd: json['week_end'] as String,
      totalMissed: json['total_missed'] as int,
      totalCompleted: json['total_completed'] as int,
      totalPrayers: json['total_prayers'] as int,
      todayMissed: json['today_missed'] as int,
      days: (json['days'] as List<dynamic>)
          .map((d) => PrayerDaySummary.fromJson(d as Map<String, dynamic>))
          .toList(),
    );
  }
}