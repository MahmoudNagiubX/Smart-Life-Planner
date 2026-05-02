import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../providers/prayer_history_provider.dart';

class PrayerHistoryScreen extends ConsumerStatefulWidget {
  const PrayerHistoryScreen({super.key});

  @override
  ConsumerState<PrayerHistoryScreen> createState() =>
      _PrayerHistoryScreenState();
}

class _PrayerHistoryScreenState extends ConsumerState<PrayerHistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerHistoryProvider.notifier).loadWeeklySummary();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerHistoryProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Prayer History', style: AppTextStyles.h2Light),
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading history...')
          : state.error != null
          ? AppErrorState(
              title: 'History could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(prayerHistoryProvider.notifier).loadWeeklySummary(),
            )
          : state.summary == null
          ? const AppEmptyState(
              icon: Icons.history_outlined,
              title: 'No prayer history yet',
              message: 'Prayer logs will appear here after you start tracking.',
            )
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(prayerHistoryProvider.notifier).loadWeeklySummary(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s8,
                  AppSpacing.screenH,
                  138,
                ),
                children: [
                  Text(
                    'WEEKLY OVERVIEW',
                    style: AppTextStyles.label(AppColors.textHint),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  Row(
                    children: [
                      Expanded(
                        child: _SummaryCard(
                          title: 'Completed',
                          value: '${state.summary!.totalCompleted}',
                          subtitle: 'of ${state.summary!.totalPrayers} prayers',
                          icon: Icons.check_circle_outline,
                          color: AppColors.successColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: _SummaryCard(
                          title: 'Missed',
                          value: '${state.summary!.totalMissed}',
                          subtitle:
                              '${state.summary!.todayMissed} missed today',
                          icon: Icons.warning_amber_rounded,
                          color: AppColors.errorColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(
                    'DAILY BREAKDOWN',
                    style: AppTextStyles.label(AppColors.textHint),
                  ),
                  const SizedBox(height: AppSpacing.s8),
                  ...state.summary!.days.reversed.map(
                    (day) => _DayCard(day: day),
                  ),
                ],
              ),
            ),
    );
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color color;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.color,
  });

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
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Icon(icon, color: color, size: AppIconSize.cardHeader),
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(value, style: AppTextStyles.h2(color)),
          const SizedBox(height: 2),
          Text(title, style: AppTextStyles.h4Light),
          const SizedBox(height: 2),
          Text(subtitle, style: AppTextStyles.captionLight),
        ],
      ),
    );
  }
}

// ── Day card ──────────────────────────────────────────────────────────────────

class _DayCard extends StatelessWidget {
  final dynamic day;

  const _DayCard({required this.day});

  @override
  Widget build(BuildContext context) {
    final date = DateTime.tryParse(day.prayerDate);
    if (date == null) {
      return const SizedBox.shrink();
    }
    final isToday =
        date.day == DateTime.now().day &&
        date.month == DateTime.now().month &&
        date.year == DateTime.now().year;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: isToday ? AppColors.bgSurfaceLavender : AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
        border: Border.all(
          color: isToday
              ? AppColors.brandViolet.withValues(alpha: 0.4)
              : AppColors.borderSoft,
          width: isToday ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                isToday ? 'Today' : DateFormat('EEEE, MMM d').format(date),
                style: AppTextStyles.h4Light,
              ),
              if (day.missed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8,
                    vertical: AppSpacing.s4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.errorSoft,
                    borderRadius: AppRadius.pillBr,
                  ),
                  child: Text(
                    '${day.missed} Missed',
                    style: AppTextStyles.label(AppColors.errorColor),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          const Divider(color: AppColors.dividerColor, height: 1),
          const SizedBox(height: AppSpacing.s12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn('On Time', day.completed, AppColors.successColor),
              _StatColumn('Late', day.late, AppColors.warningColor),
              _StatColumn('Excused', day.excused, AppColors.textHint),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Stat column ───────────────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatColumn(this.label, this.count, this.color);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          '$count',
          style: AppTextStyles.h3(count > 0 ? color : AppColors.textHint),
        ),
        const SizedBox(height: 2),
        Text(label, style: AppTextStyles.captionLight),
      ],
    );
  }
}
