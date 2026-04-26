import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_routes.dart';
import '../models/onboarding_data.dart';
import '../providers/onboarding_provider.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  static const _totalSteps = 10;

  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _isSubmitting = false;

  static const _prayerMethods = [
    _Choice('MWL', 'Muslim World League'),
    _Choice('Egypt', 'Egyptian General Authority'),
    _Choice('Makkah', 'Umm al-Qura, Makkah'),
    _Choice('ISNA', 'Islamic Society of North America'),
    _Choice('Karachi', 'University of Islamic Sciences'),
  ];

  static const _goals = [
    _Choice('study', 'Study'),
    _Choice('work', 'Work'),
    _Choice('self_improvement', 'Self Improvement'),
    _Choice('fitness', 'Fitness'),
    _Choice('spiritual_growth', 'Spiritual Growth'),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _goToPage(int page) async {
    FocusScope.of(context).unfocus();
    await _pageController.animateToPage(
      page,
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOutCubic,
    );
  }

  Future<void> _next() async {
    if (_currentPage < _totalSteps - 1) {
      await _goToPage(_currentPage + 1);
      return;
    }
    await _submit();
  }

  Future<void> _back() async {
    if (_currentPage > 0) {
      await _goToPage(_currentPage - 1);
    }
  }

  Future<void> _submit() async {
    setState(() => _isSubmitting = true);
    final success = await ref
        .read(onboardingProvider.notifier)
        .submitOnboarding();

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      context.go(AppRoutes.home);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Could not save onboarding. Please try again.'),
        backgroundColor: AppColors.error,
      ),
    );
  }

  Future<void> _pickTime({
    required OnboardingData data,
    required bool isWakeTime,
  }) async {
    final fallback = isWakeTime
        ? const TimeOfDay(hour: 6, minute: 0)
        : const TimeOfDay(hour: 22, minute: 0);
    final picked = await showTimePicker(
      context: context,
      initialTime:
          _parseTime(isWakeTime ? data.wakeTime : data.sleepTime) ?? fallback,
    );

    if (picked == null) return;
    final formatted = _formatTime(picked);
    final notifier = ref.read(onboardingProvider.notifier);
    notifier.updateData(
      isWakeTime
          ? data.copyWith(wakeTime: formatted)
          : data.copyWith(sleepTime: formatted),
    );
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null) return null;
    final parts = value.split(':');
    if (parts.length != 2) return null;
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;
    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay value) {
    return '${value.hour.toString().padLeft(2, '0')}:'
        '${value.minute.toString().padLeft(2, '0')}';
  }

  Future<bool> _requestPermission(Permission permission) async {
    final status = await permission.request();
    return status.isGranted || status.isLimited;
  }

  @override
  Widget build(BuildContext context) {
    final data = ref.watch(onboardingProvider);
    final notifier = ref.read(onboardingProvider.notifier);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            _ProgressHeader(
              currentStep: _currentPage + 1,
              totalSteps: _totalSteps,
            ),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _StepScaffold(
                    title: 'Preferred Language',
                    subtitle: 'Choose the language you want to start with.',
                    child: Column(
                      children: [
                        _ChoiceTile(
                          icon: Icons.language,
                          title: 'English',
                          subtitle: 'Use English across the app',
                          selected: data.language == 'en',
                          onTap: () => notifier.updateData(
                            data.copyWith(language: 'en'),
                          ),
                        ),
                        _ChoiceTile(
                          icon: Icons.translate,
                          title: 'Arabic',
                          subtitle: 'Use Arabic across the app',
                          selected: data.language == 'ar',
                          onTap: () => notifier.updateData(
                            data.copyWith(language: 'ar'),
                          ),
                        ),
                      ],
                    ),
                  ),
                  _LocationStep(data: data, notifier: notifier),
                  _ChoiceStep(
                    title: 'Prayer Calculation Method',
                    subtitle: 'Pick the method closest to your local standard.',
                    choices: _prayerMethods,
                    selectedValue: data.prayerCalculationMethod,
                    icon: Icons.mosque_outlined,
                    onSelected: (value) => notifier.updateData(
                      data.copyWith(prayerCalculationMethod: value),
                    ),
                  ),
                  _GoalsStep(
                    data: data,
                    goals: _goals,
                    onChanged: (goals) =>
                        notifier.updateData(data.copyWith(goals: goals)),
                  ),
                  _TimeStep(
                    title: 'Preferred Wake-up Time',
                    subtitle: 'This helps Smart Life Planner shape your day.',
                    icon: Icons.wb_sunny_outlined,
                    value: data.wakeTime,
                    fallbackLabel: 'Choose wake-up time',
                    onTap: () => _pickTime(data: data, isWakeTime: true),
                  ),
                  _TimeStep(
                    title: 'Preferred Sleep Time',
                    subtitle: 'Used for reminders and daily planning rhythm.',
                    icon: Icons.nightlight_outlined,
                    value: data.sleepTime,
                    fallbackLabel: 'Choose sleep time',
                    onTap: () => _pickTime(data: data, isWakeTime: false),
                  ),
                  _PermissionStep(
                    title: 'Notification Permission',
                    subtitle:
                        'Enable reminders for tasks, habits, and prayers.',
                    icon: Icons.notifications_outlined,
                    enabled: data.notificationsEnabled,
                    onAllow: () async {
                      final granted = await _requestPermission(
                        Permission.notification,
                      );
                      notifier.updateData(
                        data.copyWith(notificationsEnabled: granted),
                      );
                    },
                    onSkip: () => notifier.updateData(
                      data.copyWith(notificationsEnabled: false),
                    ),
                  ),
                  _PermissionStep(
                    title: 'Microphone Permission',
                    subtitle:
                        'Use voice capture when you want hands-free input.',
                    icon: Icons.mic_none_outlined,
                    enabled: data.microphoneEnabled,
                    onAllow: () async {
                      final granted = await _requestPermission(
                        Permission.microphone,
                      );
                      notifier.updateData(
                        data.copyWith(microphoneEnabled: granted),
                      );
                    },
                    onSkip: () => notifier.updateData(
                      data.copyWith(microphoneEnabled: false),
                    ),
                  ),
                  _PermissionStep(
                    title: 'Location Permission',
                    subtitle:
                        'Improve prayer times and location-aware features.',
                    icon: Icons.location_on_outlined,
                    enabled: data.locationEnabled,
                    onAllow: () async {
                      final granted = await _requestPermission(
                        Permission.locationWhenInUse,
                      );
                      notifier.updateData(
                        data.copyWith(locationEnabled: granted),
                      );
                    },
                    onSkip: () => notifier.updateData(
                      data.copyWith(locationEnabled: false),
                    ),
                  ),
                  _SummaryStep(data: data),
                ],
              ),
            ),
            _BottomControls(
              isFirstStep: _currentPage == 0,
              isLastStep: _currentPage == _totalSteps - 1,
              isLoading: _isSubmitting,
              onBack: _back,
              onNext: _next,
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationStep extends StatefulWidget {
  final OnboardingData data;
  final OnboardingNotifier notifier;

  const _LocationStep({required this.data, required this.notifier});

  @override
  State<_LocationStep> createState() => _LocationStepState();
}

class _LocationStepState extends State<_LocationStep> {
  late final TextEditingController _countryController;
  late final TextEditingController _cityController;

  @override
  void initState() {
    super.initState();
    _countryController = TextEditingController(text: widget.data.country ?? '');
    _cityController = TextEditingController(text: widget.data.city ?? '');
  }

  @override
  void didUpdateWidget(covariant _LocationStep oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data.country != oldWidget.data.country &&
        widget.data.country != _countryController.text) {
      _countryController.text = widget.data.country ?? '';
    }
    if (widget.data.city != oldWidget.data.city &&
        widget.data.city != _cityController.text) {
      _cityController.text = widget.data.city ?? '';
    }
  }

  @override
  void dispose() {
    _countryController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Country or City',
      subtitle: 'Set a manual location now. Device location is optional later.',
      child: Column(
        children: [
          TextField(
            controller: _countryController,
            textInputAction: TextInputAction.next,
            decoration: const InputDecoration(
              labelText: 'Country',
              prefixIcon: Icon(Icons.public_outlined),
            ),
            onChanged: (value) => widget.notifier.updateData(
              widget.data.copyWith(country: value),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _cityController,
            textInputAction: TextInputAction.done,
            decoration: const InputDecoration(
              labelText: 'City',
              prefixIcon: Icon(Icons.location_city_outlined),
            ),
            onChanged: (value) =>
                widget.notifier.updateData(widget.data.copyWith(city: value)),
          ),
        ],
      ),
    );
  }
}

