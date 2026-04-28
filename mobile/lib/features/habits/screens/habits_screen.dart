import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/habit_model.dart';
import '../providers/habit_provider.dart';
import 'create_habit_sheet.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
  String? _selectedCategory;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(habitsProvider.notifier).loadHabits();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(habitsProvider);
    final l10n = AppLocalizations.of(context)!;
    final categories =
        state.habits
            .map((habit) => habit.category)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();
    final visibleHabits = _selectedCategory == null
        ? state.habits
        : state.habits
              .where((habit) => habit.category == _selectedCategory)
              .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          l10n.habits,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading habits...')
          : state.error != null
          ? AppErrorState(
              title: 'Habits could not load',
              message: state.error!,
              onRetry: () => ref.read(habitsProvider.notifier).loadHabits(),
            )
          : state.habits.isEmpty
          ? const AppEmptyState(
              icon: Icons.local_fire_department_outlined,
              title: 'No habits yet',
              message: 'Create a small daily habit to start building momentum.',
              accentColor: AppColors.warning,
            )
          : RefreshIndicator(
              onRefresh: () => ref.read(habitsProvider.notifier).loadHabits(),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: visibleHabits.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _CategoryFilterBar(
                      categories: categories,
                      selectedCategory: _selectedCategory,
                      onSelected: (category) {
                        setState(() => _selectedCategory = category);
                      },
                    );
                  }
                  final habit = visibleHabits[index - 1];
                  final isCompleted = state.completedTodayIds.contains(
                    habit.id,
                  );
                  return _HabitCard(
                    habit: habit,
                    isCompletedToday: isCompleted,
                  );
                },
              ),
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            shape: const RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            builder: (_) => const CreateHabitSheet(),
          );
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _CategoryFilterBar extends StatelessWidget {
  final List<String> categories;
  final String? selectedCategory;
  final ValueChanged<String?> onSelected;

  const _CategoryFilterBar({
    required this.categories,
    required this.selectedCategory,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onSelected: (_) => onSelected(null),
              ),
            ),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(_labelForCategory(category)),
                  selected: selectedCategory == category,
                  onSelected: (_) => onSelected(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitCard extends ConsumerWidget {
  final HabitModel habit;
  final bool isCompletedToday;

  const _HabitCard({required this.habit, required this.isCompletedToday});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompletedToday
            ? AppColors.success.withValues(alpha: 0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompletedToday
              ? AppColors.success.withValues(alpha: 0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: isCompletedToday
                ? null
                : () =>
                      ref.read(habitsProvider.notifier).completeHabit(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? AppColors.success
                    : Colors.transparent,
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompletedToday
                      ? AppColors.success
                      : AppColors.textSecondary,
                  width: 2,
                ),
              ),
              child: isCompletedToday
                  ? const Icon(Icons.check, color: Colors.white, size: 20)
                  : null,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: isCompletedToday
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (habit.description != null)
                  Text(
                    habit.description!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 10,
                  runSpacing: 4,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _MiniMeta(
                      icon: Icons.local_fire_department,
                      label: '${habit.currentStreak} day streak',
                      color: AppColors.warning,
                    ),
                    _MiniMeta(
                      icon: Icons.repeat,
                      label: _frequencyLabel(habit),
                      color: AppColors.textSecondary,
                    ),
                    if (habit.category != null)
                      _MiniMeta(
                        icon: _iconForCategory(habit.category!),
                        label: _labelForCategory(habit.category!),
                        color: AppColors.primary,
                      ),
                    if (habit.reminderTime != null)
                      _MiniMeta(
                        icon: Icons.notifications_active_outlined,
                        label: _displayReminderTime(habit.reminderTime!),
                        color: AppColors.success,
                      ),
                  ],
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) async {
              if (value == 'set_reminder') {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      _timeOfDayFromString(habit.reminderTime) ??
                      const TimeOfDay(hour: 8, minute: 0),
                );
                if (picked == null) return;
                await ref
                    .read(habitsProvider.notifier)
                    .updateHabitReminder(
                      habitId: habit.id,
                      reminderTime: _formatReminderTime(picked),
                    );
                return;
              }
              if (value == 'clear_reminder') {
                await ref
                    .read(habitsProvider.notifier)
                    .updateHabitReminder(
                      habitId: habit.id,
                      clearReminderTime: true,
                    );
                return;
              }
              if (value == 'delete') {
                final confirmed = await confirmDestructiveAction(
                  context: context,
                  title: 'Delete Habit',
                  message:
                      'Delete "${habit.title}"? This will remove the habit from your list.',
                );
                if (!confirmed) return;
                await ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'set_reminder',
                child: Text('Set reminder'),
              ),
              if (habit.reminderTime != null)
                const PopupMenuItem(
                  value: 'clear_reminder',
                  child: Text('Clear reminder'),
                ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: AppColors.error)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniMeta extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _MiniMeta({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: color),
        ),
      ],
    );
  }
}

String _frequencyLabel(HabitModel habit) {
  if (habit.frequencyType == 'custom') {
    final interval = habit.frequencyConfig?['interval_days'];
    if (interval is int && interval > 1) {
      return 'Every $interval days';
    }
    return 'Custom';
  }
  return habit.frequencyType;
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

IconData _iconForCategory(String category) {
  switch (category) {
    case 'study':
      return Icons.school;
    case 'reading':
      return Icons.menu_book;
    case 'quran':
      return Icons.auto_stories;
    case 'exercise':
      return Icons.fitness_center;
    case 'hydration':
      return Icons.water_drop;
    case 'sleep':
      return Icons.bedtime;
    case 'meditation':
      return Icons.self_improvement;
    default:
      return Icons.category;
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

String _formatReminderTime(TimeOfDay time) {
  final hour = time.hour.toString().padLeft(2, '0');
  final minute = time.minute.toString().padLeft(2, '0');
  return '$hour:$minute:00';
}

String _displayReminderTime(String value) {
  final parts = value.split(':');
  if (parts.length < 2) return value;
  return '${parts[0]}:${parts[1]}';
}
