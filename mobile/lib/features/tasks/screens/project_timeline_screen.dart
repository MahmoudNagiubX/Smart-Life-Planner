import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class ProjectTimelineScreen extends ConsumerStatefulWidget {
  final String projectId;

  const ProjectTimelineScreen({super.key, required this.projectId});

  @override
  ConsumerState<ProjectTimelineScreen> createState() =>
      _ProjectTimelineScreenState();
}

class _ProjectTimelineScreenState extends ConsumerState<ProjectTimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(projectTimelineProvider(widget.projectId).notifier).load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(projectTimelineProvider(widget.projectId));
    final project = state.project;
    final sortedTasks = [...state.tasks]..sort(_compareTimelineTasks);

    return Scaffold(
      appBar: AppBar(title: Text(project?.title ?? 'Project Timeline')),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading project timeline...')
          : state.error != null
          ? AppErrorState(
              title: 'Timeline could not load',
              message: state.error!,
              onRetry: () => ref
                  .read(projectTimelineProvider(widget.projectId).notifier)
                  .load(),
            )
          : RefreshIndicator(
              onRefresh: () => ref
                  .read(projectTimelineProvider(widget.projectId).notifier)
                  .load(),
              child: sortedTasks.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.timeline_outlined,
                      title: 'No project tasks',
                      message:
                          'Tasks linked to this project will appear on a read-only timeline.',
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        _ProjectTimelineHeader(
                          project: project,
                          tasks: sortedTasks,
                        ),
                        const SizedBox(height: 16),
                        ...sortedTasks.asMap().entries.map(
                          (entry) => _TimelineTaskRow(
                            task: entry.value,
                            isFirst: entry.key == 0,
                            isLast: entry.key == sortedTasks.length - 1,
                          ),
                        ),
                      ],
                    ),
            ),
    );
  }
}

class _ProjectTimelineHeader extends StatelessWidget {
  final TaskProject? project;
  final List<TaskModel> tasks;

  const _ProjectTimelineHeader({required this.project, required this.tasks});

  @override
  Widget build(BuildContext context) {
    final datedTasks = tasks
        .where((task) => _taskTimelineDate(task) != null)
        .toList();
    final start = datedTasks.isEmpty
        ? null
        : _taskTimelineDate(datedTasks.first);
    final end = datedTasks.isEmpty ? null : _taskTimelineDate(datedTasks.last);
    final totalMinutes = tasks.fold<int>(
      0,
      (total, task) => total + (task.estimatedMinutes ?? 0),
    );
    final completed = tasks.where((task) => task.status == 'completed').length;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project?.title ?? 'Project',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _TimelineMetricChip(
                icon: Icons.task_alt,
                label: '${tasks.length} tasks',
              ),
              _TimelineMetricChip(
                icon: Icons.check_circle_outline,
                label: '$completed done',
              ),
              _TimelineMetricChip(
                icon: Icons.timer_outlined,
                label: totalMinutes == 0 ? 'No estimate' : '$totalMinutes min',
              ),
              _TimelineMetricChip(
                icon: Icons.date_range_outlined,
                label: start == null || end == null
                    ? 'No dates'
                    : '${_shortDate(start)} - ${_shortDate(end)}',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineTaskRow extends StatelessWidget {
  final TaskModel task;
  final bool isFirst;
  final bool isLast;

  const _TimelineTaskRow({
    required this.task,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timelineDate = _taskTimelineDate(task);
    final dueAt = task.dueAt == null ? null : DateTime.tryParse(task.dueAt!);
    final estimate = task.estimatedMinutes;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 34,
            child: Column(
              children: [
                Expanded(
                  child: Container(
                    width: 2,
                    color: isFirst
                        ? Colors.transparent
                        : AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: _statusColor(task.status),
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 2,
                    color: isLast
                        ? Colors.transparent
                        : AppColors.primary.withValues(alpha: 0.28),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => context.push('/home/tasks/${task.id}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _statusColor(task.status).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    if (task.description != null &&
                        task.description!.isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        task.description!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _TimelineMetricChip(
                          icon: Icons.play_arrow_outlined,
                          label:
                              'Start ${timelineDate == null ? 'unset' : _shortDate(timelineDate)}',
                        ),
                        _TimelineMetricChip(
                          icon: Icons.flag_outlined,
                          label:
                              'Due ${dueAt == null ? 'unset' : _shortDate(dueAt)}',
                        ),
                        _TimelineMetricChip(
                          icon: Icons.timer_outlined,
                          label: estimate == null
                              ? 'No estimate'
                              : '$estimate min',
                        ),
                        _TimelineMetricChip(
                          icon: Icons.layers_outlined,
                          label: _statusLabel(task.status),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TimelineMetricChip({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              color: AppColors.primary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

int _compareTimelineTasks(TaskModel left, TaskModel right) {
  final leftDate = _taskTimelineDate(left);
  final rightDate = _taskTimelineDate(right);
  if (leftDate == null && rightDate == null) {
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }
  if (leftDate == null) return 1;
  if (rightDate == null) return -1;
  return leftDate.compareTo(rightDate);
}

DateTime? _taskTimelineDate(TaskModel task) {
  return DateTime.tryParse(task.createdAt)?.toLocal();
}

String _shortDate(DateTime date) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

Color _statusColor(String status) {
  return switch (status) {
    'completed' => AppColors.success,
    'in_progress' => AppColors.warning,
    'waiting' => AppColors.prayerGold,
    'next' => AppColors.primary,
    _ => AppColors.textSecondary,
  };
}

String _statusLabel(String status) {
  return switch (status) {
    'in_progress' => 'In progress',
    'completed' => 'Done',
    'waiting' => 'Waiting',
    'next' => 'Next',
    _ => 'Inbox',
  };
}
