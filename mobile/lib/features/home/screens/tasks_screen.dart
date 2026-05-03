import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_animations.dart';
import '../../../core/widgets/app_confirmation_dialog.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_empty_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../../focus/providers/focus_provider.dart';
import '../../habits/providers/habit_provider.dart';
import '../../prayer/providers/prayer_provider.dart';
import '../../focus/models/focus_model.dart';
import '../../habits/models/habit_model.dart';
import '../../notes/models/app_template_library.dart';
import '../../prayer/models/prayer_model.dart';
import '../../tasks/providers/task_provider.dart';
import '../../tasks/models/task_model.dart';
import '../../tasks/screens/create_task_sheet.dart';

// ── Main screen ───────────────────────────────────────────────────────────────

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearchVisible = false;

  // Tab index mapping (matches cloud design order):
  // 0=Today, 1=Inbox, 2=Upcoming, 3=Completed, 4=Smart, 5=GTD, 6=Kanban, 7=Matrix, 8=Calendar
  static const _kTabCount = 9;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _kTabCount, vsync: this);
    _tabController.addListener(() => setState(() {}));
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(tasksProvider.notifier).loadTasks();
      ref.read(focusProvider.notifier).loadAnalytics();
      ref.read(habitsProvider.notifier).loadHabits();
      ref.read(prayerProvider.notifier).loadTodayPrayers();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(tasksProvider);
    final searchedTasks = _filterTasks(state.tasks);
    final isSearching = _searchQuery.trim().isNotEmpty;

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ────────────────────────────────────────────────
            AppFadeSlide(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  AppSpacing.s20,
                  AppSpacing.screenH,
                  AppSpacing.s12,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Tasks',
                        style: GoogleFonts.manrope(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                          letterSpacing: -0.4,
                          height: 1.2,
                        ),
                      ),
                    ),
                    _HeaderIconButton(
                      icon: _isSearchVisible ? Icons.close : Icons.search,
                      tooltip: 'Search tasks',
                      onTap: _toggleSearch,
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _HeaderIconButton(
                      icon: Icons.dashboard_customize_outlined,
                      tooltip: 'Task templates',
                      onTap: () => _showTaskTemplatePicker(context),
                    ),
                    const SizedBox(width: AppSpacing.s8),
                    _HeaderIconButton(
                      icon: Icons.account_tree_outlined,
                      tooltip: 'Project timelines',
                      onTap: () => _showProjectTimelinePicker(context, ref),
                    ),
                  ],
                ),
              ),
            ),
            if (_isSearchVisible)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenH,
                  0,
                  AppSpacing.screenH,
                  AppSpacing.s12,
                ),
                child: TextField(
                  controller: _searchController,
                  textInputAction: TextInputAction.search,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  decoration: InputDecoration(
                    hintText: 'Search tasks...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Clear search',
                            icon: const Icon(Icons.close),
                            onPressed: _clearSearch,
                          ),
                    filled: true,
                    fillColor: AppColors.bgSurface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(
                        color: AppColors.borderSoft,
                      ),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(
                        color: AppColors.borderSoft,
                      ),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppRadius.xl),
                      borderSide: const BorderSide(
                        color: AppColors.brandPrimary,
                      ),
                    ),
                  ),
                ),
              ),

            // ── Tab pills ─────────────────────────────────────────────
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.screenH,
                ),
                children: [
                  _TabPill(label: 'Today', index: 0, controller: _tabController),
                  _TabPill(label: 'Calendar', index: 8, controller: _tabController),
                  _TabPill(label: 'Inbox', index: 1, controller: _tabController),
                  _TabPill(label: 'Upcoming', index: 2, controller: _tabController),
                  _TabPill(label: 'Done', index: 3, controller: _tabController),
                  _TabPill(label: 'Smart', index: 4, controller: _tabController),
                  _TabPill(label: 'GTD', index: 5, controller: _tabController),
                  _TabPill(label: 'Kanban', index: 6, controller: _tabController),
                  _TabPill(label: 'Matrix', index: 7, controller: _tabController),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.s12),

            // ── Tab content ───────────────────────────────────────────
            Expanded(
              child: state.isLoading
                  ? const AppLoadingState(message: 'Loading tasks...')
                  : state.error != null
                  ? AppErrorState(
                      title: 'Tasks could not load',
                      message: state.error!,
                      onRetry: () =>
                          ref.read(tasksProvider.notifier).loadTasks(),
                    )
                  : isSearching && searchedTasks.isEmpty
                  ? const AppEmptyState(
                      icon: Icons.search_off_outlined,
                      title: 'No matching tasks',
                      message:
                          'Try another task title, description, or category.',
                      accentColor: AppColors.brandPrimary,
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        // 0 — Today
                        _TodayView(
                          tasks: searchedTasks
                              .where((t) => !t.isDeleted)
                              .toList(),
                        ),
                        // 1 — Inbox (pending, no due date)
                        _TaskList(
                          tasks: searchedTasks
                              .where(
                                (t) =>
                                    t.status != 'completed' &&
                                    !t.isDeleted &&
                                    t.dueAt == null,
                              )
                              .toList(),
                          status: 'pending',
                        ),
                        // 2 — Upcoming (has future due date)
                        _TaskList(
                          tasks: searchedTasks
                              .where(
                                (t) =>
                                    t.status != 'completed' &&
                                    !t.isDeleted &&
                                    t.dueAt != null,
                              )
                              .toList(),
                          status: 'upcoming',
                        ),
                        // 3 — Done
                        _TaskList(
                          tasks: searchedTasks
                              .where((t) => t.status == 'completed')
                              .toList(),
                          status: 'completed',
                        ),
                        // 4 — Smart lists
                        _SmartListsView(
                          tasks: searchedTasks
                              .where((t) => !t.isDeleted)
                              .toList(),
                        ),
                        // 5 — GTD
                        _GtdBucketsView(
                          tasks: searchedTasks
                              .where((t) => !t.isDeleted)
                              .toList(),
                        ),
                        // 6 — Kanban
                        _KanbanBoardView(
                          tasks: searchedTasks
                              .where((t) => !t.isDeleted)
                              .toList(),
                        ),
                        // 7 — Matrix
                        _EisenhowerMatrixView(
                          tasks: searchedTasks
                              .where(
                                (t) =>
                                    t.status != 'completed' && !t.isDeleted,
                              )
                              .toList(),
                        ),
                        // 8 — Calendar
                        const _TaskCalendarView(),
                      ],
                    ),
            ),
          ],
        ),
      ),
      floatingActionButton: AppFadeSlide(
        delay: const Duration(milliseconds: 200),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: AppGradients.action,
            borderRadius: BorderRadius.circular(AppRadius.pill),
            boxShadow: [
              BoxShadow(
                color: AppColors.brandPrimary.withValues(alpha: 0.35),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(AppRadius.pill),
              onTap: () => showModalBottomSheet(
                context: context,
                isScrollControlled: true,
                backgroundColor: Colors.transparent,
                builder: (_) => const CreateTaskSheet(),
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 24),
            ),
          ),
        ),
      ),
    );
  }

  void _toggleSearch() {
    setState(() {
      if (_isSearchVisible && _searchQuery.trim().isNotEmpty) {
        _searchController.clear();
        _searchQuery = '';
        return;
      }
      _isSearchVisible = !_isSearchVisible;
    });
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      _searchQuery = '';
    });
  }

  List<TaskModel> _filterTasks(List<TaskModel> tasks) {
    final query = _normalizeSearchText(_searchQuery);
    if (query.isEmpty) return tasks;
    return tasks.where((task) => _matchesTaskSearch(task, query)).toList();
  }

  bool _matchesTaskSearch(TaskModel task, String query) {
    final fields = <String>[
      task.title,
      if (task.description != null) task.description!,
      if (task.category != null) task.category!,
      if (task.projectId != null) task.projectId!,
    ];
    return fields.any((field) => _normalizeSearchText(field).contains(query));
  }

  String _normalizeSearchText(String value) {
    return value.trim().toLowerCase();
  }

  Future<void> _showTaskTemplatePicker(BuildContext context) async {
    final templates = appTemplates
        .where((template) => template.hasTaskPlan)
        .toList(growable: false);
    final template = await showModalBottomSheet<AppTemplate>(
      context: context,
      backgroundColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
      ),
      builder: (context) => _TaskTemplatePickerSheet(templates: templates),
    );
    if (template == null || !context.mounted) return;

    var createdCount = 0;
    for (final task in template.tasks) {
      final created = await ref
          .read(tasksProvider.notifier)
          .createTask(
            title: task.title,
            description: task.description,
            priority: task.priority,
            category: task.category,
            estimatedMinutes: task.estimatedMinutes,
          );
      if (created) createdCount++;
    }

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Created $createdCount tasks from ${template.title}.'),
      ),
    );
  }
}

