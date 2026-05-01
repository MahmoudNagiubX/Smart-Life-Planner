import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/islamic_calendar_model.dart';

void main() {
  test('IslamicCalendarModel parses estimated Hijri date and events', () {
    final calendar = IslamicCalendarModel.fromJson({
      'gregorian_date': '2026-05-01',
      'hijri_date': {
        'year': 1447,
        'month': 11,
        'day': 14,
        'month_name': 'Dhu al-Qadah',
        'label': '14 Dhu al-Qadah 1447 AH',
        'estimated': true,
      },
      'events': [
        {
          'key': 'eid_al_adha',
          'title': 'Eid al-Adha',
          'hijri_month': 12,
          'hijri_day': 10,
          'gregorian_date': '2026-05-27',
          'hijri_label': '10 Dhu al-Hijjah 1447 AH',
          'estimated': true,
          'description': 'Estimated by a civil Hijri calculation.',
        },
      ],
      'calculation_note': 'Estimated.',
    });

    expect(calendar.hijriDate.label, '14 Dhu al-Qadah 1447 AH');
    expect(calendar.hijriDate.estimated, isTrue);
    expect(calendar.events.single.key, 'eid_al_adha');
    expect(calendar.events.single.gregorianDate.year, 2026);
  });
}
