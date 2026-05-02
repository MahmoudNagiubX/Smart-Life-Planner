import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/daily_plan_model.dart';
import '../providers/ai_provider.dart';

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
      ref.read(aiProvider.notifier).loadDailyPlan();
    });
  }

  Future<void> _refreshPlan() {
    return ref.read(aiProvider.notifier).loadDailyPlan();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: state.isPlanLoading
          ? const AppLoadingState(message: 'AI is building your plan...')
          : RefreshIndicator(
              color: AppColors.brandPrimary,
              onRefresh: _refreshPlan,
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Header
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.screenH, 56,
                        AppSpacing.screenH, 0,
                      ),
                      child: _DailyPlanHeader(
                        date: state.dailyPlan?.date ?? '',
                        onRefresh: _refreshPlan,
                      ),
                    ),
                  ),

                  // Body
                  if (state.dailyPlan == null)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _NoPlanState(
                        error: state.error,
                        onGenerate: _refreshPlan,
                      ),
                    )
                  else ...[
                    // Summary card
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(
                          AppSpacing.screenH, AppSpacing.s20,
                          AppSpacing.screenH, 0,
                        ),
                        child: _PlanSummaryCard(plan: state.dailyPlan!),
                      ),
                    ),

                    // Timeline or empty
                    if (state.dailyPlan!.plan.isEmpty)
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.s32),
                          child: Center(
                            child: Text(
                              'No tasks to plan today',
                              style: AppTextStyles.bodyLight,
                            ),
                          ),
                        ),
                      )
                    else
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            AppSpacing.screenH, AppSpacing.s20,
                            AppSpacing.screenH, 0,
                          ),
                          child: _Timeline(items: state.dailyPlan!.plan),
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

// ── No Plan State ─────────────────────────────────────────────────────────────

class _NoPlanState extends StatelessWidget {
  final String? error;
  final Future<void> Function() onGenerate;

  const _NoPlanState({required this.error, required this.onGenerate});

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return AppErrorState(
        title: 'Daily plan could not load',
        message: error!,
        onRetry: onGenerate,
      );
    }

    return AppEmptyState(
      icon: Icons.calendar_today,
      title: 'No plan yet',
      message: 'Generate a daily plan when you are ready.',
      action: ElevatedButton.icon(
        onPressed: onGenerate,
        icon: const Icon(Icons.auto_awesome),
        label: const Text('Generate Plan'),
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _DailyPlanHeader extends StatelessWidget {
  final String date;
  final Future<void> Function() onRefresh;

  const _DailyPlanHeader({required this.date, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Daily Plan', style: AppTextStyles.h1Light),
              const SizedBox(height: 4),
              Text(
                date.isNotEmpty ? date : 'Your AI-generated schedule',
                style: AppTextStyles.bodySmallLight,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.s12),
        Tooltip(
          message: 'Generate new plan',
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

// ── Plan Summary Card ─────────────────────────────────────────────────────────

class _PlanSummaryCard extends StatelessWidget {
  final DailyPlanData plan;

  const _PlanSummaryCard({required this.plan});

  @override
  Widget build(BuildContext context) {
    final count = plan.plan.length;
    final totalMin = plan.plan.fold(0, (sum, i) => sum + i.durationMinutes);
    final hours = totalMin ~/ 60;
    final mins = totalMin % 60;
    final timeLabel =
        hours > 0 ? '${hours}h ${mins}m planned' : '${mins}m planned';

    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                  color: Colors.white.withValues(alpha: 0.35)),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: Colors.white,
              size: 26,
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Your AI-Generated Plan',
                  style: AppTextStyles.h4(Colors.white),
                ),
                const SizedBox(height: 4),
                Text(
                  '$count ${count == 1 ? 'block' : 'blocks'} · $timeLabel',
                  style: AppTextStyles.bodySmall(
                      Colors.white.withValues(alpha: 0.88)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Timeline ──────────────────────────────────────────────────────────────────

class _Timeline extends StatelessWidget {
  final List<DailyPlanItem> items;

  const _Timeline({required this.items});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (int i = 0; i < items.length; i++)
          _TimelineItem(
            item: items[i],
            index: i + 1,
            isLast: i == items.length - 1,
          ),
      ],
    );
  }
}

class _TimelineItem extends StatelessWidget {
  final DailyPlanItem item;
  final int index;
  final bool isLast;

  const _TimelineItem({
    required this.item,
    required this.index,
    required this.isLast,
  });

  Color _blockColor() {
    final r = item.reason.toLowerCase();
    if (r.contains('focus') || r.contains('deep work')) {
      return AppColors.brandPink;
    }
    if (r.contains('prayer') || r.contains('spiritual')) {
      return AppColors.brandViolet;
    }
    if (r.contains('break') || r.contains('rest') || r.contains('coffee')) {
      return AppColors.warningColor;
    }
    if (r.contains('habit') || r.contains('routine')) {
      return AppColors.featHabits;
    }
    if (r.contains('meeting')) return AppColors.brandPink;
    return AppColors.brandPrimary;
  }

  IconData _blockIcon() {
    final r = item.reason.toLowerCase();
    if (r.contains('focus') || r.contains('deep work')) {
      return Icons.timer_outlined;
    }
    if (r.contains('prayer') || r.contains('spiritual')) {
      return Icons.nightlight_round;
    }
    if (r.contains('break') || r.contains('rest')) {
      return Icons.coffee_outlined;
    }
    if (r.contains('habit') || r.contains('routine')) {
      return Icons.track_changes_outlined;
    }
    return Icons.auto_awesome;
  }

  @override
  Widget build(BuildContext context) {
    final color = _blockColor();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s12),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time label
            SizedBox(
              width: 48,
              child: Padding(
                padding: const EdgeInsets.only(top: 14),
                child: Text(
                  item.suggestedTime,
                  textAlign: TextAlign.right,
                  style: AppTextStyles.caption(AppColors.textHint).copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),

            // Dot + connector
            Column(
              children: [
                const SizedBox(height: 14),
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.35),
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
                      decoration: BoxDecoration(
                        color: AppColors.dividerColor,
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  )
                else
                  const SizedBox(height: 8),
              ],
            ),
            const SizedBox(width: 12),

            // Plan card
            Expanded(
              child: Container(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.s16, AppSpacing.s12,
                  AppSpacing.s12, AppSpacing.s12,
                ),
                decoration: BoxDecoration(
                  color: AppColors.bgSurface,
                  borderRadius: AppRadius.cardBr,
                  boxShadow: AppShadows.soft,
                  border: Border(
                    left: BorderSide(color: color, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            style: AppTextStyles.h4Light,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.timer_outlined,
                                size: 12,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${item.durationMinutes} min',
                                style: AppTextStyles.captionLight,
                              ),
                              if (item.reason.isNotEmpty) ...[
                                const SizedBox(width: 8),
                                Icon(
                                  _blockIcon(),
                                  size: 12,
                                  color: color,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    item.reason,
                                    style: AppTextStyles.captionLight,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Index badge
                    Container(
                      width: 24,
                      height: 24,
                      margin: const EdgeInsets.only(left: AppSpacing.s8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '$index',
                          style: AppTextStyles.caption(color).copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
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
