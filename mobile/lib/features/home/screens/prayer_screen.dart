import 'dart:math' show pi;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../routes/app_routes.dart';
import '../../prayer/providers/quran_goal_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../prayer/models/prayer_model.dart';
import '../widgets/progress_ring.dart';

const _kNavClearance = 138.0;

class PrayerScreen extends ConsumerStatefulWidget {
  const PrayerScreen({super.key});

  @override
  ConsumerState<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends ConsumerState<PrayerScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(prayerProvider.notifier).loadTodayPrayers();
      ref.read(quranGoalProvider.notifier).loadSummary();
    });
  }

  String _prayerDisplayName(String name) {
    const names = {
      'fajr': 'Fajr',
      'dhuhr': 'Dhuhr',
      'asr': 'Asr',
      'maghrib': 'Maghrib',
      'isha': 'Isha',
    };
    return names[name] ?? name;
  }

  String _formatTime(String? isoTime) {
    if (isoTime == null) return '--:--';
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      final h = dt.hour % 12;
      final hour = (h == 0 ? 12 : h).toString();
      final minute = dt.minute.toString().padLeft(2, '0');
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      return '$hour:$minute $period';
    } catch (_) {
      return '--:--';
    }
  }

  PrayerTime? _findNextPrayer(List<PrayerTime> prayers) {
    for (final p in prayers) {
      if (!p.completed && p.status != 'missed') return p;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(prayerProvider);
    final quranState = ref.watch(quranGoalProvider);
    final data = state.data;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading prayer times...')
          : state.error != null
          ? AppErrorState(
              title: 'Prayer times could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(prayerProvider.notifier).loadTodayPrayers(),
            )
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: () =>
                  ref.read(prayerProvider.notifier).loadTodayPrayers(),
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH,
                        56,
                        AppSpacing.screenH,
                        0,
                      ),
                      child: _PrayerHeader(
                        onSettings: () =>
                            context.push(AppRoutes.prayerSettings),
                      ),
                    ),
                  ),
                  if (data != null) ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: AppFadeSlide(
                          child: Builder(
                            builder: (_) {
                              final next = _findNextPrayer(data.prayers);
                              return _NextPrayerHeroCard(
                                next: next,
                                nextDisplayName: next != null
                                    ? _prayerDisplayName(next.prayerName)
                                    : '',
                                formattedTime: _formatTime(next?.scheduledAt),
                                completedCount: data.completedCount,
                                totalCount: data.totalCount,
                                onMarkPrayed: () {
                                  if (next != null) {
                                    ref
                                        .read(prayerProvider.notifier)
                                        .togglePrayer(
                                          next.prayerName,
                                          next.completed,
                                        );
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: AppFadeSlide(
                          delay: const Duration(milliseconds: 60),
                          child: _DailyPrayerListCard(
                            prayers: data.prayers,
                            displayNameOf: _prayerDisplayName,
                            formatTime: _formatTime,
                            nextPrayer: _findNextPrayer(data.prayers),
                            onToggle: (p) => ref
                                .read(prayerProvider.notifier)
                                .togglePrayer(p.prayerName, p.completed),
                            onLongPress: (p) =>
                                _showPrayerStatusSheet(context, ref, p),
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: AppFadeSlide(
                          delay: const Duration(milliseconds: 120),
                          child: _SpiritualProgressCard(
                            completedCount: data.completedCount,
                            totalCount: data.totalCount,
                            missedCount: data.missedCount,
                          ),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: _QuranQiblaRow(
                          pagesCompleted:
                              quranState.summary?.todayPagesCompleted,
                          dailyTarget: quranState.summary?.dailyPageTarget,
                          progressPercent: quranState.summary?.progressPercent,
                          onQuranGoal: () => context.push(AppRoutes.quranGoal),
                          onQibla: () => context.push(AppRoutes.qibla),
                        ),
                      ),
                    ),
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: _SpiritualToolsGrid(
                          onHistory: () =>
                              context.push(AppRoutes.prayerHistory),
                          onRamadan: () => context.push(AppRoutes.ramadan),
                          onDhikr: () => context.push(AppRoutes.dhikrReminders),
                          onCalendar: () =>
                              context.push(AppRoutes.islamicCalendar),
                        ),
                      ),
                    ),
                  ],
                  const SliverToBoxAdapter(
                    child: SizedBox(height: _kNavClearance),
                  ),
                ],
              ),
            ),
    );
  }

  void _showPrayerStatusSheet(
    BuildContext context,
    WidgetRef ref,
    PrayerTime prayer,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.sheetBr,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(
                    top: AppSpacing.s16,
                    bottom: AppSpacing.s12,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.screenH,
                    AppSpacing.s8,
                    AppSpacing.screenH,
                    AppSpacing.s8,
                  ),
                  child: Text(
                    'Mark ${_prayerDisplayName(prayer.prayerName)} Status',
                    style: AppTextStyles.h4Light,
                  ),
                ),
                Divider(color: AppColors.dividerColor, height: 1),
                _StatusOption(
                  icon: Icons.check_circle_outline,
                  iconColor: AppColors.brandViolet,
                  label: 'Prayed On Time',
                  onTap: () {
                    ref
                        .read(prayerProvider.notifier)
                        .setPrayerStatus(prayer.prayerName, 'prayed_on_time');
                    Navigator.pop(context);
                  },
                ),
                _StatusOption(
                  icon: Icons.access_time,
                  iconColor: AppColors.brandPink,
                  label: 'Prayed Late',
                  onTap: () {
                    ref
                        .read(prayerProvider.notifier)
                        .setPrayerStatus(prayer.prayerName, 'prayed_late');
                    Navigator.pop(context);
                  },
                ),
                _StatusOption(
                  icon: Icons.warning_amber_rounded,
                  iconColor: AppColors.errorColor,
                  label: 'Missed',
                  onTap: () {
                    ref
                        .read(prayerProvider.notifier)
                        .setPrayerStatus(prayer.prayerName, 'missed');
                    Navigator.pop(context);
                  },
                ),
                _StatusOption(
                  icon: Icons.bed_outlined,
                  iconColor: AppColors.textHint,
                  label: 'Excused',
                  onTap: () {
                    ref
                        .read(prayerProvider.notifier)
                        .setPrayerStatus(prayer.prayerName, 'excused');
                    Navigator.pop(context);
                  },
                ),
                const SizedBox(height: AppSpacing.s8),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _PrayerHeader extends StatelessWidget {
  final VoidCallback onSettings;
  const _PrayerHeader({required this.onSettings});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Prayer', style: AppTextStyles.h1Light),
              const SizedBox(height: 4),
              Text(
                'Stay spiritually consistent throughout your day.',
                style: AppTextStyles.bodySmallLight,
              ),
              const SizedBox(height: AppSpacing.s8),
              const _PrayerHeaderChip(),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        GestureDetector(
          onTap: onSettings,
          child: Container(
            width: AppButtonHeight.icon,
            height: AppButtonHeight.icon,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.md),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.soft,
            ),
            child: const Icon(
              Icons.settings_outlined,
              size: 20,
              color: AppColors.textBody,
            ),
          ),
        ),
      ],
    );
  }
}

