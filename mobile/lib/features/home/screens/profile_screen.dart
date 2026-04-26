import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../features/auth/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

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
                      backgroundColor: AppColors.primary.withOpacity(0.2),
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
                onTap: () => context.push('/home/change-password'),
              ),

              const SizedBox(height: 32),

              // Sign out
              ElevatedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
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
