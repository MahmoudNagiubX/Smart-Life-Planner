import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/focus/models/focus_model.dart';

void main() {
  test('FocusRecommendation parses backend recommendation contract', () {
    final recommendation = FocusRecommendation.fromJson(const {
      'task_id': 'task-1',
      'title': 'Submit project report',
      'recommended_duration_minutes': 25,
      'reasons': ['high priority', 'due within 24 hours'],
      'confidence': 'high',
      'fallback_used': true,
      'explanation': 'Recommended for 25 minutes.',
    });

    expect(recommendation.taskId, 'task-1');
    expect(recommendation.hasTask, isTrue);
    expect(recommendation.recommendedDurationMinutes, 25);
    expect(recommendation.reasons, contains('high priority'));
    expect(recommendation.fallbackUsed, isTrue);
  });
}