// ── Next Prayer Hero Card ─────────────────────────────────────────────────────

class _PrayerHeaderChip extends StatelessWidget {
  const _PrayerHeaderChip();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceLavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(
          color: AppColors.brandPrimary.withValues(alpha: 0.14),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.auto_awesome_rounded,
            size: 13,
            color: AppColors.brandViolet,
          ),
          const SizedBox(width: 6),
          Text(
            'Bismillah - pray with presence',
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.brandPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _NextPrayerHeroCard extends StatelessWidget {
  final PrayerTime? next;
  final String nextDisplayName;
  final String formattedTime;
  final int completedCount;
  final int totalCount;
  final VoidCallback onMarkPrayed;

  const _NextPrayerHeroCard({
    required this.next,
    required this.nextDisplayName,
    required this.formattedTime,
    required this.completedCount,
    required this.totalCount,
    required this.onMarkPrayed,
  });

  @override
  Widget build(BuildContext context) {
    final allDone = completedCount >= totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF6A4CFF), Color(0xFF8B5CFF), Color(0xFFB07CFF)],
          stops: [0.0, 0.6, 1.0],
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        boxShadow: AppShadows.glowPurple,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -8,
            bottom: -8,
            child: SizedBox(
              width: 160,
              height: 120,
              child: CustomPaint(painter: _MosquePainter()),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    color: Colors.white,
                    size: 14,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    allDone ? 'All Prayers Complete' : 'Next Prayer',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (allDone) ...[
                Text(
                  'All done! ✨',
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'All $totalCount prayers completed today.',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ] else ...[
                Text(
                  nextDisplayName.isNotEmpty ? nextDisplayName : '—',
                  style: GoogleFonts.manrope(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  formattedTime,
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$completedCount of $totalCount prayed today',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
                const SizedBox(height: 14),
                _MarkPrayedButton(onTap: onMarkPrayed),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _MarkPrayedButton extends StatelessWidget {
  final VoidCallback onTap;
  const _MarkPrayedButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check, size: 14, color: AppColors.brandPrimary),
            const SizedBox(width: 6),
            Text(
              'Mark as prayed',
              style: GoogleFonts.manrope(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.brandPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Mosque Decoration Painter ─────────────────────────────────────────────────

class _MosquePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Mosque body with dome arch
    final bodyPath = Path()
      ..moveTo(30, size.height)
      ..lineTo(30, 60)
      ..arcToPoint(
        const Offset(100, 60),
        radius: const Radius.circular(35),
        clockwise: true,
      )
      ..lineTo(100, size.height)
      ..close();
    canvas.drawPath(
      bodyPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.15)
        ..style = PaintingStyle.fill,
    );

    // Door arch
    final doorPath = Path()
      ..moveTo(65, size.height)
      ..lineTo(65, 92)
      ..arcToPoint(
        const Offset(81, 92),
        radius: const Radius.circular(8),
        clockwise: true,
      )
      ..lineTo(81, size.height)
      ..close();
    canvas.drawPath(
      doorPath,
      Paint()
        ..color = Colors.white.withValues(alpha: 0.25)
        ..style = PaintingStyle.fill,
    );

    // Soft lavender crescent above dome
    final crescentPath = Path()
      ..moveTo(80, 18)
      ..cubicTo(77, 23, 77, 27, 80, 32)
      ..cubicTo(83, 27, 83, 23, 80, 18)
      ..close();
    canvas.drawPath(
      crescentPath,
      Paint()
        ..color = AppColors.brandPinkSoft.withValues(alpha: 0.9)
        ..style = PaintingStyle.fill,
    );

    // Decorative circles
    canvas.drawCircle(
      const Offset(125, 40),
      14,
      Paint()..color = Colors.white.withValues(alpha: 0.18),
    );
    canvas.drawCircle(
      const Offset(135, 55),
      8,
      Paint()..color = Colors.white.withValues(alpha: 0.15),
    );
  }

  @override
  bool shouldRepaint(_MosquePainter old) => false;
}

// ── Daily Prayer List Card ────────────────────────────────────────────────────

class _DailyPrayerListCard extends StatelessWidget {
  final List<PrayerTime> prayers;
  final String Function(String) displayNameOf;
  final String Function(String?) formatTime;
  final PrayerTime? nextPrayer;
  final ValueChanged<PrayerTime> onToggle;
  final ValueChanged<PrayerTime> onLongPress;

  const _DailyPrayerListCard({
    required this.prayers,
    required this.displayNameOf,
    required this.formatTime,
    required this.nextPrayer,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
      ),
      child: ClipRRect(
        borderRadius: AppRadius.cardBr,
        child: Column(
          children: [
            for (int i = 0; i < prayers.length; i++)
              if (i == 0) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.s20,
                    AppSpacing.s16,
                    AppSpacing.s20,
                    AppSpacing.s8,
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Prayer Times', style: AppTextStyles.h4Light),
                        const SizedBox(height: 3),
                        Text(
                          'Tap any prayer to update it independently.',
                          style: AppTextStyles.captionLight,
                        ),
                      ],
                    ),
                  ),
                ),
                _PrayerRow(
                  prayer: prayers[i],
                  displayName: displayNameOf(prayers[i].prayerName),
                  formattedTime: formatTime(prayers[i].scheduledAt),
                  isNext: nextPrayer?.prayerName == prayers[i].prayerName,
                  showDivider: false,
                  onToggle: () => onToggle(prayers[i]),
                  onLongPress: () => onLongPress(prayers[i]),
                ),
              ] else
                _PrayerRow(
                  prayer: prayers[i],
                  displayName: displayNameOf(prayers[i].prayerName),
                  formattedTime: formatTime(prayers[i].scheduledAt),
                  isNext: nextPrayer?.prayerName == prayers[i].prayerName,
                  showDivider: false,
                  onToggle: () => onToggle(prayers[i]),
                  onLongPress: () => onLongPress(prayers[i]),
                ),
          ],
        ),
      ),
    );
  }
}

