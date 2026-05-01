import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/ai/models/goal_roadmap_model.dart';

void main() {
  test('GoalRoadmapResult parses editable preview contract', () {
    final result = GoalRoadmapResult.fromJson({
      'goal_title': 'Learn ML basics',
      'deadline': '2026-06-01',
      'milestones': [
        {
          'index': 1,
          'title': 'Learn foundations',
          'description': 'Start.',
          'target_week': 1,
        },
      ],
      'suggested_tasks': [
        {
          'milestone_index': 1,
          'title': 'Plan next actions',
          'description': 'Plan.',
          'priority': 'high',
          'estimated_minutes': 60,
          'suggested_week': 1,
        },
      ],
      'schedule_suggestion': 'Use 5 hours weekly.',
      'confidence': 'medium',
      'requires_confirmation': true,
      'fallback_used': true,
    });

    expect(result.requiresConfirmation, isTrue);
    expect(result.milestones.single.title, 'Learn foundations');
    expect(result.suggestedTasks.single.priority, 'high');
  });
}
