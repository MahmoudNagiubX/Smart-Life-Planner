import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../reminders/widgets/task_reminder_presets_tile.dart';
import '../providers/task_provider.dart';

class CreateTaskSheet extends ConsumerStatefulWidget {
  const CreateTaskSheet({super.key});

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  String _priority = 'medium';
  String _bucket = 'pending';
  int _estimatedPomodoros = 0;
  DateTime? _dueAt;
  final Set<String> _selectedReminderPresets = {};
  DateTime? _customReminderAt;
  bool _recurringCustomEnabled = false;
  bool _constantReminderEnabled = false;
  String _recurringRule = 'FREQ=DAILY';
  bool _isLoading = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  Future<DateTime?> _pickDateTime({DateTime? initial}) async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: initial ?? now,
      firstDate: now.subtract(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 3650)),
    );
    if (date == null || !mounted) return null;
    final time = await showTimePicker(
      context: context,
      initialTime: initial == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return null;
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDueDate() async {
    final picked = await _pickDateTime(initial: _dueAt);
    if (picked != null) setState(() => _dueAt = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    final created = await ref
        .read(tasksProvider.notifier)
        .createTask(
          title: _titleController.text.trim(),
          description: _descController.text.trim().isEmpty
              ? null
              : _descController.text.trim(),
          priority: _priority,
          dueAt: _dueAt,
          estimatedPomodoros: _estimatedPomodoros,
          status: _bucket == 'calendar' ? 'pending' : _bucket,
          reminderPresets: TaskReminderPresetsTile.buildDraftsFrom(
            dueAt: _dueAt,
            selectedPresets: _selectedReminderPresets,
            customScheduledAt: _customReminderAt,
            recurringCustomEnabled: _recurringCustomEnabled,
            constantReminderEnabled: _constantReminderEnabled,
            taskPriority: _priority,
            recurringRule: _recurringRule,
          ),
        );

    if (mounted) {
      setState(() => _isLoading = false);
      if (created) {
        Navigator.pop(context);
      } else {
        final error =
            ref.read(tasksProvider).error ?? 'Task could not be created';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  void _showBucketPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'GTD Bucket',
        options: const [
          ('pending', 'Inbox'),
          ('next', 'Next Actions'),
          ('waiting', 'Waiting For'),
          ('someday', 'Someday'),
          ('calendar', 'Calendar'),
        ],
        selected: _bucket,
        onSelect: (v) => setState(() => _bucket = v),
      ),
    );
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Priority',
        options: const [
          ('low', 'Low'),
          ('medium', 'Medium'),
          ('high', 'High'),
        ],
        selected: _priority,
        onSelect: (v) => setState(() => _priority = v),
      ),
    );
  }

  Color _priorityColor(String p) => switch (p) {
    'high' => AppColors.errorColor,
    'medium' => AppColors.warningColor,
    _ => AppColors.successColor,
  };

  String _bucketLabel(String b) => switch (b) {
    'next' => 'Next Actions',
    'waiting' => 'Waiting For',
    'someday' => 'Someday',
    'calendar' => 'Calendar',
    _ => 'Inbox',
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sheetBr,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle ───────────────────────────────────────────
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.borderSoft,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),

              // ── Header ────────────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 16, AppSpacing.screenH, 20,
                ),
                child: Text(
                  'New Task',
                  style: GoogleFonts.manrope(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textHeading,
                    letterSpacing: -0.3,
                  ),
                ),
              ),

              // ── Title input ───────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: TextField(
                  controller: _titleController,
                  autofocus: true,
                  style: GoogleFonts.manrope(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Task title...',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 16,
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.bgApp,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 20,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(color: AppColors.borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(color: AppColors.borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),

              // ── Description input ─────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: TextField(
                  controller: _descController,
                  maxLines: 3,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    color: AppColors.textHeading,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Description (optional)',
                    hintStyle: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textHint,
                    ),
                    filled: true,
                    fillColor: AppColors.bgApp,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 14,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.borderSoft),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(color: AppColors.borderSoft),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.lg),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                        width: 1.5,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // ── Metadata card ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Column(
                    children: [
                      _MetaRow(
                        icon: Icons.event_outlined,
                        iconColor: AppColors.featTasks,
                        label: 'Due date',
                        value: _dueAt?.toLocal().toString().substring(0, 16),
                        onTap: _pickDueDate,
                        trailing: _dueAt != null
                            ? GestureDetector(
                                onTap: () => setState(() => _dueAt = null),
                                child: const Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                              )
                            : null,
                      ),
                      _MetaDivider(),
                      _MetaRow(
                        icon: Icons.inbox_outlined,
                        iconColor: AppColors.featFocus,
                        label: 'Bucket',
                        value: _bucketLabel(_bucket),
                        onTap: _showBucketPicker,
                      ),
                      _MetaDivider(),
                      _MetaRow(
                        icon: Icons.flag_outlined,
                        iconColor: _priorityColor(_priority),
                        label: 'Priority',
                        value:
                            _priority[0].toUpperCase() + _priority.substring(1),
                        onTap: _showPriorityPicker,
                      ),
                      _MetaDivider(),
                      _PomodoroRow(
                        value: _estimatedPomodoros,
                        onChanged: (v) =>
                            setState(() => _estimatedPomodoros = v),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // ── Reminder tile ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: TaskReminderPresetsTile(
                  dueAt: _dueAt,
                  selectedPresets: _selectedReminderPresets,
                  customScheduledAt: _customReminderAt,
                  recurringCustomEnabled: _recurringCustomEnabled,
                  constantReminderEnabled: _constantReminderEnabled,
                  taskPriority: _priority,
                  recurringRule: _recurringRule,
                  onPresetsChanged: (value) => setState(
                    () => _selectedReminderPresets
                      ..clear()
                      ..addAll(value),
                  ),
                  onCustomScheduledAtChanged: (value) =>
                      setState(() => _customReminderAt = value),
                  onRecurringCustomChanged: (value) =>
                      setState(() => _recurringCustomEnabled = value),
                  onConstantReminderChanged: (value) =>
                      setState(() => _constantReminderEnabled = value),
                  onRecurringRuleChanged: (value) =>
                      setState(() => _recurringRule = value),
                ),
              ),
              const SizedBox(height: AppSpacing.s24),

              // ── Submit button ─────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: _isLoading
                    ? SizedBox(
                        height: AppButtonHeight.primary,
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              AppColors.brandPrimary,
                            ),
                          ),
                        ),
                      )
                    : GestureDetector(
                        onTap: _submit,
                        child: Container(
                          height: AppButtonHeight.primary,
                          decoration: BoxDecoration(
                            gradient: AppGradients.action,
                            borderRadius: BorderRadius.circular(AppRadius.xl),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.brandPrimary.withValues(
                                  alpha: 0.28,
                                ),
                                blurRadius: 18,
                                offset: const Offset(0, 6),
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              'Add Task',
                              style: GoogleFonts.manrope(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: 0.2,
                              ),
                            ),
                          ),
                        ),
                      ),
              ),
              const SizedBox(height: AppSpacing.s8),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Metadata row ──────────────────────────────────────────────────────────────

