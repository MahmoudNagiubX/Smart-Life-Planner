import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text(
          '🧠 H-ASAE Rankings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(hasaeProvider.notifier).loadRankedTasks(),
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
              padding: const EdgeInsets.all(16),
              itemCount: state.rankedTasks.length,
              itemBuilder: (context, index) {
                final task = state.rankedTasks[index];
                final scorePercent = (task.score * 100).round();
                final rank = index + 1;

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: rank == 1
                        ? Border.all(
                            color: AppColors.primary.withValues(alpha: 0.4),
                          )
                        : null,
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Rank badge
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: rank == 1
                              ? AppColors.primary
                              : rank == 2
                              ? AppColors.warning.withValues(alpha: 0.8)
                              : Theme.of(context).cardTheme.color,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '#$rank',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: rank <= 2
                                  ? Colors.white
                                  : AppColors.textSecondary,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              task.title,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              task.explanation,
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppColors.textSecondary),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            // Mini score bars
                            Row(
                              children: [
                                _MiniBar(
                                  label: 'P',
                                  value:
                                      (task.components['priority'] as double? ??
                                      0),
                                ),
                                _MiniBar(
                                  label: 'U',
                                  value:
                                      (task.components['urgency'] as double? ??
                                      0),
                                ),
                                _MiniBar(
                                  label: 'E',
                                  value:
                                      (task.components['energy_time_match']
                                          as double? ??
                                      0),
                                ),
                                _MiniBar(
                                  label: 'D',
                                  value:
                                      (task.components['duration_fit']
                                          as double? ??
                                      0),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // Score
                      Column(
                        children: [
                          Text(
                            '$scorePercent',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: scorePercent >= 70
                                  ? AppColors.success
                                  : scorePercent >= 40
                                  ? AppColors.warning
                                  : AppColors.textSecondary,
                            ),
                          ),
                          Text(
                            'score',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 9),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}

class _MiniBar extends StatelessWidget {
  final String label;
  final double value;

  const _MiniBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.only(right: 4),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 8,
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: value.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                valueColor: AlwaysStoppedAnimation<Color>(
                  value > 0.7
                      ? AppColors.success
                      : value > 0.4
                      ? AppColors.warning
                      : AppColors.error,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
