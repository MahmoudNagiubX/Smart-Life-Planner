import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/focus/models/focus_model.dart';

void main() {
  test('FocusReadiness parses backend prediction contract', () {
    final readiness = FocusReadiness.fromJson(const {
      'predicted_focus_readiness': 'high',
      'readiness_score': 82,
      'reasons': ['recent focus streak is strong'],
      'signals': {'focus_streak_days': 4, 'task_completion_rate_percent': 80},
    });

    expect(readiness.predictedFocusReadiness, 'high');
    expect(readiness.readinessScore, 82);
    expect(readiness.reasons, contains('recent focus streak is strong'));
    expect(readiness.signals['focus_streak_days'], 4);
  });
}
