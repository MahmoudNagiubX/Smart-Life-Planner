import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/daily_plan_model.dart';
import '../providers/ai_provider.dart';

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
      appBar: AppBar(
        title: const Text(
          'AI Daily Plan',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Generate new plan',
            icon: const Icon(Icons.refresh),
            onPressed: _refreshPlan,
          ),
        ],
      ),
      body: state.isPlanLoading
          ? const AppLoadingState(message: 'AI is building your plan...')
          : RefreshIndicator(
              onRefresh: _refreshPlan,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  if (state.dailyPlan == null)
                    _NoPlanState(error: state.error, onGenerate: _refreshPlan)
                  else ...[
                    _PlanHeader(plan: state.dailyPlan!),
                    const SizedBox(height: 24),
                    if (state.dailyPlan!.plan.isEmpty)
                      const Center(
                        child: Padding(
                          padding: EdgeInsets.symmetric(vertical: 32),
                          child: Text(
                            'No tasks to plan today',
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                      )
                    else
                      ...state.dailyPlan!.plan.asMap().entries.map(
                        (entry) => _PlanItemCard(
                          item: entry.value,
                          index: entry.key + 1,
                        ),
                      ),
                  ],
                ],
              ),
            ),
    );
  }
}

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

    return SizedBox(
      height: MediaQuery.sizeOf(context).height * 0.65,
      child: AppEmptyState(
        icon: Icons.calendar_today,
        title: 'No plan yet',
        message: 'Generate a daily plan when you are ready.',
        action: ElevatedButton.icon(
          onPressed: onGenerate,
          icon: const Icon(Icons.auto_awesome),
          label: const Text('Generate Plan'),
        ),
      ),
    );
  }
}

class _PlanHeader extends StatelessWidget {
  final DailyPlanData plan;

  const _PlanHeader({required this.plan});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary.withValues(alpha: 0.8), AppColors.primary],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your AI-Generated Plan',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            plan.date,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _PlanItemCard extends StatelessWidget {
  final DailyPlanItem item;
  final int index;

  const _PlanItemCard({required this.item, required this.index});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 56,
            child: Column(
              children: [
                Text(
                  item.suggestedTime,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  width: 2,
                  height: 60,
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            '$index',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          item.title,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(
                        Icons.timer_outlined,
                        size: 14,
                        color: AppColors.textSecondary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${item.durationMinutes} min',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(
                        Icons.auto_awesome,
                        size: 14,
                        color: AppColors.warning,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          item.reason,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
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
