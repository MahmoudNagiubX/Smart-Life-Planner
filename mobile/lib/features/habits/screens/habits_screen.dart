import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/habit_provider.dart';
import '../models/habit_model.dart';
import 'create_habit_sheet.dart';

class HabitsScreen extends ConsumerStatefulWidget {
  const HabitsScreen({super.key});

  @override
  ConsumerState<HabitsScreen> createState() => _HabitsScreenState();
}

class _HabitsScreenState extends ConsumerState<HabitsScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '💪 Habits',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : state.habits.isEmpty
                  ? const Center(
                      child: Text(
                        'No habits yet.\nTap + to build your first habit! 💪',
                        textAlign: TextAlign.center,
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: () =>
                          ref.read(habitsProvider.notifier).loadHabits(),
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: state.habits.length,
                        itemBuilder: (context, index) {
                          final habit = state.habits[index];
                          final isCompleted =
                              state.completedTodayIds.contains(habit.id);
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

class _HabitCard extends ConsumerWidget {
  final HabitModel habit;
  final bool isCompletedToday;

  const _HabitCard({
    required this.habit,
    required this.isCompletedToday,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isCompletedToday
            ? AppColors.success.withOpacity(0.1)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCompletedToday
              ? AppColors.success.withOpacity(0.4)
              : Colors.transparent,
        ),
      ),
      child: Row(
        children: [
          // Complete button
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

          // Habit info
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
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        size: 14, color: AppColors.warning),
                    const SizedBox(width: 4),
                    Text(
                      '${habit.currentStreak} day streak',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.warning,
                          ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      habit.frequencyType,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Delete button
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, size: 18),
            onSelected: (value) {
              if (value == 'delete') {
                ref.read(habitsProvider.notifier).deleteHabit(habit.id);
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text(
                  'Delete',
                  style: TextStyle(color: AppColors.error),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}