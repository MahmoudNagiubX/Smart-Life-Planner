import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/prayer_model.dart';
import '../models/ramadan_settings_model.dart';
import '../providers/prayer_provider.dart';
import '../providers/ramadan_settings_provider.dart';

class RamadanModeScreen extends ConsumerStatefulWidget {
  const RamadanModeScreen({super.key});

  @override
  ConsumerState<RamadanModeScreen> createState() => _RamadanModeScreenState();
}

class _RamadanModeScreenState extends ConsumerState<RamadanModeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(ramadanSettingsProvider.notifier).loadSettings();
      ref.read(prayerProvider.notifier).loadTodayPrayers();
    });
  }

  Future<void> _reload() async {
    await Future.wait([
      ref.read(ramadanSettingsProvider.notifier).loadSettings(),
      ref.read(prayerProvider.notifier).loadTodayPrayers(),
    ]);
  }

  Future<void> _updateRamadanSettings({
    bool? ramadanModeEnabled,
    bool? suhoorReminderEnabled,
    int? suhoorReminderMinutesBeforeFajr,
    bool? iftarReminderEnabled,
    bool? taraweehTrackingEnabled,
    bool? fastingTrackerEnabled,
  }) async {
    final notifier = ref.read(ramadanSettingsProvider.notifier);
    await notifier.updateSettings(
      ramadanModeEnabled: ramadanModeEnabled,
      suhoorReminderEnabled: suhoorReminderEnabled,
      suhoorReminderMinutesBeforeFajr: suhoorReminderMinutesBeforeFajr,
      iftarReminderEnabled: iftarReminderEnabled,
      taraweehTrackingEnabled: taraweehTrackingEnabled,
      fastingTrackerEnabled: fastingTrackerEnabled,
    );

    final prayers = ref.read(prayerProvider).data?.prayers;
    if (prayers != null) {
      await notifier.syncRemindersForPrayers(prayers);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ramadanState = ref.watch(ramadanSettingsProvider);
    final prayerState = ref.watch(prayerProvider);
    final settings = ramadanState.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ramadan Mode',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ramadanState.isLoading && settings == null
          ? const AppLoadingState(message: 'Loading Ramadan settings...')
          : ramadanState.error != null && settings == null
          ? AppErrorState(
              title: 'Ramadan mode could not load',
              message: ramadanState.error!,
              onRetry: _reload,
            )
          : RefreshIndicator(
              onRefresh: _reload,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _FastingStatusCard(
                    settings: settings ?? _fallbackSettings,
                    prayers: prayerState.data?.prayers ?? const [],
                  ),
                  const SizedBox(height: 16),
                  _RamadanModeToggle(
                    settings: settings ?? _fallbackSettings,
                    onChanged: (value) =>
                        _updateRamadanSettings(ramadanModeEnabled: value),
                  ),
                  const SizedBox(height: 16),
                  _SuhoorReminderCard(
                    settings: settings ?? _fallbackSettings,
                    onReminderEnabledChanged: (value) =>
                        _updateRamadanSettings(suhoorReminderEnabled: value),
                    onReminderMinutesChanged: (value) => _updateRamadanSettings(
                      suhoorReminderMinutesBeforeFajr: value,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _IftarTimeCard(
                    settings: settings ?? _fallbackSettings,
                    prayers: prayerState.data?.prayers ?? const [],
                    onReminderEnabledChanged: (value) =>
                        _updateRamadanSettings(iftarReminderEnabled: value),
                  ),
                  const SizedBox(height: 16),
                  _RamadanTrackingCard(
                    settings: settings ?? _fallbackSettings,
                    onFastingTrackerChanged: (value) =>
                        _updateRamadanSettings(fastingTrackerEnabled: value),
                    onTaraweehTrackingChanged: (value) =>
                        _updateRamadanSettings(taraweehTrackingEnabled: value),
                  ),
                  if (ramadanState.isSaving) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: AppColors.prayerGold),
                  ],
                  if (ramadanState.error != null && settings != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      ramadanState.error!,
                      style: const TextStyle(color: AppColors.error),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  RamadanSettings get _fallbackSettings {
    return const RamadanSettings(
      ramadanModeEnabled: false,
      suhoorReminderEnabled: true,
      suhoorReminderMinutesBeforeFajr: 45,
      iftarReminderEnabled: true,
      taraweehTrackingEnabled: false,
      fastingTrackerEnabled: true,
    );
  }
}

class _FastingStatusCard extends StatelessWidget {
  final RamadanSettings settings;
  final List<PrayerTime> prayers;

  const _FastingStatusCard({required this.settings, required this.prayers});

  @override
  Widget build(BuildContext context) {
    final status = _fastingStatus();

    return _RamadanCard(
      icon: Icons.nights_stay_outlined,
      title: 'Fasting Status',
      accentColor: settings.ramadanModeEnabled
          ? AppColors.prayerGold
          : AppColors.textSecondary,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            status.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            status.message,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          _RamadanDetailRow(
            label: 'Fasting tracker',
            value: settings.ramadanModeEnabled && settings.fastingTrackerEnabled
                ? 'Enabled'
                : 'Disabled',
          ),
          _RamadanDetailRow(
            label: 'Fajr',
            value: _timeLabel(_prayerTime('fajr')),
          ),
          _RamadanDetailRow(
            label: 'Maghrib / Iftar',
            value: _timeLabel(_prayerTime('maghrib')),
          ),
          _RamadanDetailRow(
            label: 'Suhoor reminder',
            value: _suhoorReminderLabel(),
          ),
          _RamadanDetailRow(
            label: 'Iftar reminder',
            value: _iftarReminderLabel(),
          ),
        ],
      ),
    );
  }

  _FastingStatus _fastingStatus() {
    if (!settings.ramadanModeEnabled) {
      return const _FastingStatus(
        title: 'Ramadan mode is off',
        message: 'Enable Ramadan mode to show fasting reminders and goals.',
      );
    }

    final fajr = _prayerTime('fajr');
    final maghrib = _prayerTime('maghrib');
    final now = DateTime.now();

    if (fajr == null || maghrib == null) {
      return const _FastingStatus(
        title: 'Ramadan mode is active',
        message: 'Prayer times are loading. Iftar will use Maghrib time.',
      );
    }
    if (now.isBefore(fajr)) {
      return const _FastingStatus(
        title: 'Before Fajr',
        message: 'Suhoor window is still open for today.',
      );
    }
    if (now.isBefore(maghrib)) {
      return const _FastingStatus(
        title: 'Fasting window active',
        message: 'Iftar time will be shown from today\'s Maghrib prayer.',
      );
    }
    return const _FastingStatus(
      title: 'Iftar window',
      message: 'Maghrib has started for today.',
    );
  }

  DateTime? _prayerTime(String name) {
    for (final prayer in prayers) {
      if (prayer.prayerName == name && prayer.scheduledAt != null) {
        return DateTime.tryParse(prayer.scheduledAt!)?.toLocal();
      }
    }
    return null;
  }

  String _timeLabel(DateTime? time) =>
      time == null ? '--:--' : _formatTime(time);

  String _suhoorReminderLabel() {
    if (!settings.ramadanModeEnabled || !settings.suhoorReminderEnabled) {
      return 'Disabled';
    }
    final fajr = _prayerTime('fajr');
    if (fajr == null) return 'Waiting for Fajr';
    return _formatTime(
      fajr.subtract(
        Duration(minutes: settings.suhoorReminderMinutesBeforeFajr),
      ),
    );
  }

  String _iftarReminderLabel() {
    if (!settings.ramadanModeEnabled || !settings.iftarReminderEnabled) {
      return 'Disabled';
    }
    final maghrib = _prayerTime('maghrib');
    if (maghrib == null) return 'Waiting for Maghrib';
    return _formatTime(maghrib);
  }
}

class _FastingStatus {
  final String title;
  final String message;

  const _FastingStatus({required this.title, required this.message});
}

class _RamadanModeToggle extends StatelessWidget {
  final RamadanSettings settings;
  final ValueChanged<bool> onChanged;

  const _RamadanModeToggle({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return _RamadanCard(
      icon: Icons.toggle_on_outlined,
      title: 'Ramadan Mode',
      accentColor: AppColors.prayerGold,
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: settings.ramadanModeEnabled,
        activeThumbColor: AppColors.prayerGold,
        title: const Text('Enable Ramadan mode'),
        subtitle: const Text(
          'Shows fasting status, Suhoor preference, and Iftar from Maghrib.',
        ),
        onChanged: onChanged,
      ),
    );
  }
}

class _SuhoorReminderCard extends StatelessWidget {
  final RamadanSettings settings;
  final ValueChanged<bool> onReminderEnabledChanged;
  final ValueChanged<int> onReminderMinutesChanged;

  const _SuhoorReminderCard({
    required this.settings,
    required this.onReminderEnabledChanged,
    required this.onReminderMinutesChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RamadanCard(
      icon: Icons.alarm_outlined,
      title: 'Suhoor Reminder',
      accentColor: AppColors.primary,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.suhoorReminderEnabled,
            title: const Text('Remind before Fajr'),
            subtitle: Text(
              '${settings.suhoorReminderMinutesBeforeFajr} minutes before Fajr',
            ),
            onChanged: onReminderEnabledChanged,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease',
                onPressed: settings.suhoorReminderMinutesBeforeFajr <= 5
                    ? null
                    : () => onReminderMinutesChanged(
                        settings.suhoorReminderMinutesBeforeFajr - 5,
                      ),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Slider(
                  value: settings.suhoorReminderMinutesBeforeFajr
                      .clamp(5, 120)
                      .toDouble(),
                  min: 5,
                  max: 120,
                  divisions: 23,
                  label: '${settings.suhoorReminderMinutesBeforeFajr} minutes',
                  onChanged: settings.suhoorReminderEnabled
                      ? (value) => onReminderMinutesChanged(value.round())
                      : null,
                ),
              ),
              IconButton(
                tooltip: 'Increase',
                onPressed: settings.suhoorReminderMinutesBeforeFajr >= 120
                    ? null
                    : () => onReminderMinutesChanged(
                        settings.suhoorReminderMinutesBeforeFajr + 5,
                      ),
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _IftarTimeCard extends StatelessWidget {
  final RamadanSettings settings;
  final List<PrayerTime> prayers;
  final ValueChanged<bool> onReminderEnabledChanged;

  const _IftarTimeCard({
    required this.settings,
    required this.prayers,
    required this.onReminderEnabledChanged,
  });

  @override
  Widget build(BuildContext context) {
    final maghrib = _maghribTime();
    return _RamadanCard(
      icon: Icons.restaurant_outlined,
      title: 'Iftar Time',
      accentColor: AppColors.success,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            maghrib == null ? '--:--' : _formatTime(maghrib),
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.success,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Iftar uses today\'s Maghrib prayer time.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.iftarReminderEnabled,
            title: const Text('Iftar reminder at Maghrib'),
            subtitle: Text(
              maghrib == null
                  ? 'Reminder will schedule when Maghrib is available.'
                  : 'Reminder time: ${_formatTime(maghrib)}',
            ),
            onChanged: onReminderEnabledChanged,
          ),
        ],
      ),
    );
  }

  DateTime? _maghribTime() {
    for (final prayer in prayers) {
      if (prayer.prayerName == 'maghrib' && prayer.scheduledAt != null) {
        return DateTime.tryParse(prayer.scheduledAt!)?.toLocal();
      }
    }
    return null;
  }
}

class _RamadanTrackingCard extends StatelessWidget {
  final RamadanSettings settings;
  final ValueChanged<bool> onFastingTrackerChanged;
  final ValueChanged<bool> onTaraweehTrackingChanged;

  const _RamadanTrackingCard({
    required this.settings,
    required this.onFastingTrackerChanged,
    required this.onTaraweehTrackingChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _RamadanCard(
      icon: Icons.flag_outlined,
      title: 'Ramadan Tracking',
      accentColor: AppColors.warning,
      child: Column(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.fastingTrackerEnabled,
            title: const Text('Fasting tracker'),
            subtitle: const Text(
              'Shows fasting status and prepares today\'s fasting log.',
            ),
            onChanged: onFastingTrackerChanged,
          ),
          const Divider(height: 1),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: settings.taraweehTrackingEnabled,
            title: const Text('Taraweeh tracking'),
            subtitle: const Text(
              'Keeps Taraweeh visible for the Ramadan flow.',
            ),
            onChanged: onTaraweehTrackingChanged,
          ),
        ],
      ),
    );
  }
}

class _RamadanDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _RamadanDetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

String _formatTime(DateTime time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

class _RamadanCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;

  const _RamadanCard({
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
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
