import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../reminders/widgets/task_reminder_presets_tile.dart';
import '../providers/task_provider.dart';

// ── Icon catalogue ─────────────────────────────────────────────────────────────

const _kTaskIcons = [
  ('task',     Icons.task_alt,                  'General'),
  ('work',     Icons.bar_chart,                 'Work'),
  ('meeting',  Icons.phone_outlined,            'Meeting'),
  ('study',    Icons.menu_book_outlined,        'Study'),
  ('shopping', Icons.shopping_cart_outlined,    'Shopping'),
  ('code',     Icons.terminal_outlined,         'Code'),
  ('health',   Icons.fitness_center_outlined,   'Health'),
  ('home',     Icons.home_outlined,             'Home'),
  ('travel',   Icons.flight_outlined,           'Travel'),
  ('finance',  Icons.account_balance_outlined,  'Finance'),
  ('creative', Icons.palette_outlined,          'Creative'),
  ('food',     Icons.restaurant_outlined,       'Food'),
  ('music',    Icons.music_note_outlined,       'Music'),
  ('sport',    Icons.sports_outlined,           'Sport'),
  ('prayer',   Icons.mosque_outlined,           'Prayer'),
  ('idea',     Icons.lightbulb_outline,         'Idea'),
  ('writing',  Icons.edit_outlined,             'Writing'),
  ('email',    Icons.email_outlined,            'Email'),
  ('video',    Icons.videocam_outlined,         'Video'),
  ('data',     Icons.analytics_outlined,        'Data'),
];

typedef _IconEntry = (String, IconData, String);

