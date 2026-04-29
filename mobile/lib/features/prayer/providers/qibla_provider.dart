import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prayer_settings_provider.dart';
import '../services/qibla_compass_service.dart';
import '../services/qibla_direction_service.dart';
import '../services/qibla_location_service.dart';

enum QiblaLocationPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  restricted,
  serviceDisabled,
}

enum QiblaCoordinateSource { deviceLocation, savedCity, unavailable }

enum QiblaCompassSensorStatus {
  unknown,
  listening,
  active,
  lowAccuracy,
  unavailable,
}

class QiblaState {
  final QiblaLocationPermissionState permissionState;
  final QiblaCoordinateSource coordinateSource;
  final QiblaCompassSensorStatus compassSensorStatus;
  final bool isCheckingPermission;
  final QiblaDirection? referenceDirection;
  final double? compassHeadingDegrees;
  final double? compassAccuracyDegrees;
  final double? qiblaRotationDegrees;
  final String sourceLabel;
  final String guidanceMessage;
  final String compassMessage;
  final bool compassSensorIntegrationReady;
  final bool isCompassListening;
  final bool isSavingLocation;
  final String? saveWarning;

  const QiblaState({
    this.permissionState = QiblaLocationPermissionState.unknown,
    this.coordinateSource = QiblaCoordinateSource.unavailable,
    this.compassSensorStatus = QiblaCompassSensorStatus.unknown,
    this.isCheckingPermission = false,
    this.referenceDirection,
    this.compassHeadingDegrees,
    this.compassAccuracyDegrees,
    this.qiblaRotationDegrees,
    this.sourceLabel = 'Unavailable',
    this.guidanceMessage =
        'Allow location or save a manual city to calculate Qibla direction.',
    this.compassMessage =
        'Compass sensor has not started yet. Numeric bearing remains available.',
    this.compassSensorIntegrationReady = false,
    this.isCompassListening = false,
    this.isSavingLocation = false,
    this.saveWarning,
  });

  bool get hasLocationAccess =>
      permissionState == QiblaLocationPermissionState.granted;

  bool get hasDirection => referenceDirection != null;

  bool get usesDeviceLocation =>
      coordinateSource == QiblaCoordinateSource.deviceLocation;

  bool get hasCompassHeading => compassHeadingDegrees != null;

  double? get displayRotationDegrees =>
      qiblaRotationDegrees ?? referenceDirection?.bearingDegrees;

  QiblaState copyWith({
    QiblaLocationPermissionState? permissionState,
    QiblaCoordinateSource? coordinateSource,
    QiblaCompassSensorStatus? compassSensorStatus,
    bool? isCheckingPermission,
    QiblaDirection? referenceDirection,
    double? compassHeadingDegrees,
    double? compassAccuracyDegrees,
    double? qiblaRotationDegrees,
    String? sourceLabel,
    String? guidanceMessage,
    String? compassMessage,
    bool? compassSensorIntegrationReady,
    bool? isCompassListening,
    bool? isSavingLocation,
    String? saveWarning,
    bool clearSaveWarning = false,
    bool clearDirection = false,
    bool clearCompassHeading = false,
    bool clearCompassAccuracy = false,
    bool clearRotation = false,
  }) {
    return QiblaState(
      permissionState: permissionState ?? this.permissionState,
      coordinateSource: coordinateSource ?? this.coordinateSource,
      compassSensorStatus: compassSensorStatus ?? this.compassSensorStatus,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
      referenceDirection: clearDirection
          ? null
          : referenceDirection ?? this.referenceDirection,
      compassHeadingDegrees: clearCompassHeading
          ? null
          : compassHeadingDegrees ?? this.compassHeadingDegrees,
      compassAccuracyDegrees: clearCompassAccuracy
          ? null
          : compassAccuracyDegrees ?? this.compassAccuracyDegrees,
      qiblaRotationDegrees: clearRotation
          ? null
          : qiblaRotationDegrees ?? this.qiblaRotationDegrees,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      guidanceMessage: guidanceMessage ?? this.guidanceMessage,
      compassMessage: compassMessage ?? this.compassMessage,
      compassSensorIntegrationReady:
          compassSensorIntegrationReady ?? this.compassSensorIntegrationReady,
      isCompassListening: isCompassListening ?? this.isCompassListening,
      isSavingLocation: isSavingLocation ?? this.isSavingLocation,
      saveWarning: clearSaveWarning ? null : saveWarning ?? this.saveWarning,
    );
  }
}

class QiblaNotifier extends StateNotifier<QiblaState> {
  final Ref _ref;
  final QiblaService _qiblaService;
  final QiblaLocationService _locationService;
  final QiblaCompassService _compassService;
  StreamSubscription<QiblaCompassReading>? _compassSubscription;

