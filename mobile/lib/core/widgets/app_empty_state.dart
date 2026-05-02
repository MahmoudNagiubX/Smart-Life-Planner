import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color accentColor;
  final Widget? action;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.accentColor = AppColors.brandPrimary,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: accentColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: accentColor.withValues(alpha: 0.35),
                  ),
                ),
                child: Icon(icon, color: accentColor, size: 34),
              ),
              const SizedBox(height: AppSpacing.s20),
              Text(
                title,
                textAlign: TextAlign.center,
                style: AppTextStyles.h3Light,
              ),
              const SizedBox(height: AppSpacing.s8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: AppTextStyles.body(AppColors.textBody),
              ),
              if (action != null) ...[
                const SizedBox(height: AppSpacing.s20),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}
