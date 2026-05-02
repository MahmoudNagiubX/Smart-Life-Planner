import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('AI Assistant', style: AppTextStyles.h2Light),
            Text(
              'Ready to help when AI flows are available.',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          AppSpacing.s16,
          AppSpacing.screenH,
          AppSpacing.s32,
        ),
        children: [
          const _AiHeaderCard(),
          const SizedBox(height: AppSpacing.s16),
          const _AssistantMessageCard(),
          const SizedBox(height: AppSpacing.s16),
          Wrap(
            spacing: AppSpacing.s8,
            runSpacing: AppSpacing.s8,
            children: const [
              _SuggestionChip(label: 'Plan my day'),
              _SuggestionChip(label: 'Review progress'),
              _SuggestionChip(label: 'Break down a goal'),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),
          Text('Prepared flows', style: AppTextStyles.h4Light),
          const SizedBox(height: AppSpacing.s12),
          ...aiCoachFeatures.map(
            (feature) => _CoachFeatureCard(feature: feature),
          ),
        ],
      ),
    );
  }
}

class _AiHeaderCard extends StatelessWidget {
  const _AiHeaderCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.bgSurface.withValues(alpha: 0.18),
              borderRadius: AppRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.bgSurface.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.psychology_alt_outlined,
              color: AppColors.bgSurface,
              size: 30,
            ),
          ),
          const SizedBox(width: AppSpacing.s16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Life Coach',
                  style: AppTextStyles.h3(AppColors.bgSurface),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Coaching surfaces stay read-only until their safe AI flows are connected.',
                  style: AppTextStyles.bodySmall(
                    AppColors.bgSurface.withValues(alpha: 0.86),
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

class _AssistantMessageCard extends StatelessWidget {
  const _AssistantMessageCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: AppIconSize.avatar,
            height: AppIconSize.avatar,
            decoration: BoxDecoration(
              color: AppColors.featAISoft,
              borderRadius: AppRadius.circular(AppRadius.md),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.featAI,
              size: AppIconSize.cardHeader,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Assistant',
                  style: AppTextStyles.label(AppColors.textHeading),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  'Choose a prepared coaching area to preview what is coming next. No data is changed automatically from this screen.',
                  style: AppTextStyles.bodySmallLight,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SuggestionChip extends StatelessWidget {
  final String label;

  const _SuggestionChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s12,
        vertical: AppSpacing.s8,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.pillBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Text(label, style: AppTextStyles.label(AppColors.brandPrimary)),
    );
  }
}

class _CoachFeatureCard extends StatelessWidget {
  final AiCoachFeature feature;

  const _CoachFeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Material(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.circular(AppRadius.xl),
        child: InkWell(
          borderRadius: AppRadius.circular(AppRadius.xl),
          onTap: () => context.push('${AppRoutes.aiCoach}/${feature.id}'),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s16),
            child: Row(
              children: [
                Container(
                  width: AppIconSize.avatar,
                  height: AppIconSize.avatar,
                  decoration: BoxDecoration(
                    color: AppColors.featAISoft,
                    borderRadius: AppRadius.circular(AppRadius.md),
                  ),
                  child: Icon(
                    feature.icon,
                    color: AppColors.featAI,
                    size: AppIconSize.cardHeader,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(feature.title, style: AppTextStyles.h4Light),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        feature.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmallLight,
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: AppColors.textHint,
                  size: AppIconSize.action,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
