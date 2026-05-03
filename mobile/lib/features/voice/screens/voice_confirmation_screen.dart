import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../dashboard/providers/dashboard_provider.dart';
import '../../tasks/providers/task_provider.dart';
import '../models/voice_result_model.dart';
import '../providers/voice_provider.dart';

class VoiceConfirmationScreen extends ConsumerWidget {
  const VoiceConfirmationScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(voiceProvider);
    final result = state.result;

    if (result == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final selectedCount = state.editableTasks.where((t) => t.isSelected).length;
    final transcriptText = state.editableTranscript.isNotEmpty
        ? state.editableTranscript
        : result.transcribedText;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.textHeading),
          onPressed: () {
            ref.read(voiceProvider.notifier).reset();
            Navigator.pop(context);
          },
        ),
        title: Text('Review Voice Task', style: AppTextStyles.h3Light),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s8,
                  AppSpacing.screenH,
                  AppSpacing.s24,
                ),
                children: [
                  _VoiceHeroCard(
                    selectedCount: selectedCount,
                    totalCount: state.editableTasks.length,
                    confidence: result.confidence,
                  ),
                  const SizedBox(height: AppSpacing.s16),
                  _TranscriptCard(
                    text: transcriptText,
                    confidence: result.confidence,
                    onChanged: (value) => ref
                        .read(voiceProvider.notifier)
                        .updateTranscript(value),
                  ),
                  if (result.requiresConfirmation ||
                      result.confidence == 'low' ||
                      result.fallbackReason != null) ...[
                    const SizedBox(height: AppSpacing.s12),
                    const _ReviewNotice(),
                  ],
                  const SizedBox(height: AppSpacing.s16),
                  if (state.editableTasks.isEmpty)
                    _EmptyTasksCard(transcriptText: transcriptText)
                  else
                    ...List.generate(state.editableTasks.length, (index) {
                      final task = state.editableTasks[index];
                      return _VoiceTaskCard(
                        task: task,
                        onToggle: () => ref
                            .read(voiceProvider.notifier)
                            .toggleTaskSelection(index),
                        onTitleChanged: (value) => ref
                            .read(voiceProvider.notifier)
                            .updateTaskTitle(index, value),
                      );
                    }),
                ],
              ),
            ),
            _BottomActions(
              selectedCount: selectedCount,
              onCancel: () {
                ref.read(voiceProvider.notifier).reset();
                Navigator.pop(context);
              },
              onSave: selectedCount == 0
                  ? null
                  : () => _confirmSelectedTasks(context, ref, selectedCount),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmSelectedTasks(
    BuildContext context,
    WidgetRef ref,
    int selectedCount,
  ) async {
    try {
      final count = await ref.read(voiceProvider.notifier).confirmTasks();
      await ref.read(tasksProvider.notifier).loadTasks();
      await ref.read(dashboardProvider.notifier).loadDashboard();
      if (!context.mounted) return;
      Navigator.pop(context);
      if (Navigator.of(context).canPop()) Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$count task${count != 1 ? 's' : ''} saved.'),
          backgroundColor: AppColors.brandPrimary,
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to save tasks.'),
          backgroundColor: AppColors.errorColor,
        ),
      );
    }
  }
}

class _VoiceHeroCard extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final String confidence;

  const _VoiceHeroCard({
    required this.selectedCount,
    required this.totalCount,
    required this.confidence,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        gradient: AppGradients.action,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.glowPurple,
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: AppColors.bgSurface.withValues(alpha: 0.18),
              borderRadius: AppRadius.circular(AppRadius.lg),
              border: Border.all(
                color: AppColors.bgSurface.withValues(alpha: 0.35),
              ),
            ),
            child: const Icon(
              Icons.record_voice_over_outlined,
              color: AppColors.bgSurface,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Voice preview',
                  style: AppTextStyles.h3(AppColors.bgSurface),
                ),
                const SizedBox(height: AppSpacing.s4),
                Text(
                  '$selectedCount of $totalCount selected',
                  style: AppTextStyles.bodySmall(
                    AppColors.bgSurface.withValues(alpha: 0.86),
                  ),
                ),
              ],
            ),
          ),
          _Pill(
            label: confidence.toUpperCase(),
            color: AppColors.bgSurface,
            foreground: AppColors.brandPrimary,
          ),
        ],
      ),
    );
  }
}

class _TranscriptCard extends StatelessWidget {
  final String text;
  final String confidence;
  final ValueChanged<String> onChanged;

