import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/providers/ai_provider.dart';
import '../../ai/widgets/ai_confirmation_sheet.dart';
import '../../tasks/providers/task_provider.dart';

class QuickCaptureSheet extends ConsumerStatefulWidget {
  const QuickCaptureSheet({super.key});

  @override
  ConsumerState<QuickCaptureSheet> createState() => _QuickCaptureSheetState();
}

class _QuickCaptureSheetState extends ConsumerState<QuickCaptureSheet> {
  final _controller = TextEditingController();
  String _type = 'task';
  String _priority = 'medium';
  bool _useAi = true;
  bool _isLoading = false;
  bool _showAiFallback = false;
  String? _aiFallbackMessage;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() => _isLoading = true);

    if (_type == 'task' && _useAi) {
      // AI parsing flow
      await ref.read(aiProvider.notifier).parseTask(text);
      final aiState = ref.read(aiProvider);

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (aiState.parsedTask != null) {
        if (aiState.parseStatus == AiParseStatus.failed) {
          _switchToManualFallback(aiState.parsedTask!);
          return;
        }

        // Show confirmation sheet
        final confirmed = await showModalBottomSheet<bool>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => AiConfirmationSheet(parsedTask: aiState.parsedTask!),
        );

        if (confirmed == true && mounted) {
          Navigator.pop(context);
        } else if (confirmed == false && mounted) {
          _switchToManualFallback(aiState.parsedTask!);
        }
      } else {
        // AI failed — fallback to manual
        _switchToManualFallback(
          ParsedTask.manualFallback(text, 'Could not parse that.'),
        );
      }
    } else {
      // Manual flow
      final created = await ref
          .read(tasksProvider.notifier)
          .createTask(title: text, priority: _priority);
      if (mounted) {
        setState(() => _isLoading = false);
        if (created) {
          Navigator.pop(context);
        } else {
          _showTaskError();
        }
      }
    }
  }

  void _showTaskError() {
    final error = ref.read(tasksProvider).error ?? 'Task could not be created';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
  }

  void _switchToManualFallback(ParsedTask parsedTask) {
    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _useAi = false;
      _showAiFallback = true;
      _aiFallbackMessage =
          parsedTask.fallbackReason ?? "Couldn't parse that, enter manually.";
      _controller.text = parsedTask.title;
      _priority = parsedTask.priority;
    });
  }

  @override
  Widget build(BuildContext context) {
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

          Row(
            children: [
              Text(
                '⚡ Quick Capture',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Type selector
          Row(
            children: [
              _TypeChip(
                label: '✅ Task',
                selected: _type == 'task',
                onTap: () => setState(() => _type = 'task'),
              ),
              const SizedBox(width: 8),
              _TypeChip(
                label: '📝 Note',
                selected: _type == 'note',
                onTap: () => setState(() => _type = 'note'),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Input
          if (_showAiFallback) ...[
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
              child: Text(
                _aiFallbackMessage ?? "Couldn't parse that, enter manually.",
                style: const TextStyle(color: AppColors.warning),
              ),
            ),
            const SizedBox(height: 12),
          ],

          TextField(
            controller: _controller,
            autofocus: true,
            maxLines: 3,
            minLines: 1,
            decoration: InputDecoration(
              hintText: _type == 'task' && _useAi
                  ? 'e.g. Finish report tomorrow at 6 PM high priority'
                  : _type == 'task'
                  ? 'What needs to be done?'
                  : 'Capture your thought...',
            ),
          ),
          const SizedBox(height: 12),

          // Priority (manual task only)
          if (_type == 'task' && !_useAi) ...[
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
          ],

          // AI toggle (only for tasks)
          if (_type == 'task')
            Row(
              children: [
                const Text('🤖', style: TextStyle(fontSize: 16)),
                const SizedBox(width: 8),
                const Text('Use AI to parse task'),
                const Spacer(),
                Switch(
                  value: _useAi,
                  activeThumbColor: AppColors.primary,
                  onChanged: (v) => setState(() => _useAi = v),
                ),
              ],
            ),

          const SizedBox(height: 20),

          _isLoading
              ? const Center(child: CircularProgressIndicator())
              : ElevatedButton(
                  onPressed: _submit,
                  child: Text(
                    _type == 'task' && _useAi ? '🤖 Parse & Save' : 'Save',
                  ),
                ),
        ],
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : AppColors.cardDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}
