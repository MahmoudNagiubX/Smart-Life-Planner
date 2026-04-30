import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/focus/models/focus_model.dart';

void main() {
  test('FocusAnalytics parses real report metrics', () {
    final analytics = FocusAnalytics.fromJson(const {
      'today_minutes': 50,
      'today_sessions': 2,
      'week_minutes': 180,
      'week_sessions': 6,
      'completed_sessions': 10,
      'current_streak_days': 3,
      'longest_streak_days': 5,
      'average_session_minutes': 25,
      'completion_rate_percent': 80,
      'report_summary': 'Today: 50 minutes.',
    });

    expect(analytics.todayMinutes, 50);
    expect(analytics.weekMinutes, 180);
    expect(analytics.currentStreakDays, 3);
    expect(analytics.longestStreakDays, 5);
    expect(analytics.completionRatePercent, 80);
  });
}
