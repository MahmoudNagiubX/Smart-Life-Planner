import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../home/widgets/progress_ring.dart';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Analytics', style: AppTextStyles.h2Light),
            Text(
              'A calm read on your progress.',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: _IconSurfaceButton(
              tooltip: 'Refresh analytics',
              icon: Icons.refresh,
              onPressed: () => ref.read(analyticsProvider.notifier).loadAll(),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(58),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.s8,
              AppSpacing.screenH,
              AppSpacing.s12,
            ),
            child: Container(
              height: AppButtonHeight.small,
              padding: const EdgeInsets.all(AppSpacing.s4),
              decoration: BoxDecoration(
                color: AppColors.bgSurfaceLavender,
                borderRadius: AppRadius.pillBr,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  gradient: AppGradients.action,
                  borderRadius: AppRadius.pillBr,
                  boxShadow: AppShadows.glowPurple,
                ),
                dividerColor: AppColors.bgSurfaceLavender,
                indicatorSize: TabBarIndicatorSize.tab,
                labelStyle: AppTextStyles.label(AppColors.bgSurface),
                labelColor: AppColors.bgSurface,
                unselectedLabelStyle: AppTextStyles.label(AppColors.textBody),
                unselectedLabelColor: AppColors.textBody,
                tabs: const [
                  Tab(text: 'Today'),
                  Tab(text: 'This Week'),
                ],
              ),
            ),
          ),
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
      color: AppColors.brandPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.s16,
          AppSpacing.screenH,
          AppSpacing.s32,
        ),
        children: [
          _ProductivityScoreCard(score: today.productivityScore),
          const SizedBox(height: AppSpacing.sectionGap),
          const _SectionTitle(title: "Today's activity"),
          const SizedBox(height: AppSpacing.s12),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.task_alt,
                label: 'Tasks completed',
                value: '${today.tasksCompleted}',
                subtitle: '${today.tasksPending} pending',
                color: AppColors.successColor,
                softColor: AppColors.successSoft,
              ),
              _MetricData(
                icon: Icons.check_circle_outline,
                label: 'Habits completed',
                value: '${today.habitsCompleted}/${today.totalHabits}',
                subtitle: today.totalHabits > 0
                    ? '${((today.habitsCompleted / today.totalHabits) * 100).round()}% complete'
                    : 'No active habits',
                color: AppColors.warningColor,
                softColor: AppColors.warningSoft,
              ),
              _MetricData(
                icon: Icons.mosque_outlined,
                label: 'Prayers logged',
                value: '${today.prayersCompleted}/${today.totalPrayers}',
                subtitle: today.prayersCompleted == today.totalPrayers
                    ? 'Daily prayers logged'
                    : '${today.totalPrayers - today.prayersCompleted} remaining',
                color: AppColors.brandGold,
                softColor: AppColors.warningSoft,
              ),
              _MetricData(
                icon: Icons.timer_outlined,
                label: 'Focus minutes',
                value: '${today.focusMinutes}m',
                subtitle: '${today.focusSessions} sessions',
                color: AppColors.brandPrimary,
                softColor: AppColors.bgSurfaceLavender,
              ),
            ],
          ),
          if (state.insights.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.s24),
            const _SectionTitle(title: 'Insights'),
            const SizedBox(height: AppSpacing.s12),
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
      color: AppColors.brandPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.s16,
          AppSpacing.screenH,
          AppSpacing.s32,
        ),
        children: [
          const _SectionTitle(title: 'This week'),
          const SizedBox(height: AppSpacing.s12),
          _MetricGrid(
            metrics: [
              _MetricData(
                icon: Icons.task_alt,
                label: 'Tasks completed',
                value: '${weekly.totalTasksCompleted}',
                subtitle: 'Last 7 days',
                color: AppColors.successColor,
                softColor: AppColors.successSoft,
              ),
              _MetricData(
                icon: Icons.timer_outlined,
                label: 'Focus minutes',
                value: '${weekly.totalFocusMinutes}m',
                subtitle: 'Completed sessions',
                color: AppColors.brandPrimary,
                softColor: AppColors.bgSurfaceLavender,
              ),
              _MetricData(
                icon: Icons.notes_outlined,
                label: 'Notes created',
                value: '${weekly.totalNotesCreated}',
                subtitle: 'Text, checklist, voice, or linked notes',
                color: AppColors.infoColor,
                softColor: AppColors.infoSoft,
              ),
              _MetricData(
                icon: Icons.mosque_outlined,
                label: 'Prayers logged',
                value: '${weekly.totalPrayersCompleted}',
                subtitle: 'Out of 35 weekly prayers',
                color: AppColors.brandGold,
                softColor: AppColors.warningSoft,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          _SummaryCard(
            icon: Icons.star_outline,
            title: 'Average productivity score',
            value: '${weekly.avgProductivityScore} / 100',
            subtitle: 'Calculated from tasks, focus, habits, and prayer logs.',
            color: AppColors.brandPrimary,
          ),
          const SizedBox(height: AppSpacing.s24),
          const _SectionTitle(title: 'Focus minutes by day'),
          const SizedBox(height: AppSpacing.s12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.focusMinutes.toDouble(),
            maxValue: maxFocus > 0 ? maxFocus.toDouble() : 1,
            color: AppColors.brandPrimary,
            unit: 'm',
          ),
          const SizedBox(height: AppSpacing.s24),
          const _SectionTitle(title: 'Tasks completed by day'),
          const SizedBox(height: AppSpacing.s12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.tasksCompleted.toDouble(),
            maxValue: maxTasks > 0 ? maxTasks.toDouble() : 1,
            color: AppColors.successColor,
            unit: '',
          ),
          const SizedBox(height: AppSpacing.s24),
          const _SectionTitle(title: 'Prayer logs by day'),
          const SizedBox(height: AppSpacing.s12),
          _BarChart(
            data: weekly.dailyBreakdown,
            getValue: (day) => day.prayersCompleted.toDouble(),
            maxValue: 5,
            color: AppColors.brandGold,
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
      accentColor: AppColors.featAnalytics,
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
  final Color softColor;

  const _MetricData({
    required this.icon,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.color,
    required this.softColor,
  });
}

class _MetricGrid extends StatelessWidget {
  final List<_MetricData> metrics;

  const _MetricGrid({required this.metrics});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 620;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: metrics.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: isWide ? 4 : 2,
            crossAxisSpacing: AppSpacing.s12,
            mainAxisSpacing: AppSpacing.s12,
            childAspectRatio: isWide ? 1.12 : 0.98,
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
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: metric.softColor,
              borderRadius: AppRadius.circular(AppRadius.md),
            ),
            child: Icon(
              metric.icon,
              color: metric.color,
              size: AppIconSize.cardHeader,
            ),
          ),
          const Spacer(),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: AlignmentDirectional.centerStart,
            child: Text(
              metric.value,
              style: AppTextStyles.metricNumber(metric.color),
            ),
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            metric.label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.label(AppColors.textHeading),
          ),
          const SizedBox(height: AppSpacing.s2),
          Text(
            metric.subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.caption(AppColors.textHint),
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
    if (score >= 70) return AppColors.successColor;
    if (score >= 40) return AppColors.warningColor;
    return AppColors.errorColor;
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
      trailing: ProgressRing(
        value: score / 100,
        size: 70,
        strokeWidth: 8,
        trackColor: AppColors.borderSoft,
        gradientColors: [color, AppColors.brandPink],
        child: Text('$score', style: AppTextStyles.h4(color)),
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
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Row(
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: AppIconSize.cardHeader),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.caption(AppColors.textHint)),
                const SizedBox(height: AppSpacing.s2),
                Text(value, style: AppTextStyles.h3(color)),
                const SizedBox(height: AppSpacing.s2),
                Text(subtitle, style: AppTextStyles.bodySmallLight),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: AppSpacing.s12),
            trailing!,
          ],
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
    return Text(title, style: AppTextStyles.h4Light);
  }
}

