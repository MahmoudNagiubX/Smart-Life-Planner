import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../ai/providers/ai_provider.dart';
import '../../ai/widgets/ai_confirmation_sheet.dart';
import '../../notes/models/note_model.dart';
import '../../notes/providers/note_provider.dart';
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
    final classification = await _classify(text);
    if (!mounted) return;
    setState(() => _isLoading = false);

    final confirmed = await showModalBottomSheet<_CaptureConfirmation>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _QuickCaptureConfirmationSheet(
        classification: classification,
        initialType: _type,
      ),
    );
    if (confirmed == null || !mounted) return;

    setState(() {
      _isLoading = true;
      _type = confirmed.captureType;
    });

    if (confirmed.captureType == 'task' && _useAi) {
      await _parseTaskWithAi(confirmed.content);
    } else if (confirmed.captureType == 'task') {
      await _createTask(confirmed.title);
    } else if (confirmed.captureType == 'reminder') {
      await _createTask(
        confirmed.title,
        reminderAt: confirmed.reminderAt == null
            ? null
            : DateTime.tryParse(confirmed.reminderAt!)?.toLocal(),
      );
    } else if (confirmed.captureType == 'checklist') {
      await _createChecklistNote(confirmed);
    } else {
      await _createTextNote(confirmed);
    }
  }

  Future<_QuickCaptureClassification> _classify(String text) async {
    try {
      final result = await ref.read(aiServiceProvider).classifyCapture(text);
      return _QuickCaptureClassification.fromJson(result, text);
    } catch (_) {
      return _QuickCaptureClassification(
        captureType: 'unclear',
        confidence: 'low',
        title: text,
        content: text,
        checklistItems: const [],
        reason: 'Classification unavailable. Choose the type manually.',
      );
    }
  }

  Future<void> _parseTaskWithAi(String text) async {
    await ref.read(aiProvider.notifier).parseTask(text);
    final aiState = ref.read(aiProvider);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (aiState.parsedTask != null) {
      if (aiState.parseStatus == AiParseStatus.failed) {
        _switchToManualFallback(aiState.parsedTask!);
        return;
      }

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
      return;
    }

    _switchToManualFallback(
      ParsedTask.manualFallback(text, 'Could not parse that.'),
    );
  }

  Future<void> _createTask(String title, {DateTime? reminderAt}) async {
    final created = await ref
        .read(tasksProvider.notifier)
        .createTask(title: title, priority: _priority, reminderAt: reminderAt);
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (created) {
      Navigator.pop(context);
    } else {
      _showTaskError();
    }
  }

  Future<void> _createTextNote(_CaptureConfirmation capture) async {
    await ref
        .read(notesProvider.notifier)
        .createNote(
          title: capture.title,
          content: capture.content,
          tags: capture.captureType == 'journal_entry'
              ? const ['journal']
              : const <String>[],
          sourceType: 'quick_capture',
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
  }

  Future<void> _createChecklistNote(_CaptureConfirmation capture) async {
    final rawItems = capture.checklistItems.isNotEmpty
        ? capture.checklistItems
        : capture.content
              .split('\n')
              .map((line) => line.trim())
              .where((line) => line.isNotEmpty)
              .toList();
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final checklistItems = <ChecklistItemModel>[
      for (var index = 0; index < rawItems.length; index++)
        ChecklistItemModel(
          id: 'item_${index}_$timestamp',
          text: rawItems[index],
          isCompleted: false,
        ),
    ];

    await ref
        .read(notesProvider.notifier)
        .createNote(
          title: capture.title,
          content: checklistItems.map((item) => item.text).join('\n'),
          noteType: 'checklist',
          checklistItems: checklistItems,
          sourceType: 'quick_capture',
        );
    if (!mounted) return;
    setState(() => _isLoading = false);
    Navigator.pop(context);
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
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Quick Capture',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _TypeChip(
                  label: 'Task',
                  selected: _type == 'task',
                  onTap: () => setState(() => _type = 'task'),
                ),
                _TypeChip(
                  label: 'Note',
                  selected: _type == 'note',
                  onTap: () => setState(() => _type = 'note'),
                ),
                _TypeChip(
                  label: 'Checklist',
                  selected: _type == 'checklist',
                  onTap: () => setState(() => _type = 'checklist'),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
              maxLines: 4,
              minLines: 1,
              decoration: InputDecoration(
                hintText: _type == 'task' && _useAi
                    ? 'e.g. Finish report tomorrow at 6 PM high priority'
                    : _type == 'checklist'
                    ? 'One checklist item per line'
                    : _type == 'task'
                    ? 'What needs to be done?'
                    : 'Capture your thought...',
              ),
            ),
            const SizedBox(height: 12),
            if (_type == 'task' && !_useAi) ...[
              DropdownButtonFormField<String>(
                initialValue: _priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 'low', child: Text('Low')),
                  DropdownMenuItem(value: 'medium', child: Text('Medium')),
                  DropdownMenuItem(value: 'high', child: Text('High')),
                ],
                onChanged: (v) => setState(() => _priority = v!),
              ),
              const SizedBox(height: 12),
            ],
            if (_type == 'task')
              Row(
                children: [
                  const Icon(Icons.auto_awesome, size: 18),
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
                    child: const Text('Review Capture'),
                  ),
          ],
        ),
      ),
    );
  }
}

