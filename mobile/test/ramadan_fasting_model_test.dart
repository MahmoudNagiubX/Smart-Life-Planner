import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/ramadan_fasting_model.dart';

void main() {
  test('parses empty Ramadan fasting summary', () {
    final summary = RamadanFastingSummary.fromJson(const {
      'date': '2026-04-30',
      'today': null,
      'month': 4,
      'year': 2026,
      'month_fasted_count': 0,
      'month_not_fasted_count': 0,
      'month_logged_count': 0,
    });

    expect(summary.today, isNull);
    expect(summary.monthLoggedCount, 0);
  });

  test('parses today fasting log and monthly counts', () {
    final summary = RamadanFastingSummary.fromJson(const {
      'date': '2026-04-30',
      'today': {
        'id': 'log-id',
        'user_id': 'user-id',
        'fasting_date': '2026-04-30',
        'fasted': true,
        'note': null,
        'created_at': '2026-04-30T08:00:00Z',
        'updated_at': '2026-04-30T08:00:00Z',
      },
      'month': 4,
      'year': 2026,
      'month_fasted_count': 12,
      'month_not_fasted_count': 1,
      'month_logged_count': 13,
    });

    expect(summary.today?.fasted, isTrue);
    expect(summary.monthFastedCount, 12);
    expect(summary.monthNotFastedCount, 1);
    expect(summary.monthLoggedCount, 13);
  });
}
