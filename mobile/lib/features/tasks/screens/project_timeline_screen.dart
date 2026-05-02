import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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

class _ProjectTimelineScreenState
    extends ConsumerState<ProjectTimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(projectTimelineProvider(widget.projectId).notifier)
          .load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state =
        ref.watch(projectTimelineProvider(widget.projectId));
    final sortedBars = [...state.taskBars]
      ..sort(_compareTimelineBars);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text(
          state.project?.title ?? 'Project Timeline',
          style: AppTextStyles.h2Light,
        ),
      ),
      body: state.isLoading
          ? const AppLoadingState(
              message: 'Loading project timeline...')
          : state.error != null
              ? AppErrorState(
                  title: 'Timeline could not load',
                  message: state.error!,
                  onRetry: () => ref
                      .read(projectTimelineProvider(widget.projectId)
                          .notifier)
                      .load(),
                )
              : RefreshIndicator(
                  color: AppColors.brandPrimary,
                  onRefresh: () => ref
                      .read(projectTimelineProvider(widget.projectId)
                          .notifier)
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
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.screenH,
                                AppSpacing.s16,
                                AppSpacing.screenH,
                                0,
                              ),
                              child: _ProjectTimelineHeader(
                                project: state.project,
                                taskBars: sortedBars,
                              ),
                            ),
                            const SizedBox(height: AppSpacing.s16),
                            Expanded(
                              child: ListView.builder(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.screenH),
                                itemCount: sortedBars.length,
                                itemBuilder: (context, index) {
                                  final bar = sortedBars[index];
                                  return _TimelineTaskRow(
                                    key: ValueKey(bar.taskId),
                                    bar: bar,
                                    isFirst: index == 0,
                                    isLast: index ==
                                        sortedBars.length - 1,
                                    onDateChanged:
                                        _confirmAndSaveDateChange,
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                ),
    );
  }

  Future<void> _confirmAndSaveDateChange(
    ProjectTimelineTaskBarModel bar,
    _TimelineDateField field,
    DateTime newValue,
  ) async {
    final state =
        ref.read(projectTimelineProvider(widget.projectId));
    final validationError = _validateTimelineDateChange(
      state: state,
      bar: bar,
      field: field,
      newValue: newValue,
    );
    if (validationError != null) {
      _showTimelineMessage(validationError);
      return;
    }

    final oldValue = field == _TimelineDateField.start
        ? bar.startDateTime
        : bar.dueDateTime;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.cardBr),
        title:
            Text('Save timeline change?', style: AppTextStyles.h3Light),
        content: Text(
          '${bar.title}\n'
          '${_fieldLabel(field)}: ${_dateOrUnset(oldValue)} -> ${_dateOrUnset(newValue)}',
          style: AppTextStyles.body(AppColors.textSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final error = await ref
        .read(
            projectTimelineProvider(widget.projectId).notifier)
        .updateTimelineTaskDates(
          taskId: bar.taskId,
          startDate:
              field == _TimelineDateField.start ? newValue : null,
          dueDate:
              field == _TimelineDateField.due ? newValue : null,
        );

    if (!mounted) return;
    _showTimelineMessage(error ?? 'Timeline updated');
  }

  String? _validateTimelineDateChange({
    required ProjectTimelineState state,
    required ProjectTimelineTaskBarModel bar,
    required _TimelineDateField field,
    required DateTime newValue,
  }) {
    final newStart = field == _TimelineDateField.start
        ? newValue
        : bar.startDateTime;
    final newDue =
        field == _TimelineDateField.due ? newValue : bar.dueDateTime;
    if (newStart != null &&
        newDue != null &&
        newStart.isAfter(newDue)) {
      return 'Start date cannot be after due date.';
    }

    final barsById = {
      for (final item in state.taskBars) item.taskId: item
    };
    if (newStart != null) {
      for (final dependencyId in bar.dependencyIds) {
        final dependency = barsById[dependencyId];
        final dependencyDue = dependency?.dueDateTime;
        if (dependencyDue != null &&
            dependencyDue.isAfter(newStart)) {
          return 'Task cannot start before a blocking dependency is due.';
        }
      }
    }
    if (newDue != null) {
      for (final dependency in state.dependencies) {
        if (dependency.dependsOnTaskId != bar.taskId) continue;
        final dependent = barsById[dependency.taskId];
        final dependentStart = dependent?.startDateTime;
        if (dependentStart != null &&
            newDue.isAfter(dependentStart)) {
          return 'Due date cannot move after a dependent task starts.';
        }
      }
    }
    return null;
  }

  void _showTimelineMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
      ),
    );
  }
}

// ── Timeline header ───────────────────────────────────────────────────────────

class _ProjectTimelineHeader extends StatelessWidget {
  final TaskProject? project;
  final List<ProjectTimelineTaskBarModel> taskBars;

  const _ProjectTimelineHeader(
      {required this.project, required this.taskBars});

