import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
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
      ref.read(focusProvider.notifier).loadRecommendation();
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

  Future<bool> _confirmLeaveDistractionMode() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave focus session?'),
        content: const Text(
          'Distraction-free mode is active. Your timer will keep running if you leave.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _handleBlockedPop() async {
    if (await _confirmLeaveDistractionMode() && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _showTaskChooser(List<TaskModel> tasks) async {
    var sourceTasks = tasks;
    if (sourceTasks.isEmpty) {
      await ref.read(tasksProvider.notifier).loadTasks();
      if (!mounted) return;
      sourceTasks = ref.read(tasksProvider).tasks;
    }

    final candidates = sourceTasks
        .where((task) => task.status != 'completed' && !task.isDeleted)
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending tasks available.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<TaskModel>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            itemCount: candidates.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final task = candidates[index];
              final estimate = task.estimatedMinutes == null
                  ? 'Default focus block'
                  : '${task.estimatedMinutes}m estimate';
              return ListTile(
                leading: const Icon(Icons.task_alt),
                title: Text(task.title),
                subtitle: Text('${task.priority} priority - $estimate'),
                onTap: () => Navigator.of(context).pop(task),
              );
            },
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await ref
          .read(focusProvider.notifier)
          .startFocusSession(taskId: selected.id);
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
    final activeTask = _taskById(tasksState.tasks, state.activeSession?.taskId);

    return PopScope(
      canPop: !distractionActive,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && distractionActive) {
          _handleBlockedPop();
        }
      },
      child: Scaffold(
        appBar: distractionActive
            ? null
            : AppBar(
                title: const Text(
                  'Focus',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                actions: [
                  IconButton(
                    tooltip: 'Focus settings',
                    onPressed: () => context.push(AppRoutes.focusSettings),
                    icon: const Icon(Icons.settings_outlined),
                  ),
                ],
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
              AnimatedOpacity(
                opacity: distractionActive ? 0.96 : 1,
                duration: const Duration(milliseconds: 180),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(distractionActive ? 28 : 32),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(
                      distractionActive ? 0 : 20,
                    ),
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
                          style: Theme.of(context).textTheme.displayLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                                fontSize: distractionActive ? 84 : 72,
                              ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _sessionLabel(state.activeSession!.sessionType),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        if (distractionActive) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Distraction-free mode',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppColors.textSecondary),
                          ),
                        ],
                        if (activeTask != null) ...[
                          const SizedBox(height: 12),
                          _ActivePomodoroProgress(task: activeTask),
                        ],
                        const SizedBox(height: 8),
                        LinearProgressIndicator(
                          value: state.activeSession != null
                              ? state.remainingSeconds /
                                    (state.activeSession!.plannedMinutes * 60)
                              : 0,
                          backgroundColor: AppColors.primary.withValues(
                            alpha: 0.2,
                          ),
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
                                  side: const BorderSide(
                                    color: AppColors.error,
                                  ),
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
                        if (_isBreakSession(
                          state.activeSession!.sessionType,
                        )) ...[
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
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
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
                                              .startBreakSession(
                                                longBreak: false,
                                              ),
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
                                              .startBreakSession(
                                                longBreak: true,
                                              ),
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
              ),
              if (!distractionActive) ...[
                if (!hasActive) ...[
                  const SizedBox(height: 24),
                  _FocusRecommendationCard(
                    state: state,
                    onAccept: () => ref
                        .read(focusProvider.notifier)
                        .startRecommendedFocus(),
                    onChooseAnother: () => _showTaskChooser(tasksState.tasks),
                    onRefresh: () =>
                        ref.read(focusProvider.notifier).loadRecommendation(),
                  ),
                ],
                const SizedBox(height: 24),
                _FocusSettings(state: state),
                const SizedBox(height: 24),
                _EstimatedPomodoros(
                  tasks: estimatedTasks,
                  focusMinutes: state.focusMinutes,
                ),
                const SizedBox(height: 24),
                _ReportSummary(state: state),
                if (state.sessions.isNotEmpty) ...[
                  const SizedBox(height: 32),
                  Text(
                    'Recent Sessions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...state.sessions
                      .take(5)
                      .map((s) => _SessionTile(session: s)),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }
}

TaskModel? _taskById(List<TaskModel> tasks, String? taskId) {
  if (taskId == null) return null;
  for (final task in tasks) {
    if (task.id == taskId) return task;
  }
  return null;
}

class _ActivePomodoroProgress extends StatelessWidget {
  final TaskModel task;

  const _ActivePomodoroProgress({required this.task});

  @override
  Widget build(BuildContext context) {
    final estimate = task.estimatedPomodoros;
    final completed = task.completedPomodoros;
    final label = estimate > 0
        ? '$completed / $estimate Pomodoros'
        : '$completed Pomodoro${completed == 1 ? '' : 's'} completed';
    final value = estimate > 0 ? (completed / estimate).clamp(0.0, 1.0) : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            task.title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: estimate > 0 ? value : null,
            minHeight: 5,
            backgroundColor: AppColors.primary.withValues(alpha: 0.18),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _FocusRecommendationCard extends StatelessWidget {
  final FocusState state;
  final VoidCallback onAccept;
  final VoidCallback onChooseAnother;
  final VoidCallback onRefresh;

  const _FocusRecommendationCard({
    required this.state,
    required this.onAccept,
    required this.onChooseAnother,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = state.recommendation;

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
          Row(
            children: [
              const Icon(Icons.auto_awesome, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recommended Focus',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh recommendation',
                onPressed: state.isRecommendationLoading ? null : onRefresh,
                icon: const Icon(Icons.refresh),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (state.isRecommendationLoading) ...[
            const LinearProgressIndicator(minHeight: 4),
            const SizedBox(height: 10),
            Text(
              'Choosing the best focus task...',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ] else if (state.recommendationError != null) ...[
            Text(
              state.recommendationError!,
              style: const TextStyle(color: AppColors.error),
            ),
          ] else if (recommendation == null) ...[
            Text(
              'No recommendation loaded yet.',
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
          ] else ...[
            Text(
              recommendation.title ?? 'No pending task',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              recommendation.explanation,
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _RecommendationChip(
                  label: '${recommendation.recommendedDurationMinutes} min',
                  icon: Icons.timer_outlined,
                ),
                _RecommendationChip(
                  label: '${recommendation.confidence} confidence',
                  icon: Icons.insights_outlined,
                ),
                _RecommendationChip(
                  label: recommendation.fallbackUsed
                      ? 'Rules fallback'
                      : 'AI explained',
                  icon: recommendation.fallbackUsed
                      ? Icons.rule
                      : Icons.auto_awesome,
                ),
              ],
            ),
            if (recommendation.reasons.isNotEmpty) ...[
              const SizedBox(height: 10),
              Text(
                recommendation.reasons.take(3).join(' - '),
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (recommendation.hasTask)
                  FilledButton.icon(
                    onPressed: onAccept,
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Accept'),
                  ),
                OutlinedButton.icon(
                  onPressed: onChooseAnother,
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Choose task'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _RecommendationChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _RecommendationChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Chip(
      avatar: Icon(icon, size: 16),
      label: Text(label),
      visualDensity: VisualDensity.compact,
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
                label: 'Completion',
                value: '${analytics.completionRatePercent}%',
                sub: '${analytics.completedSessions} completed',
                color: AppColors.prayerGold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _StatCard(
          label: 'Average session',
          value: '${analytics.averageSessionMinutes}m',
          sub: 'Based on completed focus sessions',
          color: AppColors.primary,
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
          _DurationSlider(
            label: 'Long break after',
            value: state.sessionsBeforeLongBreak,
            min: 1,
            max: 12,
            divisions: 11,
            suffix: ' sessions',
            onChanged: notifier.setSessionsBeforeLongBreak,
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
          DropdownButtonFormField<String>(
            initialValue: state.ambientSoundKey,
            decoration: const InputDecoration(
              labelText: 'Ambient sound',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(value: 'silence', child: Text('Silence')),
              DropdownMenuItem(value: 'rain', child: Text('Rain')),
              DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
              DropdownMenuItem(
                value: 'white_noise',
                child: Text('White noise'),
              ),
            ],
            onChanged: (value) {
              if (value != null) notifier.setAmbientSoundKey(value);
            },
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
  final String suffix;
  final ValueChanged<int> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.suffix = 'm',
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
              '$value$suffix',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          label: '$value$suffix',
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
