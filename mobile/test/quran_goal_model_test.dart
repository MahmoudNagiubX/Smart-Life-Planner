import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/models/quran_goal_model.dart';

void main() {
  test('QuranGoalSummary parses real weekly summary fields', () {
    final summary = QuranGoalSummary.fromJson({
      'goal': null,
      'today': null,
      'today_pages_completed': 3,
      'progress_percent': 60,
      'weekly_total_pages': 21,
      'weekly_target_pages': 35,
      'weekly_completion_percent': 60,
      'current_streak_days': 2,
      'weekly_summary': [
        {
          'progress_date': '2026-04-30',
          'pages_read': 3,
          'target_pages': 5,
          'target_met': false,
          'completion_percent': 60,
        },
      ],
    });

    expect(summary.todayPagesCompleted, 3);
    expect(summary.weeklyCompletionPercent, 60);
    expect(summary.currentStreakDays, 2);
    expect(summary.weeklySummary.single.pagesCompleted, 3);
    expect(summary.weeklySummary.single.targetPages, 5);
    expect(summary.weeklySummary.single.completionPercent, 60);
  });
}
