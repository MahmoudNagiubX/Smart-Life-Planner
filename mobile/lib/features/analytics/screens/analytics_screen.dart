import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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

class _AnalyticsScreenState extends ConsumerState<AnalyticsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(analyticsProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(analyticsProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: state.isLoading
            ? const AppLoadingState(message: 'Loading analytics...')
            : state.error != null && state.weekly == null
            ? AppErrorState(
                title: 'Analytics could not load',
                message: state.error!,
                onRetry: () =>
                    ref.read(analyticsProvider.notifier).loadAll(),
              )
            : RefreshIndicator(
                onRefresh: () =>
                    ref.read(analyticsProvider.notifier).loadAll(),
                color: AppColors.brandPrimary,
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.s20,
                    AppSpacing.screenH,
                    138,
                  ),
                  children: [
                    // ── Header ───────────────────────────────────────────
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Analytics',
                                style: GoogleFonts.manrope(
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.textHeading,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              Text(
                                'This week',
                                style: GoogleFonts.manrope(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.textBody,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Week selector pill
                        GestureDetector(
                          onTap: () =>
                              ref.read(analyticsProvider.notifier).loadAll(),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.bgSurface,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.pill),
                              border:
                                  Border.all(color: AppColors.borderSoft),
                              boxShadow: AppShadows.soft,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  'Week',
                                  style: GoogleFonts.manrope(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textHeading,
                                  ),
                                ),
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.keyboard_arrow_down,
                                  size: 16,
                                  color: AppColors.textBody,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.s20),

                    if (state.weekly == null)
                      AppEmptyState(
                        icon: Icons.insights_outlined,
                        title: 'No analytics data yet',
                        message:
                            'Complete tasks, focus sessions, prayers, or habits to unlock analytics.',
                        accentColor: AppColors.featAnalytics,
                      )
                    else ...[
                      // ── 4 stat cards (2×2) ───────────────────────────
                      _StatCardGrid(weekly: state.weekly!, today: state.today),
                      const SizedBox(height: AppSpacing.s20),

                      // ── Focus & tasks chart ──────────────────────────
                      _FocusTasksChart(
                        data: state.weekly!.dailyBreakdown,
                      ),
                      const SizedBox(height: AppSpacing.s20),

                      // ── Prayer bar chart ─────────────────────────────
                      _PrayerChart(data: state.weekly!.dailyBreakdown),
                      const SizedBox(height: AppSpacing.s20),

                      // ── AI insight card ──────────────────────────────
                      if (state.insights.isNotEmpty)
                        _AiInsightCard(insights: state.insights)
                      else
                        _AiInsightFallback(weekly: state.weekly!),
                    ],
                  ],
                ),
              ),
      ),
    );
  }
}

// ── 4 stat cards ──────────────────────────────────────────────────────────────

class _StatCardGrid extends StatelessWidget {
  final WeeklyAnalytics weekly;
  final TodayAnalytics? today;

  const _StatCardGrid({required this.weekly, this.today});

  @override
  Widget build(BuildContext context) {
    final focusH = weekly.totalFocusMinutes / 60;
    final focusLabel = focusH >= 1
        ? '${focusH.toStringAsFixed(1)}h'
        : '${weekly.totalFocusMinutes}m';

    final prayerTotal = today?.totalPrayers ?? 5;
    final prayerCompleted = weekly.totalPrayersCompleted;
    final prayerOnTime = prayerTotal * 7 > 0
        ? (prayerCompleted / (prayerTotal * 7) * 100).round()
        : 0;

    final habitPct = weekly.totalHabitsLogged > 0
        ? ((weekly.totalHabitsLogged / (weekly.totalHabitsLogged + 5))
              * 100)
              .round()
        : 0;

    final cards = [
      _StatData(
        label: 'Tasks done',
        value: '${weekly.totalTasksCompleted}',
        sub: weekly.avgProductivityScore > 0
            ? '+${(weekly.avgProductivityScore * 0.1).round()} vs last'
            : 'This week',
        color: AppColors.brandPrimary,
        barProgress: (weekly.totalTasksCompleted / 50).clamp(0.0, 1.0),
        barColor: AppColors.brandPrimary,
      ),
      _StatData(
        label: 'Focus minutes',
        value: focusLabel,
        sub: '${_streakCount(weekly.dailyBreakdown)} streaks',
        color: AppColors.brandPink,
        barProgress: (weekly.totalFocusMinutes / 420).clamp(0.0, 1.0),
        barColor: AppColors.brandPink,
      ),
      _StatData(
        label: 'Habits',
        value: '$habitPct%',
        sub: '${weekly.totalHabitsLogged} / 7 days',
        color: AppColors.successColor,
        barProgress: habitPct / 100,
        barColor: AppColors.successColor,
      ),
      _StatData(
        label: 'Prayer',
        value: '$prayerCompleted / ${prayerTotal * 7}',
        sub: '$prayerOnTime% on time',
        color: AppColors.brandViolet,
        barProgress: prayerTotal * 7 > 0
            ? (prayerCompleted / (prayerTotal * 7)).clamp(0.0, 1.0)
            : 0,
        barColor: AppColors.brandViolet,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: AppSpacing.s12,
        crossAxisSpacing: AppSpacing.s12,
        childAspectRatio: 1.4,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _StatCard(data: cards[i]),
    );
  }

  int _streakCount(List<DailyBreakdown> breakdown) {
    var streak = 0;
    for (final d in breakdown.reversed) {
      if (d.focusMinutes > 0) {
        streak++;
      } else {
        break;
      }
    }
    return streak;
  }
}

class _StatData {
  final String label;
  final String value;
  final String sub;
  final Color color;
  final double barProgress;
  final Color barColor;

