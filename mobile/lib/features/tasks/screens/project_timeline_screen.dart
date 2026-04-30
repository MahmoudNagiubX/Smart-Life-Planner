import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/project_timeline_model.dart';
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
    final sortedBars = [...state.taskBars]..sort(_compareTimelineBars);

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
              child: sortedBars.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.timeline_outlined,
                      title: 'No project tasks',
                      message:
                          'Tasks linked to this project will appear on a timeline.',
                    )
                  : Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                          child: _ProjectTimelineHeader(
                            project: project,
                            taskBars: sortedBars,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            itemCount: sortedBars.length,
                            itemBuilder: (context, index) {
                              final bar = sortedBars[index];
                              return _TimelineTaskRow(
                                key: ValueKey(bar.taskId),
                                bar: bar,
                                isFirst: index == 0,
                                isLast: index == sortedBars.length - 1,
                              );
                            },
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
  final List<ProjectTimelineTaskBarModel> taskBars;

  const _ProjectTimelineHeader({required this.project, required this.taskBars});

  @override
  Widget build(BuildContext context) {
    final datedTasks = taskBars
        .where((bar) => bar.startDateTime != null || bar.dueDateTime != null)
        .toList();
    final start = datedTasks.isEmpty
        ? null
        : datedTasks.first.startDateTime ?? datedTasks.first.dueDateTime;
    final end = datedTasks.isEmpty
        ? null
        : datedTasks.last.dueDateTime ?? datedTasks.last.startDateTime;
    final totalMinutes = taskBars.fold<int>(
      0,
      (total, bar) => total + (bar.estimatedDurationMinutes ?? 0),
    );
    final completed = taskBars.where((bar) => bar.status == 'completed').length;
    final conflicts = taskBars.where((bar) => bar.conflict).length;

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
                label: '${taskBars.length} tasks',
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
              if (conflicts > 0)
                _TimelineMetricChip(
                  icon: Icons.warning_amber_outlined,
                  label: '$conflicts conflicts',
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TimelineTaskRow extends StatelessWidget {
  final ProjectTimelineTaskBarModel bar;
  final bool isFirst;
  final bool isLast;

  const _TimelineTaskRow({
    super.key,
    required this.bar,
    required this.isFirst,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    final timelineDate = bar.startDateTime;
    final dueAt = bar.dueDateTime;
    final estimate = bar.estimatedDurationMinutes;

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
                    color: _statusColor(bar.status),
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
              onTap: () => context.push('/home/tasks/${bar.taskId}'),
              child: Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: _statusColor(bar.status).withValues(alpha: 0.2),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bar.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
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
                          label: _statusLabel(bar.status),
                        ),
                        if (bar.dependencyIds.isNotEmpty)
                          _TimelineMetricChip(
                            icon: Icons.account_tree_outlined,
                            label: '${bar.dependencyIds.length} deps',
                          ),
                        if (bar.overdue)
                          const _TimelineMetricChip(
                            icon: Icons.schedule_outlined,
                            label: 'Overdue',
                          ),
                        if (bar.conflict)
                          const _TimelineMetricChip(
                            icon: Icons.warning_amber_outlined,
                            label: 'Conflict',
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

int _compareTimelineBars(
  ProjectTimelineTaskBarModel left,
  ProjectTimelineTaskBarModel right,
) {
  final leftDate = left.startDateTime ?? left.dueDateTime;
  final rightDate = right.startDateTime ?? right.dueDateTime;
  if (leftDate == null && rightDate == null) {
    return left.title.toLowerCase().compareTo(right.title.toLowerCase());
  }
  if (leftDate == null) return 1;
  if (rightDate == null) return -1;
  return leftDate.compareTo(rightDate);
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
