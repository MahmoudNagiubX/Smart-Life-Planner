import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../routes/app_routes.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    Future<void> showDeleteDialog() async {
      final controller = TextEditingController();
      final result = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Delete Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'This action is permanent and cannot be undone. All your data will be erased after 30 days.',
                style: TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              const Text(
                'To confirm, enter your password. If you signed in with Google or Apple, type the word DELETE.',
              ),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Password or DELETE',
                  border: OutlineInputBorder(),
                ),
                obscureText: true,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete Permanently'),
            ),
          ],
        ),
      );

      if (result == true && context.mounted) {
        final input = controller.text.trim();
        if (input.isEmpty) return;

        final isSocial = input.toUpperCase() == 'DELETE';
        final success = await ref
            .read(authProvider.notifier)
            .deleteAccount(
              password: isSocial ? null : input,
              confirmation: isSocial ? 'DELETE' : null,
            );

        if (success && context.mounted) {
          context.go(AppRoutes.welcome);
        } else if (context.mounted) {
          final error = ref.read(authProvider).error;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(error ?? 'Failed to delete account'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                'Profile',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // User card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: const Icon(
                        Icons.person,
                        size: 28,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?['full_name'] as String? ?? '',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          user?['email'] as String? ?? '',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Menu items
              _MenuItem(
                icon: Icons.analytics_outlined,
                label: 'Analytics & Insights',
                color: AppColors.primary,
                onTap: () => context.push('/home/analytics'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.task_alt,
                label: 'My Tasks',
                color: AppColors.success,
                onTap: () => context.go('/home/tasks'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.track_changes_outlined,
                label: 'My Habits',
                color: AppColors.warning,
                onTap: () => context.go('/home/habits'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.notes_outlined,
                label: 'My Notes',
                color: AppColors.prayerGold,
                onTap: () => context.push('/home/notes'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.calendar_today_outlined,
                label: 'AI Daily Plan',
                color: AppColors.primary,
                onTap: () => context.push('/home/daily-plan'),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.lock_outlined,
                label: 'Change Password',
                color: AppColors.textSecondary,
                onTap: () => context.push(AppRoutes.changePassword),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.settings_outlined,
                label: 'Settings',
                color: AppColors.textSecondary,
                onTap: () => context.push(AppRoutes.settings),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.notifications_active_outlined,
                label: 'Notification Center',
                color: AppColors.primary,
                onTap: () => context.push(AppRoutes.notificationCenter),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.notifications_outlined,
                label: 'Notification Settings',
                color: AppColors.warning,
                onTap: () => context.push(AppRoutes.notificationSettings),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.language,
                label: 'Language',
                color: AppColors.success,
                onTap: () => context.push(AppRoutes.languageSettings),
              ),
              const SizedBox(height: 10),
              _MenuItem(
                icon: Icons.mosque_outlined,
                label: 'Prayer Settings',
                color: AppColors.prayerGold,
                onTap: () => context.push(AppRoutes.prayerSettings),
              ),

              const SizedBox(height: 32),

              // Sign out
              ElevatedButton.icon(
                onPressed: () async {
                  final confirmed = await confirmDestructiveAction(
                    context: context,
                    title: 'Sign Out',
                    message: 'Sign out of Smart Life Planner on this device?',
                    confirmLabel: 'Sign Out',
                  );
                  if (!confirmed) return;
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  foregroundColor: Colors.red,
                  elevation: 0,
                  side: const BorderSide(color: Colors.red),
                ),
              ),

              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 16),

              // Danger Zone
              Text(
                'Danger Zone',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.red,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: showDeleteDialog,
                icon: const Icon(Icons.delete_forever),
                label: const Text('Delete Account'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.red,
                  side: const BorderSide(color: Colors.red),
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(Icons.chevron_right, color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
