import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_life_planner/core/l10n/app_localizations.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
    _theme = _themeOptions.containsKey(settings.theme) ? settings.theme : 'dark';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text(l10n.settings, style: AppTextStyles.h2Light),
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
              color: AppColors.brandPrimary,
              onRefresh: () => ref
                  .read(appSettingsProvider.notifier)
                  .loadSettings(force: true),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.s8,
                  AppSpacing.screenH, AppSpacing.s32,
                ),
                children: [
                  // Appearance
                  _SettingsCard(
                    icon: Icons.palette_outlined,
                    title: 'Appearance',
                    color: AppColors.brandPrimary,
                    child: Column(
                      children: [
                        _NavRow(
                          icon: Icons.language,
                          title: 'Language',
                          value: settings?.languageLabel ?? 'English',
                          onTap: () => context.push(AppRoutes.languageSettings),
                        ),
                        const _Divider(),
                        const SizedBox(height: AppSpacing.s8),
                        DropdownButtonFormField<String>(
                          initialValue: _theme,
                          decoration: const InputDecoration(
                            labelText: 'Theme mode',
                            prefixIcon: Icon(Icons.brightness_6_outlined),
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
                  const SizedBox(height: AppSpacing.s12),

                  // Daily rhythm
                  _SettingsCard(
                    icon: Icons.schedule_outlined,
                    title: 'Daily rhythm',
                    color: AppColors.successColor,
                    child: Column(
                      children: [
                        TextField(
                          controller: _timezoneController,
                          style: AppTextStyles.bodyLight,
                          decoration: const InputDecoration(
                            labelText: 'Timezone',
                            prefixIcon: Icon(Icons.public_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        TextField(
                          controller: _countryController,
                          style: AppTextStyles.bodyLight,
                          decoration: const InputDecoration(
                            labelText: 'Country',
                            prefixIcon: Icon(Icons.flag_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
                        TextField(
                          controller: _cityController,
                          style: AppTextStyles.bodyLight,
                          decoration: const InputDecoration(
                            labelText: 'City',
                            prefixIcon: Icon(Icons.location_city_outlined),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.s12),
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
                            const SizedBox(width: AppSpacing.s12),
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
                  const SizedBox(height: AppSpacing.s12),

                  // Notifications & permissions
                  _SettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Notifications and permissions',
                    color: AppColors.warningColor,
                    child: Column(
                      children: [
                        _SwitchRow(
                          title: 'Enable reminders',
                          subtitle: 'Master setting saved to your account.',
                          value: _notificationsEnabled,
                          onChanged: (value) =>
                              setState(() => _notificationsEnabled = value),
                        ),
                        const _Divider(),
                        _SwitchRow(
                          title: 'Microphone preference',
                          subtitle:
                              'Stores whether voice features should be enabled.',
                          value: _microphoneEnabled,
                          onChanged: (value) =>
                              setState(() => _microphoneEnabled = value),
                        ),
                        const _Divider(),
                        _SwitchRow(
                          title: 'Location preference',
                          subtitle:
                              'Used by prayer and Qibla features when allowed.',
                          value: _locationEnabled,
                          onChanged: (value) =>
                              setState(() => _locationEnabled = value),
                        ),
                        const _Divider(),
                        _NavRow(
                          icon: Icons.tune_outlined,
                          title: 'Detailed notification preferences',
                          value: 'Channels, types, quiet hours',
                          onTap: () =>
                              context.push(AppRoutes.notificationSettings),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // Connected summaries
                  _SettingsCard(
                    icon: Icons.summarize_outlined,
                    title: 'Connected summaries',
                    color: AppColors.featPrayer,
                    child: Column(
                      children: [
                        _NavRow(
                          icon: Icons.mosque_outlined,
                          title: 'Prayer preferences',
                          value: settings?.prayerSummary ?? 'Prayer settings',
                          onTap: () => context.push(AppRoutes.prayerSettings),
                        ),
                        const _Divider(),
                        _NavRow(
                          icon: Icons.timer_outlined,
                          title: 'Focus preferences',
                          value: settings?.focusSummary ??
                              'Focus reminder preferences',
                          onTap: () =>
                              context.push(AppRoutes.notificationSettings),
                        ),
                        const _Divider(),
                        _StatusRow(
                          icon: Icons.sync_outlined,
                          title: 'Sync status',
                          value: state.hasLoaded
                              ? 'Settings loaded from your account.'
                              : 'Not checked yet.',
                        ),
                      ],
                    ),
                  ),

                  if (state.isSaving) ...[
                    const SizedBox(height: AppSpacing.s16),
                    const LinearProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ],
                  if (state.error != null && settings != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(AppColors.errorColor),
                    ),
                  ],
                  const SizedBox(height: AppSpacing.s24),
                  _GradientButton(
                    label: 'Save Settings',
                    icon: Icons.save_outlined,
                    enabled: !state.isSaving,
                    onTap: state.isSaving ? null : _save,
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final Widget child;

  const _SettingsCard({
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
              Text(title, style: AppTextStyles.h4Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

// ── Row widgets ───────────────────────────────────────────────────────────────

class _NavRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final VoidCallback onTap;

  const _NavRow({
    required this.icon,
    required this.title,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceLavender,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 17, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: AppTextStyles.bodyLight),
                  if (value.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(value, style: AppTextStyles.captionLight),
                  ],
                ],
              ),
            ),
            const Icon(
              Icons.chevron_right,
              color: AppColors.textHint,
              size: AppIconSize.action,
            ),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLight),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.captionLight),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brandPrimary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _StatusRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _StatusRow({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceLavender,
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: Icon(icon, size: 17, color: AppColors.brandPrimary),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLight),
                const SizedBox(height: 2),
                Text(value, style: AppTextStyles.captionLight),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(color: AppColors.dividerColor, height: AppSpacing.s16);
  }
}

// ── Time dropdown ─────────────────────────────────────────────────────────────

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

// ── Gradient button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppButtonHeight.primary,
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.action : null,
        color: enabled ? null : AppColors.borderSoft,
        borderRadius: AppRadius.pillBr,
        boxShadow: enabled ? AppShadows.glowPurple : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                label,
                style: enabled
                    ? AppTextStyles.buttonLight
                    : AppTextStyles.button(AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
