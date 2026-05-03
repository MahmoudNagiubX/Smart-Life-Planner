import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';

class _HabitTemplate {
  final String title;
  final String description;
  final String category;
  final String emoji;
  final IconData icon;

  const _HabitTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.emoji,
    required this.icon,
  });
}

class CreateHabitSheet extends ConsumerStatefulWidget {
  final HabitModel? habit;

  const CreateHabitSheet({super.key, this.habit});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _emojiController = TextEditingController();
  String _frequency = 'daily';
  String _category = 'study';
  bool _reminderEnabled = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 8, minute: 0);
  bool _isLoading = false;

  static const _templates = [
    _HabitTemplate(
      title: 'Daily study block',
      description: 'Complete one focused study session.',
      category: 'study',
      emoji: '📚',
      icon: Icons.school,
    ),
    _HabitTemplate(
      title: 'Read 10 pages',
      description: 'Read and reflect for a few minutes.',
      category: 'reading',
      emoji: '📖',
      icon: Icons.menu_book,
    ),
    _HabitTemplate(
      title: 'Quran reading',
      description: 'Read or listen to Quran today.',
      category: 'quran',
      emoji: '🕌',
      icon: Icons.auto_stories,
    ),
    _HabitTemplate(
      title: 'Exercise',
      description: 'Move your body with a short workout.',
      category: 'exercise',
      emoji: '💪',
      icon: Icons.fitness_center,
    ),
    _HabitTemplate(
      title: 'Hydration',
      description: 'Drink enough water through the day.',
      category: 'hydration',
      emoji: '💧',
      icon: Icons.water_drop,
    ),
    _HabitTemplate(
      title: 'Sleep routine',
      description: 'Start winding down on time.',
      category: 'sleep',
      emoji: '🌙',
      icon: Icons.bedtime,
    ),
    _HabitTemplate(
      title: 'Meditation',
      description: 'Take a quiet breathing or reflection pause.',
      category: 'meditation',
      emoji: '🧘',
      icon: Icons.self_improvement,
    ),
  ];

  static const _categories = [
    'study',
    'reading',
    'quran',
    'exercise',
    'hydration',
    'sleep',
    'meditation',
  ];

  bool get _isEditing => widget.habit != null;

  @override
  void initState() {
    super.initState();
    final habit = widget.habit;
    if (habit == null) {
      _emojiController.text = _defaultEmojiForCategory(_category);
      return;
    }
    _titleController.text = habit.title;
    _descController.text = habit.description ?? '';
    _emojiController.text =
        habit.emoji ?? _defaultEmojiForCategory(habit.category ?? _category);
    _frequency = habit.frequencyType;
    _category = habit.category ?? _category;
    final reminderTime = _timeOfDayFromString(habit.reminderTime);
    if (reminderTime != null) {
      _reminderEnabled = true;
      _reminderTime = reminderTime;
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _emojiController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);
    final emoji = _normalizeEmojiInput(_emojiController.text);
    final description = _descController.text.trim().isEmpty
        ? null
        : _descController.text.trim();
    final frequencyConfig = _frequency == 'custom'
        ? {'interval_days': 2}
        : null;
    final reminderTime = _reminderEnabled ? _formatTime(_reminderTime) : null;

    if (_isEditing) {
      await ref
          .read(habitsProvider.notifier)
          .updateHabit(
            habitId: widget.habit!.id,
            title: _titleController.text.trim(),
            description: description,
            clearDescription: description == null,
            frequencyType: _frequency,
            frequencyConfig: frequencyConfig,
            clearFrequencyConfig: frequencyConfig == null,
            category: _category,
            emoji: emoji,
            clearEmoji: emoji == null,
            reminderTime: reminderTime,
            clearReminderTime: !_reminderEnabled,
          );
    } else {
      await ref
          .read(habitsProvider.notifier)
          .createHabit(
            title: _titleController.text.trim(),
            description: description,
            frequencyType: _frequency,
            frequencyConfig: frequencyConfig,
            category: _category,
            emoji: emoji,
            reminderTime: reminderTime,
          );
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  void _applyTemplate(_HabitTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descController.text = template.description;
      _emojiController.text = template.emoji;
      _category = template.category;
      _frequency = 'daily';
    });
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
              _isEditing ? 'Edit Habit' : 'New Habit',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Habit Library',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 112,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _templates.length,
                separatorBuilder: (context, index) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final template = _templates[index];
                  return _TemplateChip(
                    template: template,
                    onTap: () => _applyTemplate(template),
                  );
                },
              ),
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
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _emojiController,
              textInputAction: TextInputAction.next,
              inputFormatters: [LengthLimitingTextInputFormatter(16)],
              decoration: const InputDecoration(
                labelText: 'Custom emoji or short icon',
                hintText: '📚',
                helperText: 'Paste an emoji or keep the suggested icon.',
                counterText: '',
              ),
              maxLength: 16,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _category,
              decoration: const InputDecoration(labelText: 'Category'),
              items: _categories
                  .map(
                    (category) => DropdownMenuItem(
                      value: category,
                      child: Text(_labelForCategory(category)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() {
                _category = v!;
                if (_emojiController.text.trim().isEmpty) {
                  _emojiController.text = _defaultEmojiForCategory(_category);
                }
              }),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _frequency,
              decoration: const InputDecoration(labelText: 'Frequency'),
              items: const [
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'custom', child: Text('Every 2 days')),
              ],
              onChanged: (v) => setState(() => _frequency = v!),
            ),
            const SizedBox(height: 12),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              value: _reminderEnabled,
              onChanged: (value) => setState(() => _reminderEnabled = value),
              title: const Text('Daily reminder'),
              subtitle: Text(
                _reminderEnabled
                    ? 'Remind me at ${_reminderTime.format(context)}'
                    : 'No habit reminder',
              ),
              secondary: const Icon(Icons.notifications_active_outlined),
            ),
            if (_reminderEnabled)
              OutlinedButton.icon(
                onPressed: () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _reminderTime,
                  );
                  if (picked != null) {
                    setState(() => _reminderTime = picked);
                  }
                },
                icon: const Icon(Icons.schedule_outlined),
                label: Text(_reminderTime.format(context)),
              ),
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: Text(_isEditing ? 'Save Habit' : 'Create Habit'),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}

