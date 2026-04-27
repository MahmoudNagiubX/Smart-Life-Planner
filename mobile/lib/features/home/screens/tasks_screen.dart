import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/screens/create_task_sheet.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Completed'),
          ],
        ),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading tasks...')
          : state.error != null
          ? AppErrorState(
              title: 'Tasks could not load',
              message: state.error!,
              onRetry: () => ref.read(tasksProvider.notifier).loadTasks(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _TaskList(
                  tasks: state.tasks
                      .where((t) => t.status == 'pending')
                      .toList(),
                  status: 'pending',
                ),
                _TaskList(
                  tasks: state.tasks
                      .where((t) => t.status == 'completed')
                      .toList(),
                  status: 'completed',
                ),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          builder: (_) => const CreateTaskSheet(),
        ),
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  final String status;

  const _TaskList({required this.tasks, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      final isCompletedTab = status == 'completed';
      return AppEmptyState(
        icon: isCompletedTab
            ? Icons.check_circle_outline
            : Icons.task_alt_outlined,
        title: isCompletedTab ? 'No completed tasks' : 'No tasks yet',
        message: isCompletedTab
            ? 'Completed tasks will appear here after you finish them.'
            : 'Create your first task to start planning the day.',
        accentColor: isCompletedTab ? AppColors.success : AppColors.primary,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(task: task);
      },
    );
  }
}

class _TaskCard extends ConsumerWidget {
  final TaskModel task;

  const _TaskCard({required this.task});

  Color _priorityColor(String priority) {
    switch (priority) {
      case 'high':
        return AppColors.error;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.success;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _priorityColor(task.priority), width: 4),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () {
              if (task.status == 'pending') {
                ref.read(tasksProvider.notifier).completeTask(task.id);
              }
            },
            child: Icon(
              task.status == 'completed'
                  ? Icons.check_circle
                  : Icons.radio_button_unchecked,
              color: task.status == 'completed'
                  ? AppColors.success
                  : AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: task.status == 'completed'
                        ? TextDecoration.lineThrough
                        : null,
                  ),
                ),
                if (task.dueAt != null)
                  Text(
                    'Due: ${task.dueAt!.substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, size: 20),
            onPressed: () async {
              final confirmed = await confirmDestructiveAction(
                context: context,
                title: 'Delete Task',
                message:
                    'Delete "${task.title}"? This task will be removed from your active list.',
              );
              if (!confirmed) return;
              await ref.read(tasksProvider.notifier).deleteTask(task.id);
            },
          ),
        ],
      ),
    );
  }
}
