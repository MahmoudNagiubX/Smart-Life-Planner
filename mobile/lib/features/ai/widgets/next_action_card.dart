import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
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
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
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
              onRefresh: () => ref.read(aiProvider.notifier).loadNextAction(),
            ),
            const SizedBox(height: 8),
            Text(
              aiState.error ?? 'No next action loaded yet.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: aiState.error == null
                    ? AppColors.textSecondary
                    : AppColors.error,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () =>
                        ref.read(aiProvider.notifier).loadNextAction(),
                    icon: const Icon(Icons.refresh, size: 18),
                    label: const Text('Refresh'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => context.push('/home/daily-plan'),
                    icon: const Icon(Icons.calendar_today, size: 18),
                    label: const Text('Full Plan'),
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
            onRefresh: () => ref.read(aiProvider.notifier).loadNextAction(),
          ),
          const SizedBox(height: 8),
          Text(
            hasTask ? next.title ?? 'Untitled task' : 'All caught up',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),
          Text(
            next.reason,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
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
                          await ref.read(aiProvider.notifier).loadNextAction();
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  child: const Text('Mark Done'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/home/daily-plan'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
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

class _NextActionShell extends StatelessWidget {
  final Widget child;
  final bool highlighted;

  const _NextActionShell({required this.child, this.highlighted = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlighted ? null : Theme.of(context).cardTheme.color,
        gradient: highlighted
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.15),
                  AppColors.primary.withValues(alpha: 0.05),
                ],
              )
            : null,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlighted
              ? AppColors.primary.withValues(alpha: 0.3)
              : AppColors.primary.withValues(alpha: 0.2),
        ),
      ),
      child: child,
    );
  }
}

class _NextActionHeader extends StatelessWidget {
  final VoidCallback onRefresh;

  const _NextActionHeader({required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Icon(Icons.auto_awesome, size: 16, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          'Next Best Action',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        IconButton(
          constraints: const BoxConstraints.tightFor(width: 32, height: 32),
          padding: EdgeInsets.zero,
          tooltip: 'Refresh next action',
          onPressed: onRefresh,
          icon: const Icon(Icons.refresh, size: 16, color: AppColors.primary),
        ),
      ],
    );
  }
}
