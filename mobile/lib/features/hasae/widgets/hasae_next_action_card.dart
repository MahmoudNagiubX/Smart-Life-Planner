import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
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
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          children: [
            SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
            SizedBox(width: 12),
            Text('🧠 H-ASAE is analyzing...'),
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
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary.withValues(alpha: 0.12),
            AppColors.primary.withValues(alpha: 0.04),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('🧠', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                'Next Best Action',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              // Score badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Score $scorePercent',
                  style: const TextStyle(
                    fontSize: 10,
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => ref.read(hasaeProvider.notifier).loadAll(),
                child: const Icon(
                  Icons.refresh,
                  size: 16,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Task title
          Text(
            next.title ?? '',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 4),

          // Reason
          Text(
            '💡 ${next.reason.split('|').first.trim()}',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          // Prayer warning
          if (prayerWarning) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.prayerGold.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('🕌', style: TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                  Text(
                    '${_prayerDisplayName(next.nextPrayer!)} in ${next.minutesUntilPrayer} min',
                    style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.prayerGold,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],

          // Score components bar
          if (next.components != null) ...[
            const SizedBox(height: 10),
            _ScoreBreakdown(components: next.components!),
          ],

          const SizedBox(height: 12),

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
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  child: const Text('✅ Done'),
                ),
              ),
              const SizedBox(width: 8),
              if (next.alternative != null)
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showAlternative(context, next),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 38),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    child: const Text('↕ Alt'),
                  ),
                ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: () => context.push('/home/ranked-tasks'),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 38),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
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
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '↕ Alternative Task',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              alt.title ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
            const SizedBox(height: 4),
            Text(
              'Score: ${(alt.score * 100).round()}',
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 20),
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
              child: const Text('✅ Mark Done'),
            ),
          ],
        ),
      ),
    );
  }
}

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
            padding: const EdgeInsets.only(right: 4),
            child: Column(
              children: [
                Text(
                  item.label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                ClipRRect(
                  borderRadius: BorderRadius.circular(2),
                  child: LinearProgressIndicator(
                    value: item.value.clamp(0.0, 1.0),
                    minHeight: 4,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                    valueColor: AlwaysStoppedAnimation<Color>(
                      item.value > 0.7
                          ? AppColors.success
                          : item.value > 0.4
                          ? AppColors.warning
                          : AppColors.error,
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
