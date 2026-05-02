import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart';

import '../../../core/notifications/notification_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/prayer_notification_sound.dart';
import '../models/prayer_settings_model.dart';
import '../providers/prayer_provider.dart';
import '../providers/prayer_settings_provider.dart';
import '../providers/ramadan_settings_provider.dart';

class PrayerSettingsScreen extends ConsumerStatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  ConsumerState<PrayerSettingsScreen> createState() =>
      _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends ConsumerState<PrayerSettingsScreen> {
  final _cityController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _soundPreviewPlayer = AudioPlayer();
  String? _syncedSettingsKey;

  static const _methods = <String, String>{
    'MWL': 'Muslim World League',
    'Egypt': 'Egyptian General Authority',
    'Makkah': 'Umm al-Qura, Makkah',
    'ISNA': 'ISNA',
    'Karachi': 'University of Islamic Sciences, Karachi',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _cityController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _soundPreviewPlayer.dispose();
    super.dispose();
  }

  void _syncControllers(PrayerSettings settings) {
    final key = [
      settings.city ?? '',
      settings.prayerLocationLat?.toString() ?? '',
      settings.prayerLocationLng?.toString() ?? '',
    ].join('|');
    if (_syncedSettingsKey == key) return;

    _syncedSettingsKey = key;
    _cityController.text = settings.city ?? '';
    _latitudeController.text = settings.prayerLocationLat?.toString() ?? '';
    _longitudeController.text = settings.prayerLocationLng?.toString() ?? '';
  }

  Future<void> _saveAndRefresh({
    String? prayerCalculationMethod,
    double? prayerLocationLat,
    double? prayerLocationLng,
    String? city,
    int? prayerReminderMinutesBefore,
    bool? athanSoundEnabled,
    String? prayerNotificationSound,
    bool? ramadanModeEnabled,
  }) async {
    await ref
        .read(prayerSettingsProvider.notifier)
        .updateSettings(
          prayerCalculationMethod: prayerCalculationMethod,
          prayerLocationLat: prayerLocationLat,
          prayerLocationLng: prayerLocationLng,
          city: city,
          prayerReminderMinutesBefore: prayerReminderMinutesBefore,
          athanSoundEnabled: athanSoundEnabled,
          prayerNotificationSound: prayerNotificationSound,
          ramadanModeEnabled: ramadanModeEnabled,
        );
    await ref.read(ramadanSettingsProvider.notifier).loadSettings();
    await ref
        .read(prayerProvider.notifier)
        .refreshPrayerRemindersAfterSettingsChange();
  }

  Future<void> _saveLocation() async {
    final latText = _latitudeController.text.trim();
    final lngText = _longitudeController.text.trim();
    final lat = latText.isEmpty ? null : double.tryParse(latText);
    final lng = lngText.isEmpty ? null : double.tryParse(lngText);

    if ((latText.isNotEmpty && lat == null) ||
        (lngText.isNotEmpty && lng == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid latitude and longitude.')),
      );
      return;
    }
    if ((lat != null && (lat < -90 || lat > 90)) ||
        (lng != null && (lng < -180 || lng > 180))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location coordinates are out of range.')),
      );
      return;
    }

    await _saveAndRefresh(
      city: _cityController.text.trim(),
      prayerLocationLat: lat,
      prayerLocationLng: lng,
    );
  }

  Future<void> _previewPrayerSound(String soundKey) async {
    try {
      final normalized = PrayerNotificationSound.normalize(soundKey);
      if (normalized == PrayerNotificationSound.athan) {
        await _soundPreviewPlayer.stop();
        await _soundPreviewPlayer.setAsset(
          PrayerNotificationSound.athanAssetPath,
        );
        await _soundPreviewPlayer.play();
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Playing Athan preview.')));
        return;
      }

      await NotificationService().initialize();
      await NotificationService().showPrayerSoundPreview(soundKey: normalized);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            normalized == PrayerNotificationSound.silent
                ? 'Silent preview sent if notifications are allowed.'
                : 'Default sound preview sent if notifications are allowed.',
          ),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not preview prayer sound.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerSettingsProvider);
    final settings = state.settings;
    if (settings != null) {
      _syncControllers(settings);
    }

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Prayer Settings', style: AppTextStyles.h2Light),
      ),
      body: state.isLoading && settings == null
          ? const AppLoadingState(message: 'Loading prayer settings...')
          : state.error != null && settings == null
          ? AppErrorState(
              title: 'Prayer settings could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(prayerSettingsProvider.notifier).loadSettings(),
            )
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(prayerSettingsProvider.notifier).loadSettings(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s8,
                  AppSpacing.screenH,
                  AppSpacing.s32,
                ),
                children: [
                  _MethodCard(
                    settings: settings ?? _fallbackSettings,
                    methods: _methods,
                    onChanged: (value) {
                      if (value == null) return;
                      _saveAndRefresh(prayerCalculationMethod: value);
                    },
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _LocationCard(
                    cityController: _cityController,
                    latitudeController: _latitudeController,
                    longitudeController: _longitudeController,
                    onSave: _saveLocation,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _ReminderTimingCard(
                    settings: settings ?? _fallbackSettings,
                    onChanged: (value) =>
                        _saveAndRefresh(prayerReminderMinutesBefore: value),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _PrayerSoundCard(
                    settings: settings ?? _fallbackSettings,
                    onChanged: (value) =>
                        _saveAndRefresh(prayerNotificationSound: value),
                    onPreview: _previewPrayerSound,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _RamadanToggleCard(
                    settings: settings ?? _fallbackSettings,
                    onChanged: (value) =>
                        _saveAndRefresh(ramadanModeEnabled: value),
                  ),
                  if (state.isSaving) ...[
                    const SizedBox(height: AppSpacing.s16),
                    const LinearProgressIndicator(color: AppColors.featPrayer),
                  ],
                  if (state.error != null && settings != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(AppColors.errorColor),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  PrayerSettings get _fallbackSettings {
    return const PrayerSettings(
      prayerCalculationMethod: 'MWL',
      prayerLocationLat: null,
      prayerLocationLng: null,
      city: null,
      prayerReminderMinutesBefore: 10,
      athanSoundEnabled: false,
      prayerNotificationSound: PrayerNotificationSound.defaultSound,
      ramadanModeEnabled: false,
    );
  }
}

// ── Sub-cards ─────────────────────────────────────────────────────────────────

class _MethodCard extends StatelessWidget {
  final PrayerSettings settings;
  final Map<String, String> methods;
  final ValueChanged<String?> onChanged;

  const _MethodCard({
    required this.settings,
    required this.methods,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _PrayerSettingsCard(
      icon: Icons.calculate_outlined,
      title: 'Calculation Method',
      color: AppColors.featPrayer,
      child: DropdownButtonFormField<String>(
        isExpanded: true,
        initialValue: settings.prayerCalculationMethod,
        decoration: const InputDecoration(labelText: 'Prayer calculation'),
        items: methods.entries
            .map(
              (entry) =>
                  DropdownMenuItem(value: entry.key, child: Text(entry.value)),
            )
            .toList(),
        onChanged: onChanged,
      ),
    );
  }
}

class _LocationCard extends StatelessWidget {
  final TextEditingController cityController;
  final TextEditingController latitudeController;
  final TextEditingController longitudeController;
  final VoidCallback onSave;

  const _LocationCard({
    required this.cityController,
    required this.latitudeController,
    required this.longitudeController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _PrayerSettingsCard(
      icon: Icons.location_on_outlined,
      title: 'Location',
      color: AppColors.brandPrimary,
      child: Column(
        children: [
          TextField(
            controller: cityController,
            textInputAction: TextInputAction.next,
            style: AppTextStyles.bodyLight,
            decoration: const InputDecoration(
              labelText: 'Manual city',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: latitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: AppTextStyles.bodyLight,
                  decoration: const InputDecoration(labelText: 'Latitude'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: TextField(
                  controller: longitudeController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: true,
                  ),
                  style: AppTextStyles.bodyLight,
                  decoration: const InputDecoration(labelText: 'Longitude'),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _GradientButton(
            label: 'Save Location',
            icon: Icons.save_outlined,
            onTap: onSave,
          ),
        ],
      ),
    );
  }
}

class _ReminderTimingCard extends StatelessWidget {
  final PrayerSettings settings;
  final ValueChanged<int> onChanged;

  const _ReminderTimingCard({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final value = settings.prayerReminderMinutesBefore.clamp(0, 60);

    return _PrayerSettingsCard(
      icon: Icons.notifications_active_outlined,
      title: 'Reminder Timing',
      color: AppColors.warningColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Minutes before each prayer',
                  style: AppTextStyles.bodyLight,
                ),
              ),
              Text(
                '$value min',
                style: AppTextStyles.label(AppColors.warningColor),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.warningColor,
              thumbColor: AppColors.warningColor,
              inactiveTrackColor: AppColors.borderSoft,
              overlayColor: AppColors.warningColor.withValues(alpha: 0.12),
              valueIndicatorColor: AppColors.warningColor,
            ),
            child: Slider(
              value: value.toDouble(),
              min: 0,
              max: 60,
              divisions: 12,
              label: '$value minutes',
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrayerSoundCard extends StatelessWidget {
  final PrayerSettings settings;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onPreview;

  const _PrayerSoundCard({
    required this.settings,
    required this.onChanged,
    required this.onPreview,
  });

  @override
  Widget build(BuildContext context) {
    final selectedSound = PrayerNotificationSound.normalize(
      settings.prayerNotificationSound,
      legacyAthanEnabled: settings.athanSoundEnabled,
    );

    return _PrayerSettingsCard(
      icon: Icons.volume_up_outlined,
      title: 'Prayer Sound',
      color: AppColors.successColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: selectedSound,
            decoration: const InputDecoration(
              labelText: 'Prayer reminder sound',
            ),
            items: PrayerNotificationSound.values
                .map(
                  (soundKey) => DropdownMenuItem(
                    value: soundKey,
                    child: Text(PrayerNotificationSound.label(soundKey)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              if (value != null) onChanged(value);
            },
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            PrayerNotificationSound.description(selectedSound),
            style: AppTextStyles.captionLight,
          ),
          const SizedBox(height: AppSpacing.s12),
          OutlinedButton.icon(
            onPressed: () => onPreview(selectedSound),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.brandPrimary,
              side: const BorderSide(color: AppColors.brandPrimary),
              shape: RoundedRectangleBorder(
                borderRadius: AppRadius.circular(AppRadius.md),
              ),
            ),
            icon: const Icon(Icons.play_arrow_outlined),
            label: const Text('Preview'),
          ),
        ],
      ),
    );
  }
}

class _RamadanToggleCard extends StatelessWidget {
  final PrayerSettings settings;
  final ValueChanged<bool> onChanged;

  const _RamadanToggleCard({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _PrayerSettingsCard(
      icon: Icons.nights_stay_outlined,
      title: 'Ramadan Mode',
      color: AppColors.featPrayer,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Enable Ramadan mode', style: AppTextStyles.bodyLight),
                  const SizedBox(height: 2),
                  Text(
                    'Also available from the Ramadan Mode screen.',
                    style: AppTextStyles.captionLight,
                  ),
                ],
              ),
            ),
            Switch(
              value: settings.ramadanModeEnabled,
              onChanged: onChanged,
              activeTrackColor: AppColors.featPrayer,
              activeThumbColor: Colors.white,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Prayer settings card shell ────────────────────────────────────────────────

class _PrayerSettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _PrayerSettingsCard({
    required this.icon,
    required this.title,
    required this.color,
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
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.avatar,
                height: AppIconSize.avatar,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: AppIconSize.cardHeader),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: Text(
                  title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h4Light,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppButtonHeight.primary,
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.pillBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Text(label, style: AppTextStyles.buttonLight),
            ],
          ),
        ),
      ),
    );
  }
}
