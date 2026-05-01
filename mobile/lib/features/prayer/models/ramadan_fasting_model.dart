class RamadanFastingLog {
  final String id;
  final String userId;
  final String fastingDate;
  final bool fasted;
  final String fastType;
  final String? makeupForDate;
  final String? note;
  final String createdAt;
  final String updatedAt;

  const RamadanFastingLog({
    required this.id,
    required this.userId,
    required this.fastingDate,
    required this.fasted,
    required this.fastType,
    required this.makeupForDate,
    required this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  factory RamadanFastingLog.fromJson(Map<String, dynamic> json) {
    return RamadanFastingLog(
      id: json['id'] as String,
      userId: json['user_id'] as String,
      fastingDate: json['fasting_date'] as String,
      fasted: json['fasted'] as bool,
      fastType: json['fast_type'] as String? ?? 'ramadan',
      makeupForDate: json['makeup_for_date'] as String?,
      note: json['note'] as String?,
      createdAt: json['created_at'] as String,
      updatedAt: json['updated_at'] as String,
    );
  }
}

class RamadanFastingSummary {
  final String date;
  final RamadanFastingLog? today;
  final int month;
  final int year;
  final int monthFastedCount;
  final int monthNotFastedCount;
  final int monthLoggedCount;

  const RamadanFastingSummary({
    required this.date,
    required this.today,
    required this.month,
    required this.year,
    required this.monthFastedCount,
    required this.monthNotFastedCount,
    required this.monthLoggedCount,
  });

  factory RamadanFastingSummary.fromJson(Map<String, dynamic> json) {
    final todayJson = json['today'];
    return RamadanFastingSummary(
      date: json['date'] as String,
      today: todayJson == null
          ? null
          : RamadanFastingLog.fromJson(todayJson as Map<String, dynamic>),
      month: json['month'] as int,
      year: json['year'] as int,
      monthFastedCount: json['month_fasted_count'] as int,
      monthNotFastedCount: json['month_not_fasted_count'] as int,
      monthLoggedCount: json['month_logged_count'] as int,
    );
  }
}
