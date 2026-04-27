import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';

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

  const QiblaState({
    this.permissionState = QiblaLocationPermissionState.unknown,
    this.isCheckingPermission = false,
  });

  bool get hasLocationAccess =>
      permissionState == QiblaLocationPermissionState.granted;

  QiblaState copyWith({
    QiblaLocationPermissionState? permissionState,
    bool? isCheckingPermission,
  }) {
    return QiblaState(
      permissionState: permissionState ?? this.permissionState,
      isCheckingPermission: isCheckingPermission ?? this.isCheckingPermission,
    );
  }
}

class QiblaNotifier extends StateNotifier<QiblaState> {
  QiblaNotifier() : super(const QiblaState());

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

final qiblaProvider = StateNotifierProvider<QiblaNotifier, QiblaState>((ref) {
  return QiblaNotifier();
});
