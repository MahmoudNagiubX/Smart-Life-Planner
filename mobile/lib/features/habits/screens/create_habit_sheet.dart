import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';

class _HabitTemplate {
  final String title;
  final String description;
  final String category;
  final IconData icon;

  const _HabitTemplate({
    required this.title,
    required this.description,
    required this.category,
    required this.icon,
  });
}

class CreateHabitSheet extends ConsumerStatefulWidget {
  const CreateHabitSheet({super.key});

  @override
  ConsumerState<CreateHabitSheet> createState() => _CreateHabitSheetState();
}

class _CreateHabitSheetState extends ConsumerState<CreateHabitSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _frequency = 'daily';
  String _category = 'study';
  bool _isLoading = false;

  static const _templates = [
    _HabitTemplate(
      title: 'Daily study block',
      description: 'Complete one focused study session.',
      category: 'study',
      icon: Icons.school,
    ),
    _HabitTemplate(
      title: 'Read 10 pages',
      description: 'Read and reflect for a few minutes.',
      category: 'reading',
      icon: Icons.menu_book,
    ),
    _HabitTemplate(
      title: 'Quran reading',
      description: 'Read or listen to Quran today.',
      category: 'quran',
      icon: Icons.auto_stories,
    ),
    _HabitTemplate(
      title: 'Exercise',
      description: 'Move your body with a short workout.',
      category: 'exercise',
      icon: Icons.fitness_center,
    ),
    _HabitTemplate(
      title: 'Hydration',
      description: 'Drink enough water through the day.',
      category: 'hydration',
      icon: Icons.water_drop,
    ),
    _HabitTemplate(
      title: 'Sleep routine',
      description: 'Start winding down on time.',
      category: 'sleep',
      icon: Icons.bedtime,
    ),
    _HabitTemplate(
      title: 'Meditation',
      description: 'Take a quiet breathing or reflection pause.',
      category: 'meditation',
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

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    await ref
        .read(habitsProvider.notifier)
        .createHabit(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          frequencyType: _frequency,
          frequencyConfig: _frequency == 'custom' ? {'interval_days': 2} : null,
          category: _category,
        );

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pop(context);
    }
  }

  void _applyTemplate(_HabitTemplate template) {
    setState(() {
      _titleController.text = template.title;
      _descController.text = template.description;
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
              'New Habit',
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
              onChanged: (v) => setState(() => _category = v!),
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
            const SizedBox(height: 24),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      child: const Text('Create Habit'),
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
            Icon(template.icon, color: AppColors.primary),
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
