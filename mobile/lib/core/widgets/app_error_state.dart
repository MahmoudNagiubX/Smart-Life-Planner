import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_empty_state.dart';

class AppErrorState extends StatelessWidget {
  final String title;
  final String message;
  final Future<void> Function()? onRetry;

  const AppErrorState({
    super.key,
    this.title = 'Something went wrong',
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return AppEmptyState(
      icon: Icons.error_outline,
      title: title,
      message: message,
      accentColor: AppColors.error,
      action: onRetry == null
          ? null
          : OutlinedButton.icon(
              onPressed: () => onRetry!(),
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
    );
  }
}
