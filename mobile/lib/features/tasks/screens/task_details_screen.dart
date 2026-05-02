import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../notes/providers/note_provider.dart';
import '../../notes/screens/create_note_sheet.dart';
import '../models/task_model.dart';
import '../providers/task_provider.dart';

class TaskDetailsScreen extends ConsumerStatefulWidget {
  final String taskId;

  const TaskDetailsScreen({super.key, required this.taskId});

  @override
  ConsumerState<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends ConsumerState<TaskDetailsScreen> {
  late Future<TaskModel> _taskFuture;
  late Future<List<TaskCompletionEventModel>> _completionHistoryFuture;

  @override
  void initState() {
    super.initState();
    _loadTaskData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(taskLinkedNotesProvider(widget.taskId).notifier).loadNotes();
    });
  }

  void _loadTaskData() {
    final taskService = ref.read(taskServiceProvider);
    _taskFuture = taskService.getTask(widget.taskId);
    _completionHistoryFuture = taskService.getCompletionHistory(widget.taskId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadTaskData();
    });
    await ref.read(taskLinkedNotesProvider(widget.taskId).notifier).loadNotes();
  }

  Future<void> _createLinkedNote() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgApp,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBr),
      builder: (_) => CreateNoteSheet(linkedTaskId: widget.taskId),
    );
    if (!mounted) return;
    await ref.read(taskLinkedNotesProvider(widget.taskId).notifier).loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final linkedNotesState = ref.watch(taskLinkedNotesProvider(widget.taskId));

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Task Details', style: AppTextStyles.h2Light),
      ),
      body: FutureBuilder<TaskModel>(
        future: _taskFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AppLoadingState(message: 'Loading task...');
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return AppErrorState(
              title: 'Task could not load',
              message: 'Open the task again or refresh this screen.',
              onRetry: _refresh,
            );
          }

          final task = snapshot.data!;
          return RefreshIndicator(
            color: AppColors.brandPrimary,
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                AppSpacing.s8,
                AppSpacing.screenH,
                138,
              ),
              children: [
                _TaskSummaryCard(task: task),
                const SizedBox(height: AppSpacing.s16),
                _CompletionHistorySection(future: _completionHistoryFuture),
                const SizedBox(height: AppSpacing.s20),
                Row(
                  children: [
                    Text(
                      'LINKED NOTES',
                      style: AppTextStyles.label(AppColors.textHint),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _createLinkedNote,
                      icon: const Icon(
                        Icons.note_add_outlined,
                        color: AppColors.brandPrimary,
                        size: 18,
                      ),
                      label: const Text(
                        'Add',
                        style: TextStyle(color: AppColors.brandPrimary),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s8),
                if (linkedNotesState.isLoading)
                  const AppLoadingState(message: 'Loading linked notes...')
                else if (linkedNotesState.error != null)
                  AppErrorState(
                    title: 'Linked notes could not load',
                    message: linkedNotesState.error!,
                    onRetry: () => ref
                        .read(taskLinkedNotesProvider(widget.taskId).notifier)
                        .loadNotes(),
                  )
                else if (linkedNotesState.notes.isEmpty)
                  const AppEmptyState(
                    icon: Icons.sticky_note_2_outlined,
                    title: 'No linked notes',
                    message: 'Add a note from this task to keep context close.',
                  )
                else
                  ...linkedNotesState.notes.map(
                    (note) => Container(
                      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
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
                            note.title ?? 'Untitled note',
                            style: AppTextStyles.h4Light,
                          ),
                          const SizedBox(height: AppSpacing.s8),
                          Text(
                            note.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(AppColors.textSecondary),
                          ),
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: AppSpacing.s8),
                            Wrap(
                              spacing: AppSpacing.s8,
                              runSpacing: AppSpacing.s8,
                              children: note.tags
                                  .map(
                                    (tag) => Chip(
                                      avatar: const Icon(
                                        Icons.label_outline,
                                        size: 15,
                                        color: AppColors.brandPrimary,
                                      ),
                                      label: Text(
                                        '#$tag',
                                        style: AppTextStyles.caption(
                                          AppColors.textSecondary,
                                        ),
                                      ),
                                      backgroundColor:
                                          AppColors.bgSurfaceLavender,
                                      side: BorderSide.none,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: AppRadius.pillBr,
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Completion history section ────────────────────────────────────────────────

class _CompletionHistorySection extends StatelessWidget {
  final Future<List<TaskCompletionEventModel>> future;

  const _CompletionHistorySection({required this.future});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<TaskCompletionEventModel>>(
      future: future,
      builder: (context, snapshot) {
        final events = snapshot.data ?? const <TaskCompletionEventModel>[];
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
              Row(
                children: [
                  const Icon(
                    Icons.history,
                    size: 20,
                    color: AppColors.brandPrimary,
                  ),
                  const SizedBox(width: AppSpacing.s8),
                  Text('Completion History', style: AppTextStyles.h4Light),
                ],
              ),
              const SizedBox(height: AppSpacing.s12),
              const Divider(color: AppColors.dividerColor, height: 1),
              const SizedBox(height: AppSpacing.s12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const AppLoadingState(message: 'Loading history...')
              else if (snapshot.hasError)
                Text(
                  'Completion history could not load.',
                  style: AppTextStyles.caption(AppColors.textSecondary),
                )
              else if (events.isEmpty)
                Text(
                  'Complete or reopen this task to build its history.',
                  style: AppTextStyles.caption(AppColors.textSecondary),
                )
              else
                ...events.map((event) => _CompletionHistoryRow(event: event)),
            ],
          ),
        );
      },
    );
  }
}

// ── Completion history row ────────────────────────────────────────────────────

class _CompletionHistoryRow extends StatelessWidget {
  final TaskCompletionEventModel event;

  const _CompletionHistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isCompleted = event.eventType == 'completed';
    final color = isCompleted ? AppColors.successColor : AppColors.warningColor;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_circle_outline : Icons.restart_alt,
              size: 17,
              color: color,
            ),
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Completed' : 'Reopened',
                  style: AppTextStyles.h4Light,
                ),
                Text(
                  _eventSubtitle(event),
                  style: AppTextStyles.caption(AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _eventSubtitle(TaskCompletionEventModel event) {
    final previous = event.previousStatus == null
        ? ''
        : '${_statusLabel(event.previousStatus!)} to ';
    return '$previous${_statusLabel(event.nextStatus)} - ${_dateTimeLabel(event.occurredAt)}';
  }
}

// ── Task summary card ─────────────────────────────────────────────────────────

class _TaskSummaryCard extends StatelessWidget {
  final TaskModel task;

  const _TaskSummaryCard({required this.task});

  @override
  Widget build(BuildContext context) {
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
          Text(task.title, style: AppTextStyles.h3Light),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s8),
            Text(
              task.description!,
              style: AppTextStyles.body(AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: AppSpacing.s12),
          _PomodoroProgressCard(task: task),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: [
              Chip(
                avatar: const Icon(
                  Icons.flag_outlined,
                  size: 15,
                  color: AppColors.brandPrimary,
                ),
                label: Text(
                  task.priority,
                  style: AppTextStyles.caption(AppColors.brandPrimary),
                ),
                backgroundColor: AppColors.bgSurfaceLavender,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
              ),
              Chip(
                avatar: const Icon(
                  Icons.task_alt,
                  size: 15,
                  color: AppColors.brandPrimary,
                ),
                label: Text(
                  task.status,
                  style: AppTextStyles.caption(AppColors.brandPrimary),
                ),
                backgroundColor: AppColors.bgSurfaceLavender,
                side: BorderSide.none,
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
              ),
              if (task.dueAt != null)
                Chip(
                  avatar: const Icon(
                    Icons.event_outlined,
                    size: 15,
                    color: AppColors.brandPrimary,
                  ),
                  label: Text(
                    task.dueAt!.substring(0, 10),
                    style: AppTextStyles.caption(AppColors.brandPrimary),
                  ),
                  backgroundColor: AppColors.bgSurfaceLavender,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Pomodoro progress card ────────────────────────────────────────────────────

class _PomodoroProgressCard extends StatelessWidget {
  final TaskModel task;

  const _PomodoroProgressCard({required this.task});

  @override
  Widget build(BuildContext context) {
    final estimate = task.estimatedPomodoros;
    final completed = task.completedPomodoros;
    final hasEstimate = estimate > 0;
    final progress = hasEstimate ? (completed / estimate).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.brandPrimary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.timer_outlined,
                size: 18,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                hasEstimate
                    ? '$completed / $estimate Pomodoros'
                    : '$completed Pomodoro${completed == 1 ? '' : 's'} completed',
                style: AppTextStyles.h4Light,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          LinearProgressIndicator(
            value: hasEstimate ? progress : null,
            minHeight: 5,
            color: AppColors.brandPrimary,
            backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.18),
            borderRadius: AppRadius.pillBr,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            hasEstimate
                ? 'Linked focus sessions update this progress.'
                : 'Set a Pomodoro estimate when creating a task.',
            style: AppTextStyles.caption(AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

String _statusLabel(String status) {
  return switch (status) {
    'in_progress' => 'In progress',
    'completed' => 'Done',
    'waiting' => 'Waiting',
    'next' => 'Next',
    _ => 'Pending',
  };
}

String _dateTimeLabel(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return 'Time recorded';
  final date =
      '${parsed.year}-${parsed.month.toString().padLeft(2, '0')}-${parsed.day.toString().padLeft(2, '0')}';
  final time =
      '${parsed.hour.toString().padLeft(2, '0')}:${parsed.minute.toString().padLeft(2, '0')}';
  return '$date $time';
}
