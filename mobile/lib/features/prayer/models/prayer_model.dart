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
      prayerName: _asString(json['prayer_name'], fallback: 'unknown'),
      scheduledAt: _asNullableString(json['scheduled_at']),
      completed: _asBool(json['completed']),
      completedAt: _asNullableString(json['completed_at']),
      status: _normalizePrayerStatus(json['status']),
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
    final rawPrayers = json['prayers'];
    return DailyPrayers(
      date: _asString(json['date']),
      prayers: (rawPrayers is List<dynamic> ? rawPrayers : const [])
          .whereType<Map>()
          .map((p) => PrayerTime.fromJson(Map<String, dynamic>.from(p)))
          .toList(),
      completedCount: _asInt(json['completed_count']),
      totalCount: _asInt(json['total_count']),
      missedCount: _asInt(json['missed_count']),
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
      prayerDate: _asString(json['prayer_date']),
      total: _asInt(json['total']),
      completed: _asInt(json['completed']),
      missed: _asInt(json['missed']),
      late: _asInt(json['late']),
      excused: _asInt(json['excused']),
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
    final rawDays = json['days'];
    return PrayerWeeklySummary(
      weekStart: _asString(json['week_start']),
      weekEnd: _asString(json['week_end']),
      totalMissed: _asInt(json['total_missed']),
      totalCompleted: _asInt(json['total_completed']),
      totalPrayers: _asInt(json['total_prayers']),
      todayMissed: _asInt(json['today_missed']),
      days: (rawDays is List<dynamic> ? rawDays : const [])
          .whereType<Map>()
          .map((d) => PrayerDaySummary.fromJson(Map<String, dynamic>.from(d)))
          .toList(),
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

bool _asBool(dynamic value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return false;
}

String? _normalizePrayerStatus(dynamic value) {
  final status = _asNullableString(value)?.trim();
  if (status == null || status.isEmpty) return null;
  const valid = {'prayed_on_time', 'prayed_late', 'missed', 'excused'};
  return valid.contains(status) ? status : null;
}
