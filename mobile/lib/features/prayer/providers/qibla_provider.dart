import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import 'prayer_settings_provider.dart';
import '../services/qibla_direction_service.dart';

enum QiblaLocationPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  restricted,
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

  const QiblaState({
    this.permissionState = QiblaLocationPermissionState.unknown,
    this.coordinateSource = QiblaCoordinateSource.unavailable,
    this.isCheckingPermission = false,
    this.referenceDirection,
    this.sourceLabel = 'Unavailable',
    this.guidanceMessage =
        'Allow location or save a manual city to calculate Qibla direction.',
    this.compassSensorIntegrationReady = false,
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
    );
  }
}

class QiblaNotifier extends StateNotifier<QiblaState> {
  final Ref _ref;
  final QiblaDirectionService _directionService;

  QiblaNotifier(this._ref, this._directionService) : super(const QiblaState());

  QiblaDirection calculateDirectionForLocation({
    required double latitude,
    required double longitude,
  }) {
    return _directionService.calculateBearing(
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
    await openAppSettings();
    await _resolveDirection(requestPermission: false);
  }

  Future<void> _resolveDirection({required bool requestPermission}) async {
    state = state.copyWith(isCheckingPermission: true);
    final permissionStatus = requestPermission
        ? await Permission.locationWhenInUse.request()
        : await Permission.locationWhenInUse.status;
    final permissionState = _mapPermissionStatus(permissionStatus);

    if (permissionState == QiblaLocationPermissionState.granted) {
      final deviceCoordinate = await _deviceCoordinate();
      if (deviceCoordinate != null) {
        state = _stateForCoordinate(
          coordinate: deviceCoordinate,
          permissionState: permissionState,
          source: QiblaCoordinateSource.deviceLocation,
          sourceLabel: 'Device location',
          message:
              'Bearing is calculated from your current device coordinates.',
        );
        return;
      }
    }

    final savedCoordinate = await _savedCoordinate();
    if (savedCoordinate != null) {
      state = _stateForCoordinate(
        coordinate: savedCoordinate,
        permissionState: permissionState,
        source: QiblaCoordinateSource.savedCity,
        sourceLabel: savedCoordinate.label ?? 'Saved city',
        message:
            'Bearing is calculated from saved prayer settings, not live device location.',
      );
      return;
    }

    state = state.copyWith(
      isCheckingPermission: false,
      permissionState: permissionState,
      coordinateSource: QiblaCoordinateSource.unavailable,
      sourceLabel: 'Unavailable',
      guidanceMessage:
          'Allow location or add latitude and longitude in Prayer Settings.',
      clearDirection: true,
    );
  }

  QiblaState _stateForCoordinate({
    required _QiblaCoordinate coordinate,
    required QiblaLocationPermissionState permissionState,
    required QiblaCoordinateSource source,
    required String sourceLabel,
    required String message,
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
    );
  }

  Future<_QiblaCoordinate?> _deviceCoordinate() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return _QiblaCoordinate(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return null;
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

  QiblaLocationPermissionState _mapPermissionStatus(PermissionStatus status) {
    if (status.isGranted) return QiblaLocationPermissionState.granted;
    if (status.isPermanentlyDenied) {
      return QiblaLocationPermissionState.permanentlyDenied;
    }
    if (status.isRestricted) return QiblaLocationPermissionState.restricted;
    return QiblaLocationPermissionState.denied;
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

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier(ref, ref.watch(qiblaDirectionServiceProvider));
});