class _PrayerRow extends StatelessWidget {
  final PrayerTime prayer;
  final String displayName;
  final String formattedTime;
  final bool isNext;
  final bool showDivider;
  final VoidCallback onToggle;
  final VoidCallback onLongPress;

  const _PrayerRow({
    required this.prayer,
    required this.displayName,
    required this.formattedTime,
    required this.isNext,
    required this.showDivider,
    required this.onToggle,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final isCompleted = prayer.completed;
    final isMissed = prayer.status == 'missed';

    return GestureDetector(
      onTap: onToggle,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.s12,
          AppSpacing.s4,
          AppSpacing.s12,
          AppSpacing.s4,
        ),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: isNext ? AppColors.bgSurfaceLavender : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: isNext
                ? Border.all(
                    color: AppColors.brandPrimary.withValues(alpha: 0.18),
                  )
                : null,
          ),
          child: Row(
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 4,
                height: 58,
                decoration: BoxDecoration(
                  color: isNext ? AppColors.brandPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s12,
                    vertical: AppSpacing.s8,
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: isNext
                              ? AppColors.bgSurface
                              : AppColors.bgSurfaceLavender.withValues(
                                  alpha: 0.60,
                                ),
                          borderRadius: BorderRadius.circular(AppRadius.md),
                        ),
                        child: Icon(
                          _iconForPrayer(prayer.prayerName),
                          size: 18,
                          color: isNext
                              ? AppColors.brandPrimary
                              : AppColors.textHint,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              displayName,
                              style: AppTextStyles.h4(
                                isMissed
                                    ? AppColors.errorColor
                                    : AppColors.textHeading,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              formattedTime,
                              style: AppTextStyles.caption(
                                isNext
                                    ? AppColors.brandPrimary
                                    : AppColors.textHint,
                              ),
                            ),
                          ],
                        ),
                      ),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: isCompleted
                              ? AppColors.brandViolet
                              : AppColors.bgSurface,
                          border: Border.all(
                            color: isCompleted
                                ? AppColors.brandViolet
                                : isNext
                                ? AppColors.brandPrimary
                                : AppColors.borderSoft,
                            width: 2,
                          ),
                        ),
                        child: isCompleted
                            ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 13,
                              )
                            : null,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForPrayer(String name) {
    return switch (name) {
      'fajr' => Icons.wb_twilight_outlined,
      'dhuhr' => Icons.wb_sunny_outlined,
      'asr' => Icons.wb_sunny_outlined,
      'maghrib' => Icons.filter_drama_outlined,
      'isha' => Icons.nightlight_round,
      _ => Icons.nightlight_round,
    };
  }
}

