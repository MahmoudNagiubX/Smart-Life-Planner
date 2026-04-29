import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_life_planner/core/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../routes/app_routes.dart';
import '../models/app_settings_model.dart';
import '../providers/app_settings_provider.dart';

class AppSettingsScreen extends ConsumerStatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  ConsumerState<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends ConsumerState<AppSettingsScreen> {
  static const _themeOptions = {
    'dark': 'Dark',
    'light': 'Light',
    'system': 'System',
  };
  static const _timeOptions = [
    '04:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
    '00:00',
    '01:00',
  ];

  final _countryController = TextEditingController();
  final _cityController = TextEditingController();
  final _timezoneController = TextEditingController();
  String? _settingsKey;
  String _theme = 'dark';
  String _wakeTime = '06:00';
  String _sleepTime = '22:00';
  bool _notificationsEnabled = true;
  bool _microphoneEnabled = false;
  bool _locationEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSettingsProvider.notifier).loadSettings();
    });
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    _timezoneController.dispose();
    super.dispose();
  }

  void _sync(AppSettingsModel settings) {
    final key = [
      settings.country ?? '',
      settings.city ?? '',
      settings.timezone,
      settings.theme,
      settings.wakeTime ?? '',
      settings.sleepTime ?? '',
      settings.notificationsEnabled,
      settings.microphoneEnabled,
      settings.locationEnabled,
    ].join('|');
    if (_settingsKey == key) return;
    _settingsKey = key;
    _countryController.text = settings.country ?? '';
    _cityController.text = settings.city ?? '';
    _timezoneController.text = settings.timezone;
    _theme = _themeOptions.containsKey(settings.theme)
        ? settings.theme
        : 'dark';
    _wakeTime = _safeTime(settings.wakeTime, '06:00');
    _sleepTime = _safeTime(settings.sleepTime, '22:00');
    _notificationsEnabled = settings.notificationsEnabled;
    _microphoneEnabled = settings.microphoneEnabled;
    _locationEnabled = settings.locationEnabled;
  }

  String _safeTime(String? value, String fallback) {
    if (value == null || value.isEmpty) return fallback;
    return _timeOptions.contains(value) ? value : fallback;
  }

  Future<void> _save() async {
    final timezone = _timezoneController.text.trim();
    if (timezone.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Timezone is required.')));
      return;
    }

    final success = await ref
        .read(appSettingsProvider.notifier)
        .saveSettings(
          theme: _theme,
          notificationsEnabled: _notificationsEnabled,
          country: _countryController.text.trim(),
          city: _cityController.text.trim(),
          timezone: timezone,
          wakeTime: _wakeTime,
          sleepTime: _sleepTime,
          microphoneEnabled: _microphoneEnabled,
          locationEnabled: _locationEnabled,
        );

    if (!mounted) return;
    final message = success
        ? 'Settings saved.'
        : ref.read(appSettingsProvider).error ?? 'Failed to save settings.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(appSettingsProvider);
    final settings = state.settings;
    if (settings != null) _sync(settings);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.settings,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && settings == null
          ? const AppLoadingState(message: 'Loading settings...')
          : state.error != null && settings == null
          ? AppErrorState(
              title: 'Settings could not load',
              message: state.error!,
              onRetry: () => ref
                  .read(appSettingsProvider.notifier)
                  .loadSettings(force: true),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(appSettingsProvider.notifier)
                  .loadSettings(force: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _SettingsCard(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    accentColor: AppColors.primary,
                    child: Column(
                      children: [
                        _NavigationRow(
                          icon: Icons.language,
                          title: 'Language',
                          subtitle: settings?.languageLabel ?? 'English',
                          onTap: () => context.push(AppRoutes.languageSettings),
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          initialValue: _theme,
                          decoration: const InputDecoration(
                            labelText: 'Theme mode',
                          ),
                          items: _themeOptions.entries
                              .map(
                                (entry) => DropdownMenuItem(
                                  value: entry.key,
                                  child: Text(entry.value),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value == null) return;
                            setState(() => _theme = value);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    icon: Icons.schedule_outlined,
                    title: 'Daily rhythm',
                    accentColor: AppColors.success,
                    child: Column(
                      children: [
                        TextField(
                          controller: _timezoneController,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            prefixIcon: Icon(Icons.public_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _countryController,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _cityController,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: _TimeDropdown(
                                label: 'Wake time',
                                value: _wakeTime,
                                onChanged: (value) =>
                                    setState(() => _wakeTime = value),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _TimeDropdown(
                                label: 'Sleep time',
                                value: _sleepTime,
                                onChanged: (value) =>
                                    setState(() => _sleepTime = value),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications and permissions',
                    accentColor: AppColors.warning,
                    child: Column(
                      children: [
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _notificationsEnabled,
                          title: const Text('Enable reminders'),
                          subtitle: const Text(
                            'Master setting saved to your account.',
                          ),
                          onChanged: (value) =>
                              setState(() => _notificationsEnabled = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _microphoneEnabled,
                          title: const Text('Microphone preference'),
                          subtitle: const Text(
                            'Stores whether voice features should be enabled.',
                          ),
                          onChanged: (value) =>
                              setState(() => _microphoneEnabled = value),
                        ),
                        SwitchListTile(
                          contentPadding: EdgeInsets.zero,
                          value: _locationEnabled,
                          title: const Text('Location preference'),
                          subtitle: const Text(
                            'Used by prayer and Qibla features when allowed.',
                          ),
                          onChanged: (value) =>
                              setState(() => _locationEnabled = value),
                        ),
                        _NavigationRow(
                          icon: Icons.tune_outlined,
                          title: 'Detailed notification preferences',
                          subtitle: 'Channels, types, quiet hours, timing',
                          onTap: () =>
                              context.push(AppRoutes.notificationSettings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  _SettingsCard(
                    icon: Icons.summarize_outlined,
                    title: 'Connected summaries',
                    accentColor: AppColors.prayerGold,
                    child: Column(
                      children: [
                        _NavigationRow(
                          icon: Icons.mosque_outlined,
                          title: 'Prayer preferences',
                          subtitle:
                              settings?.prayerSummary ?? 'Prayer settings',
                          onTap: () => context.push(AppRoutes.prayerSettings),
                        ),
                        const SizedBox(height: 10),
                        _NavigationRow(
                          icon: Icons.timer_outlined,
                          title: 'Focus preferences',
                          subtitle:
                              settings?.focusSummary ??
                              'Focus reminder preferences',
                          onTap: () =>
                              context.push(AppRoutes.notificationSettings),
                        ),
                        const SizedBox(height: 10),
                        _StatusRow(
                          icon: Icons.sync_outlined,
                          title: 'Sync status',
                          subtitle: state.hasLoaded
                              ? 'Settings loaded from your account.'
                              : 'Not checked yet.',
                        ),
                      ],
                    ),
                  ),
                  if (state.isSaving) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: AppColors.primary),
                  ],
                  if (state.error != null && settings != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: state.isSaving ? null : _save,
                      icon: const Icon(Icons.save_outlined),
                      label: const Text('Save Settings'),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final String value;
  final ValueChanged<String> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = _AppSettingsScreenState._timeOptions.contains(value)
        ? value
        : '06:00';
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(labelText: label),
      items: _AppSettingsScreenState._timeOptions
          .map((time) => DropdownMenuItem(value: time, child: Text(time)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _NavigationRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _NavigationRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, color: AppColors.textSecondary),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color accentColor;
  final Widget child;

  const _SettingsCard({
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
