import 'dart:async';

import 'package:flutter_compass/flutter_compass.dart';

class QiblaCompassReading {
  static const lowAccuracyThresholdDegrees = 30.0;

  final double? headingDegrees;
  final double? accuracyDegrees;
  final String? fallbackMessage;

  const QiblaCompassReading({
    required this.headingDegrees,
    required this.accuracyDegrees,
    this.fallbackMessage,
  });

  const QiblaCompassReading.unavailable(this.fallbackMessage)
    : headingDegrees = null,
      accuracyDegrees = null;

  bool get hasHeading => headingDegrees != null;

  bool get isLowAccuracy =>
      accuracyDegrees != null && accuracyDegrees! > lowAccuracyThresholdDegrees;
}

class QiblaCompassService {
  const QiblaCompassService();

  Stream<QiblaCompassReading> watchHeading() {
    final events = FlutterCompass.events;
    if (events == null) {
      return Stream.value(
        const QiblaCompassReading.unavailable(
          'Compass sensor is not available on this device.',
        ),
      );
    }

    return events
        .transform(
          StreamTransformer<CompassEvent, QiblaCompassReading>.fromHandlers(
            handleData: (event, sink) => sink.add(_readingFromEvent(event)),
            handleError: (_, _, sink) {
              sink.add(
                const QiblaCompassReading.unavailable(
                  'Compass sensor could not start. Use the numeric Qibla bearing instead.',
                ),
              );
            },
          ),
        )
        .timeout(
          const Duration(seconds: 5),
          onTimeout: (sink) {
            sink.add(
              const QiblaCompassReading.unavailable(
                'Compass sensor did not provide a heading. Use the numeric Qibla bearing instead.',
              ),
            );
          },
        );
  }

  QiblaCompassReading _readingFromEvent(CompassEvent event) {
    final heading = event.heading;
    if (heading == null || !heading.isFinite) {
      return const QiblaCompassReading.unavailable(
        'Compass heading is unavailable on this device.',
      );
    }

    return QiblaCompassReading(
      headingDegrees: _normalizeDegrees(heading),
      accuracyDegrees: _safeAccuracy(event.accuracy),
    );
  }

  double _normalizeDegrees(double degrees) => (degrees % 360 + 360) % 360;

  double? _safeAccuracy(double? accuracy) {
    if (accuracy == null || !accuracy.isFinite || accuracy < 0) return null;
    return accuracy;
  }
}
