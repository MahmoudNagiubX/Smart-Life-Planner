import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../providers/analytics_provider.dart';
import '../models/analytics_model.dart';

class AnalyticsScreen extends ConsumerStatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  ConsumerState<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

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
          '📊 Analytics',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
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
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
          ? Center(child: Text(state.error!))
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

// ── Today Tab ──────────────────────────────────────────────

class _TodayTab extends StatelessWidget {
  final AnalyticsState state;

  const _TodayTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final today = state.today;
    if (today == null || _hasNoTodayData(today)) {
      return const AppEmptyState(
        icon: Icons.insights_outlined,
        title: 'No analytics data yet',
        message:
            'Complete tasks, focus sessions, habits, or prayers to unlock analytics.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ProviderScope.containerOf(
        context,
      ).read(analyticsProvider.notifier).loadAll(),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Productivity Score
            _ProductivityScoreCard(score: today.productivityScore),
            const SizedBox(height: 20),

            // Stats grid
            Text(
              "Today's Stats",
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.4,
              children: [
                _StatGridCard(
                  emoji: '✅',
                  label: 'Tasks Done',
                  value: '${today.tasksCompleted}',
                  sub: '${today.tasksPending} pending',
                  color: AppColors.success,
                ),
                _StatGridCard(
                  emoji: '⏱️',
                  label: 'Focus Time',
                  value: '${today.focusMinutes}m',
                  sub: '${today.focusSessions} sessions',
                  color: AppColors.primary,
                ),
                _StatGridCard(
                  emoji: '💪',
                  label: 'Habits',
                  value: '${today.habitsCompleted}/${today.totalHabits}',
                  sub: today.totalHabits > 0
                      ? '${((today.habitsCompleted / today.totalHabits) * 100).round()}% done'
                      : 'No habits yet',
                  color: AppColors.warning,
                ),
                _StatGridCard(
                  emoji: '🕌',
                  label: 'Prayers',
                  value: '${today.prayersCompleted}/${today.totalPrayers}',
                  sub: today.prayersCompleted == 5
                      ? 'All done! 🎉'
                      : '${today.totalPrayers - today.prayersCompleted} remaining',
                  color: AppColors.prayerGold,
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Insights
            if (state.insights.isNotEmpty) ...[
              Text(
                '🤖 Insights',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...state.insights.map((i) => _InsightCard(insight: i)),
            ],
          ],
        ),
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

// ── Weekly Tab ──────────────────────────────────────────────

class _WeeklyTab extends StatelessWidget {
  final AnalyticsState state;

  const _WeeklyTab({required this.state});

  @override
  Widget build(BuildContext context) {
    final weekly = state.weekly;
    if (weekly == null || _hasNoWeeklyData(weekly)) {
      return const AppEmptyState(
        icon: Icons.insights_outlined,
        title: 'No analytics data yet',
        message:
            'Complete tasks, focus sessions, habits, or prayers to unlock analytics.',
      );
    }

    final maxFocus = weekly.dailyBreakdown
        .map((d) => d.focusMinutes)
        .fold(0, (a, b) => a > b ? a : b);

    final maxTasks = weekly.dailyBreakdown
        .map((d) => d.tasksCompleted)
        .fold(0, (a, b) => a > b ? a : b);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Weekly summary cards
          Row(
            children: [
              Expanded(
                child: _WeekSummaryCard(
                  emoji: '✅',
                  label: 'Tasks',
                  value: '${weekly.totalTasksCompleted}',
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeekSummaryCard(
                  emoji: '⏱️',
                  label: 'Focus',
                  value: '${weekly.totalFocusMinutes}m',
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeekSummaryCard(
                  emoji: '🔥',
                  label: 'Streak',
                  value: '${weekly.bestHabitStreak}d',
                  color: AppColors.warning,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _WeekSummaryCard(
                  emoji: '🕌',
                  label: 'Prayers',
                  value: '${weekly.totalPrayersCompleted}',
                  color: AppColors.prayerGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Avg score
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.8),
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Text('⭐', style: TextStyle(fontSize: 28)),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Avg Productivity Score',
                      style: TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                    Text(
                      '${weekly.avgProductivityScore} / 100',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Focus minutes chart
          Text(
            '⏱️ Focus Minutes — Last 7 Days',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (d) => d.focusMinutes.toDouble(),
            maxValue: maxFocus > 0 ? maxFocus.toDouble() : 1,
            color: AppColors.primary,
            unit: 'm',
          ),
          const SizedBox(height: 24),

          // Tasks chart
          Text(
            '✅ Tasks Completed — Last 7 Days',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (d) => d.tasksCompleted.toDouble(),
            maxValue: maxTasks > 0 ? maxTasks.toDouble() : 1,
            color: AppColors.success,
            unit: '',
          ),
          const SizedBox(height: 24),

          // Prayer consistency chart
          Text(
            '🕌 Prayer Consistency — Last 7 Days',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (d) => d.prayersCompleted.toDouble(),
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
        weekly.bestHabitStreak == 0 &&
        weekly.avgProductivityScore == 0 &&
        !hasBreakdownActivity;
  }
}

// ── Widgets ──────────────────────────────────────────────────

class _ProductivityScoreCard extends StatelessWidget {
  final int score;
  const _ProductivityScoreCard({required this.score});

  Color _scoreColor() {
    if (score >= 70) return AppColors.success;
    if (score >= 40) return AppColors.warning;
    return AppColors.error;
  }

  String _scoreLabel() {
    if (score >= 80) return 'Excellent! 🚀';
    if (score >= 60) return 'Great! 💪';
    if (score >= 40) return 'Good progress 👍';
    if (score >= 20) return 'Getting started 🌱';
    return 'Let\'s go! ⚡';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _scoreColor().withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _scoreColor().withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 72,
            height: 72,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value: score / 100,
                  strokeWidth: 7,
                  backgroundColor: _scoreColor().withValues(alpha: 0.15),
                  valueColor: AlwaysStoppedAnimation<Color>(_scoreColor()),
                ),
                Center(
                  child: Text(
                    '$score',
                    style: TextStyle(
                      color: _scoreColor(),
                      fontWeight: FontWeight.bold,
                      fontSize: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Productivity Score',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _scoreLabel(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: _scoreColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Based on tasks, focus, habits & prayers',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                    fontSize: 11,
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

class _StatGridCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatGridCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            sub,
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

class _InsightCard extends StatelessWidget {
  final AnalyticsInsight insight;
  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
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
          Text(insight.emoji, style: const TextStyle(fontSize: 24)),
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
}

class _WeekSummaryCard extends StatelessWidget {
  final String emoji;
  final String label;
  final String value;
  final Color color;

  const _WeekSummaryCard({
    required this.emoji,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 14,
            ),
          ),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
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
          final barHeight = 80.0 * ratio;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (value > 0)
                Text(
                  '${value.toInt()}$unit',
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              const SizedBox(height: 2),
              AnimatedContainer(
                duration: const Duration(milliseconds: 600),
                width: 28,
                height: barHeight > 0 ? barHeight : 3,
                decoration: BoxDecoration(
                  color: barHeight > 0 ? color : color.withValues(alpha: 0.15),
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
          );
        }).toList(),
      ),
    );
  }
}
