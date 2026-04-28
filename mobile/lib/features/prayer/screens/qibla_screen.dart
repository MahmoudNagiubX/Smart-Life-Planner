import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../providers/qibla_provider.dart';
import '../services/qibla_direction_service.dart';

class QiblaScreen extends ConsumerStatefulWidget {
  const QiblaScreen({super.key});

  @override
  ConsumerState<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends ConsumerState<QiblaScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(qiblaProvider.notifier).checkLocationPermission();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qiblaProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.qibla,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body:
          state.isCheckingPermission &&
              state.permissionState == QiblaLocationPermissionState.unknown
          ? const AppLoadingState(message: 'Checking location permission...')
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(qiblaProvider.notifier).refreshDirection(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _CompassPlaceholder(direction: state.referenceDirection),
                  const SizedBox(height: 24),
                  _DirectionCard(
                    direction: state.referenceDirection,
                    sourceLabel: state.sourceLabel,
                    guidanceMessage: state.guidanceMessage,
                    usesDeviceLocation: state.usesDeviceLocation,
                  ),
                  const SizedBox(height: 16),
                  _PermissionCard(permissionState: state.permissionState),
                  const SizedBox(height: 16),
                  _SensorStatusCard(
                    isReady: state.compassSensorIntegrationReady,
                  ),
                ],
              ),
            ),
    );
  }
}

class _CompassPlaceholder extends StatelessWidget {
  final QiblaDirection? direction;

  const _CompassPlaceholder({required this.direction});

  @override
  Widget build(BuildContext context) {
    final bearing = direction?.bearingDegrees ?? 0;

    return Center(
      child: SizedBox(
        width: 260,
        height: 260,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.prayerGold.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.prayerGold.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
            ),
            const Positioned(top: 18, child: _CompassLabel('N')),
            const Positioned(right: 22, child: _CompassLabel('E')),
            const Positioned(bottom: 18, child: _CompassLabel('S')),
            const Positioned(left: 22, child: _CompassLabel('W')),
            Transform.rotate(
              angle: bearing * math.pi / 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, size: 88, color: AppColors.prayerGold),
                  const SizedBox(height: 8),
                  Container(
                    width: 10,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.prayerGold.withValues(alpha: 0.55),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: AppColors.prayerGold,
                shape: BoxShape.circle,
              ),
            ),
            if (direction != null)
              Positioned(
                bottom: 58,
                child: Text(
                  '${direction!.displayDegrees} ${direction!.compassLabel}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.prayerGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CompassLabel extends StatelessWidget {
  final String label;

  const _CompassLabel(this.label);

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: Theme.of(context).textTheme.titleMedium?.copyWith(
        color: AppColors.prayerGold,
        fontWeight: FontWeight.bold,
      ),
    );
  }
}

class _DirectionCard extends StatelessWidget {
  final QiblaDirection? direction;
  final String sourceLabel;
  final String guidanceMessage;
  final bool usesDeviceLocation;

  const _DirectionCard({
    required this.direction,
    required this.sourceLabel,
    required this.guidanceMessage,
    required this.usesDeviceLocation,
  });