  const _StatData({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.barProgress,
    required this.barColor,
  });
}

class _StatCard extends StatelessWidget {
  final _StatData data;

  const _StatCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            data.label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
          const Spacer(),
          Text(
            data.value,
            style: GoogleFonts.manrope(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: data.color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            data.sub,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: data.barProgress,
              backgroundColor: AppColors.borderSoft,
              valueColor: AlwaysStoppedAnimation<Color>(data.barColor),
              minHeight: 3,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus & Tasks dual bar chart ───────────────────────────────────────────────

class _FocusTasksChart extends StatelessWidget {
  final List<DailyBreakdown> data;

  const _FocusTasksChart({required this.data});

  @override
  Widget build(BuildContext context) {
    final maxFocus = data
        .map((d) => d.focusMinutes)
        .fold(0, (a, b) => a > b ? a : b);
    final maxTasks = data
        .map((d) => d.tasksCompleted)
        .fold(0, (a, b) => a > b ? a : b);
    final maxVal = [maxFocus, maxTasks * 10, 1].reduce((a, b) => a > b ? a : b);

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Focus & tasks',
                  style: GoogleFonts.manrope(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Text(
                'Last 7 days',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((day) {
                final focusRatio = maxVal > 0
                    ? (day.focusMinutes / maxVal).clamp(0.0, 1.0)
                    : 0.0;
                final taskRatio = maxVal > 0
                    ? ((day.tasksCompleted * 10) / maxVal).clamp(0.0, 1.0)
                    : 0.0;
                final barH = 80.0;

                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          // Tasks bar (purple)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 10,
                            height: barH * taskRatio + 4,
                            decoration: BoxDecoration(
                              color: AppColors.brandPrimary,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 3),
                          // Focus bar (pink)
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 500),
                            width: 10,
                            height: barH * focusRatio + 4,
                            decoration: BoxDecoration(
                              color: AppColors.brandPink,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        day.dayLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.brandPrimary, label: 'Tasks'),
              const SizedBox(width: AppSpacing.s16),
              _LegendDot(color: AppColors.brandPink, label: 'Focus'),
            ],
          ),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: AppColors.textBody,
          ),
        ),
      ],
    );
  }
}

// ── Prayer bar chart ──────────────────────────────────────────────────────────

class _PrayerChart extends StatelessWidget {
  final List<DailyBreakdown> data;

  const _PrayerChart({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prayer logs by day',
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: data.map((day) {
                final ratio = (day.prayersCompleted / 5).clamp(0.0, 1.0);
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (day.prayersCompleted > 0)
                        Text(
                          '${day.prayersCompleted}',
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            color: AppColors.brandViolet,
                          ),
                        ),
                      const SizedBox(height: 4),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        width: 20,
                        height: 64.0 * ratio + 4,
                        decoration: BoxDecoration(
                          gradient: ratio > 0 ? AppGradients.action : null,
                          color: ratio == 0
                              ? AppColors.borderSoft
                              : null,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.s8),
                      Text(
                        day.dayLabel,
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AI Insight card ───────────────────────────────────────────────────────────

class _AiInsightCard extends StatelessWidget {
  final List<AnalyticsInsight> insights;

  const _AiInsightCard({required this.insights});

  @override
  Widget build(BuildContext context) {
    final insight = insights.first;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'AI insight',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          _InsightRichText(title: insight.title, message: insight.message),
          if (insights.length > 1) ...[
            const SizedBox(height: AppSpacing.s12),
            const Divider(color: AppColors.borderSoft),
            const SizedBox(height: AppSpacing.s8),
            for (final extra in insights.skip(1))
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.s8),
                child: _InsightRichText(
                  title: extra.title,
                  message: extra.message,
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _InsightRichText extends StatelessWidget {
  final String title;
  final String message;

  const _InsightRichText({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    // Bold any words wrapped in ** in the message (simple parser)
    final spans = <TextSpan>[];
    final parts = message.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(
        TextSpan(
          text: parts[i],
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: i.isOdd ? FontWeight.w700 : FontWeight.w500,
            color: AppColors.textHeading,
          ),
        ),
      );
    }
    return RichText(text: TextSpan(children: spans));
  }
}

// Fallback when no AI insight is available
class _AiInsightFallback extends StatelessWidget {
  final WeeklyAnalytics weekly;

  const _AiInsightFallback({required this.weekly});

  @override
  Widget build(BuildContext context) {
    final best = _bestDay(weekly.dailyBreakdown);
    final message = best != null
        ? 'You were most productive on **${best.dayLabel}**. Try scheduling deep work blocks early to build momentum.'
        : 'Keep completing tasks and focus sessions to unlock personalized AI insights.';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.15),
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.auto_awesome,
                size: 16,
                color: AppColors.brandPrimary,
              ),
              const SizedBox(width: 6),
              Text(
                'AI insight',
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          _InsightRichText(title: '', message: message),
        ],
      ),
    );
  }

  DailyBreakdown? _bestDay(List<DailyBreakdown> breakdown) {
    if (breakdown.isEmpty) return null;
    return breakdown.reduce(
      (a, b) =>
          (a.tasksCompleted + a.focusMinutes ~/ 10) >=
                  (b.tasksCompleted + b.focusMinutes ~/ 10)
              ? a
              : b,
    );
  }
}

// Keep AppTextStyles import used
// ignore: unused_element
Widget _unused() => Text('', style: AppTextStyles.bodySmallLight);
