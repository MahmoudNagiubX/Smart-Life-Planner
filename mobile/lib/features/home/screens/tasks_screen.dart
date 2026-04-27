import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../focus/providers/focus_provider.dart';
import '../../habits/providers/habit_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../focus/models/focus_model.dart';
import '../../habits/models/habit_model.dart';
import '../../prayer/models/prayer_model.dart';
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
    _tabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(focusProvider.notifier).loadAnalytics();
      ref.read(habitsProvider.notifier).loadHabits();
      ref.read(prayerProvider.notifier).loadTodayPrayers();
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
            Tab(text: 'Matrix'),
            Tab(text: 'Calendar'),
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
                _EisenhowerMatrixView(
                  tasks: state.tasks
                      .where((t) => t.status == 'pending' && !t.isDeleted)
                      .toList(),
                ),
                const _TaskCalendarView(),
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

class _EisenhowerMatrixView extends StatelessWidget {
  final List<TaskModel> tasks;

  const _EisenhowerMatrixView({required this.tasks});

  bool _isUrgent(TaskModel task) {
    if (task.dueAt == null) return false;
    final dueAt = DateTime.tryParse(task.dueAt!)?.toLocal();
    if (dueAt == null) return false;
    final now = DateTime.now();
    return dueAt.isBefore(now) ||
        dueAt.difference(now) <= const Duration(hours: 48);
  }

