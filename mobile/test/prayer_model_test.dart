import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/prayer_model.dart';

void main() {
  test('DailyPrayers parses old logs without status safely', () {
    final prayers = DailyPrayers.fromJson(const {
      'date': '2026-05-02',
      'prayers': [
        {
          'prayer_name': 'fajr',
          'scheduled_at': null,
          'completed': true,
          'completed_at': '2026-05-02T04:10:00Z',
        },
        {
          'prayer_name': 'dhuhr',
          'scheduled_at': '2026-05-02T12:00:00Z',
          'completed': false,
          'completed_at': null,
          'status': null,
        },
      ],
      'completed_count': 1,
      'total_count': 5,
    });

    expect(prayers.prayers, hasLength(2));
    expect(prayers.prayers.first.status, isNull);
    expect(prayers.completedCount, 1);
    expect(prayers.missedCount, 0);
  });

  test('PrayerWeeklySummary tolerates empty or partial history payloads', () {
    final summary = PrayerWeeklySummary.fromJson(const {
      'week_start': '2026-04-26',
      'week_end': '2026-05-02',
      'days': [
        {'prayer_date': '2026-05-02', 'missed': 1},
      ],
    });

    expect(summary.totalMissed, 0);
    expect(summary.days.single.prayerDate, '2026-05-02');
    expect(summary.days.single.missed, 1);
    expect(summary.days.single.completed, 0);
  });
}
