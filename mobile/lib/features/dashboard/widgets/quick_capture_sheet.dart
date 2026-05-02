import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
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
      backgroundColor: AppColors.bgApp,
      shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBr),
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
        backgroundColor: AppColors.bgApp,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.sheetBr),
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
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s32,
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
                  color: AppColors.borderSoft,
                  borderRadius: AppRadius.pillBr,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Container(
                  width: AppIconSize.avatar,
                  height: AppIconSize.avatar,
                  decoration: BoxDecoration(
                    gradient: AppGradients.action,
                    borderRadius: AppRadius.circular(AppRadius.md),
                    boxShadow: AppShadows.glowPurple,
                  ),
                  child: const Icon(
                    Icons.add_task_outlined,
                    color: AppColors.bgSurface,
                    size: AppIconSize.cardHeader,
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Quick Capture', style: AppTextStyles.h2Light),
                      Text(
                        'Drop a thought in and review before saving.',
                        style: AppTextStyles.captionLight,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            Wrap(
              spacing: AppSpacing.s8,
              runSpacing: AppSpacing.s8,
              children: [
                _TypeChip(
                  label: 'Task',
                  icon: Icons.task_alt,
                  selected: _type == 'task',
                  onTap: () => setState(() => _type = 'task'),
                ),
                _TypeChip(
                  label: 'Note',
                  icon: Icons.sticky_note_2_outlined,
                  selected: _type == 'note',
                  onTap: () => setState(() => _type = 'note'),
                ),
                _TypeChip(
                  label: 'Checklist',
                  icon: Icons.checklist_outlined,
                  selected: _type == 'checklist',
                  onTap: () => setState(() => _type = 'checklist'),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.s16),
            if (_showAiFallback) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: AppRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warningColor),
                ),
                child: Text(
                  _aiFallbackMessage ?? "Couldn't parse that, enter manually.",
                  style: AppTextStyles.bodySmall(AppColors.warningColor),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),
            ],
            Container(
              decoration: BoxDecoration(
                color: AppColors.bgSurface,
                borderRadius: AppRadius.circular(AppRadius.xl),
                border: Border.all(color: AppColors.borderSoft),
                boxShadow: AppShadows.soft,
              ),
              child: TextField(
                controller: _controller,
                autofocus: true,
                maxLines: 5,
                minLines: 3,
                style: AppTextStyles.body(AppColors.textHeading),
                decoration: InputDecoration(
                  hintText: _type == 'task' && _useAi
                      ? 'e.g. Finish report tomorrow at 6 PM high priority'
                      : _type == 'checklist'
                      ? 'One checklist item per line'
                      : _type == 'task'
                      ? 'What needs to be done?'
                      : 'Capture your thought...',
                  hintStyle: AppTextStyles.bodySmall(AppColors.textHint),
                  filled: true,
                  fillColor: AppColors.bgSurface,
                  border: OutlineInputBorder(
                    borderRadius: AppRadius.circular(AppRadius.xl),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.all(AppSpacing.s16),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s12),
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
              const SizedBox(height: AppSpacing.s12),
            ],
            if (_type == 'task')
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.s12,
                  vertical: AppSpacing.s8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.featAISoft,
                  borderRadius: AppRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.auto_awesome,
                      size: 18,
                      color: AppColors.featAI,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    Text(
                      'Use AI to parse task',
                      style: AppTextStyles.bodySmall(AppColors.textHeading),
                    ),
                    const Spacer(),
                    Switch(
                      value: _useAi,
                      activeThumbColor: AppColors.brandPrimary,
                      onChanged: (v) => setState(() => _useAi = v),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppSpacing.s20),
            _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.brandPrimary,
                    ),
                  )
                : _GradientActionButton(
                    label: 'Review Capture',
                    icon: Icons.arrow_forward,
                    onPressed: _submit,
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
        left: AppSpacing.screenH,
        right: AppSpacing.screenH,
        top: AppSpacing.s16,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSpacing.s32,
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
                  color: AppColors.borderSoft,
                  borderRadius: AppRadius.pillBr,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.s20),
            Text('Confirm Capture', style: AppTextStyles.h2Light),
            const SizedBox(height: AppSpacing.s8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppSpacing.s12),
              decoration: BoxDecoration(
                color: AppColors.featAISoft,
                borderRadius: AppRadius.circular(AppRadius.lg),
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Text(
                '${classification.reason} Confidence: ${classification.confidence}.',
                style: AppTextStyles.bodySmallLight,
              ),
            ),
            const SizedBox(height: AppSpacing.s16),
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
            const SizedBox(height: AppSpacing.s12),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Title'),
            ),
            const SizedBox(height: AppSpacing.s12),
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
              const SizedBox(height: AppSpacing.s12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.warningSoft,
                  borderRadius: AppRadius.circular(AppRadius.md),
                  border: Border.all(color: AppColors.warningColor),
                ),
                child: Text(
                  'No reminder time was detected. It will save as a task without a reminder.',
                  style: AppTextStyles.bodySmall(AppColors.warningColor),
                ),
              ),
            ],
            const SizedBox(height: AppSpacing.s20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: _GradientActionButton(
                    label: 'Save',
                    icon: Icons.check,
                    onPressed: _confirm,
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
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s12,
          vertical: AppSpacing.s8,
        ),
        decoration: BoxDecoration(
          gradient: selected ? AppGradients.action : null,
          color: selected ? null : AppColors.bgSurface,
          borderRadius: AppRadius.pillBr,
          border: Border.all(
            color: selected
                ? AppColors.bgSurfaceLavender
                : AppColors.borderSoft,
          ),
          boxShadow: selected ? AppShadows.glowPurple : AppShadows.soft,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppColors.bgSurface : AppColors.brandPrimary,
            ),
            const SizedBox(width: AppSpacing.s6),
            Text(
              label,
              style: AppTextStyles.label(
                selected ? AppColors.bgSurface : AppColors.textBody,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GradientActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onPressed;

  const _GradientActionButton({
    required this.label,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.bgSurface,
      borderRadius: AppRadius.pillBr,
      child: InkWell(
        borderRadius: AppRadius.pillBr,
        onTap: onPressed,
        child: Container(
          height: AppButtonHeight.primary,
          decoration: BoxDecoration(
            gradient: AppGradients.action,
            borderRadius: AppRadius.pillBr,
            boxShadow: AppShadows.glowPurple,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: AppColors.bgSurface, size: 20),
              const SizedBox(width: AppSpacing.s8),
              Text(label, style: AppTextStyles.button(AppColors.bgSurface)),
            ],
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
