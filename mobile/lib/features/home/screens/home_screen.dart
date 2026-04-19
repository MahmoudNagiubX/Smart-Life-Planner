import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../tasks/providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final tasksState = ref.watch(tasksProvider);
    final name = authState.user?['full_name'] ?? 'Friend';

    final pendingTasks =
        tasksState.tasks.where((t) => t.status == 'pending').toList();
    final completedToday = tasksState.tasks
        .where((t) =>
            t.status == 'completed' &&
            t.completedAt != null &&
            t.completedAt!.startsWith(
              DateTime.now().toIso8601String().substring(0, 10),
            ))
        .toList();

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                '👋 Hello, $name!',
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Text(
                _greeting(),
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),

              // Summary cards row
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      icon: Icons.pending_actions,
                      label: 'Pending',
                      value: '${pendingTasks.length}',
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      icon: Icons.check_circle_outline,
                      label: 'Done Today',
                      value: '${completedToday.length}',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 32),

              // Upcoming tasks section
              Text(
                'Upcoming Tasks',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),

              if (tasksState.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (pendingTasks.isEmpty)
                _EmptyTasksCard()
              else
                ...pendingTasks.take(5).map(
                      (task) => _HomeTaskTile(task: task),
                    ),

              const SizedBox(height: 32),

              // Coming soon cards
              _ComingSoonCard(
                icon: Icons.mosque_outlined,
                label: 'Next Prayer',
                color: AppColors.prayerGold,
              ),
              const SizedBox(height: 12),
              _ComingSoonCard(
                icon: Icons.timer_outlined,
                label: 'Focus Session',
                color: AppColors.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HomeTaskTile extends ConsumerWidget {
  final task;

  const _HomeTaskTile({required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () =>
                ref.read(tasksProvider.notifier).completeTask(task.id),
            child: const Icon(
              Icons.radio_button_unchecked,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (task.dueAt != null)
                  Text(
                    'Due: ${task.dueAt!.substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
              ],
            ),
          ),
          _PriorityDot(priority: task.priority),
        ],
      ),
    );
  }
}

class _PriorityDot extends StatelessWidget {
  final String priority;

  const _PriorityDot({required this.priority});

  @override
  Widget build(BuildContext context) {
    final color = priority == 'high'
        ? AppColors.error
        : priority == 'medium'
            ? AppColors.warning
            : AppColors.success;

    return Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EmptyTasksCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: Text('No pending tasks 🎉 Enjoy your day!'),
      ),
    );
  }
}

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ComingSoonCard({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              Text(
                'Coming soon',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}