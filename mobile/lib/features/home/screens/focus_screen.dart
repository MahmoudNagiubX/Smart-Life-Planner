import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../focus/models/focus_model.dart';
import '../../focus/providers/focus_provider.dart';

class FocusScreen extends ConsumerStatefulWidget {
  const FocusScreen({super.key});

  @override
  ConsumerState<FocusScreen> createState() => _FocusScreenState();
}

class _FocusScreenState extends ConsumerState<FocusScreen> {
  int _selectedMinutes = 25;
  final List<int> _presets = [15, 25, 45, 60];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(focusProvider.notifier).loadAnalytics();
    });
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(focusProvider);
    final hasActive = state.activeSession != null;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '⏱️ Focus',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Analytics row
            if (state.analytics != null) ...[
              Row(
                children: [
                  Expanded(
                    child: _StatCard(
                      label: 'Today',
                      value: '${state.analytics!.todayMinutes}m',
                      sub: '${state.analytics!.todaySessions} sessions',
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatCard(
                      label: 'This Week',
                      value: '${state.analytics!.weekMinutes}m',
                      sub: '${state.analytics!.weekSessions} sessions',
                      color: AppColors.success,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],

            // Timer card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  if (hasActive) ...[
                    Text(
                      _formatTime(state.remainingSeconds),
                      style: Theme.of(context)
                          .textTheme
                          .displayLarge
                          ?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            fontSize: 72,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Session in progress',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    // Progress indicator
                    LinearProgressIndicator(
                      value: state.activeSession != null
                          ? state.remainingSeconds /
                              (state.activeSession!.plannedMinutes * 60)
                          : 0,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                      minHeight: 6,
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () =>
                                ref.read(focusProvider.notifier).cancelSession(),
                            icon: const Icon(Icons.close, color: AppColors.error),
                            label: const Text(
                              'Cancel',
                              style: TextStyle(color: AppColors.error),
                            ),
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: AppColors.error),
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => ref
                                .read(focusProvider.notifier)
                                .completeSession(),
                            icon: const Icon(Icons.check),
                            label: const Text('Done'),
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(0, 48),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    const Text(
                      '🎯',
                      style: TextStyle(fontSize: 56),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Start a Focus Session',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),

                    // Preset buttons
                    Wrap(
                      spacing: 8,
                      children: _presets.map((min) {
                        final selected = _selectedMinutes == min;
                        return ChoiceChip(
                          label: Text('${min}m'),
                          selected: selected,
                          selectedColor: AppColors.primary,
                          onSelected: (_) =>
                              setState(() => _selectedMinutes = min),
                          labelStyle: TextStyle(
                            color: selected ? Colors.white : null,
                            fontWeight: FontWeight.w600,
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),

                    state.isLoading
                        ? const CircularProgressIndicator()
                        : ElevatedButton.icon(
                            onPressed: () => ref
                                .read(focusProvider.notifier)
                                .startSession(
                                  plannedMinutes: _selectedMinutes,
                                ),
                            icon: const Icon(Icons.play_arrow),
                            label: Text('Start $_selectedMinutes min session'),
                          ),

                    if (state.error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        state.error!,
                        style: const TextStyle(color: AppColors.error),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ],
              ),
            ),

            // Recent sessions
            if (state.sessions.isNotEmpty) ...[
              const SizedBox(height: 32),
              Text(
                'Recent Sessions',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              ...state.sessions.take(5).map(
                    (s) => _SessionTile(session: s),
                  ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _StatCard({
    required this.label,
    required this.value,
    required this.sub,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          Text(
            sub,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _SessionTile extends StatelessWidget {
  final FocusSession session;

  const _SessionTile({required this.session});

  @override
  Widget build(BuildContext context) {
    final isCompleted = session.status == 'completed';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            isCompleted ? Icons.check_circle : Icons.cancel,
            color: isCompleted ? AppColors.success : AppColors.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${session.plannedMinutes} min ${session.sessionType}',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            isCompleted
                ? '${session.actualMinutes ?? 0}m done'
                : 'cancelled',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppColors.textSecondary,
                ),
          ),
        ],
      ),
    );
  }
}