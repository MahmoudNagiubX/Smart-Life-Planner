import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/ai_provider.dart';
import '../../tasks/providers/task_provider.dart';

class AiConfirmationSheet extends ConsumerStatefulWidget {
  final ParsedTask parsedTask;

  const AiConfirmationSheet({super.key, required this.parsedTask});

  @override
  ConsumerState<AiConfirmationSheet> createState() =>
      _AiConfirmationSheetState();
}

class _AiConfirmationSheetState extends ConsumerState<AiConfirmationSheet> {
  late TextEditingController _titleController;
  late TextEditingController _dueAtController;
  late TextEditingController _estimatedMinutesController;
  late TextEditingController _categoryController;
  late String _priority;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.parsedTask.title);
    _dueAtController = TextEditingController(
      text: widget.parsedTask.dueAt ?? '',
    );
    _estimatedMinutesController = TextEditingController(
      text: widget.parsedTask.estimatedMinutes?.toString() ?? '',
    );
    _categoryController = TextEditingController(
      text: widget.parsedTask.category ?? '',
    );
    _priority = widget.parsedTask.priority;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _dueAtController.dispose();
    _estimatedMinutesController.dispose();
    _categoryController.dispose();
    super.dispose();
  }

  Color _confidenceColor(String confidence) {
    switch (confidence) {
      case 'high':
        return AppColors.successColor;
      case 'medium':
        return AppColors.warningColor;
      default:
        return AppColors.errorColor;
    }
  }

  Future<void> _confirm() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final dueAt = _dueAtController.text.trim().isEmpty
        ? null
        : DateTime.tryParse(_dueAtController.text.trim());
    final estimatedMinutes = _estimatedMinutesController.text.trim().isEmpty
        ? null
        : int.tryParse(_estimatedMinutesController.text.trim());
    final category = _categoryController.text.trim().isEmpty
        ? null
        : _categoryController.text.trim();

    final created = await ref
        .read(tasksProvider.notifier)
        .createTask(
          title: _titleController.text.trim(),
          priority: _priority,
          dueAt: dueAt,
          category: category,
          estimatedMinutes: estimatedMinutes,
        );

    if (created) {
      ref.read(aiProvider.notifier).clearParsed();
    }

    if (mounted) {
      setState(() => _isLoading = false);
      if (created) {
        Navigator.pop(context, true);
      } else {
        final error =
            ref.read(tasksProvider).error ?? 'Task could not be created';
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(
          content: Text(error),
          behavior: SnackBarBehavior.floating,
        ));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.parsedTask;

    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.s24,
        right: AppSpacing.s24,
        top: AppSpacing.s24,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.borderSoft,
                borderRadius: AppRadius.pillBr,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          // Header
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: AppSpacing.s8),
              Text('AI Parsed Your Task', style: AppTextStyles.h3Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s8),

          if (task.requiresConfirmation || task.confidence == 'low') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.warningSoft,
                borderRadius: AppRadius.circular(AppRadius.md),
                border: Border.all(
                  color: AppColors.warningColor.withValues(alpha: 0.35),
                ),
              ),
              child: Text(
                'Review the details before saving.',
                style: AppTextStyles.body(AppColors.warningColor),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
          ],

          // Confidence badge
          Row(
            children: [
              Text('Confidence: ',
                  style: AppTextStyles.caption(AppColors.textHint)),
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.s8, vertical: AppSpacing.s4),
                decoration: BoxDecoration(
                  color: _confidenceColor(task.confidence)
                      .withValues(alpha: 0.15),
                  borderRadius: AppRadius.pillBr,
                ),
                child: Text(
                  task.confidence.toUpperCase(),
                  style: AppTextStyles.label(
                      _confidenceColor(task.confidence)),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s20),

          // Editable title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              prefixIcon: Icon(Icons.task_alt),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          // Priority selector
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'Priority'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('🟢 Low')),
              DropdownMenuItem(value: 'medium', child: Text('🟡 Medium')),
              DropdownMenuItem(value: 'high', child: Text('🔴 High')),
            ],
            onChanged: (v) => setState(() => _priority = v!),
          ),
          const SizedBox(height: AppSpacing.s12),

          TextField(
            controller: _dueAtController,
            decoration: const InputDecoration(
              labelText: 'Due date / time',
              hintText: 'YYYY-MM-DDTHH:MM:SS',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          TextField(
            controller: _estimatedMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estimated minutes',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),

          // Extracted info chips
          if (task.dueAt != null ||
              task.estimatedMinutes != null ||
              task.category != null)
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s4,
              children: [
                if (task.dueAt != null)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Due: ${task.dueAt!.substring(0, 10)}',
                    color: AppColors.brandPrimary,
                  ),
                if (task.estimatedMinutes != null)
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '~${task.estimatedMinutes} min',
                    color: AppColors.warningColor,
                  ),
                if (task.category != null)
                  _InfoChip(
                    icon: Icons.label_outline,
                    label: task.category!,
                    color: AppColors.successColor,
                  ),
              ],
            ),

          const SizedBox(height: AppSpacing.s20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brandPrimary,
                    side: const BorderSide(color: AppColors.brandPrimary),
                    minimumSize:
                        const Size(0, AppButtonHeight.secondary),
                    shape: RoundedRectangleBorder(
                        borderRadius: AppRadius.pillBr),
                  ),
                  child: const Text('Edit Manually'),
                ),
              ),
              const SizedBox(width: AppSpacing.s12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(
                        color: AppColors.brandPrimary))
                    : ElevatedButton(
                        onPressed: _confirm,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.brandPrimary,
                          foregroundColor: Colors.white,
                          minimumSize: const Size(
                              0, AppButtonHeight.secondary),
                          shape: RoundedRectangleBorder(
                              borderRadius: AppRadius.pillBr),
                        ),
                        child: const Text('✅ Confirm'),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Info chip ─────────────────────────────────────────────────────────────────

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12, vertical: AppSpacing.s8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: AppRadius.pillBr,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: AppSpacing.s4),
          Text(label, style: AppTextStyles.caption(color)),
        ],
      ),
    );
  }
}
