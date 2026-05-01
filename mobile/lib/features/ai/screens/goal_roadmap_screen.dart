import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/goal_roadmap_model.dart';
import '../providers/goal_roadmap_provider.dart';

class GoalRoadmapScreen extends ConsumerStatefulWidget {
  const GoalRoadmapScreen({super.key});

  @override
  ConsumerState<GoalRoadmapScreen> createState() => _GoalRoadmapScreenState();
}

class _GoalRoadmapScreenState extends ConsumerState<GoalRoadmapScreen> {
  final _formKey = GlobalKey<FormState>();
  final _goalController = TextEditingController();
  final _levelController = TextEditingController(text: 'beginner');
  final _weeklyHoursController = TextEditingController(text: '5');
  final _constraintsController = TextEditingController();
  final _deadlineController = TextEditingController();
  final _titleControllers = <int, TextEditingController>{};
  final _descriptionControllers = <int, TextEditingController>{};
  final _selectedTaskIndexes = <int>{};
  GoalRoadmapResult? _preparedResult;

  @override
  void dispose() {
    _goalController.dispose();
    _levelController.dispose();
    _weeklyHoursController.dispose();
    _constraintsController.dispose();
    _deadlineController.dispose();
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(goalRoadmapProvider.notifier)
        .generate(
          goalTitle: _goalController.text.trim(),
          deadline: _deadlineController.text.trim().isEmpty
              ? null
              : _deadlineController.text.trim(),
          currentLevel: _levelController.text.trim(),
          weeklyAvailableHours:
              int.tryParse(_weeklyHoursController.text.trim()) ?? 5,
          constraints: _constraintsController.text.trim().isEmpty
              ? null
              : _constraintsController.text.trim(),
        );
  }

  Future<void> _confirm(GoalRoadmapResult result) async {
    final editedTasks = <GoalRoadmapTask>[];
    for (final index in _selectedTaskIndexes) {
      final task = result.suggestedTasks[index];
      editedTasks.add(
        task.copyWith(
          title: _titleControllers[index]?.text.trim(),
          description: _descriptionControllers[index]?.text.trim(),
        ),
      );
    }
    final ok = await ref
        .read(goalRoadmapProvider.notifier)
        .confirm(
          projectTitle: result.goalTitle,
          tasks: editedTasks.where((task) => task.title.isNotEmpty).toList(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Roadmap project and tasks created.'
              : ref.read(goalRoadmapProvider).error ??
                    'Roadmap could not be created.',
        ),
      ),
    );
  }

  void _preparePreview(GoalRoadmapResult result) {
    if (identical(_preparedResult, result)) return;
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    for (final controller in _descriptionControllers.values) {
      controller.dispose();
    }
    _titleControllers.clear();
    _descriptionControllers.clear();
    _selectedTaskIndexes.clear();
    for (var i = 0; i < result.suggestedTasks.length; i++) {
      final task = result.suggestedTasks[i];
      _titleControllers[i] = TextEditingController(text: task.title);
      _descriptionControllers[i] = TextEditingController(
        text: task.description,
      );
      _selectedTaskIndexes.add(i);
    }
    _preparedResult = result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(goalRoadmapProvider);
    final result = state.result;
    if (result != null) _preparePreview(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Goal Roadmap',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _SafetyCard(error: state.error),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _goalController,
                  decoration: const InputDecoration(labelText: 'Goal title'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Goal title is required'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _deadlineController,
                  decoration: const InputDecoration(
                    labelText: 'Deadline',
                    hintText: 'YYYY-MM-DD (optional)',
                  ),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _levelController,
                  decoration: const InputDecoration(labelText: 'Current level'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _weeklyHoursController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Weekly available hours',
                  ),
                  validator: (value) {
                    final hours = int.tryParse(value ?? '');
                    if (hours == null || hours < 1 || hours > 40) {
                      return 'Enter 1 to 40 hours';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _constraintsController,
                  maxLines: 2,
                  decoration: const InputDecoration(
                    labelText: 'Constraints',
                    hintText: 'Optional schedule, budget, or time limits',
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isGenerating ? null : _generate,
                    icon: state.isGenerating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_awesome_outlined),
                    label: const Text('Generate editable roadmap'),
                  ),
                ),
              ],
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            _RoadmapPreview(
              result: result,
              titleControllers: _titleControllers,
              descriptionControllers: _descriptionControllers,
              selectedTaskIndexes: _selectedTaskIndexes,
              onSelectionChanged: () => setState(() {}),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isConfirming ? null : () => _confirm(result),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Create selected tasks'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SafetyCard extends StatelessWidget {
  final String? error;

  const _SafetyCard({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview before create',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            'Generated roadmap items stay editable. Nothing is saved until you confirm selected tasks.',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (error != null) ...[
            const SizedBox(height: 8),
            Text(error!, style: const TextStyle(color: AppColors.error)),
          ],
        ],
      ),
    );
  }
}

class _RoadmapPreview extends StatelessWidget {
  final GoalRoadmapResult result;
  final Map<int, TextEditingController> titleControllers;
  final Map<int, TextEditingController> descriptionControllers;
  final Set<int> selectedTaskIndexes;
  final VoidCallback onSelectionChanged;

  const _RoadmapPreview({
    required this.result,
    required this.titleControllers,
    required this.descriptionControllers,
    required this.selectedTaskIndexes,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Roadmap Preview',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(result.scheduleSuggestion),
        const SizedBox(height: 12),
        ...result.milestones.map(
          (milestone) => _MilestoneCard(milestone: milestone),
        ),
        const SizedBox(height: 12),
        Text(
          'Editable tasks',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        for (var i = 0; i < result.suggestedTasks.length; i++)
          _EditableTaskCard(
            selected: selectedTaskIndexes.contains(i),
            titleController: titleControllers[i]!,
            descriptionController: descriptionControllers[i]!,
            onChanged: (selected) {
              if (selected) {
                selectedTaskIndexes.add(i);
              } else {
                selectedTaskIndexes.remove(i);
              }
              onSelectionChanged();
            },
          ),
      ],
    );
  }
}

class _MilestoneCard extends StatelessWidget {
  final GoalRoadmapMilestone milestone;

  const _MilestoneCard({required this.milestone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.flag_outlined, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Week ${milestone.targetWeek}: ${milestone.title}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(milestone.description),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EditableTaskCard extends StatelessWidget {
  final bool selected;
  final TextEditingController titleController;
  final TextEditingController descriptionController;
  final ValueChanged<bool> onChanged;

  const _EditableTaskCard({
    required this.selected,
    required this.titleController,
    required this.descriptionController,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SwitchListTile(
            value: selected,
            onChanged: onChanged,
            title: const Text('Create this task'),
            contentPadding: EdgeInsets.zero,
          ),
          TextField(
            controller: titleController,
            decoration: const InputDecoration(labelText: 'Task title'),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: descriptionController,
            maxLines: 2,
            decoration: const InputDecoration(labelText: 'Task description'),
          ),
        ],
      ),
    );
  }
}
