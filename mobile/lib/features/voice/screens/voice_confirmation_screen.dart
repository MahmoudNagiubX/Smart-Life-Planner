import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../tasks/providers/task_provider.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../providers/voice_provider.dart';

class VoiceConfirmationScreen extends ConsumerWidget {
  const VoiceConfirmationScreen({super.key});

  Color _priorityColor(String priority) {
    if (priority == 'high') return AppColors.error;
    if (priority == 'medium') return AppColors.warning;
    return AppColors.success;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceProvider);
    final result = state.result;

    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedCount = state.editableTasks.where((t) => t.isSelected).length;

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '🤖 Review Tasks',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            ref.read(voiceProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          // Transcript card
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.record_voice_over,
                      color: AppColors.primary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Transcript',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: _confidenceColor(
                          result.confidence,
                        ).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        result.confidence.toUpperCase(),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: _confidenceColor(result.confidence),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  result.transcribedText,
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  result.displayText,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),

          // Tasks list
          Expanded(
            child: state.editableTasks.isEmpty
                ? const Center(
                    child: Text(
                      'No tasks detected.\nTry speaking again.',
                      textAlign: TextAlign.center,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: state.editableTasks.length,
                    itemBuilder: (context, index) {
                      final task = state.editableTasks[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: task.isSelected
                              ? Theme.of(context).cardTheme.color
                              : Theme.of(
                                  context,
                                ).cardTheme.color?.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(12),
                          border: Border(
                            left: BorderSide(
                              color: task.isSelected
                                  ? _priorityColor(task.priority)
                                  : Colors.transparent,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Checkbox
                            Checkbox(
                              value: task.isSelected,
                              activeColor: AppColors.primary,
                              onChanged: (_) => ref
                                  .read(voiceProvider.notifier)
                                  .toggleTaskSelection(index),
                            ),

                            // Task info
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    task.title,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      decoration: task.isSelected
                                          ? null
                                          : TextDecoration.lineThrough,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      // Priority chip
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 8,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          color: _priorityColor(
                                            task.priority,
                                          ).withValues(alpha: 0.15),
                                          borderRadius: BorderRadius.circular(
                                            8,
                                          ),
                                        ),
                                        child: Text(
                                          task.priority,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: _priorityColor(
                                              task.priority,
                                            ),
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      if (task.dueDate != null) ...[
                                        const SizedBox(width: 8),
                                        const Icon(
                                          Icons.calendar_today_outlined,
                                          size: 12,
                                          color: AppColors.textSecondary,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          task.dueDate!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: AppColors.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),

                                  // Subtasks
                                  if (task.subtasks.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 6),
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: task.subtasks
                                            .map(
                                              (s) => Padding(
                                                padding: const EdgeInsets.only(
                                                  bottom: 2,
                                                ),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                      Icons
                                                          .subdirectory_arrow_right,
                                                      size: 12,
                                                      color: AppColors
                                                          .textSecondary,
                                                    ),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      s.title,
                                                      style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textSecondary,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            )
                                            .toList(),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Bottom action bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).scaffoldBackgroundColor,
              border: Border(
                top: BorderSide(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      ref.read(voiceProvider.notifier).reset();
                      Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton.icon(
                    onPressed: selectedCount == 0
                        ? null
                        : () async {
                            try {
                              final count = await ref
                                  .read(voiceProvider.notifier)
                                  .confirmTasks();
                              await ref
                                  .read(tasksProvider.notifier)
                                  .loadTasks();
                              await ref
                                  .read(dashboardProvider.notifier)
                                  .loadDashboard();
                              if (context.mounted) {
                                Navigator.pop(context);
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      '✅ $count task${count != 1 ? 's' : ''} saved!',
                                    ),
                                    backgroundColor: AppColors.success,
                                  ),
                                );
                              }
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Failed to save tasks.'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          },
                    icon: const Icon(Icons.check),
                    label: Text(
                      selectedCount == 0
                          ? 'No tasks selected'
                          : 'Save $selectedCount Task${selectedCount != 1 ? 's' : ''}',
                    ),
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 48),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Color _confidenceColor(String c) {
    if (c == 'high') return AppColors.success;
    if (c == 'medium') return AppColors.warning;
    return AppColors.error;
  }
}
