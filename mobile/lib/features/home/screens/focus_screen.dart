import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../focus/models/focus_model.dart';
import '../../focus/providers/focus_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusProvider.notifier).loadAnalytics();
      if (ref.read(tasksProvider).tasks.isEmpty) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool _isBreakSession(String sessionType) {
    return sessionType == 'short_break' || sessionType == 'long_break';
  }

  String _sessionLabel(String sessionType) {
    switch (sessionType) {
      case 'short_break':
        return 'Short break';
      case 'long_break':
        return 'Long break';
      case 'deep_work':
        return 'Deep work';
      default:
        return 'Focus session';
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final tasksState = ref.watch(tasksProvider);
    final hasActive = state.activeSession != null;
    final distractionActive = hasActive && state.distractionFreeMode;
    final estimatedTasks = tasksState.tasks
        .where(
          (task) =>
              task.status != 'completed' &&
              !task.isDeleted &&
              (task.estimatedMinutes ?? 0) > 0,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Focus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (state.analytics != null && !distractionActive) ...[
              _AnalyticsGrid(analytics: state.analytics!),
              const SizedBox(height: 24),
            ],
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (hasActive) ...[
                    Icon(
                      _isBreakSession(state.activeSession!.sessionType)
                          ? Icons.self_improvement
                          : Icons.timer,
                      color: AppColors.primary,
                      size: 44,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _formatTime(state.remainingSeconds),
                      style: Theme.of(context).textTheme.displayLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontSize: 72,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _sessionLabel(state.activeSession!.sessionType),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: state.activeSession != null
                          ? state.remainingSeconds /
                                (state.activeSession!.plannedMinutes * 60)
                          : 0,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => ref
                                .read(focusProvider.notifier)
                                .cancelSession(),
                            icon: const Icon(
                              Icons.close,
                              color: AppColors.error,
                            ),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ref
                                .read(focusProvider.notifier)
                                .completeSession(),
                            icon: const Icon(Icons.check),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isBreakSession(state.activeSession!.sessionType)) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: TextButton.icon(
                          onPressed: () =>
                              ref.read(focusProvider.notifier).skipBreak(),
                          icon: const Icon(Icons.skip_next),
                          label: const Text('Skip break'),
                        ),
                      ),
                    ],
                  ] else ...[
                    const Icon(
                      Icons.track_changes,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start a Focus Session',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 24),
                    state.isLoading
                        ? const CircularProgressIndicator()
                        : Column(
                            children: [
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () => ref
                                      .read(focusProvider.notifier)
                                      .startFocusSession(),
                                  icon: const Icon(Icons.play_arrow),
                                  label: Text(
                                    'Start ${state.focusMinutes} min focus',
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => ref
                                          .read(focusProvider.notifier)
                                          .startBreakSession(longBreak: false),
                                      icon: const Icon(Icons.coffee),
                                      label: Text(
                                        '${state.shortBreakMinutes}m break',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => ref
                                          .read(focusProvider.notifier)
                                          .startBreakSession(longBreak: true),
                                      icon: const Icon(Icons.weekend),
                                      label: Text(
                                        '${state.longBreakMinutes}m long',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),
            if (!distractionActive) ...[
              const SizedBox(height: 24),
              _FocusSettings(state: state),
              const SizedBox(height: 24),
              _EstimatedPomodoros(
                tasks: estimatedTasks,
                focusMinutes: state.focusMinutes,
              ),
              const SizedBox(height: 24),
              _ReportSummary(state: state),
              const SizedBox(height: 24),
              const _FocusUpgradePlaceholders(),
              if (state.sessions.isNotEmpty) ...[
                const SizedBox(height: 32),
                Text(
                  'Recent Sessions',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                ...state.sessions.take(5).map((s) => _SessionTile(session: s)),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _AnalyticsGrid extends StatelessWidget {
  final FocusAnalytics analytics;

  const _AnalyticsGrid({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Today',
                value: '${analytics.todayMinutes}m',
                sub: '${analytics.todaySessions} sessions',
                color: AppColors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'This Week',
                value: '${analytics.weekMinutes}m',
                sub: '${analytics.weekSessions} sessions',
                color: AppColors.success,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _StatCard(
                label: 'Streak',
                value: '${analytics.currentStreakDays}d',
                sub: 'Best ${analytics.longestStreakDays}d',
                color: AppColors.warning,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatCard(
                label: 'Average',
                value: '${analytics.averageSessionMinutes}m',
                sub: '${analytics.completedSessions} completed',
                color: AppColors.prayerGold,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _FocusSettings extends ConsumerWidget {
  final FocusState state;

  const _FocusSettings({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(focusProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Settings',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _DurationSlider(
            label: 'Focus',
            value: state.focusMinutes,
            min: 5,
            max: 120,
            divisions: 23,
            onChanged: notifier.setFocusMinutes,
          ),
          _DurationSlider(
            label: 'Short break',
            value: state.shortBreakMinutes,
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: notifier.setShortBreakMinutes,
          ),
          _DurationSlider(
            label: 'Long break',
            value: state.longBreakMinutes,
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: notifier.setLongBreakMinutes,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.continuousMode,
            onChanged: notifier.setContinuousMode,
            title: const Text('Continuous mode'),
            subtitle: const Text('Auto-start the next focus or break phase.'),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: state.distractionFreeMode,
            onChanged: notifier.setDistractionFreeMode,
            title: const Text('Distraction-free mode'),
            subtitle: const Text('Hide secondary panels during active focus.'),
          ),
        ],
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final ValueChanged<int> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '${value}m',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          label: '${value}m',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}

class _EstimatedPomodoros extends ConsumerWidget {
  final List<TaskModel> tasks;
  final int focusMinutes;

  const _EstimatedPomodoros({required this.tasks, required this.focusMinutes});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Estimated Pomodoros',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (tasks.isEmpty)
            Text(
              'Add task estimates to see suggested focus counts.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            )
          else
            ...tasks.take(3).map((task) {
              final count =
                  ((task.estimatedMinutes ?? focusMinutes) / focusMinutes)
                      .ceil()
                      .clamp(1, 99);
              return ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(task.title),
                subtitle: Text('$count x ${focusMinutes}m'),
                trailing: IconButton(
                  tooltip: 'Start focus',
                  onPressed: () => ref
                      .read(focusProvider.notifier)
                      .startFocusSession(taskId: task.id),
                  icon: const Icon(Icons.play_arrow),
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ReportSummary extends StatelessWidget {
  final FocusState state;

  const _ReportSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;
    final completed = state.lastCompletedSession;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Focus Report',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            completed == null
                ? analytics?.reportSummary ??
                      'Complete a focus session to build your report.'
                : 'Last session: ${completed.actualMinutes ?? 0}m ${completed.sessionType.replaceAll('_', ' ')} completed.',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FocusUpgradePlaceholders extends StatelessWidget {
  const _FocusUpgradePlaceholders();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(
          child: _PlaceholderTile(
            icon: Icons.music_note,
            title: 'Ambient sound',
            subtitle: 'Prepared for a future sound pack.',
          ),
        ),
        SizedBox(width: 12),
        Expanded(
          child: _PlaceholderTile(
            icon: Icons.auto_awesome,
            title: 'AI focus pick',
            subtitle: 'Ready for task-aware suggestions.',
          ),
        ),
      ],
    );
  }
}

class _PlaceholderTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _PlaceholderTile({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

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
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 10),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(sub, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FocusSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: isCompleted ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${session.plannedMinutes} min ${session.sessionType}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isCompleted ? '${session.actualMinutes ?? 0}m done' : 'cancelled',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}