// ── Sheet ──────────────────────────────────────────────────────────────────────

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
  int _estimatedMinutes = 0;
  String _energyLevel = 'medium';
  DateTime? _dueAt;
  DateTime? _reminderAt;
  String? _selectedIconKey;
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

  // ── Helpers ──────────────────────────────────────────────────────────────────

  Color _priorityColor(String p) => switch (p) {
    'high'   => AppColors.errorColor,
    'medium' => AppColors.warningColor,
    _        => AppColors.successColor,
  };

  IconData _priorityIcon(String p) => switch (p) {
    'high'   => Icons.flag,
    'medium' => Icons.flag_outlined,
    _        => Icons.outlined_flag,
  };

  String _bucketLabel(String b) => switch (b) {
    'next'     => 'Next Actions',
    'waiting'  => 'Waiting For',
    'someday'  => 'Someday',
    'calendar' => 'Calendar',
    _          => 'Inbox',
  };

  String _energyLabel(String e) => switch (e) {
    'high'   => 'High focus',
    'low'    => 'Low energy',
    _        => 'Medium focus',
  };

  IconData _energyIcon(String e) => switch (e) {
    'high' => Icons.bolt,
    'low'  => Icons.sentiment_satisfied_outlined,
    _      => Icons.auto_awesome,
  };

  String _formatEstimated() {
    if (_estimatedMinutes == 0 && _estimatedPomodoros == 0) return 'Not set';
    if (_estimatedMinutes > 0) {
      final h = _estimatedMinutes ~/ 60;
      final m = _estimatedMinutes % 60;
      return h > 0 ? '${h}h ${m > 0 ? '${m}m' : ''}' : '${m}m';
    }
    return '$_estimatedPomodoros pomodoros';
  }

  String _formatDue() {
    if (_dueAt == null) return 'Not set';
    final d = _dueAt!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day}, ${d.year} · $h:$min $amPm';
  }

  String _formatReminder() {
    if (_reminderAt == null) return 'Not set';
    final d = _reminderAt!;
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    final hour = d.hour;
    final amPm = hour >= 12 ? 'PM' : 'AM';
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final min = d.minute.toString().padLeft(2, '0');
    return '${months[d.month - 1]} ${d.day} · $h:$min $amPm';
  }

  _IconEntry? get _selectedIcon =>
      _selectedIconKey == null
          ? null
          : _kTaskIcons.where((e) => e.$1 == _selectedIconKey).firstOrNull;

  // ── Pickers ───────────────────────────────────────────────────────────────────

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

  Future<void> _pickReminder() async {
    final picked = await _pickDateTime(initial: _reminderAt);
    if (picked != null) setState(() => _reminderAt = picked);
  }

  void _showPriorityPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Priority',
        options: const [('low', 'Low'), ('medium', 'Medium'), ('high', 'High')],
        selected: _priority,
        onSelect: (v) => setState(() => _priority = v),
      ),
    );
  }

  void _showBucketPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Project / Bucket',
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

  void _showEnergyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _PickerSheet(
        title: 'Energy needed',
        options: const [
          ('low', 'Low energy'),
          ('medium', 'Medium focus'),
          ('high', 'High focus'),
        ],
        selected: _energyLevel,
        onSelect: (v) => setState(() => _energyLevel = v),
      ),
    );
  }

  void _showEstimatedPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => _EstimatedPickerSheet(
        minutes: _estimatedMinutes,
        pomodoros: _estimatedPomodoros,
        onChanged: (mins, poms) => setState(() {
          _estimatedMinutes = mins;
          _estimatedPomodoros = poms;
        }),
      ),
    );
  }

  void _showIconPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _TaskIconPickerSheet(
        selected: _selectedIconKey,
        onSelect: (key) => setState(() => _selectedIconKey = key),
      ),
    );
  }

  // ── Submit ────────────────────────────────────────────────────────────────────

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    // Build category: icon key if set, otherwise null
    final category = _selectedIconKey != null ? 'icon:$_selectedIconKey' : null;

    final created = await ref.read(tasksProvider.notifier).createTask(
      title: _titleController.text.trim(),
      description: _descController.text.trim().isEmpty
          ? null
          : _descController.text.trim(),
      priority: _priority,
      dueAt: _dueAt,
      reminderAt: _reminderAt,
      estimatedMinutes: _estimatedMinutes > 0 ? _estimatedMinutes : null,
      estimatedPomodoros: _estimatedPomodoros > 0 ? _estimatedPomodoros : null,
      status: _bucket == 'calendar' ? 'pending' : _bucket,
      category: category,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error)));
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final icon = _selectedIcon;

    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgApp,
        borderRadius: AppRadius.sheetBr,
      ),
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Drag handle + header row ──────────────────────────────
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
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH, 12, AppSpacing.screenH, 0,
                ),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: AppColors.bgSurface,
                          borderRadius: BorderRadius.circular(AppRadius.md),
                          border: Border.all(color: AppColors.borderSoft),
                        ),
                        child: const Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Text(
                        'New Task',
                        style: GoogleFonts.manrope(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    _isLoading
                        ? const SizedBox(
                            width: 72,
                            height: 36,
                            child: Center(
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            ),
                          )
                        : GestureDetector(
                            onTap: _submit,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 9,
                              ),
                              decoration: BoxDecoration(
                                gradient: AppGradients.action,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.pill),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppColors.brandPrimary
                                        .withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Text(
                                'Save',
                                style: GoogleFonts.manrope(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.s16),

              // ── Title field ────────────────────────────────────────────
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
                        fontWeight: FontWeight.w500,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s16,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s8),

              // ── Description field ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: TextField(
                    controller: _descController,
                    maxLines: 3,
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      color: AppColors.textHeading,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Add description...',
                      hintStyle: GoogleFonts.manrope(
                        fontSize: 14,
                        color: AppColors.textHint,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.s16,
                        vertical: AppSpacing.s12,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),

              // ── Metadata card ──────────────────────────────────────────
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
                      // Icon picker
                      _MetaRow(
                        icon: icon?.$2 ?? Icons.label_outline,
                        iconColor: AppColors.brandPrimary,
                        label: 'Icon',
                        value: icon?.$3 ?? 'None',
                        onTap: _showIconPicker,
                      ),
                      _MetaDivider(),
                      // Due date
                      _MetaRow(
                        icon: Icons.calendar_today_outlined,
                        iconColor: AppColors.featTasks,
                        label: 'Due date',
                        value: _formatDue(),
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
                      // Priority
                      _MetaRow(
                        icon: _priorityIcon(_priority),
                        iconColor: _priorityColor(_priority),
                        label: 'Priority',
                        value:
                            _priority[0].toUpperCase() + _priority.substring(1),
                        onTap: _showPriorityPicker,
                      ),
                      _MetaDivider(),
                      // Project / bucket
                      _MetaRow(
                        icon: Icons.folder_outlined,
                        iconColor: AppColors.brandViolet,
                        label: 'Project',
                        value: _bucketLabel(_bucket),
                        onTap: _showBucketPicker,
                      ),
                      _MetaDivider(),
                      // Reminder
                      _MetaRow(
                        icon: Icons.notifications_outlined,
                        iconColor: AppColors.warningColor,
                        label: 'Reminder',
                        value: _formatReminder(),
                        onTap: _pickReminder,
                        trailing: _reminderAt != null
                            ? GestureDetector(
                                onTap: () =>
                                    setState(() => _reminderAt = null),
                                child: const Icon(
                                  Icons.clear,
                                  size: 16,
                                  color: AppColors.textHint,
                                ),
                              )
                            : null,
                      ),
                      _MetaDivider(),
                      // Estimated time
                      _MetaRow(
                        icon: Icons.timer_outlined,
                        iconColor: AppColors.brandPrimary,
                        label: 'Estimated',
                        value: _formatEstimated(),
                        onTap: _showEstimatedPicker,
                      ),
                      _MetaDivider(),
                      // Energy needed
                      _MetaRow(
                        icon: _energyIcon(_energyLevel),
                        iconColor: AppColors.infoColor,
                        label: 'Energy needed',
                        value: _energyLabel(_energyLevel),
                        onTap: _showEnergyPicker,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.s12),

              // ── Reminder tile ──────────────────────────────────────────
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
              const SizedBox(height: AppSpacing.s16),

              // ── Improve with AI ────────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                child: GestureDetector(
                  onTap: () {
                    // AI improvement hook — no-op for now, wired to AI coach
                  },
                  child: Container(
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.bgSurface,
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      border: Border.all(
                        color: AppColors.brandPrimary.withValues(alpha: 0.3),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 16,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Improve with AI',
                          style: GoogleFonts.manrope(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
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

// ── Metadata row ───────────────────────────────────────────────────────────────

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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHint,
                    ),
                  ),
                  Text(
                    value ?? 'Not set',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: value != null && value != 'Not set'
                          ? AppColors.textHeading
                          : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            ),
            if (trailing != null) ...[trailing!, const SizedBox(width: 6)],
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

// ── Estimated picker sheet ─────────────────────────────────────────────────────

class _EstimatedPickerSheet extends StatefulWidget {
  final int minutes;
  final int pomodoros;
  final void Function(int minutes, int pomodoros) onChanged;

  const _EstimatedPickerSheet({
    required this.minutes,
    required this.pomodoros,
    required this.onChanged,
  });

  @override
  State<_EstimatedPickerSheet> createState() => _EstimatedPickerSheetState();
}

class _EstimatedPickerSheetState extends State<_EstimatedPickerSheet> {
  late int _minutes;
  late int _pomodoros;

  static const _minuteOptions = [15, 30, 45, 60, 90, 120, 180, 240];

  @override
  void initState() {
    super.initState();
    _minutes = widget.minutes;
    _pomodoros = widget.pomodoros;
  }

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
            AppSpacing.screenH, 12, AppSpacing.screenH, 24,
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
                'Estimated time',
                style: GoogleFonts.manrope(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final m in _minuteOptions)
                    GestureDetector(
                      onTap: () => setState(() {
                        _minutes = m;
                        _pomodoros = 0;
                      }),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          gradient: _minutes == m ? AppGradients.action : null,
                          color: _minutes == m ? null : AppColors.bgApp,
                          borderRadius:
                              BorderRadius.circular(AppRadius.pill),
                          border: Border.all(
                            color: _minutes == m
                                ? Colors.transparent
                                : AppColors.borderSoft,
                          ),
                        ),
                        child: Text(
                          m >= 60
                              ? '${m ~/ 60}h${m % 60 > 0 ? ' ${m % 60}m' : ''}'
                              : '${m}m',
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _minutes == m
                                ? Colors.white
                                : AppColors.textHeading,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text(
                    'Pomodoros',
                    style: GoogleFonts.manrope(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _pomodoros == 0
                        ? null
                        : () => setState(() => _pomodoros--),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.bgApp,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: const Icon(Icons.remove, size: 14),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      '$_pomodoros',
                      style: GoogleFonts.manrope(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: _pomodoros >= 12
                        ? null
                        : () => setState(() {
                              _pomodoros++;
                              _minutes = 0;
                            }),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.bgApp,
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.borderSoft),
                      ),
                      child: const Icon(Icons.add, size: 14),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              GestureDetector(
                onTap: () {
                  widget.onChanged(_minutes, _pomodoros);
                  Navigator.pop(context);
                },
                child: Container(
                  height: AppButtonHeight.small,
                  decoration: BoxDecoration(
                    gradient: AppGradients.action,
                    borderRadius: BorderRadius.circular(AppRadius.xl),
                  ),
                  child: Center(
                    child: Text(
                      'Done',
                      style: GoogleFonts.manrope(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
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

// ── Task icon picker sheet ─────────────────────────────────────────────────────

class _TaskIconPickerSheet extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onSelect;

  const _TaskIconPickerSheet({
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
            AppSpacing.screenH, 12, AppSpacing.screenH, 24,
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
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Choose Icon',
                      style: GoogleFonts.manrope(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textHeading,
                      ),
                    ),
                  ),
                  if (selected != null)
                    GestureDetector(
                      onTap: () {
                        onSelect(null);
                        Navigator.pop(context);
                      },
                      child: Text(
                        'Clear',
                        style: GoogleFonts.manrope(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandPrimary,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.9,
                ),
                itemCount: _kTaskIcons.length,
                itemBuilder: (context, index) {
                  final entry = _kTaskIcons[index];
                  final isSelected = selected == entry.$1;
                  return GestureDetector(
                    onTap: () {
                      onSelect(entry.$1);
                      Navigator.pop(context);
                    },
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          width: 52,
                          height: 52,
                          decoration: BoxDecoration(
                            gradient:
                                isSelected ? AppGradients.action : null,
                            color: isSelected
                                ? null
                                : AppColors.bgSurfaceLavender,
                            borderRadius:
                                BorderRadius.circular(AppRadius.md),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : AppColors.borderSoft,
                            ),
                          ),
                          child: Icon(
                            entry.$2,
                            size: 22,
                            color: isSelected
                                ? Colors.white
                                : AppColors.brandPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          entry.$3,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: isSelected
                                ? AppColors.brandPrimary
                                : AppColors.textBody,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Generic picker sheet ───────────────────────────────────────────────────────

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
            AppSpacing.screenH, 12, AppSpacing.screenH, 24,
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
