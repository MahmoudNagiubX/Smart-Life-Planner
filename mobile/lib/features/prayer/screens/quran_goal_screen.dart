import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../models/quran_goal_model.dart';
import '../providers/quran_goal_provider.dart';

class QuranGoalScreen extends ConsumerStatefulWidget {
  const QuranGoalScreen({super.key});

  @override
  ConsumerState<QuranGoalScreen> createState() => _QuranGoalScreenState();
}

class _QuranGoalScreenState extends ConsumerState<QuranGoalScreen> {
  final _targetController = TextEditingController();
  int _pagesCompleted = 0;
  String? _syncedKey;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(quranGoalProvider.notifier).loadSummary();
    });
  }

  @override
  void dispose() {
    _targetController.dispose();
    super.dispose();
  }

  void _syncControllers(QuranGoalSummary summary) {
    final key = '${summary.dailyPageTarget}|${summary.todayPagesCompleted}';
    if (_syncedKey == key) return;
    _syncedKey = key;
    _targetController.text = summary.dailyPageTarget == 0
        ? ''
        : summary.dailyPageTarget.toString();
    _pagesCompleted = summary.todayPagesCompleted;
  }

  Future<void> _saveGoal() async {
    final target = int.tryParse(_targetController.text.trim());
    if (target == null || target < 1 || target > 604) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter a target between 1 and 604 pages.'),
        ),
      );
      return;
    }
    await ref.read(quranGoalProvider.notifier).saveGoal(target);
  }

  Future<void> _saveProgress() async {
    await ref
        .read(quranGoalProvider.notifier)
        .updateTodayProgress(_pagesCompleted);
  }

  void _changeProgress(int delta) {
    setState(() {
      _pagesCompleted = (_pagesCompleted + delta).clamp(0, 604);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(quranGoalProvider);
    final summary = state.summary;
    if (summary != null) {
      _syncControllers(summary);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Quran Goal',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: state.isLoading && summary == null
          ? const AppLoadingState(message: 'Loading Quran goal...')
          : state.error != null && summary == null
          ? AppErrorState(
              title: 'Quran goal could not load',
              message: state.error!,
              onRetry: () => ref.read(quranGoalProvider.notifier).loadSummary(),
            )
          : RefreshIndicator(
              onRefresh: () =>
                  ref.read(quranGoalProvider.notifier).loadSummary(),
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                children: [
                  _DailyTargetCard(
                    controller: _targetController,
                    isSaving: state.isSaving,
                    onSave: _saveGoal,
                  ),
                  const SizedBox(height: 16),
                  _TodayProgressCard(
                    summary: summary,
                    pagesCompleted: _pagesCompleted,
                    isSaving: state.isSaving,
                    onDecrease: () => _changeProgress(-1),
                    onIncrease: () => _changeProgress(1),
                    onSave: _saveProgress,
                  ),
                  const SizedBox(height: 16),
                  _WeeklySummaryCard(summary: summary),
                  if (state.error != null && summary != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.error),
                    ),
                  ],
                ],
              ),
            ),
    );
  }
}

class _DailyTargetCard extends StatelessWidget {
  final TextEditingController controller;
  final bool isSaving;
  final VoidCallback onSave;

  const _DailyTargetCard({
    required this.controller,
    required this.isSaving,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return _QuranCard(
      icon: Icons.flag_outlined,
      title: 'Daily Page Target',
      child: Column(
        children: [
          TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Pages per day',
              prefixIcon: Icon(Icons.menu_book_outlined),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Target'),
            ),
          ),
        ],
      ),
    );
  }
}

class _TodayProgressCard extends StatelessWidget {
  final QuranGoalSummary? summary;
  final int pagesCompleted;
  final bool isSaving;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final VoidCallback onSave;

  const _TodayProgressCard({
    required this.summary,
    required this.pagesCompleted,
    required this.isSaving,
    required this.onDecrease,
    required this.onIncrease,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final target = summary?.dailyPageTarget ?? 0;
    final progress = target == 0
        ? 0.0
        : (pagesCompleted / target).clamp(0.0, 1.0);

    return _QuranCard(
      icon: Icons.today_outlined,
      title: 'Today',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease pages',
                onPressed: pagesCompleted == 0 ? null : onDecrease,
                icon: const Icon(Icons.remove_circle_outline),
              ),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      '$pagesCompleted ${pagesCompleted == 1 ? 'page' : 'pages'}',
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(
                            color: AppColors.prayerGold,
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      target == 0
                          ? 'Set a daily target first'
                          : 'of $target pages today',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Increase pages',
                onPressed: onIncrease,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.prayerGold.withValues(alpha: 0.15),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.prayerGold,
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: isSaving ? null : onSave,
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Save Today'),
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklySummaryCard extends StatelessWidget {
  final QuranGoalSummary? summary;

  const _WeeklySummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final weeklySummary = summary?.weeklySummary ?? const [];
    return _QuranCard(
      icon: Icons.calendar_month_outlined,
      title: 'Weekly Summary',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${summary?.weeklyTotalPages ?? 0} / ${summary?.weeklyTargetPages ?? 0} pages this week',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 6),
          Text(
            'A fuller weekly Quran reflection will be added after the MVP goal flow is stable.',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: weeklySummary.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _WeeklyDayPill(item: item),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _WeeklyDayPill extends StatelessWidget {
  final QuranWeeklyProgressItem item;

  const _WeeklyDayPill({required this.item});

  @override
  Widget build(BuildContext context) {
    final label = item.progressDate.length >= 10
        ? item.progressDate.substring(5)
        : item.progressDate;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: item.targetMet
            ? AppColors.prayerGold.withValues(alpha: 0.16)
            : Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: item.targetMet
              ? AppColors.prayerGold.withValues(alpha: 0.45)
              : AppColors.textSecondary.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontSize: 10,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${item.pagesCompleted}',
            style: const TextStyle(
              color: AppColors.prayerGold,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuranCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _QuranCard({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.prayerGold.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.prayerGold.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.prayerGold),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: AppColors.prayerGold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }
}
