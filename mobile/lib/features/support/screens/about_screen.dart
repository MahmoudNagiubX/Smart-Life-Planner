import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  static const appVersion = '1.0.0+1';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('About', style: AppTextStyles.h2Light),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.s8,
          AppSpacing.screenH, AppSpacing.s32,
        ),
        children: [
          // Hero header card
          Container(
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
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.35),
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_outlined,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: AppSpacing.s16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Smart Life Planner',
                        style: AppTextStyles.h3(Colors.white),
                      ),
                      const SizedBox(height: AppSpacing.s4),
                      Text(
                        'Personal planning, habits, prayer, focus, notes, and AI-assisted capture.',
                        style: AppTextStyles.bodySmall(
                          Colors.white.withValues(alpha: 0.88),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          _InfoCard(
            icon: Icons.info_outline,
            title: 'App',
            color: AppColors.brandPrimary,
            rows: const [
              _InfoRow(label: 'Name', value: 'Smart Life Planner'),
              _InfoRow(label: 'Version', value: appVersion),
              _InfoRow(label: 'Status', value: 'MVP demo build'),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          _InfoCard(
            icon: Icons.memory_outlined,
            title: 'Technology stack',
            color: AppColors.featAI,
            rows: const [
              _InfoRow(label: 'Mobile', value: 'Flutter + Riverpod'),
              _InfoRow(label: 'Backend', value: 'FastAPI + PostgreSQL'),
              _InfoRow(label: 'Routing', value: 'GoRouter'),
              _InfoRow(label: 'AI/Voice', value: 'Groq API integrations'),
              _InfoRow(
                label: 'Notifications',
                value: 'Local + unified reminders',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _InfoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<_InfoRow> rows;

  const _InfoCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.avatar,
                height: AppIconSize.avatar,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: AppIconSize.cardHeader),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(title, style: AppTextStyles.h4Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
          ...rows,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(label, style: AppTextStyles.captionLight),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall(AppColors.textHeading)
                  .copyWith(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