  bool _isImportant(TaskModel task) => task.priority == 'high';

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_view_outlined,
        title: 'No pending tasks',
        message:
            'Create tasks with priorities and deadlines to fill the matrix.',
      );
    }

    final urgentImportant = <TaskModel>[];
    final importantNotUrgent = <TaskModel>[];
    final urgentNotImportant = <TaskModel>[];
    final notUrgentNotImportant = <TaskModel>[];

    for (final task in tasks) {
      final urgent = _isUrgent(task);
      final important = _isImportant(task);
      if (urgent && important) {
        urgentImportant.add(task);
      } else if (important) {
        importantNotUrgent.add(task);
      } else if (urgent) {
        urgentNotImportant.add(task);
      } else {
        notUrgentNotImportant.add(task);
      }
    }

    final quadrants = [
      _MatrixQuadrantData(
        title: 'Urgent + Important',
        subtitle: 'Do first',
        tasks: urgentImportant,
        color: AppColors.error,
        icon: Icons.priority_high,
      ),
      _MatrixQuadrantData(
        title: 'Important, Not Urgent',
        subtitle: 'Schedule',
        tasks: importantNotUrgent,
        color: AppColors.primary,
        icon: Icons.event_available_outlined,
      ),
      _MatrixQuadrantData(
        title: 'Urgent, Not Important',
        subtitle: 'Reduce or delegate',
        tasks: urgentNotImportant,
        color: AppColors.warning,
        icon: Icons.schedule_outlined,
      ),
      _MatrixQuadrantData(
        title: 'Not Urgent + Not Important',
        subtitle: 'Batch later',
        tasks: notUrgentNotImportant,
        color: AppColors.textSecondary,
        icon: Icons.low_priority,
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Priority Matrix',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                'Urgent means overdue or due within 48 hours. Important means high priority.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quadrants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.1 : 1.35,
                ),
                itemBuilder: (context, index) {
                  return _MatrixQuadrant(data: quadrants[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatrixQuadrantData {
  final String title;
  final String subtitle;
  final List<TaskModel> tasks;
  final Color color;
  final IconData icon;

  const _MatrixQuadrantData({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.color,
    required this.icon,
  });
}

class _MatrixQuadrant extends StatelessWidget {
  final _MatrixQuadrantData data;

  const _MatrixQuadrant({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: data.color.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${data.subtitle} - ${data.tasks.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Expanded(
            child: data.tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: data.tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _MatrixTaskTile(task: data.tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatrixTaskTile extends StatelessWidget {
  final TaskModel task;

  const _MatrixTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final dueAt = task.dueAt == null
        ? null
        : DateTime.tryParse(task.dueAt!)?.toLocal();
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => context.push('/home/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueAt == null
                        ? task.priority
                        : '${_dateLabel(dueAt)} - ${task.priority}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, size: 18),
          ],
        ),
      ),
    );
  }
}

enum _CalendarMode { today, week, month }

class _TaskCalendarView extends ConsumerStatefulWidget {
  const _TaskCalendarView();

  @override
  ConsumerState<_TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends ConsumerState<_TaskCalendarView> {
  _CalendarMode _mode = _CalendarMode.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  Future<void> _loadCalendar() async {
    final range = _rangeForMode(_mode);
    await ref
        .read(taskCalendarProvider.notifier)
        .loadRange(dateFrom: range.$1, dateTo: range.$2);
  }

  (DateTime, DateTime) _rangeForMode(_CalendarMode mode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (mode == _CalendarMode.today) {
      return (today, today);
    }
    if (mode == _CalendarMode.week) {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (start, start.add(const Duration(days: 6)));
    }
    return (
      DateTime(today.year, today.month),
      DateTime(today.year, today.month + 1, 0),
    );
  }

  Future<void> _setMode(_CalendarMode mode) async {
    setState(() => _mode = mode);
    await _loadCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(taskCalendarProvider);
    final focusState = ref.watch(focusProvider);
    final habitsState = ref.watch(habitsProvider);
    final prayerState = ref.watch(prayerProvider);
    final range = _rangeForMode(_mode);
    final days = _daysBetween(range.$1, range.$2);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCalendar();
        await ref.read(focusProvider.notifier).loadAnalytics();
        await ref.read(habitsProvider.notifier).loadHabits();
        await ref.read(prayerProvider.notifier).loadTodayPrayers();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SegmentedButton<_CalendarMode>(
            segments: const [
              ButtonSegment(value: _CalendarMode.today, label: Text('Today')),
              ButtonSegment(value: _CalendarMode.week, label: Text('Week')),
              ButtonSegment(value: _CalendarMode.month, label: Text('Month')),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) => _setMode(selection.first),
          ),
          const SizedBox(height: 14),
          Text(
            _rangeLabel(range.$1, range.$2),
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (calendarState.isLoading)
            const AppLoadingState(message: 'Loading agenda...')
          else if (calendarState.error != null)
            AppErrorState(
              title: 'Calendar could not load',
              message: calendarState.error!,
              onRetry: _loadCalendar,
            )
          else if (calendarState.tasks.isEmpty &&
              _focusForRange(focusState.sessions, range.$1, range.$2).isEmpty &&
              habitsState.habits.where((habit) => habit.isActive).isEmpty &&
              prayerState.data?.prayers.isEmpty != false)
            const AppEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No agenda items',
              message:
                  'Tasks, focus sessions, habits, and prayer anchors will appear here.',
            )
          else
            ...days.map(
              (day) => _AgendaDaySection(
                day: day,
                tasks: calendarState.tasks.where((task) {
                  final dueAt = task.dueAt == null
                      ? null
                      : DateTime.tryParse(task.dueAt!)?.toLocal();
                  return dueAt != null && _sameDay(dueAt, day);
                }).toList(),
                focusSessions: focusState.sessions.where((session) {
                  final startedAt = DateTime.tryParse(
                    session.startedAt,
                  )?.toLocal();
                  return startedAt != null && _sameDay(startedAt, day);
                }).toList(),
                habits: _sameDay(day, DateTime.now())
                    ? habitsState.habits
                          .where((habit) => habit.isActive)
                          .toList()
                    : const [],
                prayers: _sameDay(day, DateTime.now())
                    ? prayerState.data?.prayers ?? const []
                    : const [],
              ),
            ),
        ],
      ),
    );
  }

  List<DateTime> _daysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final finalDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(finalDay)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  List<FocusSession> _focusForRange(
    List<FocusSession> sessions,
    DateTime start,
    DateTime end,
  ) {
    return sessions.where((session) {
      final startedAt = DateTime.tryParse(session.startedAt)?.toLocal();
      if (startedAt == null) return false;
      final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  String _rangeLabel(DateTime start, DateTime end) {
    if (_sameDay(start, end)) return _dateLabel(start);
    return '${_dateLabel(start)} - ${_dateLabel(end)}';
  }
}

class _AgendaDaySection extends StatelessWidget {
  final DateTime day;
  final List<TaskModel> tasks;
  final List<FocusSession> focusSessions;
  final List<HabitModel> habits;
  final List<PrayerTime> prayers;

  const _AgendaDaySection({
    required this.day,
    required this.tasks,
    required this.focusSessions,
    required this.habits,
    required this.prayers,
  });

  @override
  Widget build(BuildContext context) {
    final hasItems =
        tasks.isNotEmpty ||
        focusSessions.isNotEmpty ||
        habits.isNotEmpty ||
        prayers.isNotEmpty;
    if (!hasItems) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel(day),
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          ...tasks.map(
            (task) => _AgendaItem(
              icon: Icons.task_alt,
              title: task.title,
              subtitle: task.dueAt == null
                  ? task.priority
                  : '${_timeLabel(task.dueAt!)} - ${task.priority}',
              color: AppColors.primary,
            ),
          ),
          ...focusSessions.map(
            (session) => _AgendaItem(
              icon: Icons.timer_outlined,
              title: 'Focus session',
              subtitle:
                  '${session.actualMinutes ?? session.plannedMinutes} min - ${session.status}',
              color: AppColors.warning,
            ),
          ),
          ...habits
              .take(6)
              .map(
                (habit) => _AgendaItem(
                  icon: Icons.repeat,
                  title: habit.title,
                  subtitle: '${habit.frequencyType} habit',
                  color: AppColors.success,
                ),
              ),
          if (habits.length > 6)
            _AgendaItem(
              icon: Icons.more_horiz,
              title: '${habits.length - 6} more habits',
              subtitle: 'Open Habits to review all',
              color: AppColors.success,
            ),
          ...prayers.map(
            (prayer) => _AgendaItem(
              icon: Icons.mosque_outlined,
              title: _prayerName(prayer.prayerName),
              subtitle: prayer.scheduledAt == null
                  ? 'Prayer anchor'
                  : _timeLabel(prayer.scheduledAt!),
              color: AppColors.prayerGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AgendaItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
}

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _dateLabel(DateTime date) {
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
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _timeLabel(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return 'Time set';
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _prayerName(String name) {
  return switch (name) {
    'fajr' => 'Fajr',
    'dhuhr' => 'Dhuhr',
    'asr' => 'Asr',
    'maghrib' => 'Maghrib',
    'isha' => 'Isha',
    _ => name,
  };
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
            tooltip: 'Task details',
            icon: const Icon(Icons.chevron_right, size: 22),
            onPressed: () => context.push('/home/tasks/${task.id}'),
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
