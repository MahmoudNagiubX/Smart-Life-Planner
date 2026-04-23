import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';

class CreateHabitSheet extends ConsumerStatefulWidget {
  const CreateHabitSheet({super.key});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _frequency = 'daily';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await ref.read(habitsProvider.notifier).createHabit(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          frequencyType: _frequency,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
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
            '💪 New Habit',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _titleController,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Habit title'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _descController,
            decoration:
                const InputDecoration(labelText: 'Description (optional)'),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: _frequency,
            decoration: const InputDecoration(labelText: 'Frequency'),
            items: const [
              DropdownMenuItem(value: 'daily', child: Text('📅 Daily')),
              DropdownMenuItem(value: 'weekly', child: Text('📆 Weekly')),
            ],
            onChanged: (v) => setState(() => _frequency = v!),
          ),
          const SizedBox(height: 24),
          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  child: const Text('Create Habit'),
                ),
        ],
      ),
    );
  }
}