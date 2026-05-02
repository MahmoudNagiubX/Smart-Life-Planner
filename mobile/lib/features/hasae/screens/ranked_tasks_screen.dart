import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../providers/hasae_provider.dart';

class RankedTasksScreen extends ConsumerStatefulWidget {
  const RankedTasksScreen({super.key});

  @override
  ConsumerState<RankedTasksScreen> createState() => _RankedTasksScreenState();
}

class _RankedTasksScreenState extends ConsumerState<RankedTasksScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hasaeProvider.notifier).loadRankedTasks();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hasaeProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('H-ASAE Rankings', style: AppTextStyles.h2Light),
            Text(
              'AI-scored next actions',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
          ],
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s12),
            child: Tooltip(
              message: 'Refresh rankings',
              child: GestureDetector(
                onTap: () =>
                    ref.read(hasaeProvider.notifier).loadRankedTasks(),
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
                    Icons.refresh,
                    size: 20,
                    color: AppColors.brandPrimary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      body: state.isRankLoading
          ? const AppLoadingState(message: 'Loading task rankings...')
          : state.rankedTasks.isEmpty
          ? const AppEmptyState(
              icon: Icons.psychology_outlined,
              title: 'No pending tasks to rank',
              message:
                  'Add pending tasks and H-ASAE will rank the next best actions.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.s8,
                AppSpacing.screenH, 138,
              ),
              itemCount: state.rankedTasks.length,
              itemBuilder: (context, index) {
                final task = state.rankedTasks[index];
                final scorePercent = (task.score * 100).round();
                final rank = index + 1;

                return _RankCard(
                  task: task,
                  rank: rank,
                  scorePercent: scorePercent,
                );
              },
            ),
    );
  }
}

// ── Rank card ─────────────────────────────────────────────────────────────────

class _RankCard extends StatelessWidget {
  final dynamic task;
  final int rank;
  final int scorePercent;

  const _RankCard({
    required this.task,
    required this.rank,
    required this.scorePercent,
  });

  Color get _scoreColor {
    if (scorePercent >= 70) return AppColors.successColor;
    if (scorePercent >= 40) return AppColors.warningColor;
    return AppColors.textHint;
  }

  Color get _rankBadgeColor {
    if (rank == 1) return AppColors.brandPrimary;
    if (rank == 2) return AppColors.brandViolet;
    if (rank == 3) return AppColors.brandPink;
    return AppColors.bgSurfaceLavender;
  }

  Color get _rankTextColor {
    if (rank <= 3) return Colors.white;
    return AppColors.textBody;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: rank == 1 ? AppShadows.glowPurple : AppShadows.soft,
        border: Border.all(
          color: rank == 1
              ? AppColors.brandPrimary.withValues(alpha: 0.35)
              : AppColors.borderSoft,
          width: rank == 1 ? 1.5 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Rank badge
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _rankBadgeColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '#$rank',
                style: AppTextStyles.label(_rankTextColor),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  task.title,
                  style: AppTextStyles.h4Light,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  task.explanation,
                  style: AppTextStyles.captionLight,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.s12),
                Row(
                  children: [
                    _MiniBar(
                      label: 'P',
                      value: (task.components['priority'] as double? ?? 0),
                    ),
                    _MiniBar(
                      label: 'U',
                      value: (task.components['urgency'] as double? ?? 0),
                    ),
                    _MiniBar(
                      label: 'E',
                      value: (task.components['energy_time_match']
                              as double? ??
                          0),
                    ),
                    _MiniBar(
                      label: 'D',
                      value: (task.components['duration_fit'] as double? ?? 0),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Score
          const SizedBox(width: AppSpacing.s12),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$scorePercent',
                style: AppTextStyles.h3(_scoreColor),
              ),
              Text(
                'score',
                style: AppTextStyles.caption(AppColors.textHint),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Mini bar ──────────────────────────────────────────────────────────────────

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;

  const _MiniBar({required this.label, required this.value});

  Color get _color {
    if (value > 0.7) return AppColors.successColor;
    if (value > 0.4) return AppColors.warningColor;
    return AppColors.errorColor;
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: AppSpacing.s4),
        child: Column(
          children: [
            Text(
              label,
              style: AppTextStyles.caption(AppColors.textHint)
                  .copyWith(fontSize: 9),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 5,
                backgroundColor: AppColors.borderSoft,
                valueColor: AlwaysStoppedAnimation<Color>(_color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
