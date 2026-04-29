import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/analytics_model.dart';
import '../providers/analytics_provider.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadAll();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh analytics',
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'This Week'),
          ],
        ),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading analytics...')
          : state.error != null
          ? AppErrorState(
              title: 'Analytics could not load',
              message: state.error!,
              onRetry: () => ref.read(analyticsProvider.notifier).loadAll(),
            )
          : TabBarView(
              controller: _tabController,
              children: [
                _TodayTab(state: state),
                _WeeklyTab(state: state),
              ],
            ),
    );
  }
}

class _TodayTab extends ConsumerWidget {
  final AnalyticsState state;

  const _TodayTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = state.today;
    if (today == null || _hasNoTodayData(today)) {
      return _AnalyticsEmptyState(
        onRetry: () => ref.read(analyticsProvider.notifier).loadAll(),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsProvider.notifier).loadAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          _ProductivityScoreCard(score: today.productivityScore),
          const SizedBox(height: 20),
          Text(
            "Today's activity",
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.task_alt,
                label: 'Tasks completed today',
                value: '${today.tasksCompleted}',
                subtitle: '${today.tasksPending} pending',
                color: AppColors.success,
              ),
              _MetricData(
                icon: Icons.check_circle_outline,
                label: 'Habits completed today',
                value: '${today.habitsCompleted}/${today.totalHabits}',
                subtitle: today.totalHabits > 0
                    ? '${((today.habitsCompleted / today.totalHabits) * 100).round()}% complete'
                    : 'No active habits',
                color: AppColors.warning,
              ),
              _MetricData(
                icon: Icons.mosque_outlined,
                label: 'Prayers logged today',
                value: '${today.prayersCompleted}/${today.totalPrayers}',
                subtitle: today.prayersCompleted == today.totalPrayers
                    ? 'Daily prayers logged'
                    : '${today.totalPrayers - today.prayersCompleted} remaining',
                color: AppColors.prayerGold,
              ),
              _MetricData(
                icon: Icons.timer_outlined,
                label: 'Focus minutes today',
                value: '${today.focusMinutes}m',
                subtitle: '${today.focusSessions} sessions',
                color: AppColors.primary,
              ),
            ],
          ),
          if (state.insights.isNotEmpty) ...[
            const SizedBox(height: 24),
            Text(
              'Insights',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            ...state.insights.map((insight) => _InsightCard(insight: insight)),
          ],
        ],
      ),
    );
  }

  bool _hasNoTodayData(TodayAnalytics today) {
    return today.tasksCompleted == 0 &&
        today.tasksPending == 0 &&
        today.focusMinutes == 0 &&
        today.focusSessions == 0 &&
        today.habitsCompleted == 0 &&
        today.totalHabits == 0 &&
        today.prayersCompleted == 0 &&
        today.productivityScore == 0;
  }
}

class _WeeklyTab extends ConsumerWidget {
  final AnalyticsState state;

  const _WeeklyTab({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final weekly = state.weekly;
    if (weekly == null || _hasNoWeeklyData(weekly)) {
      return _AnalyticsEmptyState(
        onRetry: () => ref.read(analyticsProvider.notifier).loadAll(),
      );
    }

    final maxFocus = weekly.dailyBreakdown
        .map((day) => day.focusMinutes)
        .fold(0, (a, b) => a > b ? a : b);
    final maxTasks = weekly.dailyBreakdown
        .map((day) => day.tasksCompleted)
        .fold(0, (a, b) => a > b ? a : b);

    return RefreshIndicator(
      onRefresh: () => ref.read(analyticsProvider.notifier).loadAll(),
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'This week',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.task_alt,
                label: 'Tasks completed',
                value: '${weekly.totalTasksCompleted}',
                subtitle: 'Last 7 days',
                color: AppColors.success,
              ),
              _MetricData(
                icon: Icons.timer_outlined,
                label: 'Focus minutes this week',
                value: '${weekly.totalFocusMinutes}m',
                subtitle: 'Completed sessions',
                color: AppColors.primary,
              ),
              _MetricData(
                icon: Icons.notes_outlined,
                label: 'Notes created this week',
                value: '${weekly.totalNotesCreated}',
                subtitle: 'Text, checklist, voice, or linked notes',
                color: AppColors.textSecondary,
              ),
              _MetricData(
                icon: Icons.mosque_outlined,
                label: 'Prayers logged',
                value: '${weekly.totalPrayersCompleted}',
                subtitle: 'Out of 35 weekly prayers',
                color: AppColors.prayerGold,
              ),
            ],
          ),
          const SizedBox(height: 16),
          _SummaryCard(
            icon: Icons.star_outline,
            title: 'Average productivity score',
            value: '${weekly.avgProductivityScore} / 100',
            subtitle: 'Calculated from tasks, focus, habits, and prayer logs.',
            color: AppColors.primary,
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Focus minutes by day'),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.focusMinutes.toDouble(),
            maxValue: maxFocus > 0 ? maxFocus.toDouble() : 1,
            color: AppColors.primary,
            unit: 'm',
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Tasks completed by day'),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.tasksCompleted.toDouble(),
            maxValue: maxTasks > 0 ? maxTasks.toDouble() : 1,
            color: AppColors.success,
            unit: '',
          ),
          const SizedBox(height: 24),
          _SectionTitle(title: 'Prayer logs by day'),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.prayersCompleted.toDouble(),
            maxValue: 5,
            color: AppColors.prayerGold,
            unit: '/5',
          ),
        ],
      ),
    );
  }

  bool _hasNoWeeklyData(WeeklyAnalytics weekly) {
    final hasBreakdownActivity = weekly.dailyBreakdown.any(
      (day) =>
          day.tasksCompleted > 0 ||
          day.focusMinutes > 0 ||
          day.habitsCompleted > 0 ||
          day.prayersCompleted > 0,
    );

    return weekly.totalTasksCompleted == 0 &&
        weekly.totalFocusMinutes == 0 &&
        weekly.totalHabitsLogged == 0 &&
        weekly.totalPrayersCompleted == 0 &&
        weekly.totalNotesCreated == 0 &&
        weekly.bestHabitStreak == 0 &&
        weekly.avgProductivityScore == 0 &&
        !hasBreakdownActivity;
  }
}

