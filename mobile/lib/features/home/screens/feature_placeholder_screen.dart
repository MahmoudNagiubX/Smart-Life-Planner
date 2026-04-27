import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
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
    this.accentColor = AppColors.primary,
    this.destructiveActionLabel,
    this.destructiveActionTitle,
    this.destructiveActionMessage,
    this.destructiveActionDoneMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
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
                    foregroundColor: AppColors.error,
                    side: const BorderSide(color: AppColors.error),
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