class _MetaRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String? value;
  final VoidCallback onTap;
  final Widget? trailing;

  const _MetaRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.onTap,
    this.value,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.xl),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.s16,
          vertical: 13,
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadius.sm),
              ),
              child: Icon(icon, size: 16, color: iconColor),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.manrope(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textBody,
                ),
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
            Text(
              value ?? 'Set',
              style: GoogleFonts.manrope(
                fontSize: 14,
                fontWeight:
                    value != null ? FontWeight.w600 : FontWeight.w400,
                color: value != null
                    ? AppColors.textHeading
                    : AppColors.textHint,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: AppColors.textHint,
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaDivider extends StatelessWidget {
  const _MetaDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s16),
      color: AppColors.borderSoft,
    );
  }
}

// ── Pomodoro stepper row ──────────────────────────────────────────────────────

class _PomodoroRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _PomodoroRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.s16,
        vertical: 12,
      ),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.featFocus.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadius.sm),
            ),
            child: const Icon(
              Icons.timer_outlined,
              size: 16,
              color: AppColors.featFocus,
            ),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pomodoros',
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textBody,
                  ),
                ),
                Text(
                  value == 0 ? 'No estimate' : '$value sessions',
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textHint,
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: value == 0 ? null : () => onChanged(value - 1),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bgApp,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Icon(
                Icons.remove,
                size: 14,
                color:
                    value == 0 ? AppColors.textHint : AppColors.textHeading,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Text(
              '$value',
              style: GoogleFonts.manrope(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: AppColors.textHeading,
              ),
            ),
          ),
          GestureDetector(
            onTap: value >= 12 ? null : () => onChanged(value + 1),
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.bgApp,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.borderSoft),
              ),
              child: Icon(
                Icons.add,
                size: 14,
                color: value >= 12
                    ? AppColors.textHint
                    : AppColors.brandPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Generic picker sheet ──────────────────────────────────────────────────────

class _PickerSheet extends StatelessWidget {
  final String title;
  final List<(String, String)> options;
  final String selected;
  final ValueChanged<String> onSelect;

  const _PickerSheet({
    required this.title,
    required this.options,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sheetBr,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            12,
            AppSpacing.screenH,
            24,
          ),
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
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 8),
              ...options.map(
                ((String, String) opt) => InkWell(
                  onTap: () {
                    onSelect(opt.$1);
                    Navigator.pop(context);
                  },
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 12,
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            opt.$2,
                            style: GoogleFonts.manrope(
                              fontSize: 15,
                              fontWeight: opt.$1 == selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: opt.$1 == selected
                                  ? AppColors.brandPrimary
                                  : AppColors.textHeading,
                            ),
                          ),
                        ),
                        if (opt.$1 == selected)
                          const Icon(
                            Icons.check_circle,
                            size: 18,
                            color: AppColors.brandPrimary,
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