// ── Spiritual Progress Card ───────────────────────────────────────────────────

class _SpiritualProgressCard extends StatelessWidget {
  final int completedCount;
  final int totalCount;
  final int missedCount;

  const _SpiritualProgressCard({
    required this.completedCount,
    required this.totalCount,
    required this.missedCount,
  });

  @override
  Widget build(BuildContext context) {
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final allDone = completedCount >= totalCount && totalCount > 0;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          ProgressRing(
            value: progress,
            size: 80,
            strokeWidth: 7,
            trackColor: AppColors.borderSoft,
            gradientColors: const [
              AppColors.brandPrimary,
              AppColors.brandViolet,
            ],
            child: Center(
              child: Text(
                '$completedCount',
                style: AppTextStyles.h3(AppColors.brandPrimary),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Prayer Progress', style: AppTextStyles.h4Light),
                const SizedBox(height: 2),
                Text(
                  '$completedCount of $totalCount prayers',
                  style: AppTextStyles.bodySmallLight,
                ),
                const SizedBox(height: 4),
                Text(
                  allDone
                      ? 'All prayers completed today!'
                      : 'Keep going, you\'re doing great!',
                  style: AppTextStyles.caption(
                    allDone ? AppColors.brandViolet : AppColors.textHint,
                  ),
                ),
                if (missedCount > 0) ...[
                  const SizedBox(height: 2),
                  Text(
                    '$missedCount missed',
                    style: AppTextStyles.caption(AppColors.errorColor),
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

// ── Quran Goal + Qibla Row ────────────────────────────────────────────────────

class _QuranQiblaRow extends StatelessWidget {
  final int? pagesCompleted;
  final int? dailyTarget;
  final int? progressPercent;
  final VoidCallback onQuranGoal;
  final VoidCallback onQibla;

  const _QuranQiblaRow({
    required this.pagesCompleted,
    required this.dailyTarget,
    required this.progressPercent,
    required this.onQuranGoal,
    required this.onQibla,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _QuranGoalCard(
              pagesCompleted: pagesCompleted,
              dailyTarget: dailyTarget,
              onTap: onQuranGoal,
            ),
          ),
          const SizedBox(width: AppSpacing.cardGap),
          Expanded(child: _QiblaCard(onTap: onQibla)),
        ],
      ),
    );
  }
}

class _QuranGoalCard extends StatelessWidget {
  final int? pagesCompleted;
  final int? dailyTarget;
  final VoidCallback onTap;

  const _QuranGoalCard({
    required this.pagesCompleted,
    required this.dailyTarget,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasData = pagesCompleted != null && dailyTarget != null;
    final target = dailyTarget ?? 0;
    final completed = pagesCompleted ?? 0;
    final progress = target == 0 ? 0.0 : (completed / target).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.cardBr,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceLavender,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.menu_book_outlined,
                    size: 18,
                    color: AppColors.brandViolet,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text('Quran Goal', style: AppTextStyles.h4Light),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (hasData) ...[
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '$completed / $target',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                    TextSpan(
                      text: ' pages',
                      style: AppTextStyles.body(AppColors.textHint),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Gradient progress bar
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6A4CFF), Color(0xFFF45DB3)],
                      ),
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Text('Daily reading', style: AppTextStyles.captionLight),
            ] else ...[
              Text(
                'Set target',
                style: AppTextStyles.bodySmall(AppColors.brandPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Create your daily reading goal.',
                style: AppTextStyles.captionLight,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QiblaCard extends StatelessWidget {
  final VoidCallback onTap;
  const _QiblaCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.cardBr,
          boxShadow: AppShadows.soft,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppColors.bgSurfaceLavender,
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                  ),
                  child: const Icon(
                    Icons.explore_outlined,
                    size: 18,
                    color: AppColors.brandPrimary,
                  ),
                ),
                const SizedBox(width: 8),
                Text('Qibla', style: AppTextStyles.h4Light),
              ],
            ),
            const SizedBox(height: 8),
            Center(
              child: SizedBox(
                width: 72,
                height: 72,
                child: CustomPaint(painter: _CompassPainter()),
              ),
            ),
            const SizedBox(height: 4),
            Center(child: Text('136° SE', style: AppTextStyles.captionLight)),
          ],
        ),
      ),
    );
  }
}

