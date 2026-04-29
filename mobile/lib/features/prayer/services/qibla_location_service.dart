import 'package:geolocator/geolocator.dart';

enum QiblaDevicePermissionStatus {
  unknown,
  granted,
  denied,
  permanentlyDenied,
  serviceDisabled,
}

class QiblaDeviceLocationResult {
  final QiblaDevicePermissionStatus permissionStatus;
  final double? latitude;
  final double? longitude;
  final String? failureMessage;

  const QiblaDeviceLocationResult({
    required this.permissionStatus,
    this.latitude,
    this.longitude,
    this.failureMessage,
  });

  bool get hasCoordinate => latitude != null && longitude != null;
}

class QiblaLocationService {
  const QiblaLocationService();

  Future<QiblaDeviceLocationResult> currentLocation({
    required bool requestPermission,
  }) async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return const QiblaDeviceLocationResult(
        permissionStatus: QiblaDevicePermissionStatus.serviceDisabled,
        failureMessage: 'Location services are turned off on this device.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (requestPermission && permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    final permissionStatus = _mapPermission(permission);
    if (permissionStatus != QiblaDevicePermissionStatus.granted) {
      return QiblaDeviceLocationResult(permissionStatus: permissionStatus);
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 8),
        ),
      );
      return QiblaDeviceLocationResult(
        permissionStatus: permissionStatus,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      return const QiblaDeviceLocationResult(
        permissionStatus: QiblaDevicePermissionStatus.granted,
        failureMessage:
            'Location permission is enabled, but live coordinates are unavailable right now.',
      );
    }
  }

  Future<void> openAppSettings() async {
    await Geolocator.openAppSettings();
  }

  Future<void> openLocationSettings() async {
    await Geolocator.openLocationSettings();
  }

  QiblaDevicePermissionStatus _mapPermission(LocationPermission permission) {
    switch (permission) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return QiblaDevicePermissionStatus.granted;
      case LocationPermission.deniedForever:
        return QiblaDevicePermissionStatus.permanentlyDenied;
      case LocationPermission.denied:
        return QiblaDevicePermissionStatus.denied;
      case LocationPermission.unableToDetermine:
        return QiblaDevicePermissionStatus.unknown;
    }
  }
}
