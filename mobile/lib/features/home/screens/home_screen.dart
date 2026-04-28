import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../voice/screens/voice_capture_screen.dart';
import '../../../core/theme/app_colors.dart';
import '../../hasae/widgets/hasae_next_action_card.dart';
import '../../hasae/widgets/overload_warning_card.dart';
import '../../auth/providers/auth_provider.dart';
import '../../dashboard/models/dashboard_model.dart';
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
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Hello, $name!',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Customize dashboard',
                      onPressed: data == null
                          ? null
                          : () => _openDashboardCustomization(data),
                      icon: const Icon(Icons.tune_outlined),
                    ),
                  ],
                ),
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

                const OverloadWarningCard(),
                const SizedBox(height: 12),
                const HasaeNextActionCard(),
                const SizedBox(height: 24),

                if (dashState.isLoading)
                  const Center(child: CircularProgressIndicator())
                else if (dashState.error != null)
                  _DashboardErrorCard(
                    message: dashState.error!,
                    onRetry: _refreshDashboard,
                  )
                else if (data == null)
                  _EmptyCard(message: 'Dashboard is empty')
                else ...[
                  _PersonalizedSetupCard(data: data),
                  const SizedBox(height: 12),
                  ..._dashboardWidgets(data).expand(
                    (widgetId) => [
                      _buildDashboardWidget(context, data, widgetId),
                      const SizedBox(height: 12),
                    ],
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
                      const SizedBox(width: 12),
                      Expanded(
                        child: _NavCard(
                          icon: Icons.sensors_outlined,
                          label: 'Context',
                          color: AppColors.prayerGold,
                          onTap: () => context.go('/home/context-intelligence'),
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

  List<String> _dashboardWidgets(DashboardData data) {
    return data.personalization.dailyDashboardWidgets
        .where(defaultDashboardWidgets.contains)
        .toList();
  }

  Future<void> _openDashboardCustomization(DashboardData data) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) =>
          _DashboardCustomizeSheet(currentWidgets: _dashboardWidgets(data)),
    );
  }

  Widget _buildDashboardWidget(
    BuildContext context,
    DashboardData data,
    String widgetId,
  ) {
    final personalization = data.personalization;
    return switch (widgetId) {
      'top_tasks' => _TopTasksSection(data: data),
      'next_prayer' => _NextPrayerCard(
        nextPrayer: personalization.nextPrayer,
        onTap: () => context.go('/home/prayer'),
      ),
      'habit_snapshot' => _HabitSnapshotCard(
        activeCount: personalization.habitSnapshot.activeCount,
        completedToday: personalization.habitSnapshot.completedToday,
        highlight: personalization.habitSnapshot.highlight,
        onTap: () => context.go('/home/habits'),
      ),
      'journal_prompt' => _JournalPromptCard(
        prompt: personalization.journalPrompt,
        onTap: () => context.go('/home/notes'),
      ),
      'ai_plan' => _AiPlanPreviewCard(
        title: personalization.aiPlanCard.title,
        preview: personalization.aiPlanCard.preview,
        onTap: () => context.go('/home/daily-plan'),
      ),
      'focus_shortcut' => _FocusShortcutCard(
        label: personalization.focusShortcut.label,
        minutes: personalization.focusShortcut.suggestedMinutes,
        onTap: () => context.go('/home/focus'),
      ),
      'productivity_score' => _ProductivityScoreCard(data: data),
      'quran_goal' => _QuranGoalDashboardCard(
        onTap: () => context.push('/home/prayer/quran-goal'),
      ),
      _ => const SizedBox.shrink(),
    };
  }
}

class _PersonalizedSetupCard extends StatelessWidget {
  final DashboardData data;

