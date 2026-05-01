import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/ai/models/study_plan_model.dart';

void main() {
  test('StudyPlanResult parses confirmation contract', () {
    final result = StudyPlanResult.fromJson({
      'subject': 'Physics',
      'exam_date': '2026-06-01',
      'daily_plan': [
        {
          'date': '2026-05-01',
          'topic': 'Mechanics',
          'title': 'Study Mechanics',
          'study_minutes': 60,
          'practice_minutes': 25,
          'revision': false,
          'priority': 'medium',
        },
      ],
      'confidence': 'medium',
      'overload_warning': false,
      'requires_confirmation': true,
    });

    expect(result.requiresConfirmation, isTrue);
    expect(result.dailyPlan.single.totalMinutes, 85);
  });
}