// ── Compass Painter ───────────────────────────────────────────────────────────

class _CompassPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2;

    canvas.drawCircle(
      center,
      r - 1,
      Paint()
        ..color = AppColors.borderSoft
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    final tp = TextPainter(
      text: TextSpan(
        text: 'N',
        style: GoogleFonts.manrope(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: AppColors.textHint,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(canvas, Offset(center.dx - tp.width / 2, 4));

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(45 * pi / 180);

    final needleRect = Rect.fromLTWH(-2, -(r - 8), 4, r - 8);
    final needlePath = Path()
      ..moveTo(-2, 0)
      ..lineTo(0, -(r - 8))
      ..lineTo(2, 0)
      ..close();
    canvas.drawPath(
      needlePath,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF6A4CFF), Color(0xFFF45DB3)],
        ).createShader(needleRect)
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      Offset.zero,
      4,
      Paint()..color = AppColors.bgSurfaceLavender,
    );
    canvas.restore();
  }

  @override
  bool shouldRepaint(_CompassPainter old) => false;
}

// ── Spiritual Tools Grid ──────────────────────────────────────────────────────

class _SpiritualToolsGrid extends StatelessWidget {
  final VoidCallback onHistory;
  final VoidCallback onRamadan;
  final VoidCallback onDhikr;
  final VoidCallback onCalendar;

