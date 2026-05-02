import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';

class DeferredScopeScreen extends StatelessWidget {
  final String title;
  final String description;
  final String availableNow;
  final IconData icon;

  const DeferredScopeScreen({
    super.key,
    required this.title,
    required this.description,
    required this.availableNow,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text(title, style: AppTextStyles.h2Light),
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.s24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.warningColor.withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppColors.warningColor.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Icon(icon, color: AppColors.warningColor, size: 34),
                  ),
                  const SizedBox(height: AppSpacing.s20),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.h3Light,
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.body(AppColors.textBody),
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  Text(
                    availableNow,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(AppColors.textHint),
                  ),
                  const SizedBox(height: AppSpacing.s24),
                  OutlinedButton.icon(
                    onPressed: () => context.go('/home'),
                    icon: const Icon(Icons.dashboard_outlined,
                        color: AppColors.brandPrimary),
                    label: const Text(
                      'Back to Home',
                      style: TextStyle(color: AppColors.brandPrimary),
                    ),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.brandPrimary),
                      shape: RoundedRectangleBorder(
                          borderRadius: AppRadius.pillBr),
                      padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.s20,
                          vertical: AppSpacing.s12),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
