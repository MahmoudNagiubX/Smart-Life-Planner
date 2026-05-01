import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/dhikr_reminder_model.dart';
import '../providers/dhikr_reminder_provider.dart';

class DhikrRemindersScreen extends ConsumerStatefulWidget {
  const DhikrRemindersScreen({super.key});

  @override
  ConsumerState<DhikrRemindersScreen> createState() =>
      _DhikrRemindersScreenState();
}

class _DhikrRemindersScreenState extends ConsumerState<DhikrRemindersScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dhikrReminderProvider.notifier).loadReminders();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dhikrReminderProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dhikr Reminders',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: state.isSaving ? null : () => _openEditor(context),
        icon: const Icon(Icons.add_alert_outlined),
        label: const Text('Add'),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading dhikr reminders...')
          : state.error != null && state.reminders.isEmpty
          ? AppErrorState(
              title: 'Dhikr reminders could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(dhikrReminderProvider.notifier).loadReminders(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(dhikrReminderProvider.notifier).loadReminders(),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 96),
                children: [
                  _IntroCard(error: state.error),
                  const SizedBox(height: 16),
                  if (state.reminders.isEmpty)
                    const _EmptyDhikrState()
                  else
                    ...state.reminders.map(
                      (reminder) => _DhikrReminderTile(
                        reminder: reminder,
                        onEdit: () => _openEditor(context, reminder),
                        onToggle: (enabled) => ref
                            .read(dhikrReminderProvider.notifier)
                            .setEnabled(reminder, enabled),
                        onDisable: () => ref
                            .read(dhikrReminderProvider.notifier)
                            .disableReminder(reminder),
                      ),
                    ),
                ],
              ),
            ),
    );
  }

  Future<void> _openEditor(
    BuildContext context, [
    DhikrReminderModel? reminder,
  ]) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _DhikrEditorSheet(reminder: reminder),
    );
  }
}

class _IntroCard extends StatelessWidget {
  final String? error;

  const _IntroCard({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.prayerGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.prayerGold.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Gentle remembrance',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Create calm daily or weekday reminders for dhikr. Disabling one also cancels its future reminder.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

class _EmptyDhikrState extends StatelessWidget {
  const _EmptyDhikrState();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.notifications_active_outlined,
            size: 36,
            color: AppColors.prayerGold,
          ),
          const SizedBox(height: 10),
          Text(
            'No dhikr reminders yet',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            'Add one gentle reminder to begin.',
            textAlign: TextAlign.center,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _DhikrReminderTile extends StatelessWidget {
  final DhikrReminderModel reminder;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDisable;

  const _DhikrReminderTile({
    required this.reminder,
    required this.onEdit,
    required this.onToggle,
    required this.onDisable,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        onTap: onEdit,
        leading: const Icon(Icons.spa_outlined, color: AppColors.prayerGold),
        title: Text(reminder.title),
        subtitle: Text(
          '${_formatTime(reminder.scheduleTime)} - ${_recurrenceLabel(reminder.recurrenceRule)}'
          '${reminder.phrase == null ? '' : '\n${reminder.phrase}'}',
        ),
        isThreeLine: reminder.phrase != null,
        trailing: Switch(value: reminder.enabled, onChanged: onToggle),
        onLongPress: onDisable,
      ),
    );
  }
}

class _DhikrEditorSheet extends ConsumerStatefulWidget {
  final DhikrReminderModel? reminder;

  const _DhikrEditorSheet({this.reminder});

  @override
  ConsumerState<_DhikrEditorSheet> createState() => _DhikrEditorSheetState();
}

class _DhikrEditorSheetState extends ConsumerState<_DhikrEditorSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _phraseController;
  late TimeOfDay _time;
  late String _recurrence;
  bool _enabled = true;

  @override
  void initState() {
    super.initState();
    final reminder = widget.reminder;
    _titleController = TextEditingController(
      text: reminder?.title ?? 'Morning dhikr',
    );
    _phraseController = TextEditingController(text: reminder?.phrase ?? '');
    _time =
        _parseTimeOfDay(reminder?.scheduleTime) ??
        const TimeOfDay(hour: 7, minute: 30);
    _recurrence = reminder?.recurrenceRule ?? 'daily';
    _enabled = reminder?.enabled ?? true;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _phraseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dhikrReminderProvider);
    final bottom = MediaQuery.of(context).viewInsets.bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 8, 20, bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.reminder == null
                  ? 'Add dhikr reminder'
                  : 'Edit dhikr reminder',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _phraseController,
              decoration: const InputDecoration(
                labelText: 'Phrase',
                hintText: 'Optional',
              ),
              minLines: 1,
              maxLines: 2,
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.schedule),
              title: const Text('Reminder time'),
              subtitle: Text(_time.format(context)),
              onTap: _pickTime,
            ),
            DropdownButtonFormField<String>(
              initialValue: _recurrence,
              decoration: const InputDecoration(labelText: 'Repeat'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                DropdownMenuItem(value: 'once', child: Text('Once')),
              ],
              onChanged: (value) {
                if (value != null) setState(() => _recurrence = value);
              },
            ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _enabled,
              title: const Text('Enabled'),
              onChanged: (value) => setState(() => _enabled = value),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isSaving ? null : _save,
                icon: state.isSaving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save_outlined),
                label: const Text('Save'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(context: context, initialTime: _time);
    if (picked != null) {
      setState(() => _time = picked);
    }
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Title is required.')));
      return;
    }
    final draft = DhikrReminderDraft(
      title: title,
      phrase: _phraseController.text.trim(),
      scheduleTime: _formatApiTime(_time),
      recurrenceRule: _recurrence,
      enabled: _enabled,
    );

    final notifier = ref.read(dhikrReminderProvider.notifier);
    final ok = widget.reminder == null
        ? await notifier.createReminder(draft)
        : await notifier.updateReminder(
            reminder: widget.reminder!,
            draft: draft,
          );
    if (ok && mounted) Navigator.of(context).pop();
  }
}

String _formatApiTime(TimeOfDay time) {
  return '${time.hour.toString().padLeft(2, '0')}:'
      '${time.minute.toString().padLeft(2, '0')}:00';
}

TimeOfDay? _parseTimeOfDay(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}

String _formatTime(String value) {
  final time = _parseTimeOfDay(value);
  if (time == null) return value;
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _recurrenceLabel(String value) {
  return switch (value) {
    'weekdays' => 'Weekdays',
    'once' => 'Once',
    _ => 'Daily',
  };
}
