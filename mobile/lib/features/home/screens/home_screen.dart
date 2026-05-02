import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_tokens.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/models/dashboard_model.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../../routes/app_routes.dart';
import '../widgets/progress_ring.dart';

// ── Layout ────────────────────────────────────────────────────────────────────
// Bottom nav clearance: compact floating nav + FAB overhang + breathing room.
const double _kNavClearance = 140.0;

// ═════════════════════════════════════════════════════════════════════════════
// HomeScreen
// ═════════════════════════════════════════════════════════════════════════════

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _fade;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.04),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
      _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'Good night';
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    if (hour < 20) return 'Good evening';
    return 'Good night';
  }

  String _greetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 5 || hour >= 20) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌅';
  }

  String _dateLabel() {
    final now = DateTime.now();
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${days[now.weekday - 1]}, ${months[now.month - 1]} ${now.day}';
  }

  Future<void> _refreshDashboard() =>
      ref.read(dashboardProvider.notifier).loadDashboard();

  void _openCustomize(DashboardData data) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bgSurface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppRadius.xl3),
        ),
      ),
      builder: (_) => _DashboardCustomizeSheet(
        currentWidgets: data.personalization.dailyDashboardWidgets
            .where(defaultDashboardWidgets.contains)
            .toList(),
      ),
    );
  }

  double _dayProgress(DashboardData data) {
    final total = data.pendingCount + data.completedToday;
    final taskRatio = total == 0 ? 0.0 : data.completedToday / total;
    final prayerTotal = data.prayerProgress.total <= 0
        ? 5
        : data.prayerProgress.total;
    final prayerRatio = data.prayerProgress.completed / prayerTotal;
    return (taskRatio * 0.55 + prayerRatio * 0.45).clamp(0.0, 1.0);
  }

  (String, String?) _summaryData(double progress) {
    if (progress < 0.25) return ('Today is just starting', 'starting');
    if (progress < 0.5) return ('Making good progress', 'progress');
    if (progress < 0.8) return ('Today looks balanced', 'balanced');
    return ('Outstanding day ahead', 'Outstanding');
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final firstName = (authState.user?['full_name'] as String? ?? 'Mahmoud')
        .split(' ')
        .first;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: SlideTransition(
            position: _slide,
            child: RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: _refreshDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.only(
                  left: AppSpacing.screenH,
                  right: AppSpacing.screenH,
                  top: AppSpacing.s20,
                  bottom: _kNavClearance,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ────────────────────────────────────────────
                    _HomeHeader(
                      greeting:
                          '${_greeting()}, $firstName ${_greetingEmoji()}',
                      dateLabel: _dateLabel(),
                      initials: firstName.isNotEmpty
                          ? firstName[0].toUpperCase()
                          : 'M',
                      onCustomize: dashState.data != null
                          ? () => _openCustomize(dashState.data!)
                          : null,
                    ),
                    const SizedBox(height: AppSpacing.s20),

                    // ── Dashboard content ─────────────────────────────────
                    if (dashState.isLoading && dashState.data == null)
                      const _LoadingCard()
                    else if (dashState.error != null && dashState.data == null)
                      _ErrorCard(
                        message: dashState.error!,
                        onRetry: _refreshDashboard,
                      )
                    else if (dashState.data case final data?)
                      _DashboardBody(
                        data: data,
                        dayProgress: _dayProgress(data),
                        summaryData: _summaryData(_dayProgress(data)),
                        onCompleteTask: (id) async {
                          await ref
                              .read(tasksProvider.notifier)
                              .completeTask(id);
                          await ref
                              .read(dashboardProvider.notifier)
                              .loadDashboard();
                        },
                        onOpenCustomize: () => _openCustomize(data),
                      )
                    else
                      const _EmptyCard(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Header
// ═════════════════════════════════════════════════════════════════════════════

class _HomeHeader extends StatelessWidget {
  final String greeting;
  final String dateLabel;
  final String initials;
  final VoidCallback? onCustomize;

  const _HomeHeader({
    required this.greeting,
    required this.dateLabel,
    required this.initials,
    this.onCustomize,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // Logo
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.18),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Image.asset(
              'assets/images/app_logo.png',
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => Container(
                decoration: const BoxDecoration(gradient: AppGradients.action),
                child: const Icon(
                  Icons.auto_awesome_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),

        // Greeting + date
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                greeting,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                  letterSpacing: -0.3,
                  height: 1.2,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                dateLabel,
                style: GoogleFonts.manrope(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textHint,
                ),
              ),
            ],
          ),
        ),

        // Notification bell
        GestureDetector(
          onTap: () => HapticFeedback.lightImpact(),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.soft,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                const Icon(
                  Icons.notifications_outlined,
                  size: 20,
                  color: AppColors.textHeading,
                ),
                Positioned(
                  top: 9,
                  right: 9,
                  child: Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(
                      color: AppColors.errorColor,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.bgSurface,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.s8),

        // Avatar / customize
        GestureDetector(
          onTap: onCustomize,
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: AppGradients.action,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                initials,
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Dashboard body — only renders when data is present
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardBody extends StatelessWidget {
  final DashboardData data;
  final double dayProgress;
  final (String, String?) summaryData;
  final Future<void> Function(String id) onCompleteTask;
  final VoidCallback onOpenCustomize;

  const _DashboardBody({
    required this.data,
    required this.dayProgress,
    required this.summaryData,
    required this.onCompleteTask,
    required this.onOpenCustomize,
  });

  @override
  Widget build(BuildContext context) {
    final p = data.personalization;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Daily summary gradient card
        _DailySummaryCard(
          progress: dayProgress,
          headline: summaryData.$1,
          highlightWord: summaryData.$2,
          completedToday: data.completedToday,
          pendingCount: data.pendingCount,
          onViewDay: () => context.go(AppRoutes.tasks),
        ),
        const SizedBox(height: 16),

        // Prayer + Focus row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _NextPrayerCard(
                  nextPrayer: p.nextPrayer,
                  onTap: () => context.go(AppRoutes.prayer),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: _FocusSessionCard(
                  suggestedMinutes: p.focusShortcut.suggestedMinutes,
                  onTap: () => context.go(AppRoutes.focus),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Today's tasks
        _TodayTasksCard(
          topTasks: data.topTasks,
          onCompleteTask: onCompleteTask,
          onViewAll: () => context.go(AppRoutes.tasks),
        ),
        const SizedBox(height: 16),

        // Habits + AI row
        IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _HabitsCard(
                  snapshot: p.habitSnapshot,
                  onTap: () => context.go(AppRoutes.habits),
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: _AiSuggestionCard(
                  plan: p.aiPlanCard,
                  onTap: () => context.go(AppRoutes.aiCoach),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Daily Summary Card
// ═════════════════════════════════════════════════════════════════════════════

class _DailySummaryCard extends StatelessWidget {
  final double progress;
  final String headline;
  final String? highlightWord;
  final int completedToday;
  final int pendingCount;
  final VoidCallback onViewDay;

  const _DailySummaryCard({
    required this.progress,
    required this.headline,
    this.highlightWord,
    required this.completedToday,
    required this.pendingCount,
    required this.onViewDay,
  });

  @override
  Widget build(BuildContext context) {
    final headlineStyle = GoogleFonts.manrope(
      fontSize: 22,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.25,
    );

    Widget headlineWidget;
    final hw = highlightWord;
    if (hw != null && headline.contains(hw)) {
      final parts = headline.split(hw);
      headlineWidget = RichText(
        text: TextSpan(
          style: headlineStyle,
          children: [
            TextSpan(text: parts[0]),
            TextSpan(
              text: hw,
              style: TextStyle(color: AppColors.brandPinkSoft),
            ),
            if (parts.length > 1) TextSpan(text: parts[1]),
          ],
        ),
      );
    } else {
      headlineWidget = Text(headline, style: headlineStyle);
    }

    return Container(
      constraints: const BoxConstraints(minHeight: 178),
      decoration: BoxDecoration(
        gradient: AppGradients.brand,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.35),
            blurRadius: 36,
            offset: const Offset(0, 18),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(22, 22, 18, 22),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -20,
            bottom: -30,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.07),
                border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
              ),
            ),
          ),
          Positioned(
            right: 50,
            top: -20,
            child: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.05),
              ),
            ),
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Left: text + button
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    headlineWidget,
                    const SizedBox(height: 8),
                    Text(
                      "Keep going! You're building\nconsistency that matters.",
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.90),
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 18),
                    GestureDetector(
                      onTap: onViewDay,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.10),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'View your day',
                              style: GoogleFonts.manrope(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppColors.brandPrimary,
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.chevron_right_rounded,
                              size: 18,
                              color: AppColors.brandPrimary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),

              // Right: progress ring
              ProgressRing(
                value: progress,
                size: 112,
                strokeWidth: 9,
                trackColor: Colors.white.withValues(alpha: 0.22),
                gradientColors: [AppColors.brandPinkSoft, Colors.white],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${(progress * 100).round()}%',
                      style: GoogleFonts.manrope(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Day Progress',
                      style: GoogleFonts.manrope(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Next Prayer Card
// ═════════════════════════════════════════════════════════════════════════════

class _NextPrayerCard extends StatelessWidget {
  final DashboardNextPrayer nextPrayer;
  final VoidCallback onTap;

  const _NextPrayerCard({required this.nextPrayer, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = nextPrayer.enabled
        ? _prayerDisplayName(nextPrayer.name)
        : 'Prayer';
    final timeStr = nextPrayer.enabled ? _prayerTimeLabel(nextPrayer) : '—';
    final countdown = nextPrayer.enabled
        ? _prayerCountdown(nextPrayer.scheduledAt)
        : 'Open Prayer to sync';

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.featPrayerSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.nightlight_rounded,
                  size: 16,
                  color: AppColors.brandViolet,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Next Prayer',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textBody,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              timeStr,
              style: GoogleFonts.manrope(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: AppColors.brandPrimary,
                letterSpacing: -0.5,
              ),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            countdown,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: AppColors.textHint,
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: _MiniMasjidIcon(
              color: AppColors.brandViolet.withValues(alpha: 0.22),
              size: 70,
            ),
          ),
          const Spacer(),
          GestureDetector(
            onTap: onTap,
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: AppShadows.soft,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Prayer Times',
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.brandPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.chevron_right_rounded,
                    size: 14,
                    color: AppColors.brandPrimary,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Focus Session Card
// ═════════════════════════════════════════════════════════════════════════════

class _FocusSessionCard extends StatelessWidget {
  final int suggestedMinutes;
  final VoidCallback onTap;

  const _FocusSessionCard({
    required this.suggestedMinutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final ringValue = (suggestedMinutes / 60.0).clamp(0.0, 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Label
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.featFocusSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.gps_fixed_rounded,
                  size: 16,
                  color: AppColors.brandPink,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Focus Session',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textBody,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Ring
          Center(
            child: _FocusDial(
              child: ProgressRing(
                value: ringValue,
                size: 112,
                strokeWidth: 10,
                trackColor: AppColors.bgSurfaceLavender,
                gradientColors: [AppColors.brandPrimary, AppColors.brandPink],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$suggestedMinutes:00',
                      style: GoogleFonts.manrope(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      'Focus Time',
                      style: GoogleFonts.manrope(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          const Spacer(),

          // Button
          GestureDetector(
            onTap: () {
              HapticFeedback.lightImpact();
              onTap();
            },
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                gradient: AppGradients.action,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                boxShadow: AppShadows.glowPurple,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.22),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Start Focus',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Today's Tasks Card
// ═════════════════════════════════════════════════════════════════════════════

class _TodayTasksCard extends StatelessWidget {
  final List<DashboardTopTask> topTasks;
  final Future<void> Function(String id) onCompleteTask;
  final VoidCallback onViewAll;

  const _TodayTasksCard({
    required this.topTasks,
    required this.onCompleteTask,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final tasks = topTasks.take(3).toList();

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header row
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppColors.featTasksSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.task_alt_rounded,
                  size: 17,
                  color: AppColors.featTasks,
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                "Today's Tasks",
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onViewAll,
                child: Row(
                  children: [
                    Text(
                      'View all',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 12,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Task rows
          if (tasks.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.s20),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 40,
                      color: AppColors.borderSoft,
                    ),
                    const SizedBox(height: AppSpacing.s8),
                    Text(
                      'No tasks for today',
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ...tasks.asMap().entries.map((e) {
              final i = e.key;
              final task = e.value;
              return _TaskRow(
                task: task,
                showDivider: i > 0,
                onComplete: () => onCompleteTask(task.id),
              );
            }),
        ],
      ),
    );
  }
}

class _TaskRow extends StatelessWidget {
  final DashboardTopTask task;
  final bool showDivider;
  final VoidCallback onComplete;

  const _TaskRow({
    required this.task,
    required this.showDivider,
    required this.onComplete,
  });

  Color _bubbleBg(String p) {
    if (p == 'high') return AppColors.errorSoft;
    if (p == 'medium') return AppColors.bgSurfaceLavender;
    return AppColors.brandPinkSoft;
  }

  Color _bubbleColor(String p) {
    if (p == 'high') return AppColors.errorColor;
    if (p == 'medium') return AppColors.brandViolet;
    return AppColors.brandPink;
  }

  IconData _bubbleIcon(String p) {
    if (p == 'high') return Icons.priority_high_rounded;
    if (p == 'medium') return Icons.remove_rounded;
    return Icons.task_alt_rounded;
  }

  String _priorityLabel(String p) {
    if (p == 'high') return 'High Priority';
    if (p == 'medium') return 'Medium Priority';
    return 'Normal Priority';
  }

  String _statusLabel(String status) {
    if (status == 'completed') return 'Done';
    if (status == 'in_progress') return 'In Progress';
    return 'Today';
  }

  Color _statusBg(String status) {
    if (status == 'completed') return AppColors.bgSurfaceLavender;
    if (status == 'in_progress') return AppColors.bgSurfaceLavender;
    return AppColors.brandPinkSoft;
  }

  Color _statusColor(String status) {
    if (status == 'completed') return AppColors.brandViolet;
    if (status == 'in_progress') return AppColors.brandPrimary;
    return AppColors.brandPink;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showDivider)
          Divider(height: 1, thickness: 1, color: AppColors.dividerColor),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 11),
          child: Row(
            children: [
              // Icon bubble
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _bubbleBg(task.priority),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(
                  _bubbleIcon(task.priority),
                  size: 19,
                  color: _bubbleColor(task.priority),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),

              // Title + sub
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _priorityLabel(task.priority),
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.s8),

              // Status badge
              Container(
                height: 26,
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: _statusBg(task.status),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Center(
                  child: Text(
                    _statusLabel(task.status),
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(task.status),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),

              // Complete button
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  onComplete();
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.brandPrimary, width: 2),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    size: 16,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Habits Overview Card
// ═════════════════════════════════════════════════════════════════════════════

class _HabitsCard extends StatelessWidget {
  final DashboardHabitSnapshot snapshot;
  final VoidCallback onTap;

  const _HabitsCard({required this.snapshot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = snapshot.activeCount;
    final completed = snapshot.completedToday;
    final ratio = active == 0 ? 0.0 : (completed / active).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.xl2),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: AppShadows.card,
        ),
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(
                  Icons.bar_chart_rounded,
                  size: 16,
                  color: AppColors.brandPrimary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Habits Overview',
                    style: GoogleFonts.manrope(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const Icon(
                  Icons.more_horiz_rounded,
                  size: 16,
                  color: AppColors.textHint,
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Ring + stats
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Streak ring
                ProgressRing(
                  value: ratio,
                  size: 64,
                  strokeWidth: 6,
                  trackColor: AppColors.bgSurfaceLavender,
                  gradientColors: [AppColors.brandPink, AppColors.brandPrimary],
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$completed',
                        style: GoogleFonts.manrope(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                          height: 1.0,
                        ),
                      ),
                      const Text('🔥', style: TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Completed',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                      Text(
                        '$completed / $active',
                        style: GoogleFonts.manrope(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: ratio,
                          backgroundColor: AppColors.bgSurfaceLavender,
                          valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.brandPrimary,
                          ),
                          minHeight: 5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This Week',
                        style: GoogleFonts.manrope(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textHint,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// AI Suggestion Card
// ═════════════════════════════════════════════════════════════════════════════

class _AiSuggestionCard extends StatelessWidget {
  final DashboardAiPlanCard plan;
  final VoidCallback onTap;

  const _AiSuggestionCard({required this.plan, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final preview = plan.preview.trim().isEmpty
        ? "Small steps today create big changes tomorrow. You've got this!"
        : plan.preview.trim();

    return Container(
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.all(14),
      child: Stack(
        children: [
          Positioned(
            right: -8,
            bottom: -6,
            child: _RobotIllustration(
              size: 72,
              color: AppColors.brandPrimary.withValues(alpha: 0.88),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.auto_awesome_rounded,
                    size: 16,
                    color: AppColors.brandPink,
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      plan.title.trim().isEmpty ? 'AI Suggestion' : plan.title,
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 42),
                  child: Text(
                    preview,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textBody,
                      height: 1.45,
                    ),
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),
              GestureDetector(
                onTap: onTap,
                child: Row(
                  children: [
                    Text(
                      'Ask AI anything',
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.brandPrimary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 11,
                      color: AppColors.brandPrimary,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// State cards: loading / error / empty
// ═════════════════════════════════════════════════════════════════════════════

class _MiniMasjidIcon extends StatelessWidget {
  final Color color;
  final double size;

  const _MiniMasjidIcon({required this.color, this.size = 54});

  @override
  Widget build(BuildContext context) {
    final w = size;
    final h = size * 0.85;
    return SizedBox(
      width: w,
      height: h,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          // Main body
          Positioned(
            bottom: 0,
            left: w * 0.14,
            right: w * 0.14,
            child: Container(
              height: h * 0.40,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(w * 0.18),
                ),
              ),
            ),
          ),
          // Dome
          Positioned(
            bottom: h * 0.34,
            child: Container(
              width: w * 0.50,
              height: w * 0.50,
              decoration: BoxDecoration(
                color: AppColors.brandPinkSoft.withValues(alpha: 0.70),
                shape: BoxShape.circle,
              ),
            ),
          ),
          // Left minaret
          Positioned(
            bottom: 0,
            left: 0,
            child: Container(
              width: w * 0.12,
              height: h * 0.72,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          // Right minaret
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: w * 0.12,
              height: h * 0.60,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FocusDial extends StatelessWidget {
  final Widget child;

  const _FocusDial({required this.child});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _FocusDialPainter(),
      child: Padding(padding: const EdgeInsets.all(6), child: child),
    );
  }
}

class _FocusDialPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2 - 4;
    final paint = Paint()
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    for (var i = 0; i < 44; i++) {
      final angle = -math.pi / 2 + (math.pi * 2 * i / 44);
      final isMajor = i % 5 == 0;
      final inner = radius - (isMajor ? 8 : 5);
      final outer = radius - 1;
      paint.color = (isMajor ? AppColors.brandPink : AppColors.brandPrimary)
          .withValues(alpha: isMajor ? 0.28 : 0.16);
      canvas.drawLine(
        center + Offset(math.cos(angle) * inner, math.sin(angle) * inner),
        center + Offset(math.cos(angle) * outer, math.sin(angle) * outer),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _RobotIllustration extends StatelessWidget {
  final double size;
  final Color color;

  const _RobotIllustration({required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: size * 0.72,
            height: size * 0.62,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(size * 0.24),
              boxShadow: AppShadows.soft,
            ),
          ),
          Positioned(
            top: size * 0.20,
            child: Container(
              width: size * 0.48,
              height: size * 0.32,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, AppColors.textHeading],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(size * 0.14),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _RobotEye(color: AppColors.brandPinkSoft, size: size * 0.06),
                  SizedBox(width: size * 0.08),
                  _RobotEye(color: AppColors.brandPinkSoft, size: size * 0.06),
                ],
              ),
            ),
          ),
          Positioned(
            top: size * 0.08,
            child: Container(
              width: 4,
              height: size * 0.14,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
          ),
          Positioned(
            top: size * 0.04,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          Positioned(
            left: size * 0.06,
            child: CircleAvatar(
              radius: size * 0.09,
              backgroundColor: AppColors.bgSurfaceLavender,
            ),
          ),
          Positioned(
            right: size * 0.06,
            child: CircleAvatar(
              radius: size * 0.09,
              backgroundColor: AppColors.bgSurfaceLavender,
            ),
          ),
        ],
      ),
    );
  }
}

class _RobotEye extends StatelessWidget {
  final Color color;
  final double size;

  const _RobotEye({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size * 1.4,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s40),
        child: CircularProgressIndicator(
          color: AppColors.brandPrimary,
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Dashboard failed to load',
            style: GoogleFonts.manrope(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.errorColor,
            ),
          ),
          const SizedBox(height: AppSpacing.s6),
          Text(
            message,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          GestureDetector(
            onTap: onRetry,
            child: Container(
              height: 38,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: BorderRadius.circular(AppRadius.pill),
                border: Border.all(
                  color: AppColors.errorColor.withValues(alpha: 0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.refresh_rounded,
                    size: 16,
                    color: AppColors.errorColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Retry',
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.errorColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s28),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Center(
        child: Text(
          'Dashboard is empty',
          style: GoogleFonts.manrope(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppColors.textHint,
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Dashboard customization sheet — logic preserved exactly from original
// ═════════════════════════════════════════════════════════════════════════════

class _DashboardCustomizeSheet extends ConsumerStatefulWidget {
  final List<String> currentWidgets;

  const _DashboardCustomizeSheet({required this.currentWidgets});

  @override
  ConsumerState<_DashboardCustomizeSheet> createState() =>
      _DashboardCustomizeSheetState();
}

class _DashboardCustomizeSheetState
    extends ConsumerState<_DashboardCustomizeSheet> {
  late final List<String> _orderedWidgets;
  late final Set<String> _enabledWidgets;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enabledWidgets = widget.currentWidgets.toSet();
    _orderedWidgets = [
      ...widget.currentWidgets,
      ...defaultDashboardWidgets.where(
        (id) => !widget.currentWidgets.contains(id),
      ),
    ];
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final enabled = _orderedWidgets
        .where((id) => _enabledWidgets.contains(id))
        .toList();
    final saved = await ref
        .read(dashboardProvider.notifier)
        .updateDashboardWidgets(enabled);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context);
    } else {
      final error =
          ref.read(dashboardProvider).error ?? 'Dashboard not updated';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.sheetBr,
          boxShadow: AppShadows.floating,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.s20,
            AppSpacing.s16,
            AppSpacing.s20,
            AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppGradients.action,
                      borderRadius: BorderRadius.circular(AppRadius.md),
                      boxShadow: AppShadows.glowPurple,
                    ),
                    child: const Icon(
                      Icons.dashboard_customize_outlined,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.s12),
                  Expanded(
                    child: Text(
                      'Customize Dashboard',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    style: IconButton.styleFrom(
                      backgroundColor: AppColors.bgSurfaceSoft,
                    ),
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(
                      Icons.close_rounded,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.s16),
              SizedBox(
                height: 420,
                child: ReorderableListView.builder(
                  itemCount: _orderedWidgets.length,
                  onReorder: (oldIndex, newIndex) {
                    setState(() {
                      if (newIndex > oldIndex) newIndex -= 1;
                      final item = _orderedWidgets.removeAt(oldIndex);
                      _orderedWidgets.insert(newIndex, item);
                    });
                  },
                  itemBuilder: (context, index) {
                    final id = _orderedWidgets[index];
                    final enabled = _enabledWidgets.contains(id);
                    return Container(
                      key: ValueKey(id),
                      margin: const EdgeInsets.only(bottom: AppSpacing.s8),
                      decoration: BoxDecoration(
                        color: enabled
                            ? AppColors.bgSurfaceLavender
                            : AppColors.bgSurfaceSoft,
                        borderRadius: BorderRadius.circular(AppRadius.lg),
                        border: Border.all(
                          color: enabled
                              ? AppColors.brandPrimary.withValues(alpha: 0.25)
                              : AppColors.borderSoft,
                        ),
                      ),
                      child: SwitchListTile(
                        value: enabled,
                        activeThumbColor: Colors.white,
                        activeTrackColor: AppColors.brandPrimary,
                        secondary: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.72),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Icon(
                            _dashboardWidgetIcon(id),
                            color: enabled
                                ? AppColors.brandPrimary
                                : AppColors.textBody,
                            size: 19,
                          ),
                        ),
                        title: Text(
                          _dashboardWidgetLabel(id),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.manrope(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textHeading,
                          ),
                        ),
                        subtitle: Text(
                          'Drag to reorder',
                          style: GoogleFonts.manrope(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: AppColors.textHint,
                          ),
                        ),
                        onChanged: (enabled) {
                          setState(() {
                            if (enabled) {
                              _enabledWidgets.add(id);
                            } else {
                              _enabledWidgets.remove(id);
                            }
                          });
                        },
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
              _isSaving
                  ? const CircularProgressIndicator()
                  : _DashboardSheetButton(onPressed: _save),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardSheetButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DashboardSheetButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: AppButtonHeight.primary,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: AppGradients.action,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          boxShadow: AppShadows.glowPurple,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(AppRadius.lg),
            onTap: onPressed,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.save_outlined, color: Colors.white),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    'Save',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Helper functions — preserved from original
// ═════════════════════════════════════════════════════════════════════════════

String _dashboardWidgetLabel(String widgetId) {
  return switch (widgetId) {
    'top_tasks' => 'Top tasks',
    'next_prayer' => 'Next prayer',
    'habit_snapshot' => 'Habits',
    'journal_prompt' => 'Journal prompt',
    'ai_plan' => 'AI plan',
    'focus_shortcut' => 'Focus shortcut',
    'productivity_score' => 'Productivity score',
    'quran_goal' => 'Spiritual today',
    _ => widgetId,
  };
}

IconData _dashboardWidgetIcon(String widgetId) {
  return switch (widgetId) {
    'top_tasks' => Icons.task_alt_outlined,
    'next_prayer' => Icons.mosque_outlined,
    'habit_snapshot' => Icons.track_changes_outlined,
    'journal_prompt' => Icons.edit_note_outlined,
    'ai_plan' => Icons.auto_awesome_outlined,
    'focus_shortcut' => Icons.timer_outlined,
    'productivity_score' => Icons.insights_outlined,
    'quran_goal' => Icons.menu_book_outlined,
    _ => Icons.dashboard_customize_outlined,
  };
}

String _prayerDisplayName(String? name) {
  return switch (name) {
    'fajr' => 'Fajr',
    'dhuhr' => 'Dhuhr',
    'asr' => 'Asr',
    'maghrib' => 'Maghrib',
    'isha' => 'Isha',
    null || '' => 'Next prayer',
    _ => name,
  };
}

String _prayerTimeLabel(DashboardNextPrayer nextPrayer) {
  final scheduledAt = nextPrayer.scheduledAt;
  if (scheduledAt == null || scheduledAt.length < 16) return '—';
  final parsed = DateTime.tryParse(scheduledAt);
  if (parsed == null) return '—';
  final local = parsed.toLocal();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _prayerCountdown(String? scheduledAt) {
  if (scheduledAt == null) return '';
  final parsed = DateTime.tryParse(scheduledAt);
  if (parsed == null) return '';
  final diff = parsed.toLocal().difference(DateTime.now());
  if (diff.isNegative) return 'Time passed';
  final h = diff.inHours;
  final m = diff.inMinutes % 60;
  if (h > 0) return 'in ${h}h ${m}m';
  return 'in ${m}m';
}
