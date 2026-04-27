import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/hasae_provider.dart';

class OverloadWarningCard extends ConsumerWidget {
  const OverloadWarningCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(hasaeProvider);
    final overload = state.overload;

    if (state.isOverloadLoading || overload == null) {
      return const SizedBox.shrink();
    }

    if (!overload.overloadDetected) return const SizedBox.shrink();

    final loadPercent = (overload.loadRatio * 100).round();
    final overloadedBy = overload.overloadedByMinutes;
    final hours = overloadedBy ~/ 60;
    final mins = overloadedBy % 60;
    final overloadStr = hours > 0 ? '${hours}h ${mins}m' : '${mins}m';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                'Overload Detected',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: AppColors.warning,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.warning.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$loadPercent% load',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Your schedule is overloaded by $overloadStr. '
            'Consider deferring low-priority tasks.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.warning.withValues(alpha: 0.9),
            ),
          ),
          const SizedBox(height: 10),
          // Load bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: overload.loadRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.warning.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                overload.loadRatio > 1.0 ? AppColors.error : AppColors.warning,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
