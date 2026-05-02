import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/hasae_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';

class HasaeNextActionCard extends ConsumerStatefulWidget {
  const HasaeNextActionCard({super.key});

  @override
  ConsumerState<HasaeNextActionCard> createState() =>
      _HasaeNextActionCardState();
}

class _HasaeNextActionCardState extends ConsumerState<HasaeNextActionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(hasaeProvider.notifier).loadAll();
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

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(hasaeProvider);

    if (state.isNextActionLoading) {
      return Container(
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: AppColors.bgSurface,
          borderRadius: AppRadius.circular(AppRadius.md),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandPrimary),
            ),
            const SizedBox(width: AppSpacing.s12),
            Text('🧠 H-ASAE is analyzing...',
                style: AppTextStyles.body(AppColors.textBody)),
          ],
        ),
      );
    }

    final next = state.nextAction;
    if (next == null || next.taskId == null) {
      return const SizedBox.shrink();
    }

    final scorePercent = (next.score * 100).round();
    final prayerWarning =
        next.nextPrayer != null && next.minutesUntilPrayer < 60;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.brandPrimary.withValues(alpha: 0.12),
            AppColors.brandPrimary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.brandPrimary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 16)),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Next Best Action',
                style: AppTextStyles.label(AppColors.brandPrimary),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.brandPrimary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillBr,
                ),
                child: Text(
                  'Score $scorePercent',
                  style: AppTextStyles.caption(AppColors.brandPrimary),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              GestureDetector(
                onTap: () => ref.read(hasaeProvider.notifier).loadAll(),
                child: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppColors.brandPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),

          Text(
            next.title ?? '',
            style: AppTextStyles.h4Light,
          ),
          const SizedBox(height: AppSpacing.s4),

          Text(
            '💡 ${next.reason.split('|').first.trim()}',
            style: AppTextStyles.caption(AppColors.textBody),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Prayer warning
          if (prayerWarning) ...[
            const SizedBox(height: AppSpacing.s8),
            Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
              decoration: BoxDecoration(
                color: AppColors.brandGold.withValues(alpha: 0.10),
                borderRadius: AppRadius.pillBr,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: AppSpacing.s8),
                  Text(
                    '${_prayerDisplayName(next.nextPrayer!)} in ${next.minutesUntilPrayer} min',
                    style: AppTextStyles.caption(AppColors.brandGold),
                  ),
                ],
              ),
            ),
          ],

          // Score components bar
          if (next.components != null) ...[
            const SizedBox(height: AppSpacing.s12),
            _ScoreBreakdown(components: next.components!),
          ],

          const SizedBox(height: AppSpacing.s12),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    if (next.taskId != null) {
                      await ref
                          .read(tasksProvider.notifier)
                          .completeTask(next.taskId!);
                      await ref
                          .read(dashboardProvider.notifier)
                          .loadDashboard();
                      ref.read(hasaeProvider.notifier).loadAll();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  child: const Text('✅ Done'),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              if (next.alternative != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAlternative(context, next),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s8),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillBr),
                    ),
                    child: const Text('↕ Alt'),
                  ),
                ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/home/ranked-tasks'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s8),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  child: const Text('📋 All'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAlternative(BuildContext context, next) {
    final alt = next.alternative;
    if (alt == null) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgApp,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBr),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.borderSoft,
                  borderRadius: AppRadius.pillBr,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
            Text(
              '↕ Alternative Task',
              style: AppTextStyles.h4Light,
            ),
            const SizedBox(height: AppSpacing.s12),
            Text(
              alt.title ?? '',
              style: AppTextStyles.h4Light,
            ),
            const SizedBox(height: AppSpacing.s4),
            Text(
              'Score: ${(alt.score * 100).round()}',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
            const SizedBox(height: AppSpacing.s20),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);
                if (alt.taskId != null) {
                  await ref
                      .read(tasksProvider.notifier)
                      .completeTask(alt.taskId!);
                  ref.read(hasaeProvider.notifier).loadAll();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandPrimary,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, AppButtonHeight.primary),
                shape: RoundedRectangleBorder(borderRadius: AppRadius.pillBr),
              ),
              child: const Text('✅ Mark Done'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Score breakdown bar ───────────────────────────────────────────────────────

class _ScoreBreakdown extends StatelessWidget {
  final Map<String, dynamic> components;

  const _ScoreBreakdown({required this.components});

  @override
  Widget build(BuildContext context) {
    final items = [
      _ScoreItem('Priority', components['priority'] as double? ?? 0),
      _ScoreItem('Urgency', components['urgency'] as double? ?? 0),
      _ScoreItem('Energy', components['energy_time_match'] as double? ?? 0),
      _ScoreItem('Duration', components['duration_fit'] as double? ?? 0),
    ];

    return Row(
      children: items.map((item) {
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.only(right: AppSpacing.s4),
            child: Column(
              children: [
                Text(
                  item.label,
                  style: AppTextStyles.caption(AppColors.textHint),
                ),
                const SizedBox(height: AppSpacing.s4),
                ClipRRect(
                  borderRadius: AppRadius.pillBr,
                  child: LinearProgressIndicator(
                    value: item.value.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor:
                        AppColors.brandPrimary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.value > 0.7
                          ? AppColors.successColor
                          : item.value > 0.4
                              ? AppColors.warningColor
                              : AppColors.errorColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _ScoreItem {
  final String label;
  final double value;
  _ScoreItem(this.label, this.value);
}
