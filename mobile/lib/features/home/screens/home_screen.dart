import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../dashboard/widgets/quick_capture_sheet.dart';
import '../../tasks/providers/task_provider.dart';
import '../../ai/providers/ai_provider.dart';
import '../../ai/widgets/next_action_card.dart';

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
      ref.read(aiProvider.notifier).loadNextAction();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning ☀️';
    if (hour < 17) return 'Good afternoon 🌤️';
    return 'Good evening 🌙';
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
          onRefresh: () async {
            await ref.read(dashboardProvider.notifier).loadDashboard();
            await ref.read(aiProvider.notifier).loadNextAction();
          },
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),

                // Greeting
                Text(
                  '👋 Hello, $name!',
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
                const SizedBox(height: 16),

                const NextActionCard(),

                const SizedBox(height: 24),

                // Quick capture button
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
                      await ref
                          .read(dashboardProvider.notifier)
                          .loadDashboard();
                      await ref.read(aiProvider.notifier).loadNextAction();
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
                        color: AppColors.primary.withOpacity(0.4),
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
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Stats row
                if (dashState.isLoading)
                  const Center(child: CircularProgressIndicator())
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
                  const SizedBox(height: 28),

                  // Top tasks
                  Text(
                    'Upcoming Tasks',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (data == null || data.topTasks.isEmpty)
                    _EmptyCard(message: 'No pending tasks 🎉 Enjoy your day!')
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

                  // Coming soon cards
                  Text(
                    'Today\'s Overview',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ComingSoonCard(
                    icon: Icons.mosque_outlined,
                    label: 'Next Prayer',
                    color: AppColors.prayerGold,
                  ),
                  const SizedBox(height: 12),
                  _ComingSoonCard(
                    icon: Icons.timer_outlined,
                    label: 'Focus Session',
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  _ComingSoonCard(
                    icon: Icons.track_changes_outlined,
                    label: 'Habits',
                    color: AppColors.success,
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

class _ComingSoonCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _ComingSoonCard({
    required this.icon,
    required this.label,
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
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
              Text(
                'Coming soon',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
