import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../reminders/widgets/task_reminder_presets_tile.dart';
import '../providers/task_provider.dart';

class CreateTaskSheet extends ConsumerStatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  String _bucket = 'pending';
  DateTime? _dueAt;
  final Set<String> _selectedReminderPresets = {};
  DateTime? _customReminderAt;
  bool _recurringCustomEnabled = false;
  bool _constantReminderEnabled = false;
  String _recurringRule = 'FREQ=DAILY';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;

    final time = await showTimePicker(
      context: context,
      initialTime: initial == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;

    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDateTime(initial: _dueAt);
    if (picked != null) setState(() => _dueAt = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final created = await ref
        .read(tasksProvider.notifier)
        .createTask(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          priority: _priority,
          dueAt: _dueAt,
          status: _bucket == 'calendar' ? 'pending' : _bucket,
          reminderPresets: TaskReminderPresetsTile.buildDraftsFrom(
            dueAt: _dueAt,
            selectedPresets: _selectedReminderPresets,
            customScheduledAt: _customReminderAt,
            recurringCustomEnabled: _recurringCustomEnabled,
            constantReminderEnabled: _constantReminderEnabled,
            taskPriority: _priority,
            recurringRule: _recurringRule,
          ),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (created) {
        Navigator.pop(context);
      } else {
        final error =
            ref.read(tasksProvider).error ?? 'Task could not be created';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'New Task',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _titleController,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Task title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _bucket,
              decoration: const InputDecoration(labelText: 'GTD bucket'),
              items: const [
                DropdownMenuItem(value: 'pending', child: Text('Inbox')),
                DropdownMenuItem(value: 'next', child: Text('Next Actions')),
                DropdownMenuItem(value: 'waiting', child: Text('Waiting For')),
                DropdownMenuItem(value: 'someday', child: Text('Someday')),
                DropdownMenuItem(value: 'calendar', child: Text('Calendar')),
              ],
              onChanged: (v) => setState(() => _bucket = v!),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _priority,
              decoration: const InputDecoration(labelText: 'Priority'),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
              ],
              onChanged: (v) => setState(() => _priority = v!),
            ),
            const SizedBox(height: 12),
            _DateActionTile(
              icon: Icons.event_outlined,
              label: _dueAt == null
                  ? 'Set due date for Calendar'
                  : 'Due: ${_dueAt!.toLocal().toString().substring(0, 16)}',
              active: _dueAt != null,
              onTap: _pickDueDate,
              onClear: _dueAt == null
                  ? null
                  : () => setState(() => _dueAt = null),
            ),
            const SizedBox(height: 12),
            TaskReminderPresetsTile(
              dueAt: _dueAt,
              selectedPresets: _selectedReminderPresets,
              customScheduledAt: _customReminderAt,
              recurringCustomEnabled: _recurringCustomEnabled,
              constantReminderEnabled: _constantReminderEnabled,
              taskPriority: _priority,
              recurringRule: _recurringRule,
              onPresetsChanged: (value) => setState(
                () => _selectedReminderPresets
                  ..clear()
                  ..addAll(value),
              ),
              onCustomScheduledAtChanged: (value) =>
                  setState(() => _customReminderAt = value),
              onRecurringCustomChanged: (value) =>
                  setState(() => _recurringCustomEnabled = value),
              onConstantReminderChanged: (value) =>
                  setState(() => _constantReminderEnabled = value),
              onRecurringRuleChanged: (value) =>
                  setState(() => _recurringRule = value),
            ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Task'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _DateActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const _DateActionTile({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: active ? AppColors.primary : AppColors.textSecondary,
                ),
              ),
            ),
            if (onClear != null)
              IconButton(
                tooltip: 'Clear',
                onPressed: onClear,
                icon: const Icon(Icons.clear, size: 18),
              ),
          ],
        ),
      ),
    );
  }
}