  @override
  Widget build(BuildContext context) {
    return _QiblaInfoCard(
      icon: Icons.explore_outlined,
      title: 'Direction',
      accentColor: AppColors.prayerGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            direction == null
                ? 'Location is required'
                : usesDeviceLocation
                ? 'Using live device location'
                : 'Using saved prayer location',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            guidanceMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (direction != null) ...[
            const SizedBox(height: 14),
            _BearingSummary(label: sourceLabel, direction: direction!),
            if (!usesDeviceLocation) ...[
              const SizedBox(height: 8),
              Text(
                'Compass arrow is a bearing estimate from saved coordinates.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.warning),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

class _BearingSummary extends StatelessWidget {
  final String label;
  final QiblaDirection direction;

  const _BearingSummary({required this.label, required this.direction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.prayerGold.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            color: AppColors.prayerGold,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '$label: ${direction.displayDegrees} ${direction.compassLabel}',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _PermissionCard extends ConsumerWidget {
  final QiblaLocationPermissionState permissionState;

  const _PermissionCard({required this.permissionState});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(qiblaProvider.notifier);
    final l10n = AppLocalizations.of(context)!;

    return _QiblaInfoCard(
      icon: _permissionIcon,
      title: 'Location Permission',
      accentColor: _permissionColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _permissionTitle,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Text(
            _permissionMessage,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          if (permissionState != QiblaLocationPermissionState.granted) ...[
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed:
                  permissionState ==
                      QiblaLocationPermissionState.permanentlyDenied
                  ? notifier.openPermissionSettings
                  : notifier.requestLocationPermission,
              icon: Icon(
                permissionState ==
                        QiblaLocationPermissionState.permanentlyDenied
                    ? Icons.settings_outlined
                    : Icons.location_on_outlined,
              ),
              label: Text(
                permissionState ==
                        QiblaLocationPermissionState.permanentlyDenied
                    ? l10n.openSettings
                    : l10n.allowLocation,
              ),
            ),
          ],
        ],
      ),
    );
  }

  IconData get _permissionIcon {
    switch (permissionState) {
      case QiblaLocationPermissionState.granted:
        return Icons.check_circle_outline;
      case QiblaLocationPermissionState.permanentlyDenied:
        return Icons.settings_outlined;
      case QiblaLocationPermissionState.restricted:
        return Icons.lock_outline;
      case QiblaLocationPermissionState.denied:
      case QiblaLocationPermissionState.unknown:
        return Icons.location_off_outlined;
    }
  }

  Color get _permissionColor {
    switch (permissionState) {
      case QiblaLocationPermissionState.granted:
        return AppColors.success;
      case QiblaLocationPermissionState.permanentlyDenied:
      case QiblaLocationPermissionState.restricted:
        return AppColors.error;
      case QiblaLocationPermissionState.denied:
      case QiblaLocationPermissionState.unknown:
        return AppColors.warning;
    }
  }

  String get _permissionTitle {
    switch (permissionState) {
      case QiblaLocationPermissionState.granted:
        return 'Location access is enabled';
      case QiblaLocationPermissionState.permanentlyDenied:
        return 'Location access is blocked';
      case QiblaLocationPermissionState.restricted:
        return 'Location access is restricted';
      case QiblaLocationPermissionState.denied:
        return 'Location access is off';
      case QiblaLocationPermissionState.unknown:
        return 'Location status is unknown';
    }
  }

  String get _permissionMessage {
    switch (permissionState) {
      case QiblaLocationPermissionState.granted:
        return 'Qibla will use device coordinates when location service is available.';
      case QiblaLocationPermissionState.permanentlyDenied:
        return 'Open app settings to allow location for Qibla direction.';
      case QiblaLocationPermissionState.restricted:
        return 'This device or profile is restricting location access.';
      case QiblaLocationPermissionState.denied:
        return 'Allow location for current-place bearing, or save coordinates in Prayer Settings.';
      case QiblaLocationPermissionState.unknown:
        return 'Pull to refresh or allow location to check the current permission state.';
    }
  }
}

class _SensorStatusCard extends StatelessWidget {
  final bool isReady;

  const _SensorStatusCard({required this.isReady});

  @override
  Widget build(BuildContext context) {
    return _QiblaInfoCard(
      icon: Icons.sensors_outlined,
      title: 'Compass Sensor',
      accentColor: isReady ? AppColors.success : AppColors.primary,
      child: Text(
        isReady
            ? 'Compass sensor integration is available.'
            : 'Bearing calculation is active. Live sensor rotation is still a placeholder, so the arrow shows calculated bearing only.',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppColors.textSecondary,
          height: 1.45,
        ),
      ),
    );
  }
}

class _QiblaInfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;

  const _QiblaInfoCard({
    required this.icon,
    required this.title,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: accentColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
