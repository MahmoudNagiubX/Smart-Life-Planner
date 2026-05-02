import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../providers/ai_provider.dart';

class NextActionCard extends ConsumerStatefulWidget {
  const NextActionCard({super.key});

  @override
  ConsumerState<NextActionCard> createState() => _NextActionCardState();
}

class _NextActionCardState extends ConsumerState<NextActionCard> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(aiProvider.notifier).loadNextAction();
    });
  }

  @override
  Widget build(BuildContext context) {
    final aiState = ref.watch(aiProvider);

    if (aiState.isNextActionLoading) {
      return const _NextActionShell(
        child: Row(
          children: [
            SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: AppColors.brandPrimary),
            ),
            SizedBox(width: AppSpacing.s12),
            Text('AI is thinking...'),
          ],
        ),
      );
    }

    final next = aiState.nextAction;
    if (next == null) {
      return _NextActionShell(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _NextActionHeader(
              onRefresh: () =>
                  ref.read(aiProvider.notifier).loadNextAction(),
            ),
            const SizedBox(height: AppSpacing.s8),
            Text(
              aiState.error ?? 'No next action loaded yet.',
              style: AppTextStyles.caption(
                aiState.error == null
                    ? AppColors.textBody
                    : AppColors.errorColor,
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(aiProvider.notifier).loadNextAction(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillBr),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.s8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/home/daily-plan'),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Full Plan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.brandPrimary,
                      side: const BorderSide(color: AppColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillBr),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    final hasTask = next.taskId != null && next.taskId!.isNotEmpty;

    return _NextActionShell(
      highlighted: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _NextActionHeader(
            onRefresh: () =>
                ref.read(aiProvider.notifier).loadNextAction(),
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            hasTask ? next.title ?? 'Untitled task' : 'All caught up',
            style: AppTextStyles.h4Light,
          ),
          const SizedBox(height: AppSpacing.s4),
          Text(
            next.reason,
            style: AppTextStyles.caption(AppColors.textBody),
          ),
          const SizedBox(height: AppSpacing.s12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: hasTask
                      ? () async {
                          await ref
                              .read(tasksProvider.notifier)
                              .completeTask(next.taskId!);
                          await ref
                              .read(dashboardProvider.notifier)
                              .loadDashboard();
                          await ref
                              .read(aiProvider.notifier)
                              .loadNextAction();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  child: const Text('Mark Done'),
                ),
              ),
              const SizedBox(width: AppSpacing.s8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/home/daily-plan'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s12),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  child: const Text('Full Plan'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Card shell ────────────────────────────────────────────────────────────────

class _NextActionShell extends StatelessWidget {
  final Widget child;
  final bool highlighted;

  const _NextActionShell({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: highlighted ? null : AppColors.bgSurface,
        gradient: highlighted
            ? LinearGradient(
                colors: [
                  AppColors.brandPrimary.withValues(alpha: 0.15),
                  AppColors.brandPrimary.withValues(alpha: 0.05),
                ],
              )
            : null,
        borderRadius: AppRadius.circular(AppRadius.md),
        border: Border.all(
          color: highlighted
              ? AppColors.brandPrimary.withValues(alpha: 0.30)
              : AppColors.borderSoft,
        ),
      ),
      child: child,
    );
  }
}

// ── Header row ────────────────────────────────────────────────────────────────

class _NextActionHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NextActionHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: AppColors.brandPrimary),
        const SizedBox(width: AppSpacing.s8),
        Text(
          'Next Best Action',
          style: AppTextStyles.label(AppColors.brandPrimary),
        ),
        const Spacer(),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Refresh next action',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh,
              size: 16, color: AppColors.brandPrimary),
        ),
      ],
    );
  }
}