  const _TranscriptCard({
    required this.text,
    required this.confidence,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.mic_none_outlined,
                color: AppColors.brandPrimary,
                size: 18,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text('Transcript', style: AppTextStyles.labelLight),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Directionality(
            textDirection: _isRtl(text) ? TextDirection.rtl : TextDirection.ltr,
            child: TextFormField(
              initialValue: text,
              maxLines: 4,
              minLines: 2,
              decoration: InputDecoration(
                hintText: 'Edit transcript',
                filled: true,
                fillColor: AppColors.bgSurfaceSoft,
                border: OutlineInputBorder(
                  borderRadius: AppRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: AppRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(color: AppColors.borderSoft),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: AppRadius.circular(AppRadius.lg),
                  borderSide: const BorderSide(
                    color: AppColors.brandPrimary,
                    width: 1.5,
                  ),
                ),
              ),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReviewNotice extends StatelessWidget {
  const _ReviewNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.bgSurfaceLavender,
        borderRadius: AppRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: AppColors.brandPrimary,
            size: 18,
          ),
          const SizedBox(width: AppSpacing.s8),
          Expanded(
            child: Text(
              'Review before saving.',
              style: AppTextStyles.bodySmall(AppColors.textBody),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyTasksCard extends ConsumerWidget {
  final String transcriptText;

  const _EmptyTasksCard({required this.transcriptText});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.soft,
      ),
      child: Column(
        children: [
          const Icon(
            Icons.edit_note_outlined,
            color: AppColors.brandPrimary,
            size: 34,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text('No tasks detected', style: AppTextStyles.h4Light),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: transcriptText.trim().isEmpty
                  ? null
                  : () => ref
                        .read(voiceProvider.notifier)
                        .addManualTaskFromTranscript(),
              icon: const Icon(Icons.add_task_outlined),
              label: const Text('Create task manually'),
            ),
          ),
        ],
      ),
    );
  }
}

class _VoiceTaskCard extends StatelessWidget {
  final ParsedVoiceTaskModel task;
  final VoidCallback onToggle;
  final ValueChanged<String> onTitleChanged;

  const _VoiceTaskCard({
    required this.task,
    required this.onToggle,
    required this.onTitleChanged,
  });

  Color get _accent {
    if (task.priority == 'high') return AppColors.errorColor;
    if (task.priority == 'low') return AppColors.brandPink;
    return AppColors.brandPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s12),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(
          color: task.isSelected
              ? _accent.withValues(alpha: 0.32)
              : AppColors.borderSoft,
        ),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isSelected,
            activeColor: AppColors.brandPrimary,
            onChanged: (_) => onToggle(),
          ),
          const SizedBox(width: AppSpacing.s6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Directionality(
                  textDirection: _isRtl(task.title)
                      ? TextDirection.rtl
                      : TextDirection.ltr,
                  child: TextFormField(
                    initialValue: task.title,
                    decoration: const InputDecoration(
                      labelText: 'Task title',
                      isDense: true,
                    ),
                    style: AppTextStyles.body(AppColors.textHeading).copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: task.isSelected
                          ? null
                          : TextDecoration.lineThrough,
                    ),
                    onChanged: onTitleChanged,
                  ),
                ),
                const SizedBox(height: AppSpacing.s8),
                Wrap(
                  spacing: AppSpacing.s6,
                  runSpacing: AppSpacing.s6,
                  children: [
                    _Pill(
                      label: task.priority,
                      color: _accent.withValues(alpha: 0.12),
                      foreground: _accent,
                    ),
                    if (task.dueDate != null)
                      _Pill(
                        label: task.dueTime == null
                            ? task.dueDate!
                            : '${task.dueDate} ${task.dueTime}',
                        color: AppColors.bgSurfaceLavender,
                        foreground: AppColors.brandPrimary,
                        icon: Icons.calendar_today_outlined,
                      ),
                    if (task.estimatedDurationMinutes != null)
                      _Pill(
                        label: '${task.estimatedDurationMinutes} min',
                        color: AppColors.bgSurfaceLavender,
                        foreground: AppColors.brandViolet,
                        icon: Icons.timer_outlined,
                      ),
                  ],
                ),
                if (task.subtasks.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.s8),
                  ...task.subtasks
                      .take(3)
                      .map(
                        (subtask) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.s4),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.subdirectory_arrow_right,
                                size: 14,
                                color: AppColors.textHint,
                              ),
                              const SizedBox(width: AppSpacing.s4),
                              Expanded(
                                child: Text(
                                  subtask.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.captionLight,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomActions extends StatelessWidget {
  final int selectedCount;
  final VoidCallback onCancel;
  final VoidCallback? onSave;

  const _BottomActions({
    required this.selectedCount,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        AppSpacing.s12,
        AppSpacing.screenH,
        AppSpacing.s16,
      ),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        border: Border(top: BorderSide(color: AppColors.borderSoft)),
        boxShadow: AppShadows.soft,
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: onCancel,
              child: const Text('Cancel'),
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            flex: 2,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: onSave == null ? null : AppGradients.action,
                color: onSave == null ? AppColors.bgSurfaceLavender : null,
                borderRadius: AppRadius.pillBr,
                boxShadow: onSave == null ? null : AppShadows.glowPurple,
              ),
              child: ElevatedButton.icon(
                onPressed: onSave,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  disabledBackgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: AppColors.bgSurface,
                  disabledForegroundColor: AppColors.textHint,
                ),
                icon: const Icon(Icons.check_circle_outline),
                label: Text(
                  selectedCount == 0
                      ? 'No tasks selected'
                      : 'Save $selectedCount Task${selectedCount != 1 ? 's' : ''}',
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final Color color;
  final Color foreground;
  final IconData? icon;

  const _Pill({
    required this.label,
    required this.color,
    required this.foreground,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s8,
        vertical: AppSpacing.s4,
      ),
      decoration: BoxDecoration(color: color, borderRadius: AppRadius.pillBr),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: foreground),
            const SizedBox(width: AppSpacing.s4),
          ],
          Text(label, style: AppTextStyles.caption(foreground)),
        ],
      ),
    );
  }
}

bool _isRtl(String value) {
  return RegExp(r'[\u0600-\u06FF]').hasMatch(value);
}
