import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/context/models/context_intelligence_model.dart';

void main() {
  test('ContextIntelligenceSnapshot parses backend snapshot', () {
    final snapshot = ContextIntelligenceSnapshot.fromJson({
      'id': 'snapshot-1',
      'timestamp': '2026-05-01T12:00:00Z',
      'timezone': 'Africa/Cairo',
      'local_time_block': 'afternoon',
      'energy_level': 'high',
      'coarse_location_context': 'Cairo, Egypt',
      'weather_summary': null,
      'device_context': 'mobile',
    });

    expect(snapshot.id, 'snapshot-1');
    expect(snapshot.energyLevel, 'high');
    expect(snapshot.timeContext, 'afternoon');
    expect(snapshot.locationContext, 'Cairo, Egypt');
  });

  test('ContextIntelligenceSnapshot serializes create payload safely', () {
    const snapshot = ContextIntelligenceSnapshot(
      timezone: 'Africa/Cairo',
      energyLevel: 'medium',
      locationContext: 'Cairo, Egypt',
    );

    final payload = snapshot.toCreatePayload(nextEnergyLevel: 'low');

    expect(payload['timezone'], 'Africa/Cairo');
    expect(payload['energy_level'], 'low');
    expect(payload['coarse_location_context'], 'Cairo, Egypt');
    expect(payload.containsKey('weather_summary'), isFalse);
  });

  test('TimeContextRecommendationResult parses backend recommendations', () {
    final result = TimeContextRecommendationResult.fromJson({
      'local_time_block': 'morning',
      'energy_level': 'high',
      'goal_tags': ['study'],
      'explanation': 'Morning recommendations use your goals.',
      'recommendations': [
        {
          'task_type': 'deep_work_study',
          'title': 'Deep work or study',
          'reason': 'Morning is best for focus.',
          'suggested_energy': 'high',
          'preference_match': false,
        },
      ],
    });

    expect(result.localTimeBlock, 'morning');
    expect(result.goalTags, contains('study'));
    expect(result.recommendations.single.taskType, 'deep_work_study');
  });

  test('ContextTaskRecommendationResult parses scored tasks', () {
    final result = ContextTaskRecommendationResult.fromJson({
      'local_time_block': 'evening',
      'energy_level': 'low',
      'explanation': 'Tasks are ranked.',
      'recommendations': [
        {
          'task_id': 'task-1',
          'title': 'Review notes',
          'priority': 'medium',
          'status': 'pending',
          'category': 'review',
          'due_at': null,
          'energy_required': 'low',
          'difficulty_level': 'easy',
          'estimated_minutes': 15,
          'score': 82.5,
          'score_breakdown': {
            'priority_component': 22.75,
            'time_match_component': 25,
            'energy_match_component': 20,
            'location_match_component': 5,
            'weather_match_component': 0,
            'friction_penalty': 1.5,
            'due_bonus': 0,
          },
          'explanation': 'Good fit for evening.',
        },
      ],
    });

    expect(result.recommendations.single.title, 'Review notes');
    expect(result.recommendations.single.score, 82.5);
    expect(
      result.recommendations.single.scoreBreakdown.energyMatchComponent,
      20,
    );
  });
}
