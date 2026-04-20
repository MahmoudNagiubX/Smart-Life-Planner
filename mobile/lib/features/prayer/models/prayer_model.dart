class PrayerTime {
  final String prayerName;
  final String? scheduledAt;
  final bool completed;
  final String? completedAt;

  PrayerTime({
    required this.prayerName,
    this.scheduledAt,
    required this.completed,
    this.completedAt,
  });

  factory PrayerTime.fromJson(Map<String, dynamic> json) {
    return PrayerTime(
      prayerName: json['prayer_name'] as String,
      scheduledAt: json['scheduled_at'] as String?,
      completed: json['completed'] as bool,
      completedAt: json['completed_at'] as String?,
    );
  }
}

class DailyPrayers {
  final String date;
  final List<PrayerTime> prayers;
  final int completedCount;
  final int totalCount;

  DailyPrayers({
    required this.date,
    required this.prayers,
    required this.completedCount,
    required this.totalCount,
  });

  factory DailyPrayers.fromJson(Map<String, dynamic> json) {
    return DailyPrayers(
      date: json['date'] as String,
      prayers: (json['prayers'] as List<dynamic>)
          .map((p) => PrayerTime.fromJson(p as Map<String, dynamic>))
          .toList(),
      completedCount: json['completed_count'] as int,
      totalCount: json['total_count'] as int,
    );
  }
}