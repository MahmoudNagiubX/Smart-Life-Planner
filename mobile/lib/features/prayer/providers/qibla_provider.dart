import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prayer_settings_provider.dart';
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

class QiblaState {
  final QiblaLocationPermissionState permissionState;
  final QiblaCoordinateSource coordinateSource;
  final bool isCheckingPermission;
  final QiblaDirection? referenceDirection;
  final String sourceLabel;
  final String guidanceMessage;
  final bool compassSensorIntegrationReady;
  final bool isSavingLocation;
  final String? saveWarning;

  const QiblaState({
    this.permissionState = QiblaLocationPermissionState.unknown,
    this.coordinateSource = QiblaCoordinateSource.unavailable,
    this.isCheckingPermission = false,
    this.referenceDirection,
    this.sourceLabel = 'Unavailable',
    this.guidanceMessage =
        'Allow location or save a manual city to calculate Qibla direction.',
    this.compassSensorIntegrationReady = false,
    this.isSavingLocation = false,
    this.saveWarning,
  });

  bool get hasLocationAccess =>
      permissionState == QiblaLocationPermissionState.granted;

  bool get hasDirection => referenceDirection != null;

  bool get usesDeviceLocation =>
      coordinateSource == QiblaCoordinateSource.deviceLocation;

  QiblaState copyWith({
    QiblaLocationPermissionState? permissionState,
    QiblaCoordinateSource? coordinateSource,
    bool? isCheckingPermission,
    QiblaDirection? referenceDirection,
    String? sourceLabel,
    String? guidanceMessage,
    bool? compassSensorIntegrationReady,
    bool? isSavingLocation,
    String? saveWarning,
    bool clearSaveWarning = false,
    bool clearDirection = false,
  }) {
    return QiblaState(
      permissionState: permissionState ?? this.permissionState,
      coordinateSource: coordinateSource ?? this.coordinateSource,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
      referenceDirection: clearDirection
          ? null
          : referenceDirection ?? this.referenceDirection,
      sourceLabel: sourceLabel ?? this.sourceLabel,
      guidanceMessage: guidanceMessage ?? this.guidanceMessage,
      compassSensorIntegrationReady:
          compassSensorIntegrationReady ?? this.compassSensorIntegrationReady,
      isSavingLocation: isSavingLocation ?? this.isSavingLocation,
      saveWarning: clearSaveWarning ? null : saveWarning ?? this.saveWarning,
    );
  }
}

class QiblaNotifier extends StateNotifier<QiblaState> {
  final Ref _ref;
  final QiblaService _qiblaService;
  final QiblaLocationService _locationService;

  QiblaNotifier(this._ref, this._qiblaService, this._locationService)
    : super(const QiblaState());

  QiblaDirection calculateDirectionForLocation({
    required double latitude,
    required double longitude,
  }) {
    return _qiblaService.calculateBearing(
      latitude: latitude,
      longitude: longitude,
    );
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
      sourceLabel: sourceLabel,
      guidanceMessage: message,
      saveWarning: saveWarning,
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

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier(
    ref,
    ref.watch(qiblaServiceProvider),
    ref.watch(qiblaLocationServiceProvider),
  );
});
