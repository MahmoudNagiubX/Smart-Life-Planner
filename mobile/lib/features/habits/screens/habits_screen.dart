import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s16,
                AppSpacing.screenH,
                AppSpacing.s12,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(l10n.habits, style: AppTextStyles.h1Light),
                        const SizedBox(height: AppSpacing.s4),
                        Text(
                          'Build consistency one small action at a time.',
                          style: AppTextStyles.bodySmall(AppColors.textHint),
                        ),
                      ],
                    ),
                  ),
                  _HabitHeaderAction(onPressed: _openCreateHabitSheet),
                ],
              ),
            ),
            Expanded(
              child: state.isLoading
                  ? const AppLoadingState(message: 'Loading habits...')
                  : state.error != null
                  ? AppErrorState(
                      title: 'Habits could not load',
                      message: state.error!,
                      onRetry: () =>
                          ref.read(habitsProvider.notifier).loadHabits(),
                    )
                  : state.habits.isEmpty
                  ? AppEmptyState(
                      icon: Icons.local_fire_department_outlined,
                      title: 'No habits yet',
                      message:
                          'Create one small daily habit to start your streak.',
                      accentColor: AppColors.success,
                      action: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: AppColors.bgSurface,
                          minimumSize: const Size(0, AppButtonHeight.small),
                          shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillBr,
                          ),
                        ),
                        onPressed: _openCreateHabitSheet,
                        icon: const Icon(Icons.add),
                        label: const Text('Create Habit'),
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(habitsProvider.notifier).loadHabits(),
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s4,
                          AppSpacing.screenH,
                          104,
                        ),
                        itemCount: visibleHabits.length + 2,
                        itemBuilder: (context, index) {
                          if (index == 0) {
                            return _HabitSummaryCard(
                              habits: state.habits,
                              completedTodayIds: state.completedTodayIds,
                            );
                          }
                          if (index == 1) {
                            return _CategoryFilterBar(
                              categories: categories,
                              selectedCategory: _selectedCategory,
                              onSelected: (category) {
                                setState(() => _selectedCategory = category);
                              },
                            );
                          }
                          final habit = visibleHabits[index - 2];
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
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openCreateHabitSheet,
        backgroundColor: AppColors.brandPrimary,
        foregroundColor: AppColors.bgSurface,
        child: const Icon(Icons.add),
      ),
    );
  }

  Future<void> _openCreateHabitSheet() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBr),
      builder: (_) => const CreateHabitSheet(),
    );
  }
}

class _HabitHeaderAction extends StatelessWidget {
  final VoidCallback onPressed;

  const _HabitHeaderAction({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: AppButtonHeight.icon,
      height: AppButtonHeight.icon,
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: BorderRadius.circular(AppRadius.md),
        boxShadow: AppShadows.glowPurple,
      ),
      child: IconButton(
        tooltip: 'Add habit',
        onPressed: onPressed,
        icon: const Icon(Icons.add, color: AppColors.bgSurface),
      ),
    );
  }
}

class _HabitSummaryCard extends StatelessWidget {
  final List<HabitModel> habits;
  final Set<String> completedTodayIds;

  const _HabitSummaryCard({
    required this.habits,
    required this.completedTodayIds,
  });

