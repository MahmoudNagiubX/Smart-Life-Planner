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
      year: _asInt(json['year']),
      month: _asInt(json['month']),
      day: _asInt(json['day']),
      monthName: _asString(json['month_name']),
      label: _asString(json['label'], fallback: 'Estimated Hijri date'),
      estimated: _asBool(json['estimated'], fallback: true),
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
      key: _asString(json['key']),
      title: _asString(json['title'], fallback: 'Islamic calendar event'),
      hijriMonth: _asInt(json['hijri_month']),
      hijriDay: _asInt(json['hijri_day']),
      gregorianDate:
          DateTime.tryParse(_asString(json['gregorian_date'])) ??
          DateTime.now(),
      hijriLabel: _asString(json['hijri_label']),
      estimated: _asBool(json['estimated'], fallback: true),
      description: _asString(json['description']),
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
    final rawEvents = json['events'];
    return IslamicCalendarModel(
      gregorianDate:
          DateTime.tryParse(_asString(json['gregorian_date'])) ??
          DateTime.now(),
      hijriDate: HijriDateModel.fromJson(
        _asMap(json['hijri_date']) ?? const {},
      ),
      events: (rawEvents is List<dynamic> ? rawEvents : const [])
          .whereType<Map>()
          .map(
            (item) => IslamicCalendarEventModel.fromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      calculationNote: _asString(
        json['calculation_note'],
        fallback: 'Islamic calendar dates are estimated.',
      ),
    );
  }
}

String _asString(dynamic value, {String fallback = ''}) {
  if (value is String) return value;
  return value?.toString() ?? fallback;
}

int _asInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? 0;
  return 0;
}

bool _asBool(dynamic value, {bool fallback = false}) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final normalized = value.toLowerCase();
    if (normalized == 'true') return true;
    if (normalized == 'false') return false;
  }
  return fallback;
}

Map<String, dynamic>? _asMap(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return null;
}
