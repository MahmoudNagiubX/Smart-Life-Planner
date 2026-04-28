import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/reminder_model.dart';

class TaskReminderPresetsTile extends StatelessWidget {
  final DateTime? dueAt;
  final Set<String> selectedPresets;
  final DateTime? customScheduledAt;
  final bool recurringCustomEnabled;
  final String recurringRule;
  final ValueChanged<Set<String>> onPresetsChanged;
  final ValueChanged<DateTime?> onCustomScheduledAtChanged;
  final ValueChanged<bool> onRecurringCustomChanged;
  final ValueChanged<String> onRecurringRuleChanged;

  const TaskReminderPresetsTile({
    super.key,
    required this.dueAt,
    required this.selectedPresets,
    required this.customScheduledAt,
    required this.recurringCustomEnabled,
    required this.recurringRule,
    required this.onPresetsChanged,
    required this.onCustomScheduledAtChanged,
    required this.onRecurringCustomChanged,
    required this.onRecurringRuleChanged,
  });

  static const presetLabels = {
    'at_due_time': 'At due time',
    '10_minutes_before': '10 min before',
    '1_hour_before': '1 hour before',
    '1_day_before': '1 day before',
  };

  static List<TaskReminderPresetDraft> buildDraftsFrom({
    required DateTime? dueAt,
    required Set<String> selectedPresets,
    required DateTime? customScheduledAt,
    required bool recurringCustomEnabled,
    required String recurringRule,
  }) {
    final drafts = <TaskReminderPresetDraft>[
      if (dueAt != null)
        ...selectedPresets.map(
          (preset) => TaskReminderPresetDraft(preset: preset),
        ),
    ];
    if (customScheduledAt != null) {
      drafts.add(
        TaskReminderPresetDraft(
          preset: recurringCustomEnabled ? 'recurring_custom' : 'custom',
          customScheduledAt: customScheduledAt,
          customRecurrenceRule: recurringCustomEnabled
              ? _safeRecurringRule(recurringRule)
              : null,
        ),
      );
    }
    return drafts;
  }

  Future<void> _pickCustomReminder(BuildContext context) async {
    final now = DateTime.now();
    final initial =
        customScheduledAt ?? dueAt ?? now.add(const Duration(hours: 1));
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: now,
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null) return;

    onCustomScheduledAtChanged(
      DateTime(date.year, date.month, date.day, time.hour, time.minute),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasDueAt = dueAt != null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.16)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.notifications_outlined,
                color: AppColors.primary,
              ),
              const SizedBox(width: 10),
              Text(
                'Smart reminders',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            hasDueAt
                ? 'Choose one or more reminders tied to the due date.'
                : 'Set a due date to enable due-time presets.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: presetLabels.entries.map((entry) {
              final selected = selectedPresets.contains(entry.key);
              return FilterChip(
                label: Text(entry.value),
                selected: selected,
                onSelected: hasDueAt
                    ? (value) {
                        final next = {...selectedPresets};
                        value ? next.add(entry.key) : next.remove(entry.key);
                        onPresetsChanged(next);
                      }
                    : null,
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => _pickCustomReminder(context),
            icon: const Icon(Icons.schedule_outlined),
            label: Text(
              customScheduledAt == null
                  ? 'Add custom reminder'
                  : 'Custom: ${_formatDateTime(customScheduledAt!)}',
            ),
          ),
          if (customScheduledAt != null) ...[
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: recurringCustomEnabled,
              title: const Text('Recurring custom rule'),
              subtitle: const Text('Stores a future-ready recurrence rule.'),
              onChanged: onRecurringCustomChanged,
            ),
            if (recurringCustomEnabled)
              TextFormField(
                initialValue: recurringRule,
                decoration: const InputDecoration(
                  labelText: 'Recurrence rule',
                  hintText: 'FREQ=WEEKLY;BYDAY=MO',
                ),
                onChanged: onRecurringRuleChanged,
              ),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => onCustomScheduledAtChanged(null),
                icon: const Icon(Icons.clear),
                label: const Text('Remove custom reminder'),
              ),
            ),
          ],
        ],
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '${local.year}-$month-$day $hour:$minute';
  }

  static String _safeRecurringRule(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? 'FREQ=DAILY' : trimmed;
  }
}
