import 'package:flutter_test/flutter_test.dart';
import 'package:smart_life_planner/features/prayer/services/qibla_direction_service.dart';

void main() {
  group('QiblaDirectionService', () {
    const service = QiblaDirectionService();

    test('is exposed through the reusable QiblaService contract', () {
      const qiblaService = QiblaService();

      final direction = qiblaService.calculateBearing(
        latitude: 30.0444,
        longitude: 31.2357,
      );

      expect(direction.bearingDegrees, closeTo(136.1, 0.2));
    });

    test('calculates the Cairo to Kaaba bearing', () {
      final direction = service.calculateBearing(
        latitude: 30.0444,
        longitude: 31.2357,
      );

      expect(direction.bearingDegrees, closeTo(136.1, 0.2));
      expect(direction.compassLabel, 'SE');
    });

    test('returns different normalized bearings for different cities', () {
      final london = service.calculateBearing(
        latitude: 51.5074,
        longitude: -0.1278,
      );
      final jakarta = service.calculateBearing(
        latitude: -6.2088,
        longitude: 106.8456,
      );
      final sydney = service.calculateBearing(
        latitude: -33.8688,
        longitude: 151.2093,
      );

      expect(london.bearingDegrees, closeTo(119.0, 0.2));
      expect(jakarta.bearingDegrees, closeTo(295.2, 0.2));
      expect(sydney.bearingDegrees, closeTo(277.5, 0.2));
      expect(jakarta.bearingDegrees, greaterThan(0));
      expect(jakarta.bearingDegrees, lessThan(360));
      expect(sydney.compassLabel, 'W');
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