  QiblaNotifier(
    this._ref,
    this._qiblaService,
    this._locationService,
    this._compassService,
  ) : super(const QiblaState());

  QiblaDirection calculateDirectionForLocation({
    required double latitude,
    required double longitude,
  }) {
    return _qiblaService.calculateBearing(
      latitude: latitude,
      longitude: longitude,
    );
  }

  void startCompass() {
    if (_compassSubscription != null) return;
    state = state.copyWith(
      isCompassListening: true,
      compassSensorStatus: QiblaCompassSensorStatus.listening,
      compassMessage: 'Waiting for compass heading from this device.',
    );
    _compassSubscription = _compassService.watchHeading().listen(
      _handleCompassReading,
      onError: (_, _) => _markCompassUnavailable(
        'Compass sensor could not start. Use the numeric Qibla bearing instead.',
      ),
    );
  }

  void stopCompass() {
    _compassSubscription?.cancel();
    _compassSubscription = null;
    state = state.copyWith(isCompassListening: false);
  }

  Future<void> checkLocationPermission() async {
    await _resolveDirection(requestPermission: false);
  }

  Future<void> refreshDirection() async {
    await _resolveDirection(requestPermission: false);
  }

  Future<void> requestLocationPermission() async {
    await _resolveDirection(requestPermission: true);
  }

  Future<void> openPermissionSettings() async {
    await _locationService.openAppSettings();
    await _resolveDirection(requestPermission: false);
  }

  Future<void> openLocationSettings() async {
    await _locationService.openLocationSettings();
    await _resolveDirection(requestPermission: false);
  }

  Future<void> _resolveDirection({required bool requestPermission}) async {
    state = state.copyWith(isCheckingPermission: true, clearSaveWarning: true);
    final deviceResult = await _locationService.currentLocation(
      requestPermission: requestPermission,
    );
    final permissionState = _mapPermissionStatus(deviceResult.permissionStatus);

    if (deviceResult.hasCoordinate) {
      final deviceCoordinate = _QiblaCoordinate(
        latitude: deviceResult.latitude!,
        longitude: deviceResult.longitude!,
      );
      final saveWarning = await _saveCoarseDeviceCoordinate(deviceCoordinate);
      state = _stateForCoordinate(
        coordinate: deviceCoordinate,
        permissionState: permissionState,
        source: QiblaCoordinateSource.deviceLocation,
        sourceLabel: 'Device location',
        message:
            'Bearing is calculated from your current device location. A coarse prayer coordinate is saved for future fallback.',
        saveWarning: saveWarning,
      );
      return;
    }

    final savedCoordinate = await _savedCoordinate();
    if (savedCoordinate != null) {
      final reason = deviceResult.failureMessage;
      state = _stateForCoordinate(
        coordinate: savedCoordinate,
        permissionState: permissionState,
        source: QiblaCoordinateSource.savedCity,
        sourceLabel: savedCoordinate.label ?? 'Saved city',
        message: reason == null
            ? 'Bearing is calculated from saved prayer settings, not live device location.'
            : '$reason Using saved prayer settings instead.',
      );
      return;
    }

    state = state.copyWith(
      isCheckingPermission: false,
      permissionState: permissionState,
      coordinateSource: QiblaCoordinateSource.unavailable,
      sourceLabel: 'Unavailable',
      guidanceMessage:
          deviceResult.failureMessage ??
          'Allow location or add latitude and longitude in Prayer Settings.',
      clearSaveWarning: true,
      clearDirection: true,
    );
  }

  QiblaState _stateForCoordinate({
    required _QiblaCoordinate coordinate,
    required QiblaLocationPermissionState permissionState,
    required QiblaCoordinateSource source,
    required String sourceLabel,
    required String message,
    String? saveWarning,
  }) {
    final direction = calculateDirectionForLocation(
      latitude: coordinate.latitude,
      longitude: coordinate.longitude,
    );
    return state.copyWith(
      isCheckingPermission: false,
      permissionState: permissionState,
      coordinateSource: source,
      referenceDirection: direction,
      qiblaRotationDegrees: _rotationForDirection(direction),
      sourceLabel: sourceLabel,
      guidanceMessage: message,
      saveWarning: saveWarning,
      clearRotation: state.compassHeadingDegrees == null,
    );
  }

