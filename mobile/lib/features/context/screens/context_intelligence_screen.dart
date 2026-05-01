import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../providers/context_intelligence_provider.dart';

class ContextIntelligenceScreen extends ConsumerStatefulWidget {
  const ContextIntelligenceScreen({super.key});

  @override
  ConsumerState<ContextIntelligenceScreen> createState() =>
      _ContextIntelligenceScreenState();
}

class _ContextIntelligenceScreenState
    extends ConsumerState<ContextIntelligenceScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(contextIntelligenceProvider.notifier).loadSnapshot();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(contextIntelligenceProvider);
    final snapshot = state.snapshot;
    final notifier = ref.read(contextIntelligenceProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Context Intelligence',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh context',
            onPressed: state.isSaving ? null : notifier.refreshTimeContext,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: state.isLoading
          ? const AppLoadingState(message: 'Loading context snapshot...')
          : state.error != null && snapshot.id.isEmpty
          ? AppErrorState(
              title: 'Context snapshot could not load',
              message: state.error!,
              onRetry: notifier.loadSnapshot,
            )
          : RefreshIndicator(
              onRefresh: notifier.loadSnapshot,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _SectionCard(
                    icon: Icons.battery_charging_full_outlined,
                    title: 'Energy Level',
                    subtitle:
                        'Choose your current energy so recommendations can adapt.',
                    child: SegmentedButton<String>(
                      segments: const [
                        ButtonSegment(
                          value: 'low',
                          label: Text('Low'),
                          icon: Icon(Icons.battery_1_bar),
                        ),
                        ButtonSegment(
                          value: 'medium',
                          label: Text('Medium'),
                          icon: Icon(Icons.battery_4_bar),
                        ),
                        ButtonSegment(
                          value: 'high',
                          label: Text('High'),
                          icon: Icon(Icons.battery_full),
                        ),
                      ],
                      selected: {snapshot.energyLevel},
                      onSelectionChanged: state.isSaving
                          ? null
                          : (selected) =>
                                notifier.setEnergyLevel(selected.first),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (state.error != null) ...[
                    Text(
                      state.error!,
                      style: const TextStyle(color: AppColors.error),
                    ),
                    const SizedBox(height: 12),
                  ],
                  _RecommendationPreview(
                    text:
                        state.recommendations?.explanation ??
                        snapshot.recommendationExplanation,
                  ),
                  const SizedBox(height: 12),
                  _TimeBlockPreview(
                    previewTimeBlock: state.previewTimeBlock,
                    currentTimeBlock: snapshot.timeContext,
                    onChanged: state.isSaving
                        ? null
                        : (block) => ref
                              .read(contextIntelligenceProvider.notifier)
                              .previewTimeBlock(block),
                  ),
                  const SizedBox(height: 12),
                  if (state.recommendations != null) ...[
                    Text(
                      'Recommended task types',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ...state.recommendations!.recommendations.map(
                      (item) => _RecommendationTile(
                        title: item.title,
                        reason: item.reason,
                        taskType: item.taskType,
                        suggestedEnergy: item.suggestedEnergy,
                        preferenceMatch: item.preferenceMatch,
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  _ContextCard(
                    icon: Icons.schedule_outlined,
                    title: 'Time Context',
                    value: snapshot.timeContext,
                    detail: 'Timezone: ${snapshot.timezone}',
                  ),
                  _ContextCard(
                    icon: Icons.location_on_outlined,
                    title: 'Location Context',
                    value: snapshot.locationContext,
                    detail: 'Coarse context only',
                  ),
                  _ContextCard(
                    icon: Icons.devices_outlined,
                    title: 'Device Context',
                    value: snapshot.deviceContext,
                    detail: 'Optional manual/device summary',
                  ),
                  _ContextCard(
                    icon: Icons.wb_cloudy_outlined,
                    title: 'Weather Context',
                    value: snapshot.weatherContext,
                    detail: 'Optional summary, no live weather yet',
                  ),
                ],
              ),
            ),
    );
  }
}

class _TimeBlockPreview extends StatelessWidget {
  final String? previewTimeBlock;
  final String currentTimeBlock;
  final ValueChanged<String?>? onChanged;

  const _TimeBlockPreview({
    required this.previewTimeBlock,
    required this.currentTimeBlock,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    const blocks = ['morning', 'afternoon', 'evening', 'night'];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ChoiceChip(
          label: Text('Current (${_blockLabel(currentTimeBlock)})'),
          selected: previewTimeBlock == null,
          onSelected: onChanged == null ? null : (_) => onChanged!(null),
        ),
        ...blocks.map(
          (block) => ChoiceChip(
            label: Text(_blockLabel(block)),
            selected: previewTimeBlock == block,
            onSelected: onChanged == null ? null : (_) => onChanged!(block),
          ),
        ),
      ],
    );
  }
}

class _RecommendationTile extends StatelessWidget {
  final String title;
  final String reason;
  final String taskType;
  final String suggestedEnergy;
  final bool preferenceMatch;

  const _RecommendationTile({
    required this.title,
    required this.reason,
    required this.taskType,
    required this.suggestedEnergy,
    required this.preferenceMatch,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: preferenceMatch
              ? AppColors.primary.withValues(alpha: 0.35)
              : Colors.transparent,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            preferenceMatch
                ? Icons.flag_outlined
                : Icons.lightbulb_outline_rounded,
            color: preferenceMatch ? AppColors.primary : AppColors.warning,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  '$taskType · $suggestedEnergy energy',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget child;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}

class _RecommendationPreview extends StatelessWidget {
  final String text;

  const _RecommendationPreview({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome_outlined, color: AppColors.warning),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ContextCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;
  final String detail;

  const _ContextCard({
    required this.icon,
    required this.title,
    required this.value,
    required this.detail,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textSecondary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.check_circle_outline,
            size: 18,
            color: AppColors.success,
          ),
        ],
      ),
    );
  }
}

String _blockLabel(String block) {
  if (block.isEmpty) return 'Unknown';
  return block[0].toUpperCase() + block.substring(1);
}