class _AnalyticsEmptyState extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _AnalyticsEmptyState({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.insights_outlined,
      title: 'No analytics data yet',
      message:
          'Complete tasks, habits, focus sessions, prayers, or notes to unlock analytics.',
      action: OutlinedButton.icon(
        onPressed: onRetry,
        icon: const Icon(Icons.refresh),
        label: const Text('Refresh'),
      ),
    );
  }
}

class _MetricData {
  final IconData icon;
  final String label;
  final String value;
  final String subtitle;
  final Color color;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 520;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: isWide ? 1.15 : 1.08,
          ),
          itemBuilder: (context, index) {
            return _MetricCard(metric: metrics[index]);
          },
        );
      },
    );
  }
}

class _MetricCard extends StatelessWidget {
  final _MetricData metric;

  const _MetricCard({required this.metric});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: metric.color.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(metric.icon, color: metric.color, size: 24),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              metric.value,
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: metric.color,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 2),
          Text(
            metric.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductivityScoreCard extends StatelessWidget {
  final int score;

  const _ProductivityScoreCard({required this.score});

  Color _scoreColor() {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel() {
    if (score >= 80) return 'Excellent';
    if (score >= 60) return 'Great progress';
    if (score >= 40) return 'Good start';
    if (score >= 20) return 'Getting started';
    return 'Ready when you are';
  }

  @override
  Widget build(BuildContext context) {
    final color = _scoreColor();
    return _SummaryCard(
      icon: Icons.insights_outlined,
      title: 'Productivity score',
      value: '$score / 100',
      subtitle: _scoreLabel(),
      color: color,
      trailing: SizedBox(
        width: 56,
        height: 56,
        child: CircularProgressIndicator(
          value: (score / 100).clamp(0.0, 1.0),
          strokeWidth: 7,
          backgroundColor: color.withValues(alpha: 0.15),
          valueColor: AlwaysStoppedAnimation<Color>(color),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String subtitle;
  final Color color;
  final Widget? trailing;

  const _SummaryCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 12), trailing!],
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(
        context,
      ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final AnalyticsInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _insightColor(insight.type);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_insightIcon(insight.type), color: color, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  insight.message,
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

  IconData _insightIcon(String type) {
    return switch (type) {
      'focus' => Icons.timer_outlined,
      'prayer' => Icons.mosque_outlined,
      'habit' => Icons.local_fire_department_outlined,
      'tasks' => Icons.task_alt,
      _ => Icons.lightbulb_outline,
    };
  }

  Color _insightColor(String type) {
    return switch (type) {
      'focus' => AppColors.primary,
      'prayer' => AppColors.prayerGold,
      'habit' => AppColors.warning,
      'tasks' => AppColors.success,
      _ => AppColors.textSecondary,
    };
  }
}

class _BarChart extends StatelessWidget {
  final List<DailyBreakdown> data;
  final double Function(DailyBreakdown) getValue;
  final double maxValue;
  final Color color;
  final String unit;

  const _BarChart({
    required this.data,
    required this.getValue,
    required this.maxValue,
    required this.color,
    required this.unit,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((day) {
          final value = getValue(day);
          final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
          final barHeight = 84.0 * ratio;

          return Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                SizedBox(
                  height: 18,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      value > 0 ? '${value.toInt()}$unit' : '',
                      style: TextStyle(
                        fontSize: 10,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: 26,
                  height: barHeight > 0 ? barHeight : 4,
                  decoration: BoxDecoration(
                    color: barHeight > 0
                        ? color
                        : color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  day.dayLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
