import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/reminder_preferences_model.dart';
import '../providers/reminder_preferences_provider.dart';

class NotificationSettingsScreen extends ConsumerStatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  ConsumerState<NotificationSettingsScreen> createState() =>
      _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState
    extends ConsumerState<NotificationSettingsScreen> {
  static const _quietHourOptions = [
    '18:00',
    '19:00',
    '20:00',
    '21:00',
    '22:00',
    '23:00',
    '00:00',
    '05:00',
    '06:00',
    '07:00',
    '08:00',
    '09:00',
  ];
  static const _prayerTimings = [0, 5, 10, 15, 20, 30, 45, 60];
  static const _bedtimeTimings = [0, 15, 30, 45, 60, 90, 120];
  static const _focusTimings = [0, 5, 10, 15, 20, 30];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(reminderPreferencesProvider.notifier).loadPreferences();
    });
  }

  Future<void> _save(ReminderPreferences preferences) async {
    await ref
        .read(reminderPreferencesProvider.notifier)
        .updatePreferences(preferences);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(reminderPreferencesProvider);
    final preferences = state.preferences;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Notification Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && !state.hasLoaded
          ? const AppLoadingState(message: 'Loading reminder preferences...')
          : state.error != null && !state.hasLoaded
          ? AppErrorState(
              title: 'Reminder settings could not load',
              message: state.error!,
              onRetry: () => ref
                  .read(reminderPreferencesProvider.notifier)
                  .loadPreferences(),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(reminderPreferencesProvider.notifier)
                  .loadPreferences(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _SettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Master Switch',
                    accentColor: AppColors.primary,
                    child: SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      value: state.notificationsEnabled,
                      title: const Text('Enable reminders'),
                      subtitle: const Text(
                        'Controls all reminder scheduling on this device.',
                      ),
                      onChanged: (value) => ref
                          .read(reminderPreferencesProvider.notifier)
                          .updateNotificationsEnabled(value),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _ChannelCard(preferences: preferences, onChanged: _save),
                  const SizedBox(height: 16),
                  _TypeCard(preferences: preferences, onChanged: _save),
                  const SizedBox(height: 16),
                  _QuietHoursCard(
                    preferences: preferences,
                    quietHourOptions: _quietHourOptions,
                    onChanged: _save,
                  ),
                  const SizedBox(height: 16),
                  _TimingCard(
                    preferences: preferences,
                    prayerTimings: _prayerTimings,
                    bedtimeTimings: _bedtimeTimings,
                    focusTimings: _focusTimings,
                    onChanged: _save,
                  ),
                  if (state.isSaving) ...[
                    const SizedBox(height: 16),
                    const LinearProgressIndicator(color: AppColors.primary),
                  ],
                  if (state.error != null && state.hasLoaded) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _ChannelCard extends StatelessWidget {
  final ReminderPreferences preferences;
  final ValueChanged<ReminderPreferences> onChanged;

  const _ChannelCard({required this.preferences, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final channels = preferences.channels;
    return _SettingsCard(
      icon: Icons.settings_input_component_outlined,
      title: 'Channels',
      accentColor: AppColors.success,
      child: Column(
        children: [
          _SwitchRow(
            title: 'Local notification',
            subtitle: 'Device reminders and alarms.',
            value: channels.local,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(local: value)),
            ),
          ),
          _SwitchRow(
            title: 'Push notification',
            subtitle: 'Server-driven channel for future release builds.',
            value: channels.push,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(push: value)),
            ),
          ),
          _SwitchRow(
            title: 'In-app notification center',
            subtitle: 'Keep reminders visible inside the app.',
            value: channels.inApp,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(inApp: value)),
            ),
          ),
          _SwitchRow(
            title: 'Email',
            subtitle: 'Placeholder channel for future account reminders.',
            value: channels.email,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(email: value)),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final ReminderPreferences preferences;
  final ValueChanged<ReminderPreferences> onChanged;

  const _TypeCard({required this.preferences, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final types = preferences.types;
    return _SettingsCard(
      icon: Icons.tune_outlined,
      title: 'Reminder Types',
      accentColor: AppColors.warning,
      child: Column(
        children: [
          _SwitchRow(
            title: 'Tasks',
            value: types.task,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(task: value)),
            ),
          ),
          _SwitchRow(
            title: 'Habits',
            value: types.habit,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(habit: value)),
            ),
          ),
          _SwitchRow(
            title: 'Notes',
            value: types.note,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(note: value)),
            ),
          ),
          _SwitchRow(
            title: 'Prayer',
            value: types.prayer,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(prayer: value)),
            ),
          ),
          _SwitchRow(
            title: 'Quran goal',
            value: types.quranGoal,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(quranGoal: value)),
            ),
          ),
          _SwitchRow(
            title: 'Focus prompts',
            value: types.focusPrompt,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(focusPrompt: value)),
            ),
          ),
          _SwitchRow(
            title: 'Bedtime',
            value: types.bedtime,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(bedtime: value)),
            ),
          ),
          _SwitchRow(
            title: 'Constant reminders',
            subtitle: 'Repeat important task reminders with safe limits.',
            value: types.constantReminders,
            onChanged: (value) => onChanged(
              preferences.copyWith(
                types: types.copyWith(constantReminders: value),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuietHoursCard extends StatelessWidget {
  final ReminderPreferences preferences;
  final List<String> quietHourOptions;
  final ValueChanged<ReminderPreferences> onChanged;

  const _QuietHoursCard({
    required this.preferences,
    required this.quietHourOptions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final quietHours = preferences.quietHours;
    return _SettingsCard(
      icon: Icons.nightlight_round,
      title: 'Quiet Hours',
      accentColor: AppColors.primary,
      child: Column(
        children: [
          _SwitchRow(
            title: 'Pause non-urgent reminders',
            value: quietHours.enabled,
            onChanged: (value) => onChanged(
              preferences.copyWith(
                quietHours: quietHours.copyWith(enabled: value),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: _TimeDropdown(
                  label: 'Start',
                  value: quietHours.start,
                  options: quietHourOptions,
                  onChanged: (value) => onChanged(
                    preferences.copyWith(
                      quietHours: quietHours.copyWith(start: value),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _TimeDropdown(
                  label: 'End',
                  value: quietHours.end,
                  options: quietHourOptions,
                  onChanged: (value) => onChanged(
                    preferences.copyWith(
                      quietHours: quietHours.copyWith(end: value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimingCard extends StatelessWidget {
  final ReminderPreferences preferences;
  final List<int> prayerTimings;
  final List<int> bedtimeTimings;
  final List<int> focusTimings;
  final ValueChanged<ReminderPreferences> onChanged;

  const _TimingCard({
    required this.preferences,
    required this.prayerTimings,
    required this.bedtimeTimings,
    required this.focusTimings,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final timing = preferences.timing;
    return _SettingsCard(
      icon: Icons.schedule_outlined,
      title: 'Timing',
      accentColor: AppColors.prayerGold,
      child: Column(
        children: [
          _NumberDropdown(
            label: 'Prayer reminder',
            value: timing.prayerMinutesBefore,
            options: prayerTimings,
            suffix: 'min before',
            onChanged: (value) => onChanged(
              preferences.copyWith(
                timing: timing.copyWith(prayerMinutesBefore: value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _NumberDropdown(
            label: 'Bedtime reminder',
            value: timing.bedtimeMinutesBefore,
            options: bedtimeTimings,
            suffix: 'min before',
            onChanged: (value) => onChanged(
              preferences.copyWith(
                timing: timing.copyWith(bedtimeMinutesBefore: value),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _NumberDropdown(
            label: 'Focus prompt',
            value: timing.focusPromptMinutesBefore,
            options: focusTimings,
            suffix: 'min before',
            onChanged: (value) => onChanged(
              preferences.copyWith(
                timing: timing.copyWith(focusPromptMinutesBefore: value),
              ),
            ),
          ),
        ],
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
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle!),
      onChanged: onChanged,
    );
  }
}

class _TimeDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<String> onChanged;

  const _TimeDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<String>(
      initialValue: safeValue,
      decoration: InputDecoration(labelText: label),
      items: options
          .map((option) => DropdownMenuItem(value: option, child: Text(option)))
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _NumberDropdown extends StatelessWidget {
  final String label;
  final int value;
  final List<int> options;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _NumberDropdown({
    required this.label,
    required this.value,
    required this.options,
    required this.suffix,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final safeValue = options.contains(value) ? value : options.first;
    return DropdownButtonFormField<int>(
      initialValue: safeValue,
      decoration: InputDecoration(labelText: label),
      items: options
          .map(
            (option) =>
                DropdownMenuItem(value: option, child: Text('$option $suffix')),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
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