class _ChoiceStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final List<_Choice> choices;
  final String selectedValue;
  final IconData icon;
  final ValueChanged<String> onSelected;

  const _ChoiceStep({
    required this.title,
    required this.subtitle,
    required this.choices,
    required this.selectedValue,
    required this.icon,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: title,
      subtitle: subtitle,
      child: Column(
        children: choices
            .map(
              (choice) => _ChoiceTile(
                icon: icon,
                title: choice.label,
                subtitle: choice.value,
                selected: selectedValue == choice.value,
                onTap: () => onSelected(choice.value),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _GoalsStep extends StatelessWidget {
  final OnboardingData data;
  final List<_Choice> goals;
  final ValueChanged<List<String>> onChanged;

  const _GoalsStep({
    required this.data,
    required this.goals,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Main Goals',
      subtitle: 'Choose what you want the app to help with first.',
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: goals.map((goal) {
          final selected = data.goals.contains(goal.value);
          return FilterChip(
            selected: selected,
            label: Text(goal.label),
            avatar: Icon(
              selected ? Icons.check_circle : Icons.add_circle_outline,
              color: selected ? AppColors.primary : AppColors.textSecondary,
              size: 18,
            ),
            onSelected: (value) {
              final next = [...data.goals];
              if (value && !next.contains(goal.value)) {
                next.add(goal.value);
              } else {
                next.remove(goal.value);
              }
              onChanged(next);
            },
          );
        }).toList(),
      ),
    );
  }
}

class _TimeStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final String? value;
  final String fallbackLabel;
  final VoidCallback onTap;

  const _TimeStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.fallbackLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: title,
      subtitle: subtitle,
      child: _ChoiceTile(
        icon: icon,
        title: value ?? fallbackLabel,
        subtitle: value == null ? 'Tap to set a time' : '24-hour format',
        selected: value != null,
        onTap: onTap,
      ),
    );
  }
}

class _PermissionStep extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool enabled;
  final Future<void> Function() onAllow;
  final VoidCallback onSkip;

  const _PermissionStep({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.enabled,
    required this.onAllow,
    required this.onSkip,
  });

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: title,
      subtitle: subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _ChoiceTile(
            icon: icon,
            title: enabled ? 'Allowed' : 'Not enabled yet',
            subtitle: enabled
                ? 'This permission is enabled.'
                : 'You can allow it now or skip it.',
            selected: enabled,
            onTap: onAllow,
          ),
          const SizedBox(height: 16),
          OutlinedButton(onPressed: onSkip, child: const Text('Skip for now')),
        ],
      ),
    );
  }
}

