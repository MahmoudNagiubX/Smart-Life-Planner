import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/quran_goal_model.dart';
import '../providers/quran_goal_provider.dart';

class QuranGoalScreen extends ConsumerStatefulWidget {
  const QuranGoalScreen({super.key});

  @override
  ConsumerState<QuranGoalScreen> createState() => _QuranGoalScreenState();
}

class _QuranGoalScreenState extends ConsumerState<QuranGoalScreen> {
  final _targetController = TextEditingController();
  int _pagesCompleted = 0;
  String? _syncedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quranGoalProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _syncControllers(QuranGoalSummary summary) {
    final key = '${summary.dailyPageTarget}|${summary.todayPagesCompleted}';
    if (_syncedKey == key) return;
    _syncedKey = key;
    _targetController.text = summary.dailyPageTarget == 0
        ? ''
        : summary.dailyPageTarget.toString();
    _pagesCompleted = summary.todayPagesCompleted;
  }

  Future<void> _saveGoal() async {
    final target = int.tryParse(_targetController.text.trim());
    if (target == null || target < 1 || target > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a target between 1 and 604 pages.'),
        ),
      );
      return;
    }
    await ref.read(quranGoalProvider.notifier).saveGoal(target);
  }

  Future<void> _saveProgress() async {
    await ref
        .read(quranGoalProvider.notifier)
        .updateTodayProgress(_pagesCompleted);
  }

  Future<void> _editWeeklyDay(QuranWeeklyProgressItem item) async {
    final summary = ref.read(quranGoalProvider).summary;
    if (summary?.goal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Set a daily target before logging.')),
      );
      return;
    }

    final controller = TextEditingController(
      text: item.pagesCompleted.toString(),
    );
    final pages = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: AppRadius.sheetBr,
          ),
          padding: EdgeInsets.only(
            left: AppSpacing.screenH,
            right: AppSpacing.screenH,
            top: AppSpacing.s24,
            bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s24,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.dividerColor,
                    borderRadius: AppRadius.pillBr,
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                'Update ${_formatDateLabel(item.progressDate)}',
                style: AppTextStyles.h4Light,
              ),
              const SizedBox(height: AppSpacing.s16),
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                style: AppTextStyles.bodyLight,
                decoration: const InputDecoration(
                  labelText: 'Pages read',
                  prefixIcon: Icon(Icons.menu_book_outlined),
                ),
              ),
              const SizedBox(height: AppSpacing.s20),
              _GradientButton(
                label: 'Save Day',
                icon: Icons.save_outlined,
                onTap: () {
                  final value = int.tryParse(controller.text.trim());
                  if (value == null || value < 0 || value > 604) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Enter pages between 0 and 604.'),
                      ),
                    );
                    return;
                  }
                  Navigator.of(context).pop(value);
                },
              ),
            ],
          ),
        );
      },
    );
    controller.dispose();
    if (pages == null) return;
    if (!mounted) return;
    await ref
        .read(quranGoalProvider.notifier)
        .updateProgressForDate(item.progressDate, pages);
  }

  void _changeProgress(int delta) {
    setState(() {
      _pagesCompleted = (_pagesCompleted + delta).clamp(0, 604);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quranGoalProvider);
    final summary = state.summary;
    if (summary != null) {
      _syncControllers(summary);
    }

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Quran Goal', style: AppTextStyles.h2Light),
      ),
      body: state.isLoading && summary == null
          ? const AppLoadingState(message: 'Loading Quran goal...')
          : state.error != null && summary == null
          ? AppErrorState(
              title: 'Quran goal could not load',
              message: state.error!,
              onRetry: () =>
                  ref.read(quranGoalProvider.notifier).loadSummary(),
            )
          : RefreshIndicator(
              color: AppColors.brandGold,
              onRefresh: () =>
                  ref.read(quranGoalProvider.notifier).loadSummary(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, AppSpacing.s8,
                  AppSpacing.screenH, AppSpacing.s32,
                ),
                children: [
                  _DailyTargetCard(
                    controller: _targetController,
                    isSaving: state.isSaving,
                    onSave: _saveGoal,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _TodayProgressCard(
                    summary: summary,
                    pagesCompleted: _pagesCompleted,
                    isSaving: state.isSaving,
                    onDecrease: () => _changeProgress(-1),
                    onIncrease: () => _changeProgress(1),
                    onSave: _saveProgress,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  _WeeklySummaryCard(
                    summary: summary,
                    isSaving: state.isSaving,
                    onEditDay: _editWeeklyDay,
                  ),
                  if (state.error != null && summary != null) ...[
                    const SizedBox(height: AppSpacing.s16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: AppTextStyles.caption(AppColors.errorColor),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

String _formatDateLabel(String value) {
  if (value.length >= 10) {
    return value.substring(5);
  }
  return value;
}

// ── Daily target card ─────────────────────────────────────────────────────────

class _DailyTargetCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;

  const _DailyTargetCard({
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _QuranCard(
      icon: Icons.flag_outlined,
      title: 'Daily Page Target',
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            style: AppTextStyles.bodyLight,
            decoration: const InputDecoration(
              labelText: 'Pages per day',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _GradientButton(
            label: isSaving ? 'Saving...' : 'Save Target',
            icon: Icons.save_outlined,
            onTap: isSaving ? () {} : onSave,
          ),
        ],
      ),
    );
  }
}

// ── Today progress card ───────────────────────────────────────────────────────

class _TodayProgressCard extends StatelessWidget {
  final QuranGoalSummary? summary;
  final int pagesCompleted;
  final bool isSaving;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSave;

  const _TodayProgressCard({
    required this.summary,
    required this.pagesCompleted,
    required this.isSaving,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final target = summary?.dailyPageTarget ?? 0;
    final progress = target == 0
        ? 0.0
        : (pagesCompleted / target).clamp(0.0, 1.0);

    return _QuranCard(
      icon: Icons.today_outlined,
      title: 'Today',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease pages',
                onPressed: pagesCompleted == 0 ? null : onDecrease,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: AppColors.textHint,
                ),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$pagesCompleted',
                      style: AppTextStyles.h2(AppColors.brandGold),
                    ),
                    Text(
                      pagesCompleted == 1 ? 'page' : 'pages',
                      style: AppTextStyles.captionLight,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      target == 0
                          ? 'Set a daily target first'
                          : 'of $target pages today',
                      style: AppTextStyles.captionLight,
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Increase pages',
                onPressed: onIncrease,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: AppColors.brandGold,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: AppRadius.pillBr,
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.brandGold.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandGold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _GradientButton(
            label: isSaving ? 'Saving...' : 'Save Today',
            icon: Icons.check_circle_outline,
            onTap: isSaving ? () {} : onSave,
          ),
        ],
      ),
    );
  }
}

// ── Weekly summary card ───────────────────────────────────────────────────────

class _WeeklySummaryCard extends StatelessWidget {
  final QuranGoalSummary? summary;
  final bool isSaving;
  final ValueChanged<QuranWeeklyProgressItem> onEditDay;

  const _WeeklySummaryCard({
    required this.summary,
    required this.isSaving,
    required this.onEditDay,
  });

  @override
  Widget build(BuildContext context) {
    final weeklySummary = summary?.weeklySummary ?? const [];
    return _QuranCard(
      icon: Icons.calendar_month_outlined,
      title: 'Weekly Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary?.weeklyTotalPages ?? 0} / ${summary?.weeklyTargetPages ?? 0} pages this week',
            style: AppTextStyles.h4Light,
          ),
          const SizedBox(height: AppSpacing.s8),
          _WeeklyMetrics(summary: summary),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: AppRadius.pillBr,
            child: LinearProgressIndicator(
              value: ((summary?.weeklyCompletionPercent ?? 0) / 100)
                  .clamp(0.0, 1.0),
              minHeight: 8,
              backgroundColor: AppColors.brandGold.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.brandGold,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: weeklySummary.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.s6),
                  child: _WeeklyDayPill(
                    item: item,
                    isDisabled: isSaving,
                    onTap: () => onEditDay(item),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Tap a day to correct its pages. Targets use the saved daily goal for each log.',
            style: AppTextStyles.captionLight,
          ),
        ],
      ),
    );
  }
}

class _WeeklyMetrics extends StatelessWidget {
  final QuranGoalSummary? summary;

  const _WeeklyMetrics({required this.summary});

  @override
  Widget build(BuildContext context) {
    final today = summary?.todayPagesCompleted ?? 0;
    final weeklyTotal = summary?.weeklyTotalPages ?? 0;
    final weeklyTarget = summary?.weeklyTargetPages ?? 0;
    final completion = summary?.weeklyCompletionPercent ?? 0;
    final streak = summary?.currentStreakDays ?? 0;
    return Wrap(
      spacing: AppSpacing.s8,
      runSpacing: AppSpacing.s8,
      children: [
        _MetricChip(label: 'Today', value: '$today pages'),
        _MetricChip(label: 'Week', value: '$weeklyTotal pages'),
        _MetricChip(label: 'Target', value: '$weeklyTarget pages'),
        _MetricChip(label: 'Complete', value: '$completion%'),
        _MetricChip(label: 'Streak', value: '$streak days'),
      ],
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final String value;

  const _MetricChip({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.brandGold.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(
          color: AppColors.brandGold.withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTextStyles.captionLight.copyWith(fontSize: 10)),
          Text(
            value,
            style: AppTextStyles.label(AppColors.brandGold),
          ),
        ],
      ),
    );
  }
}

class _WeeklyDayPill extends StatelessWidget {
  final QuranWeeklyProgressItem item;
  final bool isDisabled;
  final VoidCallback onTap;

  const _WeeklyDayPill({
    required this.item,
    required this.isDisabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = _formatDateLabel(item.progressDate);
    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.s8),
        decoration: BoxDecoration(
          color: item.targetMet
              ? AppColors.brandGold.withValues(alpha: 0.16)
              : AppColors.bgSurfaceSoft,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(
            color: item.targetMet
                ? AppColors.brandGold.withValues(alpha: 0.45)
                : AppColors.borderSoft,
          ),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: AppTextStyles.captionLight.copyWith(fontSize: 10),
                ),
              ),
            ),
            const SizedBox(height: 3),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${item.pagesCompleted}/${item.targetPages}',
                  style: AppTextStyles.label(AppColors.brandGold)
                      .copyWith(fontSize: 11),
                ),
              ),
            ),
            const SizedBox(height: 2),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '${item.completionPercent}%',
                  style: AppTextStyles.captionLight.copyWith(fontSize: 10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Quran card shell ──────────────────────────────────────────────────────────

class _QuranCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _QuranCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
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
          Row(
            children: [
              Container(
                width: AppIconSize.avatar,
                height: AppIconSize.avatar,
                decoration: BoxDecoration(
                  color: AppColors.brandGold.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(
                  icon,
                  color: AppColors.brandGold,
                  size: AppIconSize.cardHeader,
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(title, style: AppTextStyles.h4Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          child,
        ],
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppButtonHeight.primary,
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.pillBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Text(label, style: AppTextStyles.buttonLight),
            ],
          ),
        ),
      ),
    );
  }
}