  const _SpiritualToolsGrid({
    required this.onHistory,
    required this.onRamadan,
    required this.onDhikr,
    required this.onCalendar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Spiritual Tools', style: AppTextStyles.h4Light),
        const SizedBox(height: AppSpacing.s12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: AppSpacing.cardGap,
          mainAxisSpacing: AppSpacing.cardGap,
          childAspectRatio: 2.6,
          children: [
            _ToolTile(
              icon: Icons.history,
              label: 'History',
              iconColor: AppColors.featAnalytics,
              iconBg: AppColors.featAnalyticsSoft,
              onTap: onHistory,
            ),
            _ToolTile(
              icon: Icons.nights_stay_outlined,
              label: 'Ramadan',
              iconColor: AppColors.brandViolet,
              iconBg: AppColors.featPrayerSoft,
              onTap: onRamadan,
            ),
            _ToolTile(
              icon: Icons.grain_outlined,
              label: 'Dhikr',
              iconColor: AppColors.brandPink,
              iconBg: AppColors.bgSurfaceLavender,
              onTap: onDhikr,
            ),
            _ToolTile(
              icon: Icons.calendar_month_outlined,
              label: 'Calendar',
              iconColor: AppColors.featFocus,
              iconBg: AppColors.featFocusSoft,
              onTap: onCalendar,
            ),
          ],
        ),
      ],
    );
  }
}

class _ToolTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconColor;
  final Color iconBg;
  final VoidCallback onTap;

  const _ToolTile({
    required this.icon,
    required this.label,
    required this.iconColor,
    required this.iconBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.soft,
        ),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.body(AppColors.textHeading),
              ),
            ),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Status Option ─────────────────────────────────────────────────────────────

class _StatusOption extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _StatusOption({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(icon, color: iconColor),
      title: Text(label, style: AppTextStyles.bodyLight),
      onTap: onTap,
    );
  }
}
