import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../voice/screens/voice_capture_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/widgets/next_action_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/quick_capture_sheet.dart';
import '../../tasks/providers/task_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dashboardProvider.notifier).loadDashboard();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  Future<void> _refreshDashboard() {
    return ref.read(dashboardProvider.notifier).loadDashboard();
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final dashState = ref.watch(dashboardProvider);
    final name = authState.user?['full_name'] as String? ?? 'Friend';
    final data = dashState.data;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshDashboard,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                Text(
                  'Hello, $name!',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _greeting(),
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),

                GestureDetector(
                  onTap: () async {
                    await showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Theme.of(
                        context,
                      ).scaffoldBackgroundColor,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(
                          top: Radius.circular(20),
                        ),
                      ),
                      builder: (_) => const QuickCaptureSheet(),
                    );
                    if (context.mounted) {
                      await _refreshDashboard();
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 14,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).cardTheme.color,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppColors.primary.withValues(alpha: 0.4),
                      ),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.bolt, color: AppColors.primary),
                        const SizedBox(width: 12),
                        Text(
                          'Quick capture...',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppColors.textSecondary),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const VoiceCaptureScreen(),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic,
                              color: AppColors.primary,
                              size: 18,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                const NextActionCard(),
                const SizedBox(height: 24),

                if (dashState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (dashState.error != null)
                  _DashboardErrorCard(
                    message: dashState.error!,
                    onRetry: _refreshDashboard,
                  )
                else ...[
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          icon: Icons.pending_actions,
                          label: 'Pending',
                          value: '${data?.pendingCount ?? 0}',
                          color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          icon: Icons.check_circle_outline,
                          label: 'Done Today',
                          value: '${data?.completedToday ?? 0}',
                          color: AppColors.success,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _PrayerProgressCard(
                    completed: data?.prayerProgress.completed ?? 0,
                    total: data?.prayerProgress.total ?? 5,
                    onTap: () => context.go('/home/prayer'),
                  ),
                  const SizedBox(height: 28),

                  Row(
                    children: [
                      Text(
                        'Upcoming Tasks',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () => context.go('/home/tasks'),
                        child: const Text('See all'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (data == null || data.topTasks.isEmpty)
                    _EmptyCard(message: 'No pending tasks')
                  else
                    ...data.topTasks.map(
                      (task) => _TopTaskTile(
                        id: task.id,
                        title: task.title,
                        priority: task.priority,
                        dueAt: task.dueAt,
                      ),
                    ),
                  const SizedBox(height: 28),

                  Text(
                    "Today's Tools",
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _NavCard(
                          icon: Icons.timer_outlined,
                          label: 'Focus',
                          color: AppColors.primary,
                          onTap: () => context.go('/home/focus'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavCard(
                          icon: Icons.track_changes_outlined,
                          label: 'Habits',
                          color: AppColors.success,
                          onTap: () => context.go('/home/habits'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavCard(
                          icon: Icons.calendar_today_outlined,
                          label: 'AI Plan',
                          color: AppColors.warning,
                          onTap: () => context.go('/home/daily-plan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ],
      ),
    );
  }
}

class _PrayerProgressCard extends StatelessWidget {
  final int completed;
  final int total;
  final VoidCallback onTap;

  const _PrayerProgressCard({
    required this.completed,
    required this.total,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final safeTotal = total <= 0 ? 5 : total;
    final progress = (completed / safeTotal).clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.prayerGold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.prayerGold.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.mosque_outlined, color: AppColors.prayerGold),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Prayers Today',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$completed / $safeTotal completed',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.prayerGold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(999),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 6,
                      backgroundColor: AppColors.prayerGold.withValues(
                        alpha: 0.18,
                      ),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.prayerGold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.chevron_right, color: AppColors.prayerGold),
          ],
        ),
      ),
    );
  }
}

class _TopTaskTile extends ConsumerWidget {
  final String id;
  final String title;
  final String priority;
  final String? dueAt;

  const _TopTaskTile({
    required this.id,
    required this.title,
    required this.priority,
    this.dueAt,
  });

  Color _priorityColor(String p) {
    if (p == 'high') return AppColors.error;
    if (p == 'medium') return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border(
          left: BorderSide(color: _priorityColor(priority), width: 3),
        ),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: () async {
              await ref.read(tasksProvider.notifier).completeTask(id);
              await ref.read(dashboardProvider.notifier).loadDashboard();
            },
            child: const Icon(
              Icons.radio_button_unchecked,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
                if (dueAt != null)
                  Text(
                    'Due: ${dueAt!.substring(0, 10)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
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

class _DashboardErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _DashboardErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dashboard failed to load',
            style: TextStyle(
              color: AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(child: Text(message)),
    );
  }
}

class _NavCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _NavCard({
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
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
