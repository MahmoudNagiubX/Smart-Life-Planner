import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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

class _IslamicCalendarScreenState
    extends ConsumerState<IslamicCalendarScreen> {
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Islamic Calendar', style: AppTextStyles.h2Light),
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
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(islamicCalendarProvider.notifier).loadCalendar(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s8,
                  AppSpacing.screenH,
                  138,
                ),
                children: [
                  if (calendar != null) ...[
                    _HijriTodayCard(calendar: calendar),
                    const SizedBox(height: AppSpacing.s16),
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Text(
                          state.error!,
                          style: AppTextStyles.caption(AppColors.errorColor),
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
                      child: Text('Upcoming Events', style: AppTextStyles.h3Light),
                    ),
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
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A4CFF), Color(0xFF8B5CFF), Color(0xFFB07CFF)],
          stops: [0.0, 0.55, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        boxShadow: AppShadows.glowPurple,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.calendar_month_outlined,
                color: Colors.white,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                'Today',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.9),
                ),
              ),
              const Spacer(),
              const _EstimateChip(),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            calendar.hijriDate.label,
            style: GoogleFonts.manrope(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _formatDate(calendar.gregorianDate),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            calendar.calculationNote,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.75),
            ),
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
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceLavender,
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.event_available_outlined,
              color: AppColors.brandViolet,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(event.title, style: AppTextStyles.h4Light),
                    ),
                    if (event.estimated)
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: _EstimateChip(),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  event.hijriLabel,
                  style: AppTextStyles.caption(AppColors.brandPrimary),
                ),
                const SizedBox(height: 2),
                Text(
                  _formatDate(event.gregorianDate),
                  style: AppTextStyles.captionLight,
                ),
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    event.description,
                    style: AppTextStyles.bodySmallLight,
                  ),
                ],
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
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceLavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        'Estimated',
        style: GoogleFonts.manrope(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColors.brandPrimary,
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
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        boxShadow: AppShadows.soft,
      ),
      child: Text(
        'No upcoming events were calculated.',
        style: AppTextStyles.bodySmallLight,
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
