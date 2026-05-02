import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Notification Settings', style: AppTextStyles.h2Light),
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
              color: AppColors.brandPrimary,
              onRefresh: () => ref
                  .read(reminderPreferencesProvider.notifier)
                  .loadPreferences(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.s8,
                  AppSpacing.screenH, AppSpacing.s32,
                ),
                children: [
                  // Master switch
                  _SettingsCard(
                    icon: Icons.notifications_active_outlined,
                    title: 'Master Switch',
                    color: AppColors.brandPrimary,
                    child: _SwitchRow(
                      title: 'Enable reminders',
                      subtitle:
                          'Controls all reminder scheduling on this device.',
                      value: state.notificationsEnabled,
                      onChanged: (value) => ref
                          .read(reminderPreferencesProvider.notifier)
                          .updateNotificationsEnabled(value),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // Channels
                  _ChannelCard(preferences: preferences, onChanged: _save),
                  const SizedBox(height: AppSpacing.s12),

                  // Types
                  _TypeCard(preferences: preferences, onChanged: _save),
                  const SizedBox(height: AppSpacing.s12),

                  // Quiet hours
                  _QuietHoursCard(
                    preferences: preferences,
                    quietHourOptions: _quietHourOptions,
                    onChanged: _save,
                  ),
                  const SizedBox(height: AppSpacing.s12),

                  // Timing
                  _TimingCard(
                    preferences: preferences,
                    prayerTimings: _prayerTimings,
                    bedtimeTimings: _bedtimeTimings,
                    focusTimings: _focusTimings,
                    onChanged: _save,
                  ),

                  if (state.isSaving) ...[
                    const SizedBox(height: AppSpacing.s16),
                    const LinearProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  ],
                  if (state.error != null && state.hasLoaded) ...[
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
}

// ── Channel card ──────────────────────────────────────────────────────────────

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
      color: AppColors.successColor,
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
          const _Divider(),
          _SwitchRow(
            title: 'Push notification',
            subtitle: 'Server-driven channel for future release builds.',
            value: channels.push,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(push: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'In-app notification center',
            subtitle: 'Keep reminders visible inside the app.',
            value: channels.inApp,
            onChanged: (value) => onChanged(
              preferences.copyWith(channels: channels.copyWith(inApp: value)),
            ),
          ),
          const _Divider(),
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

// ── Type card ─────────────────────────────────────────────────────────────────

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
      color: AppColors.warningColor,
      child: Column(
        children: [
          _SwitchRow(
            title: 'Tasks',
            value: types.task,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(task: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Habits',
            value: types.habit,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(habit: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Notes',
            value: types.note,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(note: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Prayer',
            value: types.prayer,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(prayer: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Quran goal',
            value: types.quranGoal,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(quranGoal: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Focus prompts',
            value: types.focusPrompt,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(focusPrompt: value)),
            ),
          ),
          const _Divider(),
          _SwitchRow(
            title: 'Bedtime',
            value: types.bedtime,
            onChanged: (value) => onChanged(
              preferences.copyWith(types: types.copyWith(bedtime: value)),
            ),
          ),
          const _Divider(),
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

// ── Quiet hours card ──────────────────────────────────────────────────────────

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
      color: AppColors.brandPrimary,
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
          const SizedBox(height: AppSpacing.s12),
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
              const SizedBox(width: AppSpacing.s12),
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

// ── Timing card ───────────────────────────────────────────────────────────────

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
      color: AppColors.featPrayer,
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
          const SizedBox(height: AppSpacing.s12),
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
          const SizedBox(height: AppSpacing.s12),
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

// ── Shared widgets ────────────────────────────────────────────────────────────

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

class _Divider extends StatelessWidget {
  const _Divider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.dividerColor,
      height: AppSpacing.s16,
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
          .map(
            (option) =>
                DropdownMenuItem(value: option, child: Text(option)),
          )
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
            (option) => DropdownMenuItem(
              value: option,
              child: Text('$option $suffix'),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}
