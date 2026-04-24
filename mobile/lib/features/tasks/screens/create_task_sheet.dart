import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
  DateTime? _reminderAt;
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _pickReminder() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: now.add(const Duration(days: 365)),
    );
    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time == null || !mounted) return;

    setState(() {
      _reminderAt = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
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
          reminderAt: _reminderAt,
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withOpacity(0.4),
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
            value: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
              DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
              DropdownMenuItem(value: 'high', child: Text('🔴 High')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: 12),

          // Reminder picker
          GestureDetector(
            onTap: _pickReminder,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: AppColors.cardDark,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.notifications_outlined,
                    color: AppColors.textSecondary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    _reminderAt == null
                        ? 'Set reminder (optional)'
                        : 'Reminder: ${_reminderAt!.toLocal().toString().substring(0, 16)}',
                    style: TextStyle(
                      color: _reminderAt == null
                          ? AppColors.textSecondary
                          : AppColors.primary,
                    ),
                  ),
                  if (_reminderAt != null) ...[
                    const Spacer(),
                    GestureDetector(
                      onTap: () => setState(() => _reminderAt = null),
                      child: const Icon(
                        Icons.clear,
                        size: 18,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create Task'),
                ),
        ],
      ),
    );
  }
}
