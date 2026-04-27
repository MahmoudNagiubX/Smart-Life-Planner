import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/services/qibla_direction_service.dart';

void main() {
  group('QiblaDirectionService', () {
    const service = QiblaDirectionService();

    test('calculates the Cairo to Kaaba bearing', () {
      final direction = service.calculateBearing(
        latitude: 30.0444,
        longitude: 31.2357,
      );

      expect(direction.bearingDegrees, closeTo(136.1, 0.2));
      expect(direction.compassLabel, 'SE');
    });

    test('rejects invalid coordinates', () {
      expect(
        () => service.calculateBearing(latitude: 91, longitude: 31.2357),
        throwsArgumentError,
      );
      expect(
        () => service.calculateBearing(latitude: 30.0444, longitude: 181),
        throwsArgumentError,
      );
    });
  });
}