class _QuickCaptureClassification {
  final String captureType;
  final String confidence;
  final String title;
  final String content;
  final List<String> checklistItems;
  final String? reminderAt;
  final String reason;

  const _QuickCaptureClassification({
    required this.captureType,
    required this.confidence,
    required this.title,
    required this.content,
    required this.checklistItems,
    this.reminderAt,
    required this.reason,
  });

  factory _QuickCaptureClassification.fromJson(
    Map<String, dynamic> json,
    String fallbackText,
  ) {
    return _QuickCaptureClassification(
      captureType: json['capture_type'] as String? ?? 'unclear',
      confidence: json['confidence'] as String? ?? 'low',
      title: json['title'] as String? ?? fallbackText,
      content: json['content'] as String? ?? fallbackText,
      checklistItems: (json['checklist_items'] as List<dynamic>? ?? [])
          .map((item) => item.toString())
          .toList(),
      reminderAt: json['reminder_at'] as String?,
      reason: json['reason'] as String? ?? 'Review before saving.',
    );
  }
}

class _CaptureConfirmation {
  final String captureType;
  final String title;
  final String content;
  final List<String> checklistItems;
  final String? reminderAt;

  const _CaptureConfirmation({
    required this.captureType,
    required this.title,
    required this.content,
    required this.checklistItems,
    this.reminderAt,
  });
}

class _QuickCaptureConfirmationSheet extends StatefulWidget {
  final _QuickCaptureClassification classification;
  final String initialType;

  const _QuickCaptureConfirmationSheet({
    required this.classification,
    required this.initialType,
  });

  @override
  State<_QuickCaptureConfirmationSheet> createState() =>
      _QuickCaptureConfirmationSheetState();
}

class _QuickCaptureConfirmationSheetState
    extends State<_QuickCaptureConfirmationSheet> {
  late final TextEditingController _titleController;
  late final TextEditingController _contentController;
  late String _captureType;

  @override
  void initState() {
    super.initState();
    final suggestedType = widget.classification.captureType == 'unclear'
        ? widget.initialType
        : widget.classification.captureType;
    _captureType = _captureTypes.contains(suggestedType)
        ? suggestedType
        : 'note';
    _titleController = TextEditingController(text: widget.classification.title);
    _contentController = TextEditingController(
      text: widget.classification.content,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  List<String> _checklistItems() {
    final suggested = widget.classification.checklistItems;
    if (_captureType == 'checklist' && suggested.isNotEmpty) {
      return suggested;
    }
    return _contentController.text
        .split('\n')
        .map((line) => line.trim().replaceFirst(RegExp(r'^[-*]\s*'), ''))
        .where((line) => line.isNotEmpty)
        .toList();
  }

  void _confirm() {
    final title = _titleController.text.trim();
    final content = _contentController.text.trim();
    if (title.isEmpty || content.isEmpty) return;
    Navigator.pop(
      context,
      _CaptureConfirmation(
        captureType: _captureType,
        title: title,
        content: content,
        checklistItems: _checklistItems(),
        reminderAt: widget.classification.reminderAt,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final classification = widget.classification;
    return Padding(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
            Text(
              'Confirm Capture',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              '${classification.reason} Confidence: ${classification.confidence}.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _captureType,
              decoration: const InputDecoration(labelText: 'Save as'),
              items: const [
                DropdownMenuItem(value: 'task', child: Text('Task')),
                DropdownMenuItem(value: 'note', child: Text('Note')),
                DropdownMenuItem(value: 'reminder', child: Text('Reminder')),
                DropdownMenuItem(value: 'checklist', child: Text('Checklist')),
                DropdownMenuItem(
                  value: 'journal_entry',
                  child: Text('Journal entry'),
                ),
              ],
              onChanged: (value) {
                if (value == null) return;
                setState(() => _captureType = value);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _contentController,
              minLines: 2,
              maxLines: 5,
              decoration: InputDecoration(
                labelText: _captureType == 'checklist'
                    ? 'Checklist items'
                    : 'Content',
              ),
            ),
            if (_captureType == 'reminder' &&
                classification.reminderAt == null) ...[
              const SizedBox(height: 12),
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
                  'No reminder time was detected. It will save as a task without a reminder.',
                  style: TextStyle(color: AppColors.warning),
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _confirm,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
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

const _captureTypes = {
  'task',
  'note',
  'reminder',
  'checklist',
  'journal_entry',
};
