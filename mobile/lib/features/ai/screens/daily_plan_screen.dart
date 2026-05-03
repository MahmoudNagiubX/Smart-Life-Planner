import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../../routes/app_routes.dart';
import '../../hasae/models/hasae_model.dart';
import '../../hasae/providers/hasae_provider.dart';
import '../../schedule/providers/schedule_provider.dart';

const _kNavClearance = 138.0;

class DailyPlanScreen extends ConsumerStatefulWidget {
  const DailyPlanScreen({super.key});

  @override
  ConsumerState<DailyPlanScreen> createState() => _DailyPlanScreenState();
}

class _DailyPlanScreenState extends ConsumerState<DailyPlanScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hasaeProvider.notifier).generateDailyPlan();
    });
  }

  Future<void> _generatePlan() {
    return ref.read(hasaeProvider.notifier).generateDailyPlan();
  }

  Future<void> _acceptPlan() async {
    final ok = await ref.read(hasaeProvider.notifier).acceptDailyPlan();
    if (!mounted) return;
    if (ok) {
      await ref.read(scheduleProvider.notifier).loadSchedule();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('H-ASAE plan saved to Schedule.')),
      );
    } else {
      final error = ref.read(hasaeProvider).error ?? 'Could not save plan.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hasaeProvider);
    final plan = state.dailyPlan;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: state.isPlanLoading && plan == null
          ? const AppLoadingState(message: 'H-ASAE is building your day...')
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: _generatePlan,
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
                      child: _HasaePlanHeader(
                        date: plan?.date ?? '',
                        isPersisted: plan?.persisted == true,
                        onRefresh: _generatePlan,
                      ),
                    ),
                  ),
                  if (state.error != null && plan == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppErrorState(
                        title: 'H-ASAE plan could not load',
                        message: state.error!,
                        onRetry: _generatePlan,
                      ),
                    )
                  else if (plan == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: AppEmptyState(
                        icon: Icons.auto_awesome_outlined,
                        title: 'No smart plan yet',
                        message: 'Generate a prayer-aware schedule for today.',
                        action: ElevatedButton.icon(
                          onPressed: _generatePlan,
                          icon: const Icon(Icons.auto_awesome),
                          label: const Text('Generate Plan'),
                        ),
                      ),
                    )
                  else ...[
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH,
                          AppSpacing.s20,
                          AppSpacing.screenH,
                          0,
                        ),
                        child: _PlanSummaryCard(plan: plan),
                      ),
                    ),
                    if (plan.overloadWarning)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH,
                            AppSpacing.s12,
                            AppSpacing.screenH,
                            0,
                          ),
                          child: _OverloadCard(
                            message: plan.overloadMessage ??
                                'Your day is overloaded. H-ASAE scheduled the highest-value work first.',
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
                        child: _PlanTimeline(blocks: plan.blocks),
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
                        child: _PlanActions(
                          isPersisted: plan.persisted,
                          isAccepting: state.isPlanAccepting,
                          onReject: () => context.pop(),
                          onAccept: _acceptPlan,
                          onViewSchedule: () => context.go(AppRoutes.schedule),
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
}

class _HasaePlanHeader extends StatelessWidget {
  final String date;
  final bool isPersisted;
  final Future<void> Function() onRefresh;

  const _HasaePlanHeader({
    required this.date,
    required this.isPersisted,
    required this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('H-ASAE Smart Plan', style: AppTextStyles.h1Light),
              const SizedBox(height: 4),
              Text(
                date.isEmpty
                    ? 'Human-aware scheduling for today'
                    : '${_displayDate(date)}${isPersisted ? ' - saved' : ' - preview'}',
                style: AppTextStyles.bodySmallLight,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Tooltip(
          message: 'Replan',
          child: GestureDetector(
            onTap: onRefresh,
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
                Icons.auto_awesome,
                size: 20,
                color: AppColors.brandPrimary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlanSummaryCard extends StatelessWidget {
  final HasaeDailyPlan plan;

  const _PlanSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final taskBlocks = plan.blocks
        .where((b) => b.blockType == 'task' || b.blockType == 'focus')
        .length;
    final prayerBlocks = plan.blocks.where((b) => b.blockType == 'prayer').length;
    final minutes = plan.scheduledTaskMinutes;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.35),
                  ),
                ),
                child: const Icon(
                  Icons.psychology_alt_outlined,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: AppSpacing.s16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.persisted ? 'Plan accepted' : 'Preview ready',
                      style: AppTextStyles.h4(Colors.white),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '$taskBlocks work blocks - $prayerBlocks prayer windows - ${_minutesLabel(minutes)}',
                      style: AppTextStyles.bodySmall(
                        Colors.white.withValues(alpha: 0.88),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            plan.explanation,
            style: AppTextStyles.bodySmall(
              Colors.white.withValues(alpha: 0.9),
            ),
          ),
        ],
      ),
    );
  }
}

class _OverloadCard extends StatelessWidget {
  final String message;

  const _OverloadCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.errorSoft,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.errorColor.withValues(alpha: 0.24)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.errorColor,
            size: 20,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.bodySmall(AppColors.errorColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _PlanTimeline extends StatelessWidget {
  final List<HasaePlanBlock> blocks;

  const _PlanTimeline({required this.blocks});

  @override
  Widget build(BuildContext context) {
    if (blocks.isEmpty) {
      return AppEmptyState(
        icon: Icons.event_available_outlined,
        title: 'Nothing to schedule',
        message: 'Add pending tasks with estimates, then generate again.',
      );
    }
    return Column(
      children: [
        for (int i = 0; i < blocks.length; i++)
          _TimelineBlock(
            block: blocks[i],
            isLast: i == blocks.length - 1,
          ),
      ],
    );
  }
}

class _TimelineBlock extends StatelessWidget {
  final HasaePlanBlock block;
  final bool isLast;

  const _TimelineBlock({required this.block, required this.isLast});

  Color get _color {
    return switch (block.blockType) {
      'prayer' => AppColors.brandViolet,
      'focus' => AppColors.brandPrimary,
      'break' => AppColors.brandPink,
      _ => AppColors.infoColor,
    };
  }

  IconData get _icon {
    return switch (block.blockType) {
      'prayer' => Icons.mosque_outlined,
      'focus' => Icons.timer_outlined,
      'break' => Icons.coffee_outlined,
      _ => Icons.task_alt_outlined,
    };
  }

  @override
  Widget build(BuildContext context) {
    final duration = block.durationMinutes;
    final score = block.score == null ? null : (block.score! * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  block.timeLabel,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(AppColors.textHint).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: _color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: _color.withValues(alpha: 0.35),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.dividerColor,
                    ),
                  ),
              ],
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16,
                  AppSpacing.s12,
                  AppSpacing.s12,
                  AppSpacing.s12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.cardBr,
                  boxShadow: AppShadows.soft,
                  border: Border(left: BorderSide(color: _color, width: 4)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: _color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Icon(_icon, color: _color, size: 18),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            block.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.h4Light,
                          ),
                          const SizedBox(height: AppSpacing.s4),
                          Wrap(
                            spacing: AppSpacing.s8,
                            runSpacing: AppSpacing.s6,
                            children: [
                              _MetaChip(label: _minutesLabel(duration)),
                              _MetaChip(label: _blockTypeLabel(block.blockType)),
                              if (score != null) _MetaChip(label: 'Score $score'),
                            ],
                          ),
                          if (block.explanation?.isNotEmpty == true) ...[
                            const SizedBox(height: AppSpacing.s8),
                            Text(
                              block.explanation!.replaceFirst('[H-ASAE] ', ''),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.captionLight,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceLavender,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(label, style: AppTextStyles.caption(AppColors.textBody)),
    );
  }
}

class _PlanActions extends StatelessWidget {
  final bool isPersisted;
  final bool isAccepting;
  final VoidCallback onReject;
  final VoidCallback onAccept;
  final VoidCallback onViewSchedule;

  const _PlanActions({
    required this.isPersisted,
    required this.isAccepting,
    required this.onReject,
    required this.onAccept,
    required this.onViewSchedule,
  });

  @override
  Widget build(BuildContext context) {
    if (isPersisted) {
      return _GradientButton(
        icon: Icons.calendar_today_outlined,
        label: 'View Schedule',
        onTap: onViewSchedule,
      );
    }
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: isAccepting ? null : onReject,
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(0, AppButtonHeight.primary),
              foregroundColor: AppColors.textBody,
              side: const BorderSide(color: AppColors.borderSoft),
              shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
            ),
            child: const Text('Reject'),
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Expanded(
          child: _GradientButton(
            icon: Icons.check_rounded,
            label: isAccepting ? 'Saving...' : 'Accept Plan',
            onTap: isAccepting ? null : onAccept,
          ),
        ),
      ],
    );
  }
}

class _GradientButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Opacity(
        opacity: onTap == null ? 0.7 : 1,
        child: Container(
          height: AppButtonHeight.primary,
          decoration: BoxDecoration(
            gradient: AppGradients.action,
            borderRadius: AppRadius.pillBr,
            boxShadow: AppShadows.glowPurple,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Text(label, style: AppTextStyles.button(Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

String _displayDate(String value) {
  final parsed = DateTime.tryParse(value);
  if (parsed == null) return value;
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
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

String _minutesLabel(int minutes) {
  if (minutes <= 0) return '0 min';
  final hours = minutes ~/ 60;
  final mins = minutes % 60;
  if (hours == 0) return '$mins min';
  if (mins == 0) return '${hours}h';
  return '${hours}h ${mins}m';
}

String _blockTypeLabel(String type) {
  return switch (type) {
    'prayer' => 'Prayer',
    'focus' => 'Focus',
    'break' => 'Break',
    _ => 'Task',
  };
}
