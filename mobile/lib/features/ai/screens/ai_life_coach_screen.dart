import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';

class AiCoachFeature {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const AiCoachFeature({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const aiCoachFeatures = [
  AiCoachFeature(
    id: 'goal-roadmap',
    title: 'Goal Roadmap',
    description: 'Future guided roadmap for turning goals into milestones.',
    icon: Icons.flag_outlined,
  ),
  AiCoachFeature(
    id: 'study-planner',
    title: 'Study Planner AI',
    description: 'Future study plan suggestions based on deadlines and energy.',
    icon: Icons.school_outlined,
  ),
  AiCoachFeature(
    id: 'weekly-life-review',
    title: 'AI Weekly Review',
    description:
        'Future weekly reflection across tasks, habits, focus, and prayer.',
    icon: Icons.event_note_outlined,
  ),
  AiCoachFeature(
    id: 'motivation-engine',
    title: 'Motivation Engine',
    description: 'Future gentle encouragement based on safe app signals.',
    icon: Icons.favorite_border,
  ),
  AiCoachFeature(
    id: 'goal-decomposition',
    title: 'Long-Term Goal Decomposition',
    description: 'Future flow for breaking big goals into clear next actions.',
    icon: Icons.account_tree_outlined,
  ),
];

AiCoachFeature aiCoachFeatureById(String id) {
  return aiCoachFeatures.firstWhere(
    (feature) => feature.id == id,
    orElse: () => aiCoachFeatures.first,
  );
}

class AiLifeCoachScreen extends StatelessWidget {
  const AiLifeCoachScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'AI Life Coach',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.28),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.psychology_alt_outlined,
                  color: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'These coaching surfaces are prepared for future safe AI flows. Nothing here changes your data automatically.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...aiCoachFeatures.map(
            (feature) => _CoachFeatureCard(feature: feature),
          ),
        ],
      ),
    );
  }
}

class _CoachFeatureCard extends StatelessWidget {
  final AiCoachFeature feature;

  const _CoachFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => context.push('${AppRoutes.aiCoach}/${feature.id}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(feature.icon, color: AppColors.warning),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        feature.title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        feature.description,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
