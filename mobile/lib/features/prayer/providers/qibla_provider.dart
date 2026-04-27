import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

import '../services/qibla_direction_service.dart';

enum QiblaLocationPermissionState {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class QiblaState {
  final QiblaLocationPermissionState permissionState;
  final bool isCheckingPermission;
  final QiblaDirection? referenceDirection;
  final bool compassSensorIntegrationReady;

  const QiblaState({
    this.permissionState = QiblaLocationPermissionState.unknown,
    this.isCheckingPermission = false,
    this.referenceDirection,
    this.compassSensorIntegrationReady = false,
  });

  bool get hasLocationAccess =>
      permissionState == QiblaLocationPermissionState.granted;

  QiblaState copyWith({
    QiblaLocationPermissionState? permissionState,
    bool? isCheckingPermission,
    QiblaDirection? referenceDirection,
    bool? compassSensorIntegrationReady,
  }) {
    return QiblaState(
      permissionState: permissionState ?? this.permissionState,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
      referenceDirection: referenceDirection ?? this.referenceDirection,
      compassSensorIntegrationReady:
          compassSensorIntegrationReady ?? this.compassSensorIntegrationReady,
    );
  }
}

class QiblaNotifier extends StateNotifier<QiblaState> {
  final QiblaDirectionService _directionService;

  QiblaNotifier(this._directionService)
    : super(
        QiblaState(
          referenceDirection: _directionService
              .calculateCairoReferenceBearing(),
        ),
      );

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
    state = state.copyWith(isCheckingPermission: true);
    final status = await Permission.locationWhenInUse.status;
    state = state.copyWith(
      isCheckingPermission: false,
      permissionState: _mapPermissionStatus(status),
    );
  }

  Future<void> requestLocationPermission() async {
    state = state.copyWith(isCheckingPermission: true);
    final status = await Permission.locationWhenInUse.request();
    state = state.copyWith(
      isCheckingPermission: false,
      permissionState: _mapPermissionStatus(status),
    );
  }

  Future<void> openPermissionSettings() async {
    await openAppSettings();
    await checkLocationPermission();
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

final qiblaDirectionServiceProvider = Provider<QiblaDirectionService>((ref) {
  return const QiblaDirectionService();
});

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier(ref.watch(qiblaDirectionServiceProvider));
});
