import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_empty_state.dart';

class FeaturePlaceholderScreen extends StatelessWidget {
  final String title;
  final String description;
  final IconData icon;
  final Color accentColor;
  final String? destructiveActionLabel;
  final String? destructiveActionTitle;
  final String? destructiveActionMessage;
  final String? destructiveActionDoneMessage;

  const FeaturePlaceholderScreen({
    super.key,
    required this.title,
    required this.description,
    required this.icon,
    this.accentColor = AppColors.brandPrimary,
    this.destructiveActionLabel,
    this.destructiveActionTitle,
    this.destructiveActionMessage,
    this.destructiveActionDoneMessage,
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
        child: AppEmptyState(
          icon: icon,
          title: title,
          message: description,
          accentColor: accentColor,
          action: destructiveActionLabel == null
              ? null
              : OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.errorColor,
                    side: const BorderSide(color: AppColors.errorColor),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  onPressed: () async {
                    final confirmed = await confirmDestructiveAction(
                      context: context,
                      title: destructiveActionTitle ?? destructiveActionLabel!,
                      message:
                          destructiveActionMessage ??
                          'Confirm this destructive action?',
                      confirmLabel: destructiveActionLabel!,
                    );
                    if (!confirmed || !context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          destructiveActionDoneMessage ??
                              'Action confirmed. This feature is not active yet.',
                        ),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: AppRadius.pillBr),
                      ),
                    );
                  },
                  icon: const Icon(Icons.warning_amber_outlined),
                  label: Text(destructiveActionLabel!),
                ),
        ),
      ),
    );
  }
}
