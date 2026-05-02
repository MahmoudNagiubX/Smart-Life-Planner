import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_tokens.dart';

class AppLoadingState extends StatelessWidget {
  final String message;

  const AppLoadingState({super.key, this.message = 'Loading...'});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: AppColors.brandPrimary),
            const SizedBox(height: AppSpacing.s16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body(AppColors.textBody),
            ),
          ],
        ),
      ),
    );
  }
}