class _SummaryStep extends StatelessWidget {
  final OnboardingData data;

  const _SummaryStep({required this.data});

  @override
  Widget build(BuildContext context) {
    return _StepScaffold(
      title: 'Onboarding Summary',
      subtitle: 'Review your setup before entering the app.',
      child: Column(
        children: [
          _SummaryRow('Language', data.language == 'ar' ? 'Arabic' : 'English'),
          _SummaryRow(
            'Location',
            [data.city, data.country]
                .where((value) => value != null && value.isNotEmpty)
                .join(', ')
                .ifEmpty('Not set'),
          ),
          _SummaryRow('Prayer Method', data.prayerCalculationMethod),
          _SummaryRow(
            'Goals',
            data.goals.isEmpty
                ? 'Not set'
                : data.goals.map(_goalLabel).join(', '),
          ),
          _SummaryRow('Wake-up', data.wakeTime ?? 'Not set'),
          _SummaryRow('Sleep', data.sleepTime ?? 'Not set'),
          _SummaryRow(
            'Permissions',
            [
              if (data.notificationsEnabled) 'Notifications',
              if (data.microphoneEnabled) 'Microphone',
              if (data.locationEnabled) 'Location',
            ].join(', ').ifEmpty('Skipped for now'),
          ),
          const SizedBox(height: 18),
          _AiRecommendationPreview(data: data),
        ],
      ),
    );
  }

