import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => CreateNoteSheet(linkedTaskId: widget.taskId),
    );
    if (!mounted) return;
    await ref.read(taskLinkedNotesProvider(widget.taskId).notifier).loadNotes();
  }

  @override
  Widget build(BuildContext context) {
    final linkedNotesState = ref.watch(taskLinkedNotesProvider(widget.taskId));

    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
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
            onRefresh: _refresh,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _TaskSummaryCard(task: task),
                const SizedBox(height: 18),
                _CompletionHistorySection(future: _completionHistoryFuture),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Text(
                      'Linked Notes',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    TextButton.icon(
                      onPressed: _createLinkedNote,
                      icon: const Icon(Icons.note_add_outlined),
                      label: const Text('Add'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
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
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Theme.of(context).cardTheme.color,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.16),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            note.title ?? 'Untitled note',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            note.content,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                          if (note.tags.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: note.tags
                                  .map(
                                    (tag) => Chip(
                                      avatar: const Icon(
                                        Icons.label_outline,
                                        size: 15,
                                      ),
                                      label: Text('#$tag'),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.history, size: 20, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'Completion History',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (snapshot.connectionState == ConnectionState.waiting)
                const AppLoadingState(message: 'Loading history...')
              else if (snapshot.hasError)
                Text(
                  'Completion history could not load.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                )
              else if (events.isEmpty)
                Text(
                  'Complete or reopen this task to build its history.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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

class _CompletionHistoryRow extends StatelessWidget {
  final TaskCompletionEventModel event;

  const _CompletionHistoryRow({required this.event});

  @override
  Widget build(BuildContext context) {
    final isCompleted = event.eventType == 'completed';
    final color = isCompleted ? AppColors.success : AppColors.warning;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
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
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isCompleted ? 'Completed' : 'Reopened',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                Text(
                  _eventSubtitle(event),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
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

class _TaskSummaryCard extends StatelessWidget {
  final TaskModel task;

  const _TaskSummaryCard({required this.task});

  @override
  Widget build(BuildContext context) {
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
            task.title,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (task.description != null && task.description!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              task.description!,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          _PomodoroProgressCard(task: task),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              Chip(
                avatar: const Icon(Icons.flag_outlined, size: 15),
                label: Text(task.priority),
              ),
              Chip(
                avatar: const Icon(Icons.task_alt, size: 15),
                label: Text(task.status),
              ),
              if (task.dueAt != null)
                Chip(
                  avatar: const Icon(Icons.event_outlined, size: 15),
                  label: Text(task.dueAt!.substring(0, 10)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

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
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timer_outlined, size: 18, color: AppColors.primary),
              const SizedBox(width: 8),
              Text(
                hasEstimate
                    ? '$completed / $estimate Pomodoros'
                    : '$completed Pomodoro${completed == 1 ? '' : 's'} completed',
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: hasEstimate ? progress : null,
            minHeight: 5,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 6),
          Text(
            hasEstimate
                ? 'Linked focus sessions update this progress.'
                : 'Set a Pomodoro estimate when creating a task.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

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