  const _PersonalizedSetupCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final personalization = data.personalization;
    final goalLabels = personalization.goalLabels;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  personalization.taskEnvironment,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          if (goalLabels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: goalLabels
                  .map(
                    (goal) => Chip(
                      label: Text(goal),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

class _TopTasksSection extends StatelessWidget {
  final DashboardData data;

  const _TopTasksSection({required this.data});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Text(
              'Top Tasks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => context.go('/home/tasks'),
              child: const Text('See all'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (data.topTasks.isEmpty)
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
      ],
    );
  }
}

class _ProductivityScoreCard extends StatelessWidget {
  final DashboardData data;

  const _ProductivityScoreCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final totalTasks = data.pendingCount + data.completedToday;
    final taskScore = totalTasks == 0
        ? 0
        : ((data.completedToday / totalTasks) * 55).round();
    final prayerTotal = data.prayerProgress.total <= 0
        ? 5
        : data.prayerProgress.total;
    final prayerScore = ((data.prayerProgress.completed / prayerTotal) * 45)
        .round();
    final score = (taskScore + prayerScore).clamp(0, 100);

    return _WideActionCard(
      icon: Icons.insights_outlined,
      title: 'Productivity score',
      subtitle:
          '$score% today - ${data.completedToday} tasks done, ${data.prayerProgress.completed}/$prayerTotal prayers tracked.',
      color: AppColors.success,
      onTap: () => context.go('/home/analytics'),
    );
  }
}

class _QuranGoalDashboardCard extends StatelessWidget {
  final VoidCallback onTap;

  const _QuranGoalDashboardCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _WideActionCard(
      icon: Icons.menu_book_outlined,
      title: 'Quran goal',
      subtitle: 'Open your daily Quran target and progress.',
      color: AppColors.prayerGold,
      onTap: onTap,
    );
  }
}

class _DashboardCustomizeSheet extends ConsumerStatefulWidget {
  final List<String> currentWidgets;

  const _DashboardCustomizeSheet({required this.currentWidgets});

  @override
  ConsumerState<_DashboardCustomizeSheet> createState() =>
      _DashboardCustomizeSheetState();
}

class _DashboardCustomizeSheetState
    extends ConsumerState<_DashboardCustomizeSheet> {
  late final List<String> _orderedWidgets;
  late final Set<String> _enabledWidgets;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _enabledWidgets = widget.currentWidgets.toSet();
    _orderedWidgets = [
      ...widget.currentWidgets,
      ...defaultDashboardWidgets.where(
        (id) => !widget.currentWidgets.contains(id),
      ),
    ];
  }

