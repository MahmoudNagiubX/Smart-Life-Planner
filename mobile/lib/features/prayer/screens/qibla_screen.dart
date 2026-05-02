import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../routes/app_routes.dart';
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
      ref.read(qiblaProvider.notifier).startCompass();
    });
  }

  @override
  void dispose() {
    ref.read(qiblaProvider.notifier).stopCompass();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(qiblaProvider);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text(l10n.qibla, style: AppTextStyles.h2Light),
      ),
      body:
          state.isCheckingPermission &&
              state.permissionState == QiblaLocationPermissionState.unknown
          ? const AppLoadingState(message: 'Checking location permission...')
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(qiblaProvider.notifier).refreshDirection(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s8,
                  AppSpacing.screenH,
                  138,
                ),
                children: [
                  _QiblaCompass(
                    direction: state.referenceDirection,
                    headingDegrees: state.compassHeadingDegrees,
                    rotationDegrees: state.displayRotationDegrees,
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  _DirectionCard(
                    direction: state.referenceDirection,
                    sourceLabel: state.sourceLabel,
                    guidanceMessage: state.guidanceMessage,
                    usesDeviceLocation: state.usesDeviceLocation,
                    saveWarning: state.saveWarning,
                  ),
                  if (state.isSavingLocation) ...[
                    const SizedBox(height: AppSpacing.s12),
                    LinearProgressIndicator(
                      color: AppColors.brandGold,
                      backgroundColor: AppColors.brandGold.withValues(
                        alpha: 0.18,
                      ),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  _ManualFallbackCard(coordinateSource: state.coordinateSource),
                  const SizedBox(height: AppSpacing.s16),
                  _PermissionCard(permissionState: state.permissionState),
                  const SizedBox(height: AppSpacing.s16),
                  _SensorStatusCard(state: state),
                ],
              ),
            ),
    );
  }
}

// ── Compass ───────────────────────────────────────────────────────────────────

class _QiblaCompass extends StatelessWidget {
  final QiblaDirection? direction;
  final double? headingDegrees;
  final double? rotationDegrees;

  const _QiblaCompass({
    required this.direction,
    required this.headingDegrees,
    required this.rotationDegrees,
  });

  @override
  Widget build(BuildContext context) {
    final arrowRotation = rotationDegrees ?? 0;
    final compassRotation = -(headingDegrees ?? 0);

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
                color: AppColors.brandGold.withValues(alpha: 0.08),
                border: Border.all(
                  color: AppColors.brandGold.withValues(alpha: 0.35),
                  width: 2,
                ),
              ),
            ),
            Transform.rotate(
              angle: compassRotation * math.pi / 180,
              child: const SizedBox.expand(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(top: 18, child: _CompassLabel('N')),
                    Positioned(right: 22, child: _CompassLabel('E')),
                    Positioned(bottom: 18, child: _CompassLabel('S')),
                    Positioned(left: 22, child: _CompassLabel('W')),
                  ],
                ),
              ),
            ),
            Transform.rotate(
              angle: arrowRotation * math.pi / 180,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.navigation, size: 88, color: AppColors.brandGold),
                  const SizedBox(height: 8),
                  Container(
                    width: 10,
                    height: 54,
                    decoration: BoxDecoration(
                      color: AppColors.brandGold.withValues(alpha: 0.55),
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
                color: AppColors.brandGold,
                shape: BoxShape.circle,
              ),
            ),
            if (direction != null)
              Positioned(
                bottom: 58,
                child: Text(
                  '${direction!.displayDegrees} ${direction!.compassLabel}',
                  style: AppTextStyles.label(AppColors.brandGold),
                ),
              ),
            if (headingDegrees != null)
              Positioned(
                top: 58,
                child: Text(
                  'Heading ${headingDegrees!.toStringAsFixed(0)} deg',
                  style: AppTextStyles.caption(AppColors.textSecondary),
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
    return Text(label, style: AppTextStyles.h4(AppColors.brandGold));
  }
}

// ── Direction card ────────────────────────────────────────────────────────────

class _DirectionCard extends StatelessWidget {
  final QiblaDirection? direction;
  final String sourceLabel;
  final String guidanceMessage;
  final bool usesDeviceLocation;
  final String? saveWarning;

  const _DirectionCard({
    required this.direction,
    required this.sourceLabel,
    required this.guidanceMessage,
    required this.usesDeviceLocation,
    required this.saveWarning,
  });