  @override
  Widget build(BuildContext context) {
    final activeHabits = habits.where((habit) => habit.isActive).length;
    final completedToday = habits
        .where((habit) => completedTodayIds.contains(habit.id))
        .length;
    final currentStreak = _maxStreak(habits, best: false);
    final bestStreak = _maxStreak(habits, best: true);
    final progress = habits.isEmpty ? 0.0 : completedToday / habits.length;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s16),
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 78,
            height: 78,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  strokeWidth: 8,
                  backgroundColor: AppColors.bgSurfaceLavender,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.brandPrimary,
                  ),
                  strokeCap: StrokeCap.round,
                ),
                Text(
                  '$completedToday/${habits.length}',
                  style: AppTextStyles.h3(AppColors.textHeading),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Today's habits", style: AppTextStyles.h3Light),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '$activeHabits active - $currentStreak-day current streak',
                  style: AppTextStyles.bodySmall(AppColors.textHint),
                ),
                const SizedBox(height: AppSpacing.s8),
                Row(
                  children: [
                    _SummaryPill(
                      icon: Icons.check_circle_outline,
                      label: '$completedToday done',
                      color: AppColors.success,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _SummaryPill(
                      icon: Icons.local_fire_department_outlined,
                      label: '$bestStreak best',
                      color: AppColors.brandPink,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _SummaryPill({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8,
          vertical: AppSpacing.s6,
        ),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.pillBr,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppSpacing.s4),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.label(color),
              ),
            ),
          ],
        ),
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
      padding: const EdgeInsets.only(bottom: AppSpacing.s16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            Padding(
              padding: const EdgeInsets.only(right: AppSpacing.s8),
              child: _HabitFilterChip(
                label: const Text('All'),
                selected: selectedCategory == null,
                onTap: () => onSelected(null),
              ),
            ),
            ...categories.map(
              (category) => Padding(
                padding: const EdgeInsets.only(right: AppSpacing.s8),
                child: _HabitFilterChip(
                  label: Text(_labelForCategory(category)),
                  selected: selectedCategory == category,
                  onTap: () => onSelected(category),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HabitFilterChip extends StatelessWidget {
  final Widget label;
  final bool selected;
  final VoidCallback onTap;

  const _HabitFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: AppRadius.pillBr,
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.s12),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.action : null,
          color: selected ? null : AppColors.bgSurface,
          borderRadius: AppRadius.pillBr,
          border: Border.all(
            color: selected
                ? AppColors.bgSurface.withValues(alpha: 0)
                : AppColors.borderSoft,
          ),
          boxShadow: selected ? AppShadows.glowPurple : AppShadows.soft,
        ),
        alignment: Alignment.center,
        child: DefaultTextStyle(
          style: AppTextStyles.label(
            selected ? AppColors.bgSurface : AppColors.textBody,
          ),
          child: label,
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
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: isCompletedToday
              ? AppColors.success.withValues(alpha: 0.34)
              : AppColors.borderSoft,
        ),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: _habitAccentColor(habit).withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _iconForCategory(habit.category ?? habit.frequencyType),
              color: _habitAccentColor(habit),
              size: AppIconSize.cardHeader,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          GestureDetector(
            onTap: isCompletedToday
                ? null
                : () =>
                      ref.read(habitsProvider.notifier).completeHabit(habit.id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: isCompletedToday
                    ? AppColors.success
                    : AppColors.bgSurface.withValues(alpha: 0),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompletedToday
                      ? AppColors.success
                      : _habitAccentColor(habit),
                  width: 2,
                ),
              ),
              child: isCompletedToday
                  ? const Icon(
                      Icons.check,
                      color: AppColors.bgSurface,
                      size: 20,
                    )
                  : null,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: AppTextStyles.h4(AppColors.textHeading).copyWith(
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
                const SizedBox(height: AppSpacing.s6),
                Wrap(
                  spacing: AppSpacing.s8,
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
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillBr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(label, style: AppTextStyles.caption(color)),
        ],
      ),
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

int _maxStreak(List<HabitModel> habits, {required bool best}) {
  var maxValue = 0;
  for (final habit in habits) {
    final value = best ? habit.longestStreak : habit.currentStreak;
    if (value > maxValue) {
      maxValue = value;
    }
  }
  return maxValue;
}

Color _habitAccentColor(HabitModel habit) {
  switch (habit.category ?? habit.frequencyType) {
    case 'exercise':
    case 'hydration':
    case 'meditation':
      return AppColors.success;
    case 'reading':
    case 'study':
    case 'quran':
      return AppColors.warning;
    case 'sleep':
      return AppColors.brandViolet;
    default:
      return AppColors.brandPrimary;
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
