import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
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
        return AppColors.success;
      case 'medium':
        return AppColors.warning;
      default:
        return AppColors.error;
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
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final task = widget.parsedTask;

    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle bar
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.textSecondary.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Header
          Row(
            children: [
              const Text('🤖', style: TextStyle(fontSize: 24)),
              const SizedBox(width: 8),
              Text(
                'AI Parsed Your Task',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 4),

          if (task.requiresConfirmation || task.confidence == 'low') ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.warning.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: AppColors.warning.withValues(alpha: 0.35),
                ),
              ),
              child: const Text(
                'Review the details before saving.',
                style: TextStyle(color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Confidence badge
          Row(
            children: [
              const Text('Confidence: ', style: TextStyle(fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _confidenceColor(
                    task.confidence,
                  ).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  task.confidence.toUpperCase(),
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: _confidenceColor(task.confidence),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Editable title
          TextField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Task Title',
              prefixIcon: Icon(Icons.task_alt),
            ),
          ),
          const SizedBox(height: 12),

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
          const SizedBox(height: 12),

          TextField(
            controller: _dueAtController,
            decoration: const InputDecoration(
              labelText: 'Due date / time',
              hintText: 'YYYY-MM-DDTHH:MM:SS',
              prefixIcon: Icon(Icons.calendar_today),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _estimatedMinutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Estimated minutes',
              prefixIcon: Icon(Icons.timer_outlined),
            ),
          ),
          const SizedBox(height: 12),

          TextField(
            controller: _categoryController,
            decoration: const InputDecoration(
              labelText: 'Category',
              prefixIcon: Icon(Icons.label_outline),
            ),
          ),
          const SizedBox(height: 12),

          // Extracted info chips
          if (task.dueAt != null ||
              task.estimatedMinutes != null ||
              task.category != null)
            Wrap(
              spacing: 8,
              children: [
                if (task.dueAt != null)
                  _InfoChip(
                    icon: Icons.calendar_today,
                    label: 'Due: ${task.dueAt!.substring(0, 10)}',
                    color: AppColors.primary,
                  ),
                if (task.estimatedMinutes != null)
                  _InfoChip(
                    icon: Icons.timer_outlined,
                    label: '~${task.estimatedMinutes} min',
                    color: AppColors.warning,
                  ),
                if (task.category != null)
                  _InfoChip(
                    icon: Icons.label_outline,
                    label: task.category!,
                    color: AppColors.success,
                  ),
              ],
            ),

          const SizedBox(height: 20),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size(0, 48),
                  ),
                  child: const Text('Edit Manually'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : ElevatedButton(
                        onPressed: _confirm,
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
