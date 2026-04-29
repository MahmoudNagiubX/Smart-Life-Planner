import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/dashboard/models/dashboard_model.dart';

void main() {
  test('DashboardData parses real spiritual summary', () {
    final dashboard = DashboardData.fromJson(const {
      'pending_count': 0,
      'completed_today': 1,
      'prayer_progress': {'completed': 2, 'total': 5},
      'top_tasks': [],
      'personalization': {
        'spiritual_summary': {
          'next_prayer': {
            'name': 'maghrib',
            'scheduled_at': '2026-04-30T15:30:00Z',
            'enabled': true,
          },
          'prayer_progress': {'completed': 2, 'total': 5},
          'quran_goal': {
            'enabled': true,
            'daily_page_target': 5,
            'today_pages_completed': 3,
            'progress_percent': 60,
          },
          'ramadan': {
            'enabled': true,
            'today_logged': true,
            'fasted': true,
            'label': 'Fasting logged today',
          },
          'qibla': {'available': true, 'label': 'Open Qibla direction'},
        },
      },
    });

    final spiritual = dashboard.personalization.spiritualSummary;

    expect(spiritual.nextPrayer.name, 'maghrib');
    expect(spiritual.prayerProgress.completed, 2);
    expect(spiritual.quranGoal.todayPagesCompleted, 3);
    expect(spiritual.quranGoal.progressPercent, 60);
    expect(spiritual.ramadan.enabled, isTrue);
    expect(spiritual.qibla.available, isTrue);
  });
}
