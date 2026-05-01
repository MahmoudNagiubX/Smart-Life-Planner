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
}