  static String _goalLabel(String value) {
    return _OnboardingScreenState._goals
        .firstWhere(
          (goal) => goal.value == value,
          orElse: () => _Choice(value, value),
        )
        .label;
  }
}

class _AiRecommendationPreview extends StatelessWidget {
  final OnboardingData data;

  const _AiRecommendationPreview({required this.data});

  String _previewText() {
    final rhythm = [
      if (data.wakeTime != null) 'start after ${data.wakeTime}',
      if (data.sleepTime != null) 'wind down before ${data.sleepTime}',
    ].join(', ');
    final rhythmText = rhythm.isEmpty ? 'your daily rhythm' : rhythm;

    if (data.goals.contains('study') &&
        data.goals.contains('spiritual_growth')) {
      return 'Your first AI plans will protect study blocks around prayer anchors and $rhythmText.';
    }
    if (data.goals.contains('study')) {
      return 'Your first AI plans will prioritize focused study blocks and $rhythmText.';
    }
    if (data.goals.contains('work')) {
      return 'Your first AI plans will prioritize deep work and $rhythmText.';
    }
    if (data.goals.contains('fitness')) {
      return 'Your first AI plans will balance energy, movement, and $rhythmText.';
    }
    if (data.goals.contains('spiritual_growth')) {
      return 'Your first AI plans will keep prayer and Quran habits visible around $rhythmText.';
    }
    return 'Your first AI plans will use $rhythmText and adjust as you add tasks and habits.';
  }

  @override
  Widget build(BuildContext context) {
    final labels = data.goals.map(_SummaryStep._goalLabel).toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.auto_awesome, color: AppColors.primary),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'AI recommendation preview',
                  style: TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(_previewText(), style: Theme.of(context).textTheme.bodyMedium),
          if (labels.isNotEmpty) ...[
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels
                  .map(
                    (label) => Chip(
                      label: Text(label),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            'Stored seed: goal tags and daily rhythm only.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _ProgressHeader extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const _ProgressHeader({required this.currentStep, required this.totalSteps});

  @override
  Widget build(BuildContext context) {
    final progress = currentStep / totalSteps;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step $currentStep of $totalSteps',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 6,
              backgroundColor: AppColors.textSecondary.withValues(alpha: 0.18),
              valueColor: const AlwaysStoppedAnimation<Color>(
                AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StepScaffold extends StatelessWidget {
  final String title;
  final String subtitle;
  final Widget child;

  const _StepScaffold({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 28),
          child,
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderColor = selected
        ? AppColors.primary
        : AppColors.textSecondary.withValues(alpha: 0.22);
    final backgroundColor = selected
        ? AppColors.primary.withValues(alpha: 0.12)
        : Theme.of(context).cardTheme.color;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: borderColor),
          ),
          child: Row(
            children: [
              Icon(icon, color: selected ? AppColors.primary : null),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle, color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;

  const _SummaryRow(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _BottomControls extends StatelessWidget {
  final bool isFirstStep;
  final bool isLastStep;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _BottomControls({
    required this.isFirstStep,
    required this.isLastStep,
    required this.isLoading,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          if (!isFirstStep)
            TextButton(
              onPressed: isLoading ? null : onBack,
              child: const Text('Back'),
            )
          else
            const SizedBox(width: 72),
          const Spacer(),
          SizedBox(
            width: isLastStep ? 180 : 120,
            height: 52,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(0, 52),
                padding: const EdgeInsets.symmetric(horizontal: 16),
              ),
              onPressed: isLoading ? null : onNext,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Text(
                      isLastStep ? 'Start Using App' : 'Next',
                      textAlign: TextAlign.center,
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Choice {
  final String value;
  final String label;

  const _Choice(this.value, this.label);
}

extension _EmptyStringFallback on String {
  String ifEmpty(String fallback) => isEmpty ? fallback : this;
}
