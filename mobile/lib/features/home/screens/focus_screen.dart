import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../routes/app_routes.dart';
import '../../focus/models/focus_model.dart';
import '../../focus/providers/focus_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../widgets/progress_ring.dart';

// ── Constants ─────────────────────────────────────────────────────────────────

const double _kNavClearance = 138.0;

class _Preset {
  final String title;
  final String subtitle;
  final int focusMin;
  final int breakMin;

  const _Preset(this.title, this.subtitle, this.focusMin, this.breakMin);
}

const _kPresets = [
  _Preset('25 / 5', 'Pomodoro', 25, 5),
  _Preset('50 / 10', 'Deep Work', 50, 10),
  _Preset('90 min', 'Study Block', 90, 15),
  _Preset('Custom', 'Set your own', -1, -1),
];

// ── Screen ────────────────────────────────────────────────────────────────────

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusProvider.notifier).loadAnalytics();
      ref.read(focusProvider.notifier).loadRecommendation();
      ref.read(focusProvider.notifier).loadReadiness();
      if (ref.read(tasksProvider).tasks.isEmpty) {
        ref.read(tasksProvider.notifier).loadTasks();
      }
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  bool _isBreakSession(String sessionType) {
    return sessionType == 'short_break' || sessionType == 'long_break';
  }

  String _sessionLabel(String sessionType) {
    switch (sessionType) {
      case 'short_break':
        return 'Short break';
      case 'long_break':
        return 'Long break';
      case 'deep_work':
        return 'Deep work';
      default:
        return 'Focus session';
    }
  }

  Future<bool> _confirmLeaveDistractionMode() async {
    final leave = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Leave focus session?'),
        content: const Text(
          'Distraction-free mode is active. Your timer will keep running if you leave.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Stay'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Leave'),
          ),
        ],
      ),
    );
    return leave ?? false;
  }

  Future<void> _handleBlockedPop() async {
    if (await _confirmLeaveDistractionMode() && mounted) {
      context.go(AppRoutes.home);
    }
  }

  Future<void> _showTaskChooser(List<TaskModel> tasks) async {
    var sourceTasks = tasks;
    if (sourceTasks.isEmpty) {
      await ref.read(tasksProvider.notifier).loadTasks();
      if (!mounted) return;
      sourceTasks = ref.read(tasksProvider).tasks;
    }

    final candidates = sourceTasks
        .where((task) => task.status != 'completed' && !task.isDeleted)
        .toList();
    if (candidates.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pending tasks available.')),
      );
      return;
    }

    final selected = await showModalBottomSheet<TaskModel>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.sheetBr,
          ),
          child: SafeArea(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    margin: const EdgeInsets.only(top: 12, bottom: 8),
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.borderSoft,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                  child: Text(
                    'Choose a task',
                    style: AppTextStyles.h3Light,
                  ),
                ),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: candidates.length,
                    separatorBuilder: (_, _) => Container(
                      height: 1,
                      color: AppColors.borderSoft,
                    ),
                    itemBuilder: (context, index) {
                      final task = candidates[index];
                      final estimate = task.estimatedMinutes == null
                          ? 'Default focus block'
                          : '${task.estimatedMinutes}m estimate';
                      return InkWell(
                        onTap: () => Navigator.of(context).pop(task),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: AppColors.featTasksSoft,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.sm),
                                ),
                                child: const Icon(
                                  Icons.task_alt,
                                  size: 18,
                                  color: AppColors.featTasks,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: AppTextStyles.h4Light,
                                    ),
                                    Text(
                                      '${task.priority} priority · $estimate',
                                      style:
                                          AppTextStyles.captionLight,
                                    ),
                                  ],
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right,
                                size: 18,
                                color: AppColors.textHint,
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selected != null && mounted) {
      await ref
          .read(focusProvider.notifier)
          .startFocusSession(taskId: selected.id);
    }
  }

  double _ringProgress(FocusState state) {
    if (state.activeSession == null) return 0.0;
    final total = state.activeSession!.plannedMinutes * 60;
    if (total == 0) return 0.0;
    return (1.0 - state.remainingSeconds / total).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final tasksState = ref.watch(tasksProvider);
    final hasActive = state.activeSession != null;
    final distractionActive = hasActive && state.distractionFreeMode;
    final estimatedTasks = tasksState.tasks
        .where(
          (task) =>
              task.status != 'completed' &&
              !task.isDeleted &&
              (task.estimatedMinutes ?? 0) > 0,
        )
        .toList();
    final activeTask = _taskById(tasksState.tasks, state.activeSession?.taskId);
    final progress = _ringProgress(state);

    // ── Distraction-free immersive mode ───────────────────────────────────
    if (distractionActive) {
      return PopScope(
        canPop: false,
        onPopInvokedWithResult: (didPop, _) {
          if (!didPop) _handleBlockedPop();
        },
        child: Scaffold(
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFF3EFFF),
                  Color(0xFFFDF5FF),
                  Color(0xFFFFEAF6),
                ],
                stops: [0.0, 0.5, 1.0],
              ),
            ),
            child: SafeArea(
              child: Column(
                children: [
                  // Immersive top bar
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Row(
                      children: [
                        _ImmersiveIconBtn(
                          icon: Icons.arrow_back_rounded,
                          onTap: _handleBlockedPop,
                        ),
                        Expanded(
                          child: Text(
                            'FOCUSING',
                            textAlign: TextAlign.center,
                            style: GoogleFonts.manrope(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 2,
                              color: AppColors.textHeading.withValues(
                                alpha: 0.7,
                              ),
                            ),
                          ),
                        ),
                        _ImmersiveIconBtn(
                          icon: Icons.more_horiz_rounded,
                          onTap: () =>
                              context.push(AppRoutes.focusSettings),
                        ),
                      ],
                    ),
                  ),

                  // Session label
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Text(
                      state.activeSession != null
                          ? _sessionLabel(state.activeSession!.sessionType)
                          : 'Focus session',
                      style: AppTextStyles.bodySmall(
                        AppColors.textHeading.withValues(alpha: 0.5),
                      ),
                    ),
                  ),

                  // Ring + Timer (centered in expanded area)
                  Expanded(
                    child: Center(
                      child: ProgressRing(
                        value: progress,
                        size: 260,
                        strokeWidth: 14,
                        trackColor:
                            AppColors.brandPrimary.withValues(alpha: 0.06),
                        gradientColors: const [
                          AppColors.brandPink,
                          Color(0xFFFFB547),
                        ],
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _formatTime(state.remainingSeconds),
                              style: GoogleFonts.manrope(
                                fontSize: 56,
                                fontWeight: FontWeight.w800,
                                color: AppColors.textHeading,
                                letterSpacing: -2,
                              ),
                            ),
                            if (activeTask != null)
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4),
                                child: Text(
                                  activeTask.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.captionLight,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Bottom controls
                  Padding(
                    padding: const EdgeInsets.fromLTRB(40, 0, 40, 40),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        if (_isBreakSession(
                          state.activeSession?.sessionType ?? '',
                        ))
                          _ControlBtn(
                            icon: Icons.skip_next_rounded,
                            label: 'Skip',
                            onTap: () =>
                                ref.read(focusProvider.notifier).skipBreak(),
                          )
                        else
                          const SizedBox(width: 64),
                        _ControlBtn(
                          icon: Icons.stop_rounded,
                          label: 'End',
                          filled: true,
                          onTap: () {
                            HapticFeedback.mediumImpact();
                            ref.read(focusProvider.notifier).cancelSession();
                          },
                        ),
                        _ControlBtn(
                          icon: Icons.check_rounded,
                          label: 'Done',
                          onTap: () {
                            HapticFeedback.lightImpact();
                            ref
                                .read(focusProvider.notifier)
                                .completeSession();
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    // ── Normal / non-distraction mode ─────────────────────────────────────
    return PopScope(
      canPop: true,
      child: Scaffold(
        backgroundColor: AppColors.bgApp,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              AppSpacing.s20,
              AppSpacing.screenH,
              _kNavClearance,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header ───────────────────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Focus', style: AppTextStyles.h1Light),
                          const SizedBox(height: 2),
                          Text(
                            'Build deep work one session at a time.',
                            style: AppTextStyles.bodySmallLight,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => context.push(AppRoutes.focusSettings),
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Icon(
                          Icons.settings_outlined,
                          size: 20,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),

                // ── Analytics row (if loaded) ─────────────────────────
                if (state.analytics != null) ...[
                  _AnalyticsRow(analytics: state.analytics!),
                  const SizedBox(height: AppSpacing.s16),
                ],

                // ── Main focus card ───────────────────────────────────
                _MainFocusCard(
                  state: state,
                  hasActive: hasActive,
                  progress: progress,
                  activeTask: activeTask,
                  formatTime: _formatTime,
                  isBreak: hasActive
                      ? _isBreakSession(state.activeSession!.sessionType)
                      : false,
                  sessionLabel: hasActive
                      ? _sessionLabel(state.activeSession!.sessionType)
                      : null,
                  onStart: () => ref
                      .read(focusProvider.notifier)
                      .startFocusSession(),
                  onCancel: () =>
                      ref.read(focusProvider.notifier).cancelSession(),
                  onComplete: () =>
                      ref.read(focusProvider.notifier).completeSession(),
                  onSkipBreak: () =>
                      ref.read(focusProvider.notifier).skipBreak(),
                  onShortBreak: () => ref
                      .read(focusProvider.notifier)
                      .startBreakSession(longBreak: false),
                  onLongBreak: () => ref
                      .read(focusProvider.notifier)
                      .startBreakSession(longBreak: true),
                  isLoading: state.isLoading,
                  error: state.error,
                  focusMinutes: state.focusMinutes,
                  shortBreakMinutes: state.shortBreakMinutes,
                  longBreakMinutes: state.longBreakMinutes,
                ),

                // ── Error ─────────────────────────────────────────────
                if (state.error != null && !hasActive) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.s12),
                    decoration: BoxDecoration(
                      color: AppColors.errorSoft,
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      border: Border.all(
                        color: AppColors.errorColor.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      state.error!,
                      style: AppTextStyles.body(AppColors.errorColor),
                    ),
                  ),
                ],

                // ── Quick presets (only when idle) ────────────────────
                if (!hasActive) ...[
                  const SizedBox(height: AppSpacing.s24),
                  Text('Quick presets', style: AppTextStyles.h3Light),
                  const SizedBox(height: AppSpacing.s12),
                  _QuickPresets(
                    currentFocusMin: state.focusMinutes,
                    onSelect: (p) {
                      if (p.focusMin < 0) {
                        context.push(AppRoutes.focusSettings);
                        return;
                      }
                      HapticFeedback.selectionClick();
                      ref
                          .read(focusProvider.notifier)
                          .setFocusMinutes(p.focusMin);
                      ref
                          .read(focusProvider.notifier)
                          .setShortBreakMinutes(p.breakMin);
                    },
                  ),
                ],

                // ── Today stats row (only when idle) ──────────────────
                if (!hasActive && state.analytics != null) ...[
                  const SizedBox(height: AppSpacing.s24),
                  Text('Today', style: AppTextStyles.h3Light),
                  const SizedBox(height: AppSpacing.s12),
                  _TodayStats(analytics: state.analytics!),
                ],

                // ── Readiness card ────────────────────────────────────
                if (!hasActive) ...[
                  const SizedBox(height: AppSpacing.s20),
                  _FocusReadinessCard(
                    state: state,
                    onRefresh: () =>
                        ref.read(focusProvider.notifier).loadReadiness(),
                  ),
                ],

                // ── Recommendation card ───────────────────────────────
                if (!hasActive) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _FocusRecommendationCard(
                    state: state,
                    onAccept: () => ref
                        .read(focusProvider.notifier)
                        .startRecommendedFocus(),
                    onChooseAnother: () =>
                        _showTaskChooser(tasksState.tasks),
                    onRefresh: () =>
                        ref.read(focusProvider.notifier).loadRecommendation(),
                  ),
                ],

                // ── Task with pomodoros (active) ──────────────────────
                if (hasActive && activeTask != null) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _ActivePomodoroProgress(task: activeTask),
                ],

                // ── Settings ──────────────────────────────────────────
                if (!hasActive) ...[
                  const SizedBox(height: AppSpacing.s20),
                  _FocusSettings(state: state),
                ],

                // ── Estimated pomodoros ───────────────────────────────
                if (!hasActive) ...[
                  const SizedBox(height: AppSpacing.s16),
                  _EstimatedPomodoros(
                    tasks: estimatedTasks,
                    focusMinutes: state.focusMinutes,
                  ),
                ],

                // ── Report summary ────────────────────────────────────
                const SizedBox(height: AppSpacing.s16),
                _ReportSummary(state: state),

                // ── Recent sessions ───────────────────────────────────
                if (state.sessions.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s24),
                  Text('Recent Sessions', style: AppTextStyles.h3Light),
                  const SizedBox(height: AppSpacing.s12),
                  ...state.sessions
                      .take(5)
                      .map((s) => _SessionTile(session: s)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

TaskModel? _taskById(List<TaskModel> tasks, String? taskId) {
  if (taskId == null) return null;
  for (final task in tasks) {
    if (task.id == taskId) return task;
  }
  return null;
}

// ── Immersive control button ──────────────────────────────────────────────────

class _ImmersiveIconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _ImmersiveIconBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          border: Border.all(
            color: AppColors.borderSoft,
          ),
        ),
        child: Icon(icon, size: 18, color: AppColors.textHeading),
      ),
    );
  }
}

class _ControlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool filled;
  final VoidCallback onTap;

  const _ControlBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: filled
                  ? AppColors.textHeading
                  : Colors.white.withValues(alpha: 0.7),
              shape: BoxShape.circle,
              border: filled
                  ? null
                  : Border.all(color: AppColors.borderSoft),
              boxShadow: filled ? AppShadows.soft : null,
            ),
            child: Icon(
              icon,
              size: 26,
              color: filled ? Colors.white : AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: AppTextStyles.caption(
              AppColors.textHeading.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main focus card ───────────────────────────────────────────────────────────

class _MainFocusCard extends StatelessWidget {
  final FocusState state;
  final bool hasActive;
  final double progress;
  final TaskModel? activeTask;
  final String Function(int) formatTime;
  final bool isBreak;
  final String? sessionLabel;
  final VoidCallback onStart;
  final VoidCallback onCancel;
  final VoidCallback onComplete;
  final VoidCallback onSkipBreak;
  final VoidCallback onShortBreak;
  final VoidCallback onLongBreak;
  final bool isLoading;
  final String? error;
  final int focusMinutes;
  final int shortBreakMinutes;
  final int longBreakMinutes;

  const _MainFocusCard({
    required this.state,
    required this.hasActive,
    required this.progress,
    required this.activeTask,
    required this.formatTime,
    required this.isBreak,
    required this.sessionLabel,
    required this.onStart,
    required this.onCancel,
    required this.onComplete,
    required this.onSkipBreak,
    required this.onShortBreak,
    required this.onLongBreak,
    required this.isLoading,
    required this.error,
    required this.focusMinutes,
    required this.shortBreakMinutes,
    required this.longBreakMinutes,
  });

  @override
  Widget build(BuildContext context) {
    final timerText = hasActive
        ? formatTime(state.remainingSeconds)
        : formatTime(focusMinutes * 60);
    final subLabel = hasActive
        ? (sessionLabel ?? 'Focus session')
        : 'Focus Time';
    final cardLabel = hasActive
        ? (isBreak ? 'Break session' : 'Pomodoro · Round 1 of 4')
        : 'Pomodoro · Round 1 of 4';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: AppGradients.focus,
        borderRadius: BorderRadius.circular(AppRadius.xl3),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPink.withValues(alpha: 0.30),
            blurRadius: 32,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: Column(
        children: [
          // Session label
          Text(
            cardLabel,
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 16),

          // Progress ring with timer
          ProgressRing(
            value: progress,
            size: 200,
            strokeWidth: 12,
            trackColor: Colors.white.withValues(alpha: 0.2),
            gradientColors: const [Colors.white, AppColors.brandGold],
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timerText,
                  style: GoogleFonts.manrope(
                    fontSize: 48,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: -1.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subLabel,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Controls
          if (hasActive) ...[
            // Active: Cancel + Done
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      onCancel();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'Cancel',
                          style: GoogleFonts.manrope(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      onComplete();
                    },
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_rounded,
                              size: 18,
                              color: isBreak
                                  ? AppColors.successColor
                                  : AppColors.brandPrimary,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              'Done',
                              style: GoogleFonts.manrope(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: isBreak
                                    ? AppColors.successColor
                                    : AppColors.brandPrimary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            // Skip break
            if (isBreak) ...[
              const SizedBox(height: 10),
              GestureDetector(
                onTap: onSkipBreak,
                child: Text(
                  'Skip break →',
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ] else if (isLoading) ...[
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withValues(alpha: 0.9),
                ),
              ),
            ),
          ] else ...[
            // Idle: Start Focus button
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onStart();
              },
              child: Container(
                height: 56,
                padding: const EdgeInsets.symmetric(horizontal: 40),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.12),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      size: 20,
                      color: AppColors.brandPink,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Start Focus',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brandPink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Break buttons
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: onShortBreak,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.coffee_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${shortBreakMinutes}m break',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onLongBreak,
                    child: Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Center(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.weekend_rounded,
                              size: 14,
                              color: Colors.white,
                            ),
                            const SizedBox(width: 5),
                            Text(
                              '${longBreakMinutes}m long',
                              style: GoogleFonts.manrope(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Quick presets ─────────────────────────────────────────────────────────────

class _QuickPresets extends StatelessWidget {
  final int currentFocusMin;
  final void Function(_Preset) onSelect;

  const _QuickPresets({
    required this.currentFocusMin,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 2.2,
      children: _kPresets.map((p) {
        final selected = p.focusMin == currentFocusMin;
        return GestureDetector(
          onTap: () => onSelect(p),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(
                color: selected
                    ? AppColors.brandPink
                    : AppColors.borderSoft,
                width: selected ? 2 : 1,
              ),
              boxShadow: selected ? AppShadows.glowPink : AppShadows.soft,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  p.title,
                  style: AppTextStyles.h4Light,
                ),
                const SizedBox(height: 2),
                Text(p.subtitle, style: AppTextStyles.captionLight),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

// ── Today stats row ───────────────────────────────────────────────────────────

class _TodayStats extends StatelessWidget {
  final FocusAnalytics analytics;

  const _TodayStats({required this.analytics});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        _minutesToLabel(analytics.todayMinutes),
        'Focused',
      ),
      ('${analytics.todaySessions}', 'Sessions'),
      ('${analytics.currentStreakDays}d', 'Streak'),
    ];

    return Row(
      children: items.asMap().entries.map((entry) {
        final i = entry.key;
        final item = entry.value;
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(left: i == 0 ? 0 : 8),
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: AppShadows.soft,
            ),
            child: Column(
              children: [
                ShaderMask(
                  shaderCallback: (bounds) =>
                      AppGradients.action.createShader(bounds),
                  child: Text(
                    item.$1,
                    style: GoogleFonts.manrope(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(item.$2, style: AppTextStyles.captionLight),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _minutesToLabel(int minutes) {
    if (minutes >= 60) {
      final h = minutes ~/ 60;
      final m = minutes % 60;
      return m == 0 ? '${h}h' : '${h}h ${m}m';
    }
    return '${minutes}m';
  }
}

// ── Analytics grid ────────────────────────────────────────────────────────────

class _AnalyticsRow extends StatelessWidget {
  final FocusAnalytics analytics;

  const _AnalyticsRow({required this.analytics});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _StatCard(
            label: 'This week',
            value: '${analytics.weekMinutes}m',
            sub: '${analytics.weekSessions} sessions',
            color: AppColors.successColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Completion',
            value: '${analytics.completionRatePercent}%',
            sub: '${analytics.completedSessions} done',
            color: AppColors.prayerGold,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _StatCard(
            label: 'Average',
            value: '${analytics.averageSessionMinutes}m',
            sub: 'per session',
            color: AppColors.brandPrimary,
          ),
        ),
      ],
    );
  }
}

// ── Active pomodoro progress ──────────────────────────────────────────────────

class _ActivePomodoroProgress extends StatelessWidget {
  final TaskModel task;

  const _ActivePomodoroProgress({required this.task});

  @override
  Widget build(BuildContext context) {
    final estimate = task.estimatedPomodoros;
    final completed = task.completedPomodoros;
    final label = estimate > 0
        ? '$completed / $estimate Pomodoros'
        : '$completed Pomodoro${completed == 1 ? '' : 's'} completed';
    final value = estimate > 0
        ? (completed / estimate).clamp(0.0, 1.0)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: AppColors.featTasksSoft,
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: const Icon(
                  Icons.task_alt,
                  size: 16,
                  color: AppColors.featTasks,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  task.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.h4Light,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: estimate > 0 ? value : null,
              minHeight: 6,
              backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation<Color>(
                AppColors.brandPrimary,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(label, style: AppTextStyles.captionLight),
        ],
      ),
    );
  }
}

// ── Recommendation card ───────────────────────────────────────────────────────

class _FocusRecommendationCard extends StatelessWidget {
  final FocusState state;
  final VoidCallback onAccept;
  final VoidCallback onChooseAnother;
  final VoidCallback onRefresh;

  const _FocusRecommendationCard({
    required this.state,
    required this.onAccept,
    required this.onChooseAnother,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final recommendation = state.recommendation;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.featAISoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.auto_awesome,
                  size: 17,
                  color: AppColors.featAI,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Recommended Focus',
                  style: AppTextStyles.h4Light,
                ),
              ),
              GestureDetector(
                onTap:
                    state.isRecommendationLoading ? null : onRefresh,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: state.isRecommendationLoading
                      ? AppColors.textHint
                      : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (state.isRecommendationLoading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Choosing the best focus task...',
              style: AppTextStyles.captionLight,
            ),
          ] else if (state.recommendationError != null) ...[
            Text(
              state.recommendationError!,
              style: AppTextStyles.body(AppColors.errorColor),
            ),
          ] else if (recommendation == null) ...[
            Text(
              'No recommendation loaded yet.',
              style: AppTextStyles.bodySmallLight,
            ),
          ] else ...[
            Text(
              recommendation.title ?? 'No pending task',
              style: AppTextStyles.h4Light,
            ),
            const SizedBox(height: 4),
            Text(
              recommendation.explanation,
              style: AppTextStyles.bodySmallLight,
            ),
            const SizedBox(height: AppSpacing.s12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _InfoChip(
                  label:
                      '${recommendation.recommendedDurationMinutes} min',
                  icon: Icons.timer_outlined,
                ),
                _InfoChip(
                  label: '${recommendation.confidence} confidence',
                  icon: Icons.insights_outlined,
                ),
                _InfoChip(
                  label: recommendation.fallbackUsed
                      ? 'Rules fallback'
                      : 'AI explained',
                  icon: recommendation.fallbackUsed
                      ? Icons.rule
                      : Icons.auto_awesome,
                ),
              ],
            ),
            if (recommendation.reasons.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                recommendation.reasons.take(3).join(' · '),
                style: AppTextStyles.captionLight,
              ),
            ],
            const SizedBox(height: AppSpacing.s16),
            Row(
              children: [
                if (recommendation.hasTask)
                  Expanded(
                    child: GestureDetector(
                      onTap: onAccept,
                      child: Container(
                        height: AppButtonHeight.small,
                        decoration: BoxDecoration(
                          gradient: AppGradients.action,
                          borderRadius:
                              BorderRadius.circular(AppRadius.xl),
                          boxShadow: AppShadows.glowPurple,
                        ),
                        child: Center(
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.play_arrow_rounded,
                                size: 16,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Accept',
                                style: AppTextStyles.buttonLight,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                if (recommendation.hasTask) const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: onChooseAnother,
                    child: Container(
                      height: AppButtonHeight.small,
                      decoration: BoxDecoration(
                        color: AppColors.bgSurface,
                        borderRadius: BorderRadius.circular(AppRadius.xl),
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: Center(
                        child: Text(
                          'Choose task',
                          style: AppTextStyles.button(
                            AppColors.brandPrimary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Readiness card ────────────────────────────────────────────────────────────

class _FocusReadinessCard extends StatelessWidget {
  final FocusState state;
  final VoidCallback onRefresh;

  const _FocusReadinessCard({
    required this.state,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    final readiness = state.readiness;
    final label = readiness?.predictedFocusReadiness ?? 'unknown';
    final color = switch (label) {
      'high' => AppColors.successColor,
      'medium' => AppColors.warningColor,
      _ => AppColors.textBody,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
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
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(
                  Icons.psychology_alt_outlined,
                  size: 17,
                  color: color,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Focus Readiness',
                  style: AppTextStyles.h4Light,
                ),
              ),
              GestureDetector(
                onTap: state.isReadinessLoading ? null : onRefresh,
                child: Icon(
                  Icons.refresh_rounded,
                  size: 20,
                  color: state.isReadinessLoading
                      ? AppColors.textHint
                      : AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          if (state.isReadinessLoading) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              child: LinearProgressIndicator(
                minHeight: 4,
                backgroundColor: AppColors.brandPrimary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  AppColors.brandPrimary,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Checking recent focus signals...',
              style: AppTextStyles.captionLight,
            ),
          ] else if (state.readinessError != null) ...[
            Text(
              state.readinessError!,
              style: AppTextStyles.body(AppColors.errorColor),
            ),
          ] else if (readiness == null) ...[
            Text(
              'Readiness prediction is not loaded yet.',
              style: AppTextStyles.bodySmallLight,
            ),
          ] else ...[
            Row(
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.manrope(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: readiness.readinessScore / 100,
                      minHeight: 8,
                      backgroundColor: color.withValues(alpha: 0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(color),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  '${readiness.readinessScore}%',
                  style: AppTextStyles.label(color),
                ),
              ],
            ),
            const SizedBox(height: 10),
            ...readiness.reasons.take(3).map(
              (reason) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(top: 2, right: 6),
                      child: Container(
                        width: 5,
                        height: 5,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                    Expanded(
                      child: Text(
                        reason,
                        style: AppTextStyles.captionLight,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final String label;
  final IconData icon;

  const _InfoChip({required this.label, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceLavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: AppColors.brandPrimary),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.manrope(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textHeading,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Focus settings ────────────────────────────────────────────────────────────

class _FocusSettings extends ConsumerWidget {
  final FocusState state;

  const _FocusSettings({required this.state});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifier = ref.read(focusProvider.notifier);
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Focus Settings', style: AppTextStyles.h3Light),
          const SizedBox(height: AppSpacing.s16),
          _DurationSlider(
            label: 'Focus',
            value: state.focusMinutes,
            min: 5,
            max: 120,
            divisions: 23,
            onChanged: notifier.setFocusMinutes,
          ),
          _DurationSlider(
            label: 'Short break',
            value: state.shortBreakMinutes,
            min: 1,
            max: 30,
            divisions: 29,
            onChanged: notifier.setShortBreakMinutes,
          ),
          _DurationSlider(
            label: 'Long break',
            value: state.longBreakMinutes,
            min: 5,
            max: 60,
            divisions: 11,
            onChanged: notifier.setLongBreakMinutes,
          ),
          _DurationSlider(
            label: 'Long break after',
            value: state.sessionsBeforeLongBreak,
            min: 1,
            max: 12,
            divisions: 11,
            suffix: ' sessions',
            onChanged: notifier.setSessionsBeforeLongBreak,
          ),
          _ToggleRow(
            title: 'Continuous mode',
            subtitle: 'Auto-start the next focus or break phase.',
            value: state.continuousMode,
            onChanged: notifier.setContinuousMode,
          ),
          _ToggleRow(
            title: 'Distraction-free mode',
            subtitle: 'Hide secondary panels during active focus.',
            value: state.distractionFreeMode,
            onChanged: notifier.setDistractionFreeMode,
          ),
          const SizedBox(height: 4),
          Text(
            'Ambient sound',
            style: AppTextStyles.body(AppColors.textHeading),
          ),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: AppColors.bgApp,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: DropdownButtonFormField<String>(
              initialValue: state.ambientSoundKey,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
              ),
              items: const [
                DropdownMenuItem(value: 'silence', child: Text('Silence')),
                DropdownMenuItem(value: 'rain', child: Text('Rain')),
                DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
                DropdownMenuItem(
                  value: 'white_noise',
                  child: Text('White noise'),
                ),
              ],
              onChanged: (value) {
                if (value != null) notifier.setAmbientSoundKey(value);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.body(AppColors.textHeading)),
                Text(subtitle, style: AppTextStyles.captionLight),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}

// ── Duration slider ───────────────────────────────────────────────────────────

class _DurationSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.suffix = 'm',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(label, style: AppTextStyles.bodySmallLight),
            ),
            Text(
              '$value$suffix',
              style: AppTextStyles.label(AppColors.brandPrimary),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.brandPrimary,
            inactiveTrackColor:
                AppColors.brandPrimary.withValues(alpha: 0.12),
            thumbColor: AppColors.brandPrimary,
            overlayColor:
                AppColors.brandPrimary.withValues(alpha: 0.1),
          ),
          child: Slider(
            value: value.toDouble(),
            min: min.toDouble(),
            max: max.toDouble(),
            divisions: divisions,
            label: '$value$suffix',
            onChanged: (next) => onChanged(next.round()),
          ),
        ),
      ],
    );
  }
}

// ── Estimated pomodoros ───────────────────────────────────────────────────────

class _EstimatedPomodoros extends ConsumerWidget {
  final List<TaskModel> tasks;
  final int focusMinutes;

  const _EstimatedPomodoros({
    required this.tasks,
    required this.focusMinutes,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Estimated Pomodoros', style: AppTextStyles.h3Light),
          const SizedBox(height: AppSpacing.s12),
          if (tasks.isEmpty)
            Text(
              'Add task estimates to see suggested focus counts.',
              style: AppTextStyles.bodySmallLight,
            )
          else
            ...tasks.take(3).map((task) {
              final count =
                  ((task.estimatedMinutes ?? focusMinutes) / focusMinutes)
                      .ceil()
                      .clamp(1, 99);
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColors.featTasksSoft,
                        borderRadius: BorderRadius.circular(AppRadius.xs),
                      ),
                      child: const Icon(
                        Icons.task_alt,
                        size: 16,
                        color: AppColors.featTasks,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.body(AppColors.textHeading),
                          ),
                          Text(
                            '$count × ${focusMinutes}m',
                            style: AppTextStyles.captionLight,
                          ),
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => ref
                          .read(focusProvider.notifier)
                          .startFocusSession(taskId: task.id),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          gradient: AppGradients.action,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.play_arrow_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

// ── Report summary ────────────────────────────────────────────────────────────

class _ReportSummary extends StatelessWidget {
  final FocusState state;

  const _ReportSummary({required this.state});

  @override
  Widget build(BuildContext context) {
    final analytics = state.analytics;
    final completed = state.lastCompletedSession;
    final message = completed == null
        ? analytics?.reportSummary ??
              'Complete a focus session to build your report.'
        : 'Last session: ${completed.actualMinutes ?? 0}m '
              '${completed.sessionType.replaceAll('_', ' ')} completed.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.s20),
      decoration: BoxDecoration(
        gradient: AppGradients.ai,
        borderRadius: BorderRadius.circular(AppRadius.xl2),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: AppColors.featFocusSoft,
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 17,
                  color: AppColors.featFocus,
                ),
              ),
              const SizedBox(width: 10),
              Text('Focus Report', style: AppTextStyles.h4Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Text(message, style: AppTextStyles.bodySmallLight),
        ],
      ),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.captionLight),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.metricNumber(color)),
          Text(sub, style: AppTextStyles.captionLight),
        ],
      ),
    );
  }
}

// ── Session tile ──────────────────────────────────────────────────────────────

class _SessionTile extends StatelessWidget {
  final FocusSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: AppSpacing.s12,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: isCompleted
                  ? AppColors.successSoft
                  : AppColors.errorSoft,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check_rounded : Icons.close_rounded,
              size: 17,
              color: isCompleted
                  ? AppColors.successColor
                  : AppColors.errorColor,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              '${session.plannedMinutes} min '
              '${session.sessionType.replaceAll('_', ' ')}',
              style: AppTextStyles.body(AppColors.textHeading),
            ),
          ),
          Text(
            isCompleted
                ? '${session.actualMinutes ?? 0}m done'
                : 'cancelled',
            style: AppTextStyles.captionLight,
          ),
        ],
      ),
    );
  }
}