  Future<void> _save() async {
    setState(() => _isSaving = true);
    final enabled = _orderedWidgets
        .where((widgetId) => _enabledWidgets.contains(widgetId))
        .toList();
    final saved = await ref
        .read(dashboardProvider.notifier)
        .updateDashboardWidgets(enabled);
    if (!mounted) return;
    setState(() => _isSaving = false);
    if (saved) {
      Navigator.pop(context);
    } else {
      final error =
          ref.read(dashboardProvider).error ?? 'Dashboard not updated';
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Text(
                  'Customize Dashboard',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 420,
              child: ReorderableListView.builder(
                itemCount: _orderedWidgets.length,
                onReorder: (oldIndex, newIndex) {
                  setState(() {
                    if (newIndex > oldIndex) newIndex -= 1;
                    final item = _orderedWidgets.removeAt(oldIndex);
                    _orderedWidgets.insert(newIndex, item);
                  });
                },
                itemBuilder: (context, index) {
                  final widgetId = _orderedWidgets[index];
                  return SwitchListTile(
                    key: ValueKey(widgetId),
                    value: _enabledWidgets.contains(widgetId),
                    secondary: Icon(_dashboardWidgetIcon(widgetId)),
                    title: Text(_dashboardWidgetLabel(widgetId)),
                    subtitle: const Text('Drag to reorder'),
                    onChanged: (enabled) {
                      setState(() {
                        if (enabled) {
                          _enabledWidgets.add(widgetId);
                        } else {
                          _enabledWidgets.remove(widgetId);
                        }
                      });
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            _isSaving
                ? const CircularProgressIndicator()
                : ElevatedButton.icon(
                    onPressed: _save,
                    icon: const Icon(Icons.save_outlined),
                    label: const Text('Save'),
                  ),
          ],
        ),
      ),
    );
  }
}

String _dashboardWidgetLabel(String widgetId) {
  return switch (widgetId) {
    'top_tasks' => 'Top tasks',
    'next_prayer' => 'Next prayer',
    'habit_snapshot' => 'Habits',
    'journal_prompt' => 'Journal prompt',
    'ai_plan' => 'AI plan',
    'focus_shortcut' => 'Focus shortcut',
    'productivity_score' => 'Productivity score',
    'quran_goal' => 'Quran goal',
    _ => widgetId,
  };
}

IconData _dashboardWidgetIcon(String widgetId) {
  return switch (widgetId) {
    'top_tasks' => Icons.task_alt_outlined,
    'next_prayer' => Icons.mosque_outlined,
    'habit_snapshot' => Icons.track_changes_outlined,
    'journal_prompt' => Icons.edit_note_outlined,
    'ai_plan' => Icons.auto_awesome_outlined,
    'focus_shortcut' => Icons.timer_outlined,
    'productivity_score' => Icons.insights_outlined,
    'quran_goal' => Icons.menu_book_outlined,
    _ => Icons.dashboard_customize_outlined,
  };
}

class _NextPrayerCard extends StatelessWidget {
  final DashboardNextPrayer nextPrayer;
  final VoidCallback onTap;

  const _NextPrayerCard({required this.nextPrayer, required this.onTap});

  String _timeLabel() {
    final scheduledAt = nextPrayer.scheduledAt;
    if (scheduledAt == null || scheduledAt.length < 16) {
      return 'Open Prayer to sync today\'s times';
    }

    final parsed = DateTime.tryParse(scheduledAt);
    if (parsed == null) return 'Open Prayer to sync today\'s times';
    final local = parsed.toLocal();
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final title = nextPrayer.enabled
        ? nextPrayer.name ?? 'Next prayer'
        : 'Prayer rhythm';
    final subtitle = nextPrayer.enabled
        ? _timeLabel()
        : 'Add spiritual growth in onboarding settings to prioritize prayer anchors.';

    return _WideActionCard(
      icon: Icons.mosque_outlined,
      title: title,
      subtitle: subtitle,
      color: AppColors.prayerGold,
      onTap: onTap,
    );
  }
}

class _HabitSnapshotCard extends StatelessWidget {
  final int activeCount;
  final int completedToday;
  final String highlight;
  final VoidCallback onTap;

  const _HabitSnapshotCard({
    required this.activeCount,
    required this.completedToday,
    required this.highlight,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniActionCard(
      icon: Icons.track_changes_outlined,
      title: '$completedToday / $activeCount',
      subtitle: highlight,
      color: AppColors.success,
      onTap: onTap,
    );
  }
}

class _FocusShortcutCard extends StatelessWidget {
  final String label;
  final int minutes;
  final VoidCallback onTap;

  const _FocusShortcutCard({
    required this.label,
    required this.minutes,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _MiniActionCard(
      icon: Icons.timer_outlined,
      title: '$minutes min',
      subtitle: label,
      color: AppColors.primary,
      onTap: onTap,
    );
  }
}

class _AiPlanPreviewCard extends StatelessWidget {
  final String title;
  final String preview;
  final VoidCallback onTap;

  const _AiPlanPreviewCard({
    required this.title,
    required this.preview,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _WideActionCard(
      icon: Icons.auto_awesome,
      title: title,
      subtitle: preview,
      color: AppColors.warning,
      onTap: onTap,
    );
  }
}

class _JournalPromptCard extends StatelessWidget {
  final String prompt;
  final VoidCallback onTap;

  const _JournalPromptCard({required this.prompt, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _WideActionCard(
      icon: Icons.edit_note_outlined,
      title: 'Journal prompt',
      subtitle: prompt,
      color: AppColors.prayerGold,
      onTap: onTap,
    );
  }
}

class _MiniActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 112,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.28)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const Spacer(),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _WideActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _WideActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.26)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: color),
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
