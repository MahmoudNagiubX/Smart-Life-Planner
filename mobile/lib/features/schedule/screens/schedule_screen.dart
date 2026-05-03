import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../routes/app_routes.dart';
import '../../focus/providers/focus_provider.dart';
import '../../habits/providers/habit_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../habits/models/habit_model.dart';
import '../../prayer/models/prayer_model.dart';
import '../../focus/models/focus_model.dart';
import '../models/schedule_model.dart';
import '../providers/schedule_provider.dart';

// ── Screen ─────────────────────────────────────────────────────────────────────

class ScheduleScreen extends ConsumerStatefulWidget {
  const ScheduleScreen({super.key});

  @override
  ConsumerState<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends ConsumerState<ScheduleScreen> {
  DateTime _selectedDate = _today();

  static DateTime _today() {
    final n = DateTime.now();
    return DateTime(n.year, n.month, n.day);
  }

  // Build 7-day strip centred on today
  List<DateTime> get _weekDays {
    final todayIdx = _today();
    final monday = todayIdx.subtract(Duration(days: todayIdx.weekday - 1));
    return List.generate(7, (i) => monday.add(Duration(days: i)));
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(habitsProvider.notifier).loadHabits();
      ref.read(prayerProvider.notifier).loadTodayPrayers();
      ref.read(focusProvider.notifier).loadAnalytics();
      _loadScheduleForSelectedDate();
    });
  }

  void _loadScheduleForSelectedDate() {
    ref
        .read(scheduleProvider.notifier)
        .loadSchedule(date: _isoDate(_selectedDate));
  }

  @override
  Widget build(BuildContext context) {
    final tasksState = ref.watch(tasksProvider);
    final habitsState = ref.watch(habitsProvider);
    final prayerState = ref.watch(prayerProvider);
    final focusState = ref.watch(focusProvider);
    final scheduleState = ref.watch(scheduleProvider);

    final items = _buildScheduleItems(
      blocks: scheduleState.schedule?.blocks ?? const [],
      tasks: tasksState.tasks,
      habits: habitsState.habits,
      prayers: prayerState.data?.prayers ?? [],
      sessions: focusState.sessions,
      date: _selectedDate,
    );

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.s20,
                AppSpacing.screenH, AppSpacing.s8,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: const Icon(
                        Icons.chevron_left,
                        size: 20,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Schedule',
                          style: GoogleFonts.manrope(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textHeading,
                            letterSpacing: -0.4,
                          ),
                        ),
                        Text(
                          _formatHeaderDate(_selectedDate),
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Replan button
                  AppPressable(
                    onTap: () => context.push(AppRoutes.dailyPlan),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.bgSurfaceLavender,
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: AppColors.brandPrimary.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.auto_awesome,
                            size: 14,
                            color: AppColors.brandPrimary,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Replan',
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.brandPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Date strip ───────────────────────────────────────────────
            SizedBox(
              height: 70,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                children: _weekDays.map((day) {
                  final isSelected = _sameDay(day, _selectedDate);
                  final isToday = _sameDay(day, _today());
                  return GestureDetector(
                    onTap: () {
                      setState(() => _selectedDate = day);
                      _loadScheduleForSelectedDate();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 44,
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        gradient: isSelected ? AppGradients.action : null,
                        color: isSelected ? null : Colors.transparent,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _dayLetter(day),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : AppColors.textHint,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${day.day}',
                            style: GoogleFonts.manrope(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: isSelected
                                  ? Colors.white
                                  : isToday
                                  ? AppColors.brandPrimary
                                  : AppColors.textHeading,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: AppSpacing.s12),

            if (scheduleState.schedule?.overloadDetected == true)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 0,
                  AppSpacing.screenH, AppSpacing.s12,
                ),
                child: _ScheduleOverloadBanner(
                  message: scheduleState.schedule?.overloadMessage ??
                      'Your day is overloaded. H-ASAE suggests moving lower-priority work.',
                ),
              ),

            // ── Timeline ─────────────────────────────────────────────────
            Expanded(
              child: scheduleState.isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: AppColors.brandPrimary,
                        strokeWidth: 2.5,
                      ),
                    )
                  : items.isEmpty
                  ? _EmptySchedule(date: _selectedDate)
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH, 0,
                        AppSpacing.screenH, 138,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) => AppFadeSlide(
                        delay: Duration(milliseconds: (index % 8) * 40),
                        child: _ScheduleItemTile(item: items[index]),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  List<_ScheduleItem> _buildScheduleItems({
    required List<ScheduleBlockModel> blocks,
    required List<TaskModel> tasks,
    required List<HabitModel> habits,
    required List<PrayerTime> prayers,
    required List<FocusSession> sessions,
    required DateTime date,
  }) {
    final items = <_ScheduleItem>[];
    final isToday = _sameDay(date, _today());
    final scheduledTaskIds = <String>{};
    final hasPlannedPrayers = blocks.any((b) => b.blockType == 'prayer');

    // H-ASAE persisted blocks are the authoritative smart plan on this screen.
    for (final block in blocks) {
      final start = DateTime.tryParse(block.startTime)?.toLocal();
      if (start == null || !_sameDay(start, date)) continue;
      if (block.taskId != null) scheduledTaskIds.add(block.taskId!);
      items.add(_ScheduleItem(
        time: start,
        title: block.title,
        subtitle: _blockSubtitle(block),
        type: _typeFromBlock(block.blockType),
        isCompleted: block.isCompleted,
        hasAiBadge: block.explanation?.startsWith('[H-ASAE]') == true,
      ));
    }

    // Tasks with due date on this day
    for (final task in tasks) {
      if (task.status == 'completed' || task.isDeleted) continue;
      if (scheduledTaskIds.contains(task.id)) continue;
      if (task.dueAt == null) continue;
      final due = DateTime.tryParse(task.dueAt!)?.toLocal();
      if (due == null || !_sameDay(due, date)) continue;

      items.add(_ScheduleItem(
        time: due,
        title: task.title,
        subtitle: _taskSubtitle(task),
        type: _ScheduleItemType.task,
        onTap: () {},
      ));
    }

    // Prayers (only shown for today)
    if (isToday && !hasPlannedPrayers) {
      for (final prayer in prayers) {
        if (prayer.scheduledAt == null) continue;
        final t = DateTime.tryParse(prayer.scheduledAt!)?.toLocal();
        if (t == null) continue;
        items.add(_ScheduleItem(
          time: t,
          title: _prayerLabel(prayer.prayerName),
          subtitle: 'Spiritual · 15 min',
          type: _ScheduleItemType.prayer,
          isCompleted: prayer.completedAt != null,
        ));
      }

      // Active habits — no fixed time, place at 08:00
      final activeHabits = habits.where((h) => h.isActive).take(4).toList();
      if (activeHabits.isNotEmpty) {
        final habitTime = DateTime(date.year, date.month, date.day, 8, 0);
        for (final habit in activeHabits) {
          items.add(_ScheduleItem(
            time: habitTime,
            title: habit.title,
            subtitle: 'Habit · ${habit.frequencyType}',
            type: _ScheduleItemType.habit,
          ));
        }
      }

      // Focus sessions (completed)
      for (final session in sessions.take(3)) {
        final t = DateTime.tryParse(session.startedAt)?.toLocal();
        if (t == null || !_sameDay(t, date)) continue;
        final minutes = session.actualMinutes ?? session.plannedMinutes;
        items.add(_ScheduleItem(
          time: t,
          title: 'Focus session',
          subtitle: 'Focus · $minutes min',
          type: _ScheduleItemType.focus,
          isCompleted: session.status == 'completed',
          hasAiBadge: true,
        ));
      }
    }

    // Sort by time
    items.sort((a, b) => a.time.compareTo(b.time));
    return items;
  }

  String _taskSubtitle(TaskModel task) {
    final parts = <String>[];
    if (task.category != null && !task.category!.startsWith('icon:')) {
      parts.add(task.category!);
    } else {
      parts.add('Task');
    }
    if (task.estimatedMinutes != null) {
      parts.add('${task.estimatedMinutes} min');
    }
    return parts.join(' · ');
  }
}

// ── Schedule item model ────────────────────────────────────────────────────────

enum _ScheduleItemType { task, habit, focus, prayer, meeting, break_ }

class _ScheduleItem {
  final DateTime time;
  final String title;
  final String subtitle;
  final _ScheduleItemType type;
  final bool isCompleted;
  final bool hasAiBadge;
  final VoidCallback? onTap;

  const _ScheduleItem({
    required this.time,
    required this.title,
    required this.subtitle,
    required this.type,
    this.isCompleted = false,
    this.hasAiBadge = false,
    this.onTap,
  });
}

// ── Schedule item tile ─────────────────────────────────────────────────────────

class _ScheduleItemTile extends StatelessWidget {
  final _ScheduleItem item;

  const _ScheduleItemTile({required this.item});

  Color get _dotColor {
    return switch (item.type) {
      _ScheduleItemType.habit   => AppColors.successColor,
      _ScheduleItemType.focus   => AppColors.brandPrimary,
      _ScheduleItemType.prayer  => AppColors.brandViolet,
      _ScheduleItemType.meeting => AppColors.brandPink,
      _ScheduleItemType.break_  => AppColors.warningColor,
      _ScheduleItemType.task    => AppColors.infoColor,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time column
            SizedBox(
              width: 46,
              child: Text(
                _timeStr(item.time),
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textHint,
                ),
              ),
            ),

            // Dot + line column
            Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                Expanded(
                  child: Container(
                    width: 1.5,
                    color: AppColors.borderSoft,
                  ),
                ),
              ],
            ),

            const SizedBox(width: AppSpacing.s12),

            // Card
            Expanded(
              child: GestureDetector(
                onTap: item.onTap,
                child: Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s16,
                    vertical: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSoft),
                    boxShadow: AppShadows.soft,
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    item.title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.manrope(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: item.isCompleted
                                          ? AppColors.textBody
                                          : AppColors.textHeading,
                                      decoration: item.isCompleted
                                          ? TextDecoration.lineThrough
                                          : null,
                                    ),
                                  ),
                                ),
                                if (item.hasAiBadge)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 7,
                                      vertical: 3,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppColors.bgSurfaceLavender,
                                      borderRadius: BorderRadius.circular(
                                        AppRadius.pill,
                                      ),
                                    ),
                                    child: Text(
                                      'AI',
                                      style: GoogleFonts.manrope(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w800,
                                        color: AppColors.brandPrimary,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              item.subtitle,
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                color: AppColors.textBody,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Empty state ────────────────────────────────────────────────────────────────

class _ScheduleOverloadBanner extends StatelessWidget {
  final String message;

  const _ScheduleOverloadBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(
          color: AppColors.errorColor.withValues(alpha: 0.22),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 18,
            color: AppColors.errorColor,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.manrope(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.errorColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptySchedule extends StatelessWidget {
  final DateTime date;

  const _EmptySchedule({required this.date});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceLavender,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.calendar_today_outlined,
                size: 36,
                color: AppColors.brandPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              'No schedule for ${_formatHeaderDate(date)}',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              'Generate a H-ASAE plan or add timed tasks to build this day.',
              textAlign: TextAlign.center,
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Helpers ────────────────────────────────────────────────────────────────────

String _isoDate(DateTime date) {
  final y = date.year.toString().padLeft(4, '0');
  final m = date.month.toString().padLeft(2, '0');
  final d = date.day.toString().padLeft(2, '0');
  return '$y-$m-$d';
}

_ScheduleItemType _typeFromBlock(String blockType) {
  return switch (blockType) {
    'prayer' => _ScheduleItemType.prayer,
    'focus' => _ScheduleItemType.focus,
    'habit' => _ScheduleItemType.habit,
    'break' || 'blocked' => _ScheduleItemType.break_,
    _ => _ScheduleItemType.task,
  };
}

String _blockSubtitle(ScheduleBlockModel block) {
  final parts = <String>[
    switch (block.blockType) {
      'prayer' => 'Prayer-aware block',
      'focus' => 'Focus block',
      'habit' => 'Habit',
      'break' => 'Break',
      'blocked' => 'Protected time',
      _ => 'Task block',
    },
  ];
  final minutes = block.durationMinutes;
  if (minutes > 0) parts.add('$minutes min');
  if (block.explanation?.startsWith('[H-ASAE]') == true) {
    parts.add('H-ASAE');
  }
  return parts.join(' - ');
}

bool _sameDay(DateTime a, DateTime b) =>
    a.year == b.year && a.month == b.month && a.day == b.day;

String _dayLetter(DateTime d) {
  const letters = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  return letters[d.weekday - 1];
}

String _timeStr(DateTime d) {
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

String _formatHeaderDate(DateTime d) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

String _prayerLabel(String name) {
  return switch (name) {
    'fajr'    => 'Fajr Prayer',
    'dhuhr'   => 'Dhuhr Prayer',
    'asr'     => 'Asr Prayer',
    'maghrib' => 'Maghrib Prayer',
    'isha'    => 'Isha Prayer',
    _         => '${name[0].toUpperCase()}${name.substring(1)} Prayer',
  };
}