class _InsightCard extends StatelessWidget {
  final AnalyticsInsight insight;

  const _InsightCard({required this.insight});

  @override
  Widget build(BuildContext context) {
    final color = _insightColor(insight.type);
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: AppRadius.circular(AppRadius.md),
            ),
            child: Icon(
              _insightIcon(insight.type),
              color: color,
              size: AppIconSize.cardHeader,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  insight.title,
                  style: AppTextStyles.label(AppColors.textHeading),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(insight.message, style: AppTextStyles.bodySmallLight),
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
      'focus' => AppColors.brandPink,
      'prayer' => AppColors.brandGold,
      'habit' => AppColors.warningColor,
      'tasks' => AppColors.successColor,
      _ => AppColors.infoColor,
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
      height: 184,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: data.map((day) {
          final value = getValue(day);
          final ratio = maxValue > 0 ? (value / maxValue).clamp(0.0, 1.0) : 0.0;
          final barHeight = 92.0 * ratio;

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
                      style: AppTextStyles.caption(color),
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.s4),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 450),
                  width: 24,
                  height: barHeight > 0 ? barHeight : AppSpacing.s6,
                  decoration: BoxDecoration(
                    gradient: barHeight > 0 ? AppGradients.action : null,
                    color: barHeight > 0 ? null : color.withValues(alpha: 0.12),
                    borderRadius: AppRadius.pillBr,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Text(day.dayLabel, style: AppTextStyles.captionLight),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _IconSurfaceButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _IconSurfaceButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: AppRadius.circular(AppRadius.md),
        onTap: onPressed,
        child: Container(
          width: AppButtonHeight.icon,
          height: AppButtonHeight.icon,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.circular(AppRadius.md),
            border: Border.all(color: AppColors.borderSoft),
            boxShadow: AppShadows.soft,
          ),
          child: Icon(icon, color: AppColors.brandPrimary),
        ),
      ),
    );
  }
}