  void _handleCompassReading(QiblaCompassReading reading) {
    if (!reading.hasHeading) {
      _markCompassUnavailable(
        reading.fallbackMessage ??
            'Compass heading is unavailable. Use the numeric Qibla bearing instead.',
      );
      return;
    }

    final rotation = state.referenceDirection == null
        ? null
        : _qiblaService.calculateRotationDifference(
            qiblaBearingDegrees: state.referenceDirection!.bearingDegrees,
            headingDegrees: reading.headingDegrees!,
          );
    final lowAccuracy = reading.isLowAccuracy;
    state = state.copyWith(
      isCompassListening: true,
      compassSensorIntegrationReady: true,
      compassSensorStatus: lowAccuracy
          ? QiblaCompassSensorStatus.lowAccuracy
          : QiblaCompassSensorStatus.active,
      compassHeadingDegrees: reading.headingDegrees,
      compassAccuracyDegrees: reading.accuracyDegrees,
      qiblaRotationDegrees: rotation,
      clearCompassAccuracy: reading.accuracyDegrees == null,
      clearRotation: rotation == null,
      compassMessage: lowAccuracy
          ? 'Compass accuracy is low. Move the phone in a gentle figure-eight and keep it away from metal.'
          : 'Live compass heading is active. Rotate the phone to align the arrow toward Qibla.',
    );
  }

  void _markCompassUnavailable(String message) {
    state = state.copyWith(
      isCompassListening: false,
      compassSensorIntegrationReady: false,
      compassSensorStatus: QiblaCompassSensorStatus.unavailable,
      compassMessage: message,
      clearCompassHeading: true,
      clearCompassAccuracy: true,
      clearRotation: true,
    );
  }

  double? _rotationForDirection(QiblaDirection direction) {
    final heading = state.compassHeadingDegrees;
    if (heading == null) return null;
    return _qiblaService.calculateRotationDifference(
      qiblaBearingDegrees: direction.bearingDegrees,
      headingDegrees: heading,
    );
  }

  Future<String?> _saveCoarseDeviceCoordinate(
    _QiblaCoordinate coordinate,
  ) async {
    try {
      state = state.copyWith(isSavingLocation: true);
      await _ref
          .read(prayerSettingsProvider.notifier)
          .updateSettings(
            prayerLocationLat: _coarseCoordinate(coordinate.latitude),
            prayerLocationLng: _coarseCoordinate(coordinate.longitude),
          );
      final settingsError = _ref.read(prayerSettingsProvider).error;
      state = state.copyWith(isSavingLocation: false);
      if (settingsError != null) {
        return 'Live direction is shown for this session, but saving the coarse location failed.';
      }
      return null;
    } catch (_) {
      state = state.copyWith(isSavingLocation: false);
      return 'Live direction is shown for this session, but saving the coarse location failed.';
    }
  }

  Future<_QiblaCoordinate?> _savedCoordinate() async {
    try {
      final settings = await _ref
          .read(prayerSettingsServiceProvider)
          .getSettings();
      final latitude = settings.prayerLocationLat;
      final longitude = settings.prayerLocationLng;
      if (latitude == null || longitude == null) return null;
      return _QiblaCoordinate(
        latitude: latitude,
        longitude: longitude,
        label: settings.city?.isNotEmpty == true ? settings.city : 'Saved city',
      );
    } catch (_) {
      return null;
    }
  }

  double _coarseCoordinate(double value) {
    return double.parse(value.toStringAsFixed(3));
  }

  QiblaLocationPermissionState _mapPermissionStatus(
    QiblaDevicePermissionStatus status,
  ) {
    switch (status) {
      case QiblaDevicePermissionStatus.granted:
        return QiblaLocationPermissionState.granted;
      case QiblaDevicePermissionStatus.permanentlyDenied:
        return QiblaLocationPermissionState.permanentlyDenied;
      case QiblaDevicePermissionStatus.serviceDisabled:
        return QiblaLocationPermissionState.serviceDisabled;
      case QiblaDevicePermissionStatus.denied:
        return QiblaLocationPermissionState.denied;
      case QiblaDevicePermissionStatus.unknown:
        return QiblaLocationPermissionState.unknown;
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}

class _QiblaCoordinate {
  final double latitude;
  final double longitude;
  final String? label;

  const _QiblaCoordinate({
    required this.latitude,
    required this.longitude,
    this.label,
  });
}

final qiblaDirectionServiceProvider = Provider<QiblaDirectionService>((ref) {
  return const QiblaDirectionService();
});

final qiblaServiceProvider = Provider<QiblaService>((ref) {
  return ref.watch(qiblaDirectionServiceProvider);
});

final qiblaLocationServiceProvider = Provider<QiblaLocationService>((ref) {
  return const QiblaLocationService();
});

final qiblaCompassServiceProvider = Provider<QiblaCompassService>((ref) {
  return const QiblaCompassService();
});

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier(
    ref,
    ref.watch(qiblaServiceProvider),
    ref.watch(qiblaLocationServiceProvider),
    ref.watch(qiblaCompassServiceProvider),
  );
});
