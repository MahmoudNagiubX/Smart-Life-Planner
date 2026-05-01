import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/islamic_calendar_model.dart';
import '../providers/islamic_calendar_provider.dart';

class IslamicCalendarScreen extends ConsumerStatefulWidget {
  const IslamicCalendarScreen({super.key});

  @override
  ConsumerState<IslamicCalendarScreen> createState() =>
      _IslamicCalendarScreenState();
}

class _IslamicCalendarScreenState extends ConsumerState<IslamicCalendarScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(islamicCalendarProvider.notifier).loadCalendar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(islamicCalendarProvider);
    final calendar = state.calendar;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Islamic Calendar',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && calendar == null
          ? const AppLoadingState(message: 'Loading Islamic calendar...')
          : state.error != null && calendar == null
          ? AppErrorState(
              title: 'Islamic calendar could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(islamicCalendarProvider.notifier).loadCalendar(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(islamicCalendarProvider.notifier).loadCalendar(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(20),
                children: [
                  if (calendar != null) ...[
                    _HijriTodayCard(calendar: calendar),
                    const SizedBox(height: 16),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: AppColors.error),
                        ),
                      ),
                    Text(
                      'Upcoming Events',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (calendar.events.isEmpty)
                      const _EmptyEventsCard()
                    else
                      ...calendar.events.map(
                        (event) => _IslamicEventTile(event: event),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _HijriTodayCard extends StatelessWidget {
  final IslamicCalendarModel calendar;

  const _HijriTodayCard({required this.calendar});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.prayerGold.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.prayerGold.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_month, color: AppColors.prayerGold),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Today',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const _EstimateChip(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            calendar.hijriDate.label,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppColors.prayerGold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(calendar.gregorianDate),
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Text(
            calendar.calculationNote,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _IslamicEventTile extends StatelessWidget {
  final IslamicCalendarEventModel event;

  const _IslamicEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.prayerGold.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.prayerGold,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    if (event.estimated) const _EstimateChip(),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.hijriLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.prayerGold,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(event.gregorianDate),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  event.description,
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

class _EstimateChip extends StatelessWidget {
  const _EstimateChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        'Estimated',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: AppColors.warning,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _EmptyEventsCard extends StatelessWidget {
  const _EmptyEventsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'No upcoming events were calculated.',
        style: Theme.of(
          context,
        ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
      ),
    );
  }
}

String _formatDate(DateTime date) {
  final year = date.year.toString().padLeft(4, '0');
  final month = date.month.toString().padLeft(2, '0');
  final day = date.day.toString().padLeft(2, '0');
  return '$year-$month-$day';
}