  @override
  Widget build(BuildContext context) {
    final datedTasks = taskBars
        .where((bar) =>
            bar.startDateTime != null || bar.dueDateTime != null)
        .toList();
    final start = datedTasks.isEmpty
        ? null
        : datedTasks.first.startDateTime ??
            datedTasks.first.dueDateTime;
    final end = datedTasks.isEmpty
        ? null
        : datedTasks.last.dueDateTime ??
            datedTasks.last.startDateTime;
    final totalMinutes = taskBars.fold<int>(
      0,
      (total, bar) => total + (bar.estimatedDurationMinutes ?? 0),
    );
    final completed =
        taskBars.where((bar) => bar.status == 'completed').length;
    final conflicts =
        taskBars.where((bar) => bar.conflict).length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            project?.title ?? 'Project',
            style: AppTextStyles.h3Light,
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
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
                label: totalMinutes == 0
                    ? 'No estimate'
                    : '$totalMinutes min',
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

// ── Timeline task row ─────────────────────────────────────────────────────────

class _TimelineTaskRow extends StatelessWidget {
  final ProjectTimelineTaskBarModel bar;
  final bool isFirst;
  final bool isLast;
  final Future<void> Function(
    ProjectTimelineTaskBarModel bar,
    _TimelineDateField field,
    DateTime newValue,
  ) onDateChanged;

  const _TimelineTaskRow({
    super.key,
    required this.bar,
    required this.isFirst,
    required this.isLast,
    required this.onDateChanged,
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
                        : AppColors.brandPrimary
                            .withValues(alpha: 0.28),
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
                        : AppColors.brandPrimary
                            .withValues(alpha: 0.28),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.md),
              onTap: () =>
                  context.push('/home/tasks/${bar.taskId}'),
              child: Container(
                margin: const EdgeInsets.only(
                    bottom: AppSpacing.s12),
                padding:
                    const EdgeInsets.all(AppSpacing.cardPad),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius:
                      BorderRadius.circular(AppRadius.md),
                  boxShadow: AppShadows.soft,
                  border: Border.all(
                    color: _statusColor(bar.status)
                        .withValues(alpha: 0.20),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bar.title, style: AppTextStyles.h4Light),
                    const SizedBox(height: AppSpacing.s8),
                    Wrap(
                      spacing: AppSpacing.s8,
                      runSpacing: AppSpacing.s8,
                      children: [
                        _TimelineDateAdjustChip(
                          icon: Icons.play_arrow_outlined,
                          label:
                              'Start ${timelineDate == null ? 'unset' : _shortDate(timelineDate)}',
                          value: timelineDate,
                          fallback: dueAt,
                          onDateChanged: (value) => onDateChanged(
                            bar,
                            _TimelineDateField.start,
                            value,
                          ),
                        ),
                        _TimelineDateAdjustChip(
                          icon: Icons.flag_outlined,
                          label:
                              'Due ${dueAt == null ? 'unset' : _shortDate(dueAt)}',
                          value: dueAt,
                          fallback: timelineDate,
                          onDateChanged: (value) => onDateChanged(
                            bar,
                            _TimelineDateField.due,
                            value,
                          ),
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
                            label:
                                '${bar.dependencyIds.length} deps',
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

// ── Metric chip ───────────────────────────────────────────────────────────────

class _TimelineMetricChip extends StatelessWidget {
  final IconData icon;
  final String label;

  const _TimelineMetricChip(
      {required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.10),
        borderRadius: AppRadius.pillBr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.brandPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: AppTextStyles.caption(AppColors.brandPrimary),
          ),
        ],
      ),
    );
  }
}

// ── Date adjust chip (drag + tap) ─────────────────────────────────────────────

class _TimelineDateAdjustChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final DateTime? value;
  final DateTime? fallback;
  final ValueChanged<DateTime> onDateChanged;

  const _TimelineDateAdjustChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.fallback,
    required this.onDateChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message:
          'Tap to pick a date. Drag left or right to shift one day.',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => _pickDate(context),
        onHorizontalDragEnd: (details) {
          final velocity = details.primaryVelocity ?? 0;
          if (velocity.abs() < 150) return;
          final physicalDirection = velocity > 0 ? 1 : -1;
          final isRtl =
              Directionality.of(context) == TextDirection.rtl;
          final dayDelta =
              isRtl ? -physicalDirection : physicalDirection;
          onDateChanged(_baseDate.add(Duration(days: dayDelta)));
        },
        child: _TimelineMetricChip(icon: icon, label: label),
      ),
    );
  }

  DateTime get _baseDate => value ?? fallback ?? DateTime.now();

  Future<void> _pickDate(BuildContext context) async {
    final base = _baseDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(base.year, base.month, base.day),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    onDateChanged(_copyDatePreservingTime(base, picked));
  }
}

// ── Sort / helpers ────────────────────────────────────────────────────────────

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

enum _TimelineDateField { start, due }

String _fieldLabel(_TimelineDateField field) {
  return switch (field) {
    _TimelineDateField.start => 'Start',
    _TimelineDateField.due => 'Due',
  };
}

String _dateOrUnset(DateTime? date) {
  return date == null ? 'unset' : _shortDateWithYear(date);
}

DateTime _copyDatePreservingTime(
    DateTime source, DateTime pickedDate) {
  return DateTime(
    pickedDate.year,
    pickedDate.month,
    pickedDate.day,
    source.hour,
    source.minute,
    source.second,
    source.millisecond,
    source.microsecond,
  );
}

String _shortDate(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}';
}

String _shortDateWithYear(DateTime date) {
  return '${_shortDate(date)} ${date.year}';
}

Color _statusColor(String status) {
  return switch (status) {
    'completed' => AppColors.successColor,
    'in_progress' => AppColors.warningColor,
    'waiting' => AppColors.brandGold,
    'next' => AppColors.brandPrimary,
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
