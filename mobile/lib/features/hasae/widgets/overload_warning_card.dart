import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.warningColor.withValues(alpha: 0.10),
        borderRadius: AppRadius.circular(AppRadius.md),
        border: Border.all(
            color: AppColors.warningColor.withValues(alpha: 0.40)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('⚠️', style: TextStyle(fontSize: 18)),
              const SizedBox(width: AppSpacing.s8),
              Text(
                'Overload Detected',
                style: AppTextStyles.h4(AppColors.warningColor),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: AppColors.warningColor.withValues(alpha: 0.20),
                  borderRadius: AppRadius.pillBr,
                ),
                child: Text(
                  '$loadPercent% load',
                  style: AppTextStyles.caption(AppColors.warningColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            'Your schedule is overloaded by $overloadStr. '
            'Consider deferring low-priority tasks.',
            style: AppTextStyles.bodySmall(
                AppColors.warningColor.withValues(alpha: 0.9)),
          ),
          const SizedBox(height: AppSpacing.s12),
          ClipRRect(
            borderRadius: AppRadius.pillBr,
            child: LinearProgressIndicator(
              value: overload.loadRatio.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor:
                  AppColors.warningColor.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(
                overload.loadRatio > 1.0
                    ? AppColors.errorColor
                    : AppColors.warningColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
