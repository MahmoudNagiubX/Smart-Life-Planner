class HijriDateModel {
  final int year;
  final int month;
  final int day;
  final String monthName;
  final String label;
  final bool estimated;

  const HijriDateModel({
    required this.year,
    required this.month,
    required this.day,
    required this.monthName,
    required this.label,
    required this.estimated,
  });

  factory HijriDateModel.fromJson(Map<String, dynamic> json) {
    return HijriDateModel(
      year: json['year'] as int? ?? 0,
      month: json['month'] as int? ?? 0,
      day: json['day'] as int? ?? 0,
      monthName: json['month_name'] as String? ?? '',
      label: json['label'] as String? ?? '',
      estimated: json['estimated'] as bool? ?? true,
    );
  }
}

class IslamicCalendarEventModel {
  final String key;
  final String title;
  final int hijriMonth;
  final int hijriDay;
  final DateTime gregorianDate;
  final String hijriLabel;
  final bool estimated;
  final String description;

  const IslamicCalendarEventModel({
    required this.key,
    required this.title,
    required this.hijriMonth,
    required this.hijriDay,
    required this.gregorianDate,
    required this.hijriLabel,
    required this.estimated,
    required this.description,
  });

  factory IslamicCalendarEventModel.fromJson(Map<String, dynamic> json) {
    return IslamicCalendarEventModel(
      key: json['key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      hijriMonth: json['hijri_month'] as int? ?? 0,
      hijriDay: json['hijri_day'] as int? ?? 0,
      gregorianDate: DateTime.parse(json['gregorian_date'] as String),
      hijriLabel: json['hijri_label'] as String? ?? '',
      estimated: json['estimated'] as bool? ?? true,
      description: json['description'] as String? ?? '',
    );
  }
}

class IslamicCalendarModel {
  final DateTime gregorianDate;
  final HijriDateModel hijriDate;
  final List<IslamicCalendarEventModel> events;
  final String calculationNote;

  const IslamicCalendarModel({
    required this.gregorianDate,
    required this.hijriDate,
    required this.events,
    required this.calculationNote,
  });

  factory IslamicCalendarModel.fromJson(Map<String, dynamic> json) {
    final rawEvents = json['events'] as List<dynamic>? ?? const [];
    return IslamicCalendarModel(
      gregorianDate: DateTime.parse(json['gregorian_date'] as String),
      hijriDate: HijriDateModel.fromJson(
        json['hijri_date'] as Map<String, dynamic>? ?? const {},
      ),
      events: rawEvents
          .map(
            (item) => IslamicCalendarEventModel.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
      calculationNote: json['calculation_note'] as String? ?? '',
    );
  }
}
