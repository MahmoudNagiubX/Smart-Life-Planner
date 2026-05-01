import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../models/study_plan_model.dart';
import '../providers/study_plan_provider.dart';

class StudyPlannerScreen extends ConsumerStatefulWidget {
  const StudyPlannerScreen({super.key});

  @override
  ConsumerState<StudyPlannerScreen> createState() => _StudyPlannerScreenState();
}

class _StudyPlannerScreenState extends ConsumerState<StudyPlannerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _examDateController = TextEditingController();
  final _topicsController = TextEditingController();
  final _minutesController = TextEditingController(text: '90');
  String _difficulty = 'medium';
  final _selected = <int>{};
  final _titleControllers = <int, TextEditingController>{};
  StudyPlanResult? _prepared;

  @override
  void dispose() {
    _subjectController.dispose();
    _examDateController.dispose();
    _topicsController.dispose();
    _minutesController.dispose();
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _generate() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(studyPlanProvider.notifier)
        .generate(
          subject: _subjectController.text.trim(),
          examDate: _examDateController.text.trim(),
          topics: _topicsController.text
              .split(',')
              .map((topic) => topic.trim())
              .where((topic) => topic.isNotEmpty)
              .toList(),
          difficulty: _difficulty,
          availableDailyStudyMinutes:
              int.tryParse(_minutesController.text.trim()) ?? 90,
        );
  }

  Future<void> _confirm(StudyPlanResult result) async {
    final selectedDays = <StudyPlanDay>[];
    for (final index in _selected) {
      selectedDays.add(
        result.dailyPlan[index].copyWith(
          title: _titleControllers[index]?.text.trim(),
        ),
      );
    }
    final ok = await ref
        .read(studyPlanProvider.notifier)
        .confirm(
          subject: result.subject,
          selectedDays: selectedDays
              .where((day) => day.title.isNotEmpty)
              .toList(),
        );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Study project and tasks created.'
              : ref.read(studyPlanProvider).error ??
                    'Study tasks could not be created.',
        ),
      ),
    );
  }

  void _prepare(StudyPlanResult result) {
    if (identical(_prepared, result)) return;
    for (final controller in _titleControllers.values) {
      controller.dispose();
    }
    _titleControllers.clear();
    _selected.clear();
    for (var i = 0; i < result.dailyPlan.length; i++) {
      _titleControllers[i] = TextEditingController(
        text: result.dailyPlan[i].title,
      );
      _selected.add(i);
    }
    _prepared = result;
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(studyPlanProvider);
    final result = state.result;
    if (result != null) _prepare(result);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Study Planner AI',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _Intro(error: state.error),
          const SizedBox(height: 16),
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _subjectController,
                  decoration: const InputDecoration(labelText: 'Subject'),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _examDateController,
                  decoration: const InputDecoration(
                    labelText: 'Exam date',
                    hintText: 'YYYY-MM-DD',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _topicsController,
                  decoration: const InputDecoration(
                    labelText: 'Topics',
                    hintText: 'Mechanics, Waves, Circuits',
                  ),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: _difficulty,
                  decoration: const InputDecoration(labelText: 'Difficulty'),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (value) =>
                      setState(() => _difficulty = value ?? 'medium'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minutesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Daily study minutes',
                  ),
                  validator: (value) {
                    final minutes = int.tryParse(value ?? '');
                    if (minutes == null || minutes < 15 || minutes > 720) {
                      return 'Enter 15 to 720 minutes';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: state.isGenerating ? null : _generate,
                    icon: const Icon(Icons.school_outlined),
                    label: const Text('Generate editable study plan'),
                  ),
                ),
              ],
            ),
          ),
          if (result != null) ...[
            const SizedBox(height: 20),
            if (result.overloadWarning)
              const _WarningCard(
                text: 'This plan may be heavy for the available daily time.',
              ),
            Text(
              'Editable study tasks',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (var i = 0; i < result.dailyPlan.length; i++)
              _StudyDayCard(
                day: result.dailyPlan[i],
                controller: _titleControllers[i]!,
                selected: _selected.contains(i),
                onChanged: (selected) {
                  setState(() {
                    if (selected) {
                      _selected.add(i);
                    } else {
                      _selected.remove(i);
                    }
                  });
                },
              ),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: state.isConfirming ? null : () => _confirm(result),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('Create selected study tasks'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  final String? error;

  const _Intro({this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        error ??
            'Generate an editable study plan. No tasks are created until you confirm.',
      ),
    );
  }
}

class _WarningCard extends StatelessWidget {
  final String text;

  const _WarningCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text),
    );
  }
}

class _StudyDayCard extends StatelessWidget {
  final StudyPlanDay day;
  final TextEditingController controller;
  final bool selected;
  final ValueChanged<bool> onChanged;

  const _StudyDayCard({
    required this.day,
    required this.controller,
    required this.selected,
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
            title: Text(day.date),
            subtitle: Text('${day.topic} - ${day.totalMinutes} min'),
            contentPadding: EdgeInsets.zero,
          ),
          TextField(
            controller: controller,
            decoration: const InputDecoration(labelText: 'Task title'),
          ),
        ],
      ),
    );
  }
}
