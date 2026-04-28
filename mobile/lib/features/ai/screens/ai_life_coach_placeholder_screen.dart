import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import 'ai_life_coach_screen.dart';

class AiLifeCoachPlaceholderScreen extends StatelessWidget {
  final String featureId;

  const AiLifeCoachPlaceholderScreen({super.key, required this.featureId});

  @override
  Widget build(BuildContext context) {
    final feature = aiCoachFeatureById(featureId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          feature.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.warning.withValues(alpha: 0.28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(feature.icon, color: AppColors.warning, size: 34),
                const SizedBox(height: 14),
                Text(
                  feature.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  feature.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const _SafetyNotice(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _PreparedContract(featureId: feature.id),
        ],
      ),
    );
  }
}

class _SafetyNotice extends StatelessWidget {
  const _SafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Placeholder only: future coaching will preview suggestions and ask before creating or changing tasks.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _PreparedContract extends StatelessWidget {
  final String featureId;

  const _PreparedContract({required this.featureId});

  @override
  Widget build(BuildContext context) {
    final items = switch (featureId) {
      'goal-roadmap' => [
        'Goal title and target date',
        'Milestone draft preview',
        'Editable next actions',
      ],
      'study-planner' => [
        'Subject and exam date',
        'Study session suggestions',
        'Energy-aware review blocks',
      ],
      'weekly-life-review' => [
        'Weekly activity summary',
        'Wins and blockers',
        'Editable next week focus',
      ],
      'motivation-engine' => [
        'Gentle encouragement tone',
        'No shame or pressure nudges',
        'User-controlled reminders',
      ],
      _ => [
        'Long-term goal input',
        'Milestone decomposition preview',
        'Confirm-before-create task flow',
      ],
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prepared Future Contract',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