class _TemplateChip extends StatelessWidget {
  final _HabitTemplate template;
  final VoidCallback onTap;

  const _TemplateChip({required this.template, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 150,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.2)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(template.emoji, style: const TextStyle(fontSize: 24)),
            const SizedBox(height: 10),
            Text(
              template.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
            const Spacer(),
            Text(
              _labelForCategory(template.category),
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

String _labelForCategory(String category) {
  switch (category) {
    case 'quran':
      return 'Quran';
    default:
      return category
          .split('_')
          .map(
            (word) => word.isEmpty
                ? word
                : '${word[0].toUpperCase()}${word.substring(1)}',
          )
          .join(' ');
  }
}

String _formatTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String? _normalizeEmojiInput(String value) {
  final trimmed = value.trim();
  return trimmed.isEmpty ? null : trimmed;
}

String _defaultEmojiForCategory(String category) {
  switch (category) {
    case 'reading':
      return '📖';
    case 'quran':
      return '🕌';
    case 'exercise':
      return '💪';
    case 'hydration':
      return '💧';
    case 'sleep':
      return '🌙';
    case 'meditation':
      return '🧘';
    case 'study':
    default:
      return '📚';
  }
}

TimeOfDay? _timeOfDayFromString(String? value) {
  if (value == null) return null;
  final parts = value.split(':');
  if (parts.length < 2) return null;
  final hour = int.tryParse(parts[0]);
  final minute = int.tryParse(parts[1]);
  if (hour == null || minute == null) return null;
  return TimeOfDay(hour: hour, minute: minute);
}
