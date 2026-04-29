import 'dart:math' as math;

class QiblaDirection {
  final double bearingDegrees;
  final String compassLabel;

  const QiblaDirection({
    required this.bearingDegrees,
    required this.compassLabel,
  });

  String get displayDegrees => '${bearingDegrees.toStringAsFixed(1)} deg';
}

class QiblaService {
  static const double kaabaLatitude = 21.4225;
  static const double kaabaLongitude = 39.8262;

  const QiblaService();

  QiblaDirection calculateBearing({
    required double latitude,
    required double longitude,
  }) {
    _validateCoordinates(latitude: latitude, longitude: longitude);

    final lat1 = _degreesToRadians(latitude);
    final lat2 = _degreesToRadians(kaabaLatitude);
    final deltaLongitude = _degreesToRadians(kaabaLongitude - longitude);

    final y = math.sin(deltaLongitude) * math.cos(lat2);
    final x =
        math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(deltaLongitude);

    final bearing = _normalizeDegrees(_radiansToDegrees(math.atan2(y, x)));
    return QiblaDirection(
      bearingDegrees: bearing,
      compassLabel: _compassLabelForBearing(bearing),
    );
  }

  QiblaDirection calculateCairoReferenceBearing() {
    return calculateBearing(latitude: 30.0444, longitude: 31.2357);
  }

  void _validateCoordinates({
    required double latitude,
    required double longitude,
  }) {
    if (latitude < -90 || latitude > 90) {
      throw ArgumentError.value(
        latitude,
        'latitude',
        'Must be between -90 and 90.',
      );
    }
    if (longitude < -180 || longitude > 180) {
      throw ArgumentError.value(
        longitude,
        'longitude',
        'Must be between -180 and 180.',
      );
    }
  }

  double _degreesToRadians(double degrees) => degrees * math.pi / 180;

  double _radiansToDegrees(double radians) => radians * 180 / math.pi;

  double _normalizeDegrees(double degrees) => (degrees + 360) % 360;

  String _compassLabelForBearing(double bearing) {
    const labels = ['N', 'NE', 'E', 'SE', 'S', 'SW', 'W', 'NW'];
    final index = ((bearing + 22.5) / 45).floor() % labels.length;
    return labels[index];
  }
}

class QiblaDirectionService extends QiblaService {
  const QiblaDirectionService();
}