// ── Header icon button ────────────────────────────────────────────────────────

class _HeaderIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  const _HeaderIconButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.bgSurface,
            borderRadius: BorderRadius.circular(AppRadius.sm),
            border: Border.all(color: AppColors.borderSoft),
          ),
          child: Icon(icon, size: 18, color: AppColors.textHeading),
        ),
      ),
    );
  }
}

// ── Tab pill ──────────────────────────────────────────────────────────────────

class _TabPill extends StatelessWidget {
  final String label;
  final int index;
  final TabController controller;

  const _TabPill({
    required this.label,
    required this.index,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    final active = controller.index == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        controller.animateTo(index);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          gradient: active ? AppGradients.action : null,
          color: active ? null : AppColors.bgSurface,
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: active ? null : Border.all(color: AppColors.borderSoft),
        ),
        child: Text(
          label,
          style: GoogleFonts.manrope(
            fontSize: 13,
            fontWeight: active ? FontWeight.w700 : FontWeight.w500,
            color: active ? Colors.white : AppColors.textBody,
          ),
        ),
      ),
    );
  }
}

// ── Template picker sheet ─────────────────────────────────────────────────────

class _TaskTemplatePickerSheet extends StatelessWidget {
  final List<AppTemplate> templates;

  const _TaskTemplatePickerSheet({required this.templates});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sheetBr,
      ),
      child: SafeArea(
        child: ListView.separated(
          shrinkWrap: true,
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            20,
            AppSpacing.screenH,
            24,
          ),
          itemCount: templates.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.s8),
          itemBuilder: (context, index) {
            final template = templates[index];
            return InkWell(
              borderRadius: BorderRadius.circular(AppRadius.lg),
              onTap: () => Navigator.pop(context, template),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.s16),
                decoration: BoxDecoration(
                  color: AppColors.bgApp,
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                  border: Border.all(color: AppColors.borderSoft),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColors.featTasksSoft,
                        borderRadius: BorderRadius.circular(AppRadius.sm),
                      ),
                      child: const Icon(
                        Icons.playlist_add_check_outlined,
                        size: 18,
                        color: AppColors.featTasks,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            template.title,
                            style: GoogleFonts.manrope(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textHeading,
                            ),
                          ),
                          Text(
                            '${template.tasks.length} starter tasks',
                            style: GoogleFonts.manrope(
                              fontSize: 12,
                              color: AppColors.textBody,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.chevron_right,
                      size: 18,
                      color: AppColors.textHint,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Project timeline picker ───────────────────────────────────────────────────

Future<void> _showProjectTimelinePicker(
  BuildContext context,
  WidgetRef ref,
) async {
  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
    ),
    builder: (context) => _ProjectTimelinePicker(ref: ref),
  );
}

class _ProjectTimelinePicker extends StatelessWidget {
  final WidgetRef ref;

  const _ProjectTimelinePicker({required this.ref});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.sheetBr,
      ),
      child: SafeArea(
        child: FutureBuilder<List<TaskProject>>(
          future: ref.read(taskServiceProvider).getProjects(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const SizedBox(
                height: 220,
                child: AppLoadingState(message: 'Loading projects...'),
              );
            }
            if (snapshot.hasError) {
              return const SizedBox(
                height: 260,
                child: AppErrorState(
                  title: 'Projects could not load',
                  message: 'Open Tasks again and retry project timelines.',
                ),
              );
            }
            final projects = snapshot.data ?? const [];
            if (projects.isEmpty) {
              return const SizedBox(
                height: 260,
                child: AppEmptyState(
                  icon: Icons.folder_outlined,
                  title: 'No projects',
                  message: 'Create a project to view its task timeline.',
                ),
              );
            }
            return Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH,
                20,
                AppSpacing.screenH,
                28,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Project Timelines',
                    style: GoogleFonts.manrope(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.s12),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: projects.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: AppSpacing.s8),
                      itemBuilder: (context, index) {
                        final project = projects[index];
                        return InkWell(
                          borderRadius: BorderRadius.circular(AppRadius.lg),
                          onTap: () {
                            Navigator.pop(context);
                            context.push('/home/projects/${project.id}');
                          },
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.s16),
                            decoration: BoxDecoration(
                              color: AppColors.bgApp,
                              borderRadius:
                                  BorderRadius.circular(AppRadius.lg),
                              border:
                                  Border.all(color: AppColors.borderSoft),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    color: AppColors.bgSurfaceLavender,
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.sm),
                                  ),
                                  child: const Icon(
                                    Icons.timeline_outlined,
                                    size: 18,
                                    color: AppColors.brandPrimary,
                                  ),
                                ),
                                const SizedBox(width: AppSpacing.s12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        project.title,
                                        style: GoogleFonts.manrope(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                          color: AppColors.textHeading,
                                        ),
                                      ),
                                      Text(
                                        project.status,
                                        style: GoogleFonts.manrope(
                                          fontSize: 12,
                                          color: AppColors.textBody,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const Icon(
                                  Icons.chevron_right,
                                  size: 18,
                                  color: AppColors.textHint,
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

// ── Smart lists view ──────────────────────────────────────────────────────────

class _SmartListsView extends StatefulWidget {
  final List<TaskModel> tasks;

  const _SmartListsView({required this.tasks});

  @override
  State<_SmartListsView> createState() => _SmartListsViewState();
}

class _SmartListsViewState extends State<_SmartListsView> {
  String _selectedFilterId = _smartFilters.first.id;

  @override
  Widget build(BuildContext context) {
    final activeTasks = widget.tasks
        .where((task) => task.status != 'completed')
        .toList();
    final selectedFilter = _smartFilters.firstWhere(
      (filter) => filter.id == _selectedFilterId,
      orElse: () => _smartFilters.first,
    );
    final filteredTasks = activeTasks.where(selectedFilter.matches).toList()
      ..sort(selectedFilter.compare);

    return RefreshIndicator(
      onRefresh: () async {},
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          138,
        ),
        children: [
          Text(
            'Smart Lists',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Saved filters for the task views you check most often.',
            style: GoogleFonts.manrope(
              fontSize: 12,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _smartFilters.map((filter) {
              final count = activeTasks.where(filter.matches).length;
              final selected = filter.id == _selectedFilterId;
              return GestureDetector(
                onTap: () => setState(() => _selectedFilterId = filter.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? filter.color.withValues(alpha: 0.12)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: selected
                          ? filter.color.withValues(alpha: 0.4)
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        filter.icon,
                        size: 14,
                        color: selected ? filter.color : AppColors.textBody,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${filter.title} ($count)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight: selected
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color:
                              selected ? filter.color : AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s16),
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: selectedFilter.color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(
                color: selectedFilter.color.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Icon(selectedFilter.icon, color: selectedFilter.color),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedFilter.title,
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      Text(
                        selectedFilter.description,
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (filteredTasks.isEmpty)
            AppEmptyState(
              icon: selectedFilter.icon,
              title: 'No matching tasks',
              message: selectedFilter.emptyMessage,
              accentColor: selectedFilter.color,
            )
          else
            ...filteredTasks.map((task) => _TaskCard(task: task)),
        ],
      ),
    );
  }
}

class _SmartFilter {
  final String id;
  final String title;
  final String description;
  final String emptyMessage;
  final IconData icon;
  final Color color;
  final bool Function(TaskModel task) matches;
  final int Function(TaskModel left, TaskModel right) compare;

  const _SmartFilter({
    required this.id,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.icon,
    required this.color,
    required this.matches,
    this.compare = _compareByDueDateThenPriority,
  });
}

final _smartFilters = [
  _SmartFilter(
    id: 'high_priority_week',
    title: 'High priority this week',
    description: 'High priority tasks due before the end of this week.',
    emptyMessage: 'No high priority tasks are due this week.',
    icon: Icons.flag_outlined,
    color: AppColors.error,
    matches: _isHighPriorityThisWeek,
  ),
  _SmartFilter(
    id: 'overdue',
    title: 'Overdue',
    description: 'Tasks with due dates in the past.',
    emptyMessage: 'Nothing is overdue.',
    icon: Icons.warning_amber_outlined,
    color: AppColors.warning,
    matches: _isOverdue,
  ),
  _SmartFilter(
    id: 'waiting_for',
    title: 'Waiting For',
    description: 'Tasks currently parked in the Waiting column.',
    emptyMessage: 'No tasks are waiting right now.',
    icon: Icons.hourglass_empty_outlined,
    color: AppColors.prayerGold,
    matches: (task) => task.status == 'waiting',
  ),
  _SmartFilter(
    id: 'no_due_date',
    title: 'No due date',
    description: 'Tasks that still need a date or scheduling decision.',
    emptyMessage: 'Every active task has a due date.',
    icon: Icons.event_busy_outlined,
    color: AppColors.textSecondary,
    matches: (task) => task.dueAt == null,
    compare: _compareByPriorityThenTitle,
  ),
  _SmartFilter(
    id: 'deep_work',
    title: 'Deep work tasks',
    description: 'Long or focus-heavy tasks that need protected time.',
    emptyMessage: 'No deep work tasks found.',
    icon: Icons.psychology_outlined,
    color: AppColors.primary,
    matches: _isDeepWorkTask,
  ),
  _SmartFilter(
    id: 'prayer_friendly',
    title: 'Prayer-friendly tasks',
    description: 'Short tasks that can fit between prayer anchors.',
    emptyMessage: 'No short prayer-friendly tasks found.',
    icon: Icons.mosque_outlined,
    color: AppColors.prayerGold,
    matches: _isPrayerFriendlyTask,
  ),
];

bool _isHighPriorityThisWeek(TaskModel task) {
  if (task.priority != 'high' || task.dueAt == null) return false;
  final dueAt = DateTime.tryParse(task.dueAt!)?.toLocal();
  if (dueAt == null) return false;
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final endOfWeek = today
      .subtract(Duration(days: today.weekday - 1))
      .add(const Duration(days: 7));
  return !dueAt.isBefore(today) && dueAt.isBefore(endOfWeek);
}

bool _isOverdue(TaskModel task) {
  if (task.dueAt == null) return false;
  final dueAt = DateTime.tryParse(task.dueAt!)?.toLocal();
  if (dueAt == null) return false;
  return dueAt.isBefore(DateTime.now());
}

bool _isDeepWorkTask(TaskModel task) {
  final category = task.category?.toLowerCase() ?? '';
  final title = task.title.toLowerCase();
  final estimated = task.estimatedMinutes ?? 0;
  return estimated >= 45 ||
      category.contains('deep') ||
      category.contains('focus') ||
      category.contains('study') ||
      title.contains('deep work') ||
      title.contains('study');
}

bool _isPrayerFriendlyTask(TaskModel task) {
  final estimated = task.estimatedMinutes;
  if (estimated == null) return task.dueAt == null && task.priority != 'high';
  return estimated > 0 && estimated <= 30;
}

int _compareByDueDateThenPriority(TaskModel left, TaskModel right) {
  final leftDue = left.dueAt == null ? null : DateTime.tryParse(left.dueAt!);
  final rightDue =
      right.dueAt == null ? null : DateTime.tryParse(right.dueAt!);
  if (leftDue != null && rightDue != null) {
    final dueCompare = leftDue.compareTo(rightDue);
    if (dueCompare != 0) return dueCompare;
  } else if (leftDue != null) {
    return -1;
  } else if (rightDue != null) {
    return 1;
  }
  return _compareByPriorityThenTitle(left, right);
}

int _compareByPriorityThenTitle(TaskModel left, TaskModel right) {
  final priorityCompare = _priorityRank(
    right.priority,
  ).compareTo(_priorityRank(left.priority));
  if (priorityCompare != 0) return priorityCompare;
  return left.title.toLowerCase().compareTo(right.title.toLowerCase());
}

int _priorityRank(String priority) {
  return switch (priority) {
    'high' => 3,
    'medium' => 2,
    _ => 1,
  };
}

// ── GTD buckets view ──────────────────────────────────────────────────────────

class _GtdBucketsView extends ConsumerStatefulWidget {
  final List<TaskModel> tasks;

  const _GtdBucketsView({required this.tasks});

  @override
  ConsumerState<_GtdBucketsView> createState() => _GtdBucketsViewState();
}

class _GtdBucketsViewState extends ConsumerState<_GtdBucketsView> {
  String _selectedBucket = _gtdBuckets.first.id;

  @override
  Widget build(BuildContext context) {
    final bucket = _gtdBuckets.firstWhere(
      (item) => item.id == _selectedBucket,
      orElse: () => _gtdBuckets.first,
    );
    final activeTasks = widget.tasks
        .where((task) => task.status != 'completed' && !task.isDeleted)
        .toList();
    final visibleTasks = bucket.filter(activeTasks)..sort(_compareByGtd);

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          138,
        ),
        children: [
          Text(
            'GTD Buckets',
            style: GoogleFonts.manrope(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Capture, clarify, organize, reflect, and engage from one trusted view.',
            style: GoogleFonts.manrope(fontSize: 12, color: AppColors.textBody),
          ),
          const SizedBox(height: AppSpacing.s12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _gtdBuckets.map((item) {
              final count = item.filter(activeTasks).length;
              final selected = item.id == _selectedBucket;
              return GestureDetector(
                onTap: () => setState(() => _selectedBucket = item.id),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 7,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? item.color.withValues(alpha: 0.12)
                        : AppColors.bgSurface,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    border: Border.all(
                      color: selected
                          ? item.color.withValues(alpha: 0.4)
                          : AppColors.borderSoft,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 14,
                        color: selected ? item.color : AppColors.textBody,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${item.title} ($count)',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          fontWeight:
                              selected ? FontWeight.w700 : FontWeight.w500,
                          color: selected ? item.color : AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.s16),
          _GtdBucketHeader(bucket: bucket, count: visibleTasks.length),
          const SizedBox(height: AppSpacing.s12),
          if (bucket.id == 'projects') ...[
            _ProjectsBucketPanel(tasks: activeTasks),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (visibleTasks.isEmpty)
            AppEmptyState(
              icon: bucket.icon,
              title: 'No ${bucket.title.toLowerCase()} tasks',
              message: bucket.emptyMessage,
              accentColor: bucket.color,
            )
          else
            ...visibleTasks.map((task) => _TaskCard(task: task)),
        ],
      ),
    );
  }
}

class _GtdBucketHeader extends StatelessWidget {
  final _GtdBucket bucket;
  final int count;

  const _GtdBucketHeader({required this.bucket, required this.count});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: bucket.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: bucket.color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(bucket.icon, color: bucket.color),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bucket.title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  bucket.description,
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
          Text(
            count.toString(),
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: bucket.color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProjectsBucketPanel extends StatelessWidget {
  final List<TaskModel> tasks;

  const _ProjectsBucketPanel({required this.tasks});

  @override
  Widget build(BuildContext context) {
    final projectTaskCount = tasks
        .where((task) => task.projectId != null)
        .map((task) => task.projectId!)
        .toSet()
        .length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.lg),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.folder_outlined,
            color: AppColors.brandPrimary,
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Text(
              projectTaskCount == 0
                  ? 'No active project tasks yet.'
                  : '$projectTaskCount projects have active tasks.',
              style: GoogleFonts.manrope(
                fontSize: 13,
                color: AppColors.textBody,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GtdBucket {
  final String id;
  final String title;
  final String description;
  final String emptyMessage;
  final IconData icon;
  final Color color;
  final List<TaskModel> Function(List<TaskModel> tasks) filter;

  const _GtdBucket({
    required this.id,
    required this.title,
    required this.description,
    required this.emptyMessage,
    required this.icon,
    required this.color,
    required this.filter,
  });
}

final _gtdBuckets = [
  _GtdBucket(
    id: 'inbox',
    title: 'Inbox',
    description: 'Raw captured tasks waiting for clarification.',
    emptyMessage: 'Captured tasks that need clarification will appear here.',
    icon: Icons.inbox_outlined,
    color: AppColors.textSecondary,
    filter: (tasks) => tasks
        .where(
          (task) =>
              task.status == 'pending' &&
              task.projectId == null &&
              task.dueAt == null,
        )
        .toList(),
  ),
  _GtdBucket(
    id: 'next',
    title: 'Next Actions',
    description: 'Clear tasks ready to do next.',
    emptyMessage: 'Move clarified tasks here when they are ready to execute.',
    icon: Icons.arrow_forward_outlined,
    color: AppColors.primary,
    filter: (tasks) => tasks.where((task) => task.status == 'next').toList(),
  ),
  _GtdBucket(
    id: 'projects',
    title: 'Projects',
    description: 'Tasks connected to active project outcomes.',
    emptyMessage: 'Project tasks will appear here after you link them.',
    icon: Icons.folder_copy_outlined,
    color: AppColors.success,
    filter: (tasks) =>
        tasks.where((task) => task.projectId != null).toList(),
  ),
  _GtdBucket(
    id: 'waiting',
    title: 'Waiting For',
    description: 'Tasks blocked by another person, decision, or dependency.',
    emptyMessage: 'Waiting items stay parked here until the blocker clears.',
    icon: Icons.hourglass_empty_outlined,
    color: AppColors.prayerGold,
    filter: (tasks) =>
        tasks.where((task) => task.status == 'waiting').toList(),
  ),
  _GtdBucket(
    id: 'someday',
    title: 'Someday',
    description: 'Ideas and future work you are not committing to yet.',
    emptyMessage: 'Future ideas can rest here without cluttering today.',
    icon: Icons.lightbulb_outline,
    color: AppColors.warning,
    filter: (tasks) =>
        tasks.where((task) => task.status == 'someday').toList(),
  ),
  _GtdBucket(
    id: 'calendar',
    title: 'Calendar',
    description: 'Tasks with a specific due date or time.',
    emptyMessage: 'Date-specific tasks will appear here.',
    icon: Icons.calendar_month_outlined,
    color: AppColors.error,
    filter: (tasks) => tasks.where((task) => task.dueAt != null).toList(),
  ),
];

int _compareByGtd(TaskModel left, TaskModel right) {
  final leftDue = left.dueAt == null ? null : DateTime.tryParse(left.dueAt!);
  final rightDue =
      right.dueAt == null ? null : DateTime.tryParse(right.dueAt!);
  if (leftDue != null && rightDue != null) {
    final dueCompare = leftDue.compareTo(rightDue);
    if (dueCompare != 0) return dueCompare;
  } else if (leftDue != null) {
    return -1;
  } else if (rightDue != null) {
    return 1;
  }
  return _compareByPriorityThenTitle(left, right);
}

// ── Kanban board view ─────────────────────────────────────────────────────────

class _KanbanBoardView extends ConsumerWidget {
  final List<TaskModel> tasks;

  const _KanbanBoardView({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.view_kanban_outlined,
        title: 'No tasks for the board',
        message: 'Create tasks to organize them across project stages.',
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          0,
        ),
        children: _kanbanColumns
            .map(
              (column) => _KanbanColumn(
                column: column,
                tasks: tasks
                    .where(
                      (task) =>
                          _kanbanStatus(task.status) == column.status,
                    )
                    .toList(),
                onMove: (task, status) => ref
                    .read(tasksProvider.notifier)
                    .moveTaskToStatus(task: task, status: status),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _KanbanColumn extends StatelessWidget {
  final _KanbanColumnData column;
  final List<TaskModel> tasks;
  final Future<bool> Function(TaskModel task, String status) onMove;

  const _KanbanColumn({
    required this.column,
    required this.tasks,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 280,
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: column.color.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: column.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.xs),
                ),
                child: Icon(column.icon, color: column.color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  column.title,
                  style: GoogleFonts.manrope(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textHeading,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: column.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  tasks.length.toString(),
                  style: GoogleFonts.manrope(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: column.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            column.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.manrope(
              fontSize: 11,
              color: AppColors.textBody,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 10),
                    itemBuilder: (context, index) => _KanbanTaskCard(
                      task: tasks[index],
                      currentStatus: column.status,
                      onMove: onMove,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KanbanTaskCard extends StatelessWidget {
  final TaskModel task;
  final String currentStatus;
  final Future<bool> Function(TaskModel task, String status) onMove;

  const _KanbanTaskCard({
    required this.task,
    required this.currentStatus,
    required this.onMove,
  });

  @override
  Widget build(BuildContext context) {
    final pColor = _priorityColor(task.priority);
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.lg),
      onTap: () => context.push('/home/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.bgApp,
          borderRadius: BorderRadius.circular(AppRadius.lg),
          border: Border.all(color: AppColors.borderSoft),
          boxShadow: [
            BoxShadow(
              color: pColor.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    task.title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textHeading,
                    ),
                  ),
                ),
                PopupMenuButton<String>(
                  tooltip: 'Move task',
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onSelected: (status) => onMove(task, status),
                  itemBuilder: (context) => _kanbanColumns
                      .where((column) => column.status != currentStatus)
                      .map(
                        (column) => PopupMenuItem(
                          value: column.status,
                          child: Text('Move to ${column.title}'),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
            if (task.dueAt != null) ...[
              const SizedBox(height: 4),
              Text(
                'Due ${task.dueAt!.substring(0, 10)}',
                style: GoogleFonts.manrope(
                  fontSize: 11,
                  color: AppColors.textBody,
                ),
              ),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _KanbanChip(label: task.priority, color: pColor),
                if (task.estimatedMinutes != null)
                  _KanbanChip(
                    label: '${task.estimatedMinutes} min',
                    color: AppColors.brandPrimary,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _KanbanChip extends StatelessWidget {
  final String label;
  final Color color;

  const _KanbanChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Text(
        label,
        style: GoogleFonts.manrope(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _KanbanColumnData {
  final String title;
  final String status;
  final String description;
  final Color color;
  final IconData icon;

  const _KanbanColumnData({
    required this.title,
    required this.status,
    required this.description,
    required this.color,
    required this.icon,
  });
}

const _kanbanColumns = [
  _KanbanColumnData(
    title: 'Inbox',
    status: 'pending',
    description: 'Captured tasks ready to organize.',
    color: AppColors.textSecondary,
    icon: Icons.inbox_outlined,
  ),
  _KanbanColumnData(
    title: 'Next',
    status: 'next',
    description: 'Ready to start soon.',
    color: AppColors.primary,
    icon: Icons.arrow_forward_outlined,
  ),
  _KanbanColumnData(
    title: 'In Progress',
    status: 'in_progress',
    description: 'Currently being worked on.',
    color: AppColors.warning,
    icon: Icons.pending_actions_outlined,
  ),
  _KanbanColumnData(
    title: 'Waiting',
    status: 'waiting',
    description: 'Blocked or waiting on someone.',
    color: AppColors.prayerGold,
    icon: Icons.hourglass_empty_outlined,
  ),
  _KanbanColumnData(
    title: 'Someday',
    status: 'someday',
    description: 'Future ideas and maybe-later tasks.',
    color: AppColors.warning,
    icon: Icons.lightbulb_outline,
  ),
  _KanbanColumnData(
    title: 'Done',
    status: 'completed',
    description: 'Finished tasks.',
    color: AppColors.success,
    icon: Icons.check_circle_outline,
  ),
];

String _kanbanStatus(String status) {
  if (status == 'next' ||
      status == 'in_progress' ||
      status == 'waiting' ||
      status == 'someday') {
    return status;
  }
  if (status == 'completed') return status;
  return 'pending';
}

Color _priorityColor(String priority) {
  return switch (priority) {
    'high' => AppColors.errorColor,
    'medium' => AppColors.warningColor,
    _ => AppColors.successColor,
  };
}

// ── Eisenhower matrix view ────────────────────────────────────────────────────

class _EisenhowerMatrixView extends StatelessWidget {
  final List<TaskModel> tasks;

  const _EisenhowerMatrixView({required this.tasks});

  bool _isUrgent(TaskModel task) {
    if (task.dueAt == null) return false;
    final dueAt = DateTime.tryParse(task.dueAt!)?.toLocal();
    if (dueAt == null) return false;
    final now = DateTime.now();
    return dueAt.isBefore(now) ||
        dueAt.difference(now) <= const Duration(hours: 48);
  }

  bool _isImportant(TaskModel task) => task.priority == 'high';

  @override
  Widget build(BuildContext context) {
    if (tasks.isEmpty) {
      return const AppEmptyState(
        icon: Icons.grid_view_outlined,
        title: 'No pending tasks',
        message:
            'Create tasks with priorities and deadlines to fill the matrix.',
      );
    }

    final urgentImportant = <TaskModel>[];
    final importantNotUrgent = <TaskModel>[];
    final urgentNotImportant = <TaskModel>[];
    final notUrgentNotImportant = <TaskModel>[];

    for (final task in tasks) {
      final urgent = _isUrgent(task);
      final important = _isImportant(task);
      if (urgent && important) {
        urgentImportant.add(task);
      } else if (important) {
        importantNotUrgent.add(task);
      } else if (urgent) {
        urgentNotImportant.add(task);
      } else {
        notUrgentNotImportant.add(task);
      }
    }

    final quadrants = [
      _MatrixQuadrantData(
        title: 'Urgent + Important',
        subtitle: 'Do first',
        tasks: urgentImportant,
        color: AppColors.errorColor,
        icon: Icons.priority_high,
      ),
      _MatrixQuadrantData(
        title: 'Important, Not Urgent',
        subtitle: 'Schedule',
        tasks: importantNotUrgent,
        color: AppColors.primary,
        icon: Icons.event_available_outlined,
      ),
      _MatrixQuadrantData(
        title: 'Urgent, Not Important',
        subtitle: 'Reduce or delegate',
        tasks: urgentNotImportant,
        color: AppColors.warningColor,
        icon: Icons.schedule_outlined,
      ),
      _MatrixQuadrantData(
        title: 'Not Urgent + Not Important',
        subtitle: 'Batch later',
        tasks: notUrgentNotImportant,
        color: AppColors.textSecondary,
        icon: Icons.low_priority,
      ),
    ];

    return RefreshIndicator(
      onRefresh: () async {},
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isWide = constraints.maxWidth >= 640;
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.screenH,
              0,
              AppSpacing.screenH,
              138,
            ),
            children: [
              Text(
                'Priority Matrix',
                style: GoogleFonts.manrope(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textHeading,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Urgent means overdue or due within 48 hours. Important means high priority.',
                style: GoogleFonts.manrope(
                  fontSize: 12,
                  color: AppColors.textBody,
                ),
              ),
              const SizedBox(height: AppSpacing.s16),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: quadrants.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 2 : 1,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: isWide ? 1.1 : 1.35,
                ),
                itemBuilder: (context, index) {
                  return _MatrixQuadrant(data: quadrants[index]);
                },
              ),
            ],
          );
        },
      ),
    );
  }
}

class _MatrixQuadrantData {
  final String title;
  final String subtitle;
  final List<TaskModel> tasks;
  final Color color;
  final IconData icon;

  const _MatrixQuadrantData({
    required this.title,
    required this.subtitle,
    required this.tasks,
    required this.color,
    required this.icon,
  });
}

class _MatrixQuadrant extends StatelessWidget {
  final _MatrixQuadrantData data;

  const _MatrixQuadrant({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: data.color.withValues(alpha: 0.22)),
        boxShadow: [
          BoxShadow(
            color: data.color.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: data.color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(data.icon, color: data.color, size: 17),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textHeading,
                      ),
                    ),
                    Text(
                      '${data.subtitle} · ${data.tasks.length}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 11,
                        color: AppColors.textBody,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.s12),
          Expanded(
            child: data.tasks.isEmpty
                ? Center(
                    child: Text(
                      'No tasks',
                      style: GoogleFonts.manrope(
                        fontSize: 12,
                        color: AppColors.textHint,
                      ),
                    ),
                  )
                : ListView.separated(
                    itemCount: data.tasks.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      return _MatrixTaskTile(task: data.tasks[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _MatrixTaskTile extends StatelessWidget {
  final TaskModel task;

  const _MatrixTaskTile({required this.task});

  @override
  Widget build(BuildContext context) {
    final dueAt = task.dueAt == null
        ? null
        : DateTime.tryParse(task.dueAt!)?.toLocal();
    return InkWell(
      borderRadius: BorderRadius.circular(AppRadius.sm),
      onTap: () => context.push('/home/tasks/${task.id}'),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.bgApp,
          borderRadius: BorderRadius.circular(AppRadius.sm),
          border: Border.all(color: AppColors.borderSoft),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    dueAt == null
                        ? task.priority
                        : '${_dateLabel(dueAt)} · ${task.priority}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.manrope(
                      fontSize: 11,
                      color: AppColors.textBody,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
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

// ── Calendar view ─────────────────────────────────────────────────────────────

enum _CalendarMode { today, week, month }

class _TaskCalendarView extends ConsumerStatefulWidget {
  const _TaskCalendarView();

  @override
  ConsumerState<_TaskCalendarView> createState() => _TaskCalendarViewState();
}

class _TaskCalendarViewState extends ConsumerState<_TaskCalendarView> {
  _CalendarMode _mode = _CalendarMode.today;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCalendar());
  }

  Future<void> _loadCalendar() async {
    final range = _rangeForMode(_mode);
    await ref
        .read(taskCalendarProvider.notifier)
        .loadRange(dateFrom: range.$1, dateTo: range.$2);
  }

  (DateTime, DateTime) _rangeForMode(_CalendarMode mode) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    if (mode == _CalendarMode.today) {
      return (today, today);
    }
    if (mode == _CalendarMode.week) {
      final start = today.subtract(Duration(days: today.weekday - 1));
      return (start, start.add(const Duration(days: 6)));
    }
    return (
      DateTime(today.year, today.month),
      DateTime(today.year, today.month + 1, 0),
    );
  }

  Future<void> _setMode(_CalendarMode mode) async {
    setState(() => _mode = mode);
    await _loadCalendar();
  }

  @override
  Widget build(BuildContext context) {
    final calendarState = ref.watch(taskCalendarProvider);
    final focusState = ref.watch(focusProvider);
    final habitsState = ref.watch(habitsProvider);
    final prayerState = ref.watch(prayerProvider);
    final range = _rangeForMode(_mode);
    final days = _daysBetween(range.$1, range.$2);

    return RefreshIndicator(
      onRefresh: () async {
        await _loadCalendar();
        await ref.read(focusProvider.notifier).loadAnalytics();
        await ref.read(habitsProvider.notifier).loadHabits();
        await ref.read(prayerProvider.notifier).loadTodayPrayers();
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          138,
        ),
        children: [
          // Mode selector
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Row(
              children: _CalendarMode.values.map((mode) {
                final active = _mode == mode;
                final label = switch (mode) {
                  _CalendarMode.today => 'Today',
                  _CalendarMode.week => 'Week',
                  _CalendarMode.month => 'Month',
                };
                return Expanded(
                  child: GestureDetector(
                    onTap: () => _setMode(mode),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        gradient: active ? AppGradients.action : null,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: Center(
                        child: Text(
                          label,
                          style: GoogleFonts.manrope(
                            fontSize: 13,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? Colors.white : AppColors.textBody,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            _rangeLabel(range.$1, range.$2),
            style: GoogleFonts.manrope(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (calendarState.isLoading)
            const AppLoadingState(message: 'Loading agenda...')
          else if (calendarState.error != null)
            AppErrorState(
              title: 'Calendar could not load',
              message: calendarState.error!,
              onRetry: _loadCalendar,
            )
          else if (calendarState.tasks.isEmpty &&
              _focusForRange(focusState.sessions, range.$1, range.$2).isEmpty &&
              habitsState.habits.where((habit) => habit.isActive).isEmpty &&
              prayerState.data?.prayers.isEmpty != false)
            const AppEmptyState(
              icon: Icons.calendar_month_outlined,
              title: 'No agenda items',
              message:
                  'Tasks, focus sessions, habits, and prayer anchors will appear here.',
            )
          else
            ...days.map(
              (day) => _AgendaDaySection(
                day: day,
                tasks: calendarState.tasks.where((task) {
                  final dueAt = task.dueAt == null
                      ? null
                      : DateTime.tryParse(task.dueAt!)?.toLocal();
                  return dueAt != null && _sameDay(dueAt, day);
                }).toList(),
                focusSessions: focusState.sessions.where((session) {
                  final startedAt = DateTime.tryParse(
                    session.startedAt,
                  )?.toLocal();
                  return startedAt != null && _sameDay(startedAt, day);
                }).toList(),
                habits: _sameDay(day, DateTime.now())
                    ? habitsState.habits
                          .where((habit) => habit.isActive)
                          .toList()
                    : const [],
                prayers: _sameDay(day, DateTime.now())
                    ? prayerState.data?.prayers ?? const []
                    : const [],
              ),
            ),
        ],
      ),
    );
  }

  List<DateTime> _daysBetween(DateTime start, DateTime end) {
    final days = <DateTime>[];
    var cursor = DateTime(start.year, start.month, start.day);
    final finalDay = DateTime(end.year, end.month, end.day);
    while (!cursor.isAfter(finalDay)) {
      days.add(cursor);
      cursor = cursor.add(const Duration(days: 1));
    }
    return days;
  }

  List<FocusSession> _focusForRange(
    List<FocusSession> sessions,
    DateTime start,
    DateTime end,
  ) {
    return sessions.where((session) {
      final startedAt = DateTime.tryParse(session.startedAt)?.toLocal();
      if (startedAt == null) return false;
      final day = DateTime(startedAt.year, startedAt.month, startedAt.day);
      return !day.isBefore(start) && !day.isAfter(end);
    }).toList();
  }

  String _rangeLabel(DateTime start, DateTime end) {
    if (_sameDay(start, end)) return _dateLabel(start);
    return '${_dateLabel(start)} - ${_dateLabel(end)}';
  }
}

class _AgendaDaySection extends ConsumerWidget {
  final DateTime day;
  final List<TaskModel> tasks;
  final List<FocusSession> focusSessions;
  final List<HabitModel> habits;
  final List<PrayerTime> prayers;

  const _AgendaDaySection({
    required this.day,
    required this.tasks,
    required this.focusSessions,
    required this.habits,
    required this.prayers,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasItems = tasks.isNotEmpty ||
        focusSessions.isNotEmpty ||
        habits.isNotEmpty ||
        prayers.isNotEmpty;
    if (!hasItems) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.s12),
      padding: const EdgeInsets.all(AppSpacing.s16),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _dateLabel(day),
            style: GoogleFonts.manrope(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.textHeading,
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          if (tasks.isNotEmpty)
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: true,
              itemCount: tasks.length,
              onReorder: (oldIndex, newIndex) async {
                final reordered = [...tasks];
                if (newIndex > oldIndex) newIndex -= 1;
                final task = reordered.removeAt(oldIndex);
                reordered.insert(newIndex, task);
                await ref
                    .read(taskCalendarProvider.notifier)
                    .reorderTasks(reordered);
              },
              itemBuilder: (context, index) {
                final task = tasks[index];
                return _AgendaItem(
                  key: ValueKey('agenda-task-${task.id}'),
                  icon: Icons.task_alt,
                  title: task.title,
                  subtitle: task.dueAt == null
                      ? task.priority
                      : '${_timeLabel(task.dueAt!)} · ${task.priority}',
                  color: AppColors.primary,
                );
              },
            ),
          ...focusSessions.map(
            (session) => _AgendaItem(
              icon: Icons.timer_outlined,
              title: 'Focus session',
              subtitle:
                  '${session.actualMinutes ?? session.plannedMinutes} min · ${session.status}',
              color: AppColors.warning,
            ),
          ),
          ...habits.take(6).map(
            (habit) => _AgendaItem(
              icon: Icons.repeat,
              title: habit.title,
              subtitle: '${habit.frequencyType} habit',
              color: AppColors.success,
            ),
          ),
          if (habits.length > 6)
            _AgendaItem(
              icon: Icons.more_horiz,
              title: '${habits.length - 6} more habits',
              subtitle: 'Open Habits to review all',
              color: AppColors.success,
            ),
          ...prayers.map(
            (prayer) => _AgendaItem(
              icon: Icons.mosque_outlined,
              title: _prayerName(prayer.prayerName),
              subtitle: prayer.scheduledAt == null
                  ? 'Prayer anchor'
                  : _timeLabel(prayer.scheduledAt!),
              color: AppColors.prayerGold,
            ),
          ),
        ],
      ),
    );
  }
}

class _AgendaItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const _AgendaItem({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: AppSpacing.s12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textHeading,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    color: AppColors.textBody,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helpers ───────────────────────────────────────────────────────────────────

bool _sameDay(DateTime first, DateTime second) {
  return first.year == second.year &&
      first.month == second.month &&
      first.day == second.day;
}

String _dateLabel(DateTime date) {
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[date.month - 1]} ${date.day}, ${date.year}';
}

String _timeLabel(String iso) {
  final parsed = DateTime.tryParse(iso)?.toLocal();
  if (parsed == null) return 'Time set';
  final hour = parsed.hour.toString().padLeft(2, '0');
  final minute = parsed.minute.toString().padLeft(2, '0');
  return '$hour:$minute';
}

String _prayerName(String name) {
  return switch (name) {
    'fajr' => 'Fajr',
    'dhuhr' => 'Dhuhr',
    'asr' => 'Asr',
    'maghrib' => 'Maghrib',
    'isha' => 'Isha',
    _ => name,
  };
}

const _gtdMoveStatuses = ['pending', 'next', 'waiting', 'someday'];

String _gtdStatusLabel(String status) {
  return switch (status) {
    'next' => 'Next Actions',
    'waiting' => 'Waiting For',
    'someday' => 'Someday',
    _ => 'Inbox',
  };
}

// ── Today view ────────────────────────────────────────────────────────────────

class _TodayView extends ConsumerWidget {
  final List<TaskModel> tasks;

  const _TodayView({required this.tasks});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final pendingToday = tasks.where((t) => t.status != 'completed').toList();
    final completedToday = tasks
        .where((t) {
          if (t.status != 'completed' || t.completedAt == null) return false;
          final ca = DateTime.tryParse(t.completedAt!)?.toLocal();
          return ca != null && _sameDay(ca, today);
        })
        .toList();

    final doneCount = completedToday.length;
    final remainingCount = pendingToday.length;
    final totalCount = doneCount + remainingCount;
    final progress = totalCount > 0 ? doneCount / totalCount : 0.0;

    // Estimate total hours from estimated_minutes
    final totalMinutes = pendingToday.fold<int>(
      0,
      (sum, t) => sum + (t.estimatedMinutes ?? 25),
    );

    // Group pending tasks by time of day
    final morning = <TaskModel>[];
    final afternoon = <TaskModel>[];
    final evening = <TaskModel>[];
    final noTime = <TaskModel>[];

    for (final task in pendingToday) {
      if (task.dueAt == null) {
        noTime.add(task);
        continue;
      }
      final due = DateTime.tryParse(task.dueAt!)?.toLocal();
      if (due == null) { noTime.add(task); continue; }
      final hour = due.hour;
      if (hour < 12) {
        morning.add(task);
      } else if (hour < 17) {
        afternoon.add(task);
      } else {
        evening.add(task);
      }
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(tasksProvider.notifier).loadTasks(),
      color: AppColors.brandPrimary,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, 0, AppSpacing.screenH, 138,
        ),
        children: [
          // Progress card
          Container(
            padding: const EdgeInsets.all(AppSpacing.s16),
            decoration: BoxDecoration(
              color: AppColors.bgSurface,
              borderRadius: BorderRadius.circular(AppRadius.xl),
              border: Border.all(color: AppColors.borderSoft),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brandPrimary.withValues(alpha: 0.05),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Donut ring
                SizedBox(
                  width: 56,
                  height: 56,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: progress,
                        strokeWidth: 5,
                        backgroundColor: AppColors.borderSoft,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          AppColors.brandPrimary,
                        ),
                        strokeCap: StrokeCap.round,
                      ),
                      Text(
                        '$doneCount/$totalCount',
                        style: GoogleFonts.manrope(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textHeading,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: AppSpacing.s12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Today's progress",
                        style: GoogleFonts.manrope(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textHeading,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$doneCount done · $remainingCount remaining'
                        '${totalMinutes > 0 ? ' · ${_formatHours(totalMinutes)}' : ''}',
                        style: GoogleFonts.manrope(
                          fontSize: 12,
                          color: AppColors.textBody,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.bgSurfaceLavender,
                      borderRadius: BorderRadius.circular(AppRadius.pill),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome,
                          size: 12,
                          color: AppColors.brandPrimary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'AI Plan',
                          style: GoogleFonts.manrope(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brandPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s20),

          if (morning.isNotEmpty) ...[
            _TimeGroupHeader(label: 'MORNING'),
            const SizedBox(height: AppSpacing.s8),
            ...morning.map((t) => _TaskCard(task: t)),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (afternoon.isNotEmpty) ...[
            _TimeGroupHeader(label: 'AFTERNOON'),
            const SizedBox(height: AppSpacing.s8),
            ...afternoon.map((t) => _TaskCard(task: t)),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (evening.isNotEmpty) ...[
            _TimeGroupHeader(label: 'EVENING'),
            const SizedBox(height: AppSpacing.s8),
            ...evening.map((t) => _TaskCard(task: t)),
            const SizedBox(height: AppSpacing.s12),
          ],
          if (noTime.isNotEmpty) ...[
            if (morning.isNotEmpty || afternoon.isNotEmpty || evening.isNotEmpty)
              _TimeGroupHeader(label: 'ANYTIME'),
            if (morning.isNotEmpty || afternoon.isNotEmpty || evening.isNotEmpty)
              const SizedBox(height: AppSpacing.s8),
            ...noTime.map((t) => _TaskCard(task: t)),
          ],
          if (pendingToday.isEmpty)
            AppEmptyState(
              icon: Icons.task_alt_outlined,
              title: 'All clear for today',
              message: 'No pending tasks. Add one to start planning.',
              accentColor: AppColors.brandPrimary,
            ),
        ],
      ),
    );
  }

  String _formatHours(int minutes) {
    if (minutes < 60) return '${minutes}m';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _TimeGroupHeader extends StatelessWidget {
  final String label;

  const _TimeGroupHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.manrope(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textHint,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ── Task list ─────────────────────────────────────────────────────────────────

class _TaskList extends ConsumerWidget {
  final List<TaskModel> tasks;
  final String status;

  const _TaskList({required this.tasks, required this.status});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (tasks.isEmpty) {
      final isCompletedTab = status == 'completed';
      return AppEmptyState(
        icon: isCompletedTab
            ? Icons.check_circle_outline
            : Icons.task_alt_outlined,
        title: isCompletedTab ? 'No completed tasks' : 'No tasks yet',
        message: isCompletedTab
            ? 'Completed tasks will appear here after you finish them.'
            : 'Create your first task to start planning the day.',
        accentColor: isCompletedTab ? AppColors.successColor : AppColors.primary,
      );
    }

    if (status != 'completed') {
      return ReorderableListView.builder(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH,
          0,
          AppSpacing.screenH,
          138,
        ),
        itemCount: tasks.length,
        onReorder: (oldIndex, newIndex) {
          final reordered = [...tasks];
          if (newIndex > oldIndex) newIndex -= 1;
          final task = reordered.removeAt(oldIndex);
          reordered.insert(newIndex, task);
          ref.read(tasksProvider.notifier).reorderTasks(reordered);
        },
        itemBuilder: (context, index) {
          final task = tasks[index];
          return _TaskCard(key: ValueKey(task.id), task: task);
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.screenH,
        0,
        AppSpacing.screenH,
        138,
      ),
      itemCount: tasks.length,
      itemBuilder: (context, index) {
        final task = tasks[index];
        return _TaskCard(key: ValueKey(task.id), task: task);
      },
    );
  }
}

// ── Task icon helpers ─────────────────────────────────────────────────────────

IconData _taskIconData(TaskModel task) {
  final cat = (task.category ?? '').toLowerCase();
  if (cat.isEmpty) return Icons.task_alt;
  if (cat.contains('work') || cat.contains('job') || cat.contains('office')) {
    return Icons.bar_chart;
  }
  if (cat.contains('meeting') || cat.contains('call') || cat.contains('phone')) {
    return Icons.phone_outlined;
  }
  if (cat.contains('read') || cat.contains('study') || cat.contains('book') ||
      cat.contains('learn')) {
    return Icons.menu_book_outlined;
  }
  if (cat.contains('shop') || cat.contains('errand') || cat.contains('buy') ||
      cat.contains('grocery')) {
    return Icons.shopping_cart_outlined;
  }
  if (cat.contains('code') || cat.contains('dev') || cat.contains('tech') ||
      cat.contains('programming')) {
    return Icons.terminal_outlined;
  }
  if (cat.contains('health') || cat.contains('gym') || cat.contains('exercise') ||
      cat.contains('fitness')) {
    return Icons.fitness_center_outlined;
  }
  if (cat.contains('focus') || cat.contains('deep')) {
    return Icons.psychology_outlined;
  }
  if (cat.contains('prayer') || cat.contains('spiritual')) {
    return Icons.mosque_outlined;
  }
  if (cat.contains('family') || cat.contains('home')) {
    return Icons.home_outlined;
  }
  if (cat.contains('travel') || cat.contains('trip')) {
    return Icons.flight_outlined;
  }
  // icon: prefix used by icon picker
  if (cat.startsWith('icon:')) {
    return _iconFromKey(cat.substring(5));
  }
  return Icons.task_alt;
}

Color _taskIconColor(TaskModel task) {
  final cat = (task.category ?? '').toLowerCase();
  if (cat.contains('work') || cat.contains('job')) return AppColors.brandPink;
  if (cat.contains('meeting') || cat.contains('call')) return AppColors.infoColor;
  if (cat.contains('read') || cat.contains('study') || cat.contains('book')) {
    return AppColors.brandPrimary;
  }
  if (cat.contains('shop') || cat.contains('errand')) return AppColors.brandGold;
  if (cat.contains('code') || cat.contains('dev')) return AppColors.brandViolet;
  if (cat.contains('health') || cat.contains('gym')) return AppColors.successColor;
  if (cat.contains('focus')) return AppColors.brandPrimary;
  if (cat.contains('prayer')) return AppColors.brandViolet;
  if (cat.startsWith('icon:')) return AppColors.brandPrimary;
  return AppColors.textBody;
}

IconData _iconFromKey(String key) {
  return switch (key) {
    'task'     => Icons.task_alt,
    'work'     => Icons.bar_chart,
    'meeting'  => Icons.phone_outlined,
    'study'    => Icons.menu_book_outlined,
    'shopping' => Icons.shopping_cart_outlined,
    'code'     => Icons.terminal_outlined,
    'health'   => Icons.fitness_center_outlined,
    'home'     => Icons.home_outlined,
    'travel'   => Icons.flight_outlined,
    'finance'  => Icons.account_balance_outlined,
    'creative' => Icons.palette_outlined,
    'food'     => Icons.restaurant_outlined,
    'music'    => Icons.music_note_outlined,
    'sport'    => Icons.sports_outlined,
    'prayer'   => Icons.mosque_outlined,
    'idea'     => Icons.lightbulb_outline,
    'writing'  => Icons.edit_outlined,
    'email'    => Icons.email_outlined,
    'video'    => Icons.videocam_outlined,
    'data'     => Icons.analytics_outlined,
    _          => Icons.task_alt,
  };
}

// ── Task card ─────────────────────────────────────────────────────────────────

class _TaskCard extends ConsumerWidget {
  final TaskModel task;

  const _TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pColor = _priorityColor(task.priority);
    final isCompleted = task.status == 'completed';
    final iconData = _taskIconData(task);
    final iconColor = _taskIconColor(task);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.listGap),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: [
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.xl),
        onTap: () => context.push('/home/tasks/${task.id}'),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.s16,
            vertical: AppSpacing.s12,
          ),
          child: Row(
            children: [
              // Check circle
              GestureDetector(
                onTap: () {
                  if (!isCompleted) {
                    HapticFeedback.lightImpact();
                    ref.read(tasksProvider.notifier).completeTask(task.id);
                  }
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppColors.brandViolet
                        : Colors.transparent,
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.brandViolet
                          : AppColors.borderSoft,
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check, size: 14, color: Colors.white)
                      : null,
                ),
              ),
              const SizedBox(width: 10.0),

              // Task icon badge
              Container(
                width: 32,
                height: 32,
                alignment: Alignment.center,
                clipBehavior: Clip.antiAlias,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                ),
                child: Icon(iconData, size: 17, color: iconColor),
              ),
              const SizedBox(width: 10.0),

              // Title + metadata
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      task.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.manrope(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isCompleted
                            ? AppColors.textBody
                            : AppColors.textHeading,
                        decoration: isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        if (task.category != null &&
                            !task.category!.startsWith('icon:'))
                          Text(
                            task.category!,
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textBody,
                            ),
                          ),
                        if (task.category != null &&
                            !task.category!.startsWith('icon:') &&
                            task.dueAt != null)
                          Text(
                            ' · ',
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textHint,
                            ),
                          ),
                        if (task.dueAt != null)
                          Text(
                            _shortDueLabel(task.dueAt!),
                            style: GoogleFonts.manrope(
                              fontSize: 11,
                              color: AppColors.textBody,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),

              // Priority badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 9,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: pColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  task.priority == 'high'
                      ? 'High'
                      : task.priority == 'medium'
                      ? 'Med'
                      : 'Low',
                  style: GoogleFonts.manrope(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: pColor,
                  ),
                ),
              ),

              // Move menu
              if (!isCompleted)
                PopupMenuButton<String>(
                  tooltip: 'Move task',
                  icon: Icon(
                    Icons.more_vert,
                    size: 18,
                    color: AppColors.textHint,
                  ),
                  onSelected: (status) => ref
                      .read(tasksProvider.notifier)
                      .moveTaskToStatus(task: task, status: status),
                  itemBuilder: (context) => _gtdMoveStatuses
                      .where((s) => s != task.status)
                      .map(
                        (s) => PopupMenuItem(
                          value: s,
                          child: Text('Move to ${_gtdStatusLabel(s)}'),
                        ),
                      )
                      .toList(),
                ),

              // Delete
              GestureDetector(
                onTap: () async {
                  final confirmed = await confirmDestructiveAction(
                    context: context,
                    title: 'Delete Task',
                    message:
                        'Delete "${task.title}"? This task will be removed from your active list.',
                  );
                  if (!confirmed) return;
                  await ref.read(tasksProvider.notifier).deleteTask(task.id);
                },
                child: Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Icon(
                    Icons.delete_outline,
                    size: 18,
                    color: AppColors.textHint,
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

String _shortDueLabel(String iso) {
  final d = DateTime.tryParse(iso)?.toLocal();
  if (d == null) return '';
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final due = DateTime(d.year, d.month, d.day);
  final diff = due.difference(today).inDays;
  if (diff == 0) return 'Today · ${_timeLabel(iso)}';
  if (diff == 1) return 'Tomorrow';
  if (diff == -1) return 'Yesterday';
  if (diff < 0) return 'Overdue';
  const months = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
  return '${months[d.month - 1]} ${d.day}';
}
