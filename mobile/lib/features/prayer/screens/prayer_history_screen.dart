import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text(
          'Prayer History',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
          ? const Center(child: Text('No history available.'))
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(prayerHistoryProvider.notifier).loadWeeklySummary(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Weekly Overview',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      title: 'Missed Prayers',
                      value: '${state.summary!.totalMissed}',
                      subtitle: '${state.summary!.todayMissed} missed today',
                      icon: Icons.warning_amber_rounded,
                      color: Colors.redAccent,
                    ),
                    const SizedBox(height: 12),
                    _SummaryCard(
                      title: 'Completed',
                      value: '${state.summary!.totalCompleted}',
                      subtitle:
                          'Out of ${state.summary!.totalPrayers} total prayers',
                      icon: Icons.check_circle_outline,
                      color: AppColors.prayerGold,
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Daily Breakdown',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ...state.summary!.days.reversed.map(
                      (day) => _DayCard(day: day),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 40, color: color),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

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
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isToday
              ? AppColors.prayerGold
              : AppColors.textSecondary.withValues(alpha: 0.2),
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
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              if (day.missed > 0)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${day.missed} Missed',
                    style: const TextStyle(
                      color: Colors.redAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _StatColumn('On Time', day.completed, AppColors.prayerGold),
              _StatColumn('Late', day.late, Colors.orange),
              _StatColumn('Excused', day.excused, Colors.grey),
            ],
          ),
        ],
      ),
    );
  }
}

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
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: count > 0 ? color : AppColors.textSecondary,
          ),
        ),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
        ),
      ],
    );
  }
}