  @override
  Widget build(BuildContext context) {
    return _QiblaInfoCard(
      icon: Icons.explore_outlined,
      title: 'Direction',
      accentColor: AppColors.brandGold,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            direction == null
                ? 'Location is required'
                : usesDeviceLocation
                ? 'Using live device location'
                : 'Using saved prayer location',
            style: AppTextStyles.h4Light,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            guidanceMessage,
            style: AppTextStyles.caption(AppColors.textSecondary),
          ),
          if (direction != null) ...[
            const SizedBox(height: AppSpacing.s12),
            _BearingSummary(label: sourceLabel, direction: direction!),
            if (!usesDeviceLocation) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                'Compass arrow is a bearing estimate from saved coordinates.',
                style: AppTextStyles.caption(AppColors.warningColor),
              ),
            ],
            if (saveWarning != null) ...[
              const SizedBox(height: AppSpacing.s8),
              Text(
                saveWarning!,
                style: AppTextStyles.caption(AppColors.warningColor),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ── Manual fallback card ──────────────────────────────────────────────────────

class _ManualFallbackCard extends StatelessWidget {
  final QiblaCoordinateSource coordinateSource;

  const _ManualFallbackCard({required this.coordinateSource});

  @override
  Widget build(BuildContext context) {
    final hasSavedFallback =
        coordinateSource == QiblaCoordinateSource.savedCity;
    return _QiblaInfoCard(
      icon: hasSavedFallback
          ? Icons.location_city_outlined
          : Icons.add_location_alt_outlined,
      title: 'Manual Location Fallback',
      accentColor: hasSavedFallback
          ? AppColors.successColor
          : AppColors.warningColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            hasSavedFallback
                ? 'Saved city coordinates are available.'
                : 'No saved prayer location is available.',
            style: AppTextStyles.h4Light,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            hasSavedFallback
                ? 'Qibla can still calculate a respectful bearing if live location is denied or unavailable.'
                : 'Add a manual city with latitude and longitude so Qibla works without live device location.',
            style: AppTextStyles.caption(AppColors.textSecondary),
          ),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton.icon(
            onPressed: () => context.push(AppRoutes.prayerSettings),
            icon: const Icon(
              Icons.tune_outlined,
              color: AppColors.brandPrimary,
              size: 18,
            ),
            label: Text(
              hasSavedFallback ? 'Edit Manual Location' : 'Add Manual Location',
              style: const TextStyle(color: AppColors.brandPrimary),
            ),
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.brandPrimary),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.s16,
                vertical: AppSpacing.s12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Bearing summary ───────────────────────────────────────────────────────────

class _BearingSummary extends StatelessWidget {
  final String label;
  final QiblaDirection direction;

  const _BearingSummary({required this.label, required this.direction});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.brandGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.place_outlined,
            color: AppColors.brandGold,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              '$label: ${direction.displayDegrees} ${direction.compassLabel}',
              style: AppTextStyles.bodyLight,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Permission card ───────────────────────────────────────────────────────────

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
          Text(_permissionTitle, style: AppTextStyles.h4Light),
          const SizedBox(height: AppSpacing.s8),
          Text(
            _permissionMessage,
            style: AppTextStyles.caption(AppColors.textSecondary),
          ),
          if (permissionState != QiblaLocationPermissionState.granted) ...[
            const SizedBox(height: AppSpacing.s16),
            ElevatedButton.icon(
              onPressed:
                  permissionState ==
                      QiblaLocationPermissionState.permanentlyDenied
                  ? notifier.openPermissionSettings
                  : permissionState ==
                        QiblaLocationPermissionState.serviceDisabled
                  ? notifier.openLocationSettings
                  : notifier.requestLocationPermission,
              icon: Icon(
                permissionState ==
                            QiblaLocationPermissionState.permanentlyDenied ||
                        permissionState ==
                            QiblaLocationPermissionState.serviceDisabled
                    ? Icons.settings_outlined
                    : Icons.location_on_outlined,
                size: 18,
              ),
              label: Text(
                permissionState ==
                            QiblaLocationPermissionState.permanentlyDenied ||
                        permissionState ==
                            QiblaLocationPermissionState.serviceDisabled
                    ? l10n.openSettings
                    : l10n.allowLocation,
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s16,
                  vertical: AppSpacing.s12,
                ),
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
      case QiblaLocationPermissionState.serviceDisabled:
        return Icons.location_disabled_outlined;
      case QiblaLocationPermissionState.denied:
      case QiblaLocationPermissionState.unknown:
        return Icons.location_off_outlined;
    }
  }

  Color get _permissionColor {
    switch (permissionState) {
      case QiblaLocationPermissionState.granted:
        return AppColors.successColor;
      case QiblaLocationPermissionState.permanentlyDenied:
      case QiblaLocationPermissionState.restricted:
        return AppColors.errorColor;
      case QiblaLocationPermissionState.serviceDisabled:
      case QiblaLocationPermissionState.denied:
      case QiblaLocationPermissionState.unknown:
        return AppColors.warningColor;
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
      case QiblaLocationPermissionState.serviceDisabled:
        return 'Device location is off';
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
      case QiblaLocationPermissionState.serviceDisabled:
        return 'Turn on device location services or use a saved manual city.';
      case QiblaLocationPermissionState.denied:
        return 'Smart Life Planner uses location only to calculate Qibla and saves a coarse prayer coordinate for fallback. You can also save coordinates in Prayer Settings.';
      case QiblaLocationPermissionState.unknown:
        return 'Allow location after reviewing this explanation, or add a manual prayer location instead.';
    }
  }
}

// ── Sensor status card ────────────────────────────────────────────────────────

class _SensorStatusCard extends StatelessWidget {
  final QiblaState state;

  const _SensorStatusCard({required this.state});

  @override
  Widget build(BuildContext context) {
    final status = state.compassSensorStatus;
    final isReady = state.compassSensorIntegrationReady;
    final accentColor = switch (status) {
      QiblaCompassSensorStatus.active => AppColors.successColor,
      QiblaCompassSensorStatus.lowAccuracy => AppColors.warningColor,
      QiblaCompassSensorStatus.listening => AppColors.brandPrimary,
      QiblaCompassSensorStatus.unavailable => AppColors.warningColor,
      QiblaCompassSensorStatus.unknown => AppColors.brandPrimary,
    };

    return _QiblaInfoCard(
      icon: Icons.sensors_outlined,
      title: 'Compass Sensor',
      accentColor: accentColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titleForStatus(status), style: AppTextStyles.h4Light),
          const SizedBox(height: AppSpacing.s8),
          Text(
            state.compassMessage,
            style: AppTextStyles.caption(AppColors.textSecondary),
          ),
          if (isReady) ...[
            const SizedBox(height: AppSpacing.s12),
            _CompassMetricRow(
              label: 'Current heading',
              value: '${state.compassHeadingDegrees!.toStringAsFixed(0)} deg',
            ),
            if (state.qiblaRotationDegrees != null)
              _CompassMetricRow(
                label: 'Turn toward Qibla',
                value: '${state.qiblaRotationDegrees!.toStringAsFixed(0)} deg',
              ),
            if (state.compassAccuracyDegrees != null)
              _CompassMetricRow(
                label: 'Sensor accuracy',
                value:
                    '+/- ${state.compassAccuracyDegrees!.toStringAsFixed(0)} deg',
              ),
          ] else if (state.referenceDirection != null) ...[
            const SizedBox(height: AppSpacing.s12),
            Text(
              'Fallback: face the numeric bearing ${state.referenceDirection!.displayDegrees} ${state.referenceDirection!.compassLabel}.',
              style: AppTextStyles.caption(AppColors.warningColor),
            ),
          ],
        ],
      ),
    );
  }

  String _titleForStatus(QiblaCompassSensorStatus status) {
    switch (status) {
      case QiblaCompassSensorStatus.active:
        return 'Live compass active';
      case QiblaCompassSensorStatus.lowAccuracy:
        return 'Compass needs calibration';
      case QiblaCompassSensorStatus.listening:
        return 'Starting compass sensor';
      case QiblaCompassSensorStatus.unavailable:
        return 'Compass sensor unavailable';
      case QiblaCompassSensorStatus.unknown:
        return 'Compass sensor not checked';
    }
  }
}

// ── Compass metric row ────────────────────────────────────────────────────────

class _CompassMetricRow extends StatelessWidget {
  final String label;
  final String value;

  const _CompassMetricRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Expanded(child: Text(label, style: AppTextStyles.captionLight)),
          Text(value, style: AppTextStyles.label(AppColors.textHeading)),
        ],
      ),
    );
  }
}

// ── Info card shell ───────────────────────────────────────────────────────────

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
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
        border: Border.all(color: accentColor.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: accentColor, size: AppIconSize.cardHeader),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.h4(accentColor)),
                const SizedBox(height: AppSpacing.s8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
