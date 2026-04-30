import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../providers/focus_provider.dart';

class FocusSettingsScreen extends ConsumerWidget {
  const FocusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Focus Settings')),
      body: RefreshIndicator(
        onRefresh: notifier.loadSettings,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsSection(
              title: 'Session timing',
              children: [
                _DurationSlider(
                  label: 'Focus duration',
                  value: state.focusMinutes,
                  min: 5,
                  max: 120,
                  divisions: 23,
                  onChanged: notifier.setFocusMinutes,
                ),
                _DurationSlider(
                  label: 'Short break',
                  value: state.shortBreakMinutes,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  onChanged: notifier.setShortBreakMinutes,
                ),
                _DurationSlider(
                  label: 'Long break',
                  value: state.longBreakMinutes,
                  min: 5,
                  max: 60,
                  divisions: 11,
                  onChanged: notifier.setLongBreakMinutes,
                ),
                _DurationSlider(
                  label: 'Sessions before long break',
                  value: state.sessionsBeforeLongBreak,
                  min: 1,
                  max: 12,
                  divisions: 11,
                  suffix: 'sessions',
                  onChanged: notifier.setSessionsBeforeLongBreak,
                ),
              ],
            ),
            const SizedBox(height: 16),
            _SettingsSection(
              title: 'Session behavior',
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.continuousMode,
                  onChanged: notifier.setContinuousMode,
                  title: const Text('Continuous mode'),
                  subtitle: const Text('Auto-start the next focus or break.'),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  value: state.distractionFreeMode,
                  onChanged: notifier.setDistractionFreeMode,
                  title: const Text('Distraction-free mode'),
                  subtitle: const Text('Hide secondary panels while focusing.'),
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  initialValue: state.ambientSoundKey,
                  decoration: const InputDecoration(
                    labelText: 'Ambient sound',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'silence', child: Text('Silence')),
                    DropdownMenuItem(value: 'rain', child: Text('Rain')),
                    DropdownMenuItem(value: 'cafe', child: Text('Cafe')),
                    DropdownMenuItem(
                      value: 'white_noise',
                      child: Text('White noise'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value != null) notifier.setAmbientSoundKey(value);
                  },
                ),
              ],
            ),
            if (state.error != null) ...[
              const SizedBox(height: 16),
              Text(
                state.error!,
                style: const TextStyle(color: AppColors.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _SettingsSection({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _DurationSlider extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final int divisions;
  final String suffix;
  final ValueChanged<int> onChanged;

  const _DurationSlider({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.divisions,
    this.suffix = 'min',
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: Text(label)),
            Text(
              '$value $suffix',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ],
        ),
        Slider(
          value: value.toDouble(),
          min: min.toDouble(),
          max: max.toDouble(),
          divisions: divisions,
          label: '$value $suffix',
          onChanged: (next) => onChanged(next.round()),
        ),
      ],
    );
  }
}
