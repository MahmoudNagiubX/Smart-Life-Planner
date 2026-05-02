import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/focus_provider.dart';

class FocusSettingsScreen extends ConsumerWidget {
  const FocusSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(focusProvider);
    final notifier = ref.read(focusProvider.notifier);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Focus Settings', style: AppTextStyles.h2Light),
      ),
      body: RefreshIndicator(
        color: AppColors.brandPrimary,
        onRefresh: notifier.loadSettings,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH, AppSpacing.s8,
            AppSpacing.screenH, AppSpacing.s32,
          ),
          children: [
            _SettingsSection(
              icon: Icons.timer_outlined,
              title: 'Session timing',
              color: AppColors.featFocus,
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
            const SizedBox(height: AppSpacing.s12),
            _SettingsSection(
              icon: Icons.tune_outlined,
              title: 'Session behavior',
              color: AppColors.brandPrimary,
              children: [
                _StyledSwitch(
                  title: 'Continuous mode',
                  subtitle: 'Auto-start the next focus or break.',
                  value: state.continuousMode,
                  onChanged: notifier.setContinuousMode,
                ),
                const _SectionDivider(),
                _StyledSwitch(
                  title: 'Distraction-free mode',
                  subtitle: 'Hide secondary panels while focusing.',
                  value: state.distractionFreeMode,
                  onChanged: notifier.setDistractionFreeMode,
                ),
                const _SectionDivider(),
                const SizedBox(height: AppSpacing.s8),
                DropdownButtonFormField<String>(
                  initialValue: state.ambientSoundKey,
                  decoration: const InputDecoration(
                    labelText: 'Ambient sound',
                    prefixIcon: Icon(Icons.music_note_outlined),
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
              const SizedBox(height: AppSpacing.s16),
              Container(
                padding: const EdgeInsets.all(AppSpacing.s12),
                decoration: BoxDecoration(
                  color: AppColors.errorSoft,
                  borderRadius: AppRadius.circular(AppRadius.md),
                  border: Border.all(
                      color: AppColors.errorColor.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline,
                        color: AppColors.errorColor, size: 18),
                    const SizedBox(width: AppSpacing.s8),
                    Expanded(
                      child: Text(
                        state.error!,
                        style: AppTextStyles.caption(AppColors.errorColor),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _SettingsSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final List<Widget> children;

  const _SettingsSection({
    required this.icon,
    required this.title,
    required this.color,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        boxShadow: AppShadows.soft,
        border: Border.all(color: AppColors.borderSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: AppIconSize.avatar,
                height: AppIconSize.avatar,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Icon(icon, color: color, size: AppIconSize.cardHeader),
              ),
              const SizedBox(width: AppSpacing.s12),
              Text(title, style: AppTextStyles.h4Light),
            ],
          ),
          const SizedBox(height: AppSpacing.s16),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.s8),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: Text(label, style: AppTextStyles.bodyLight)),
              Text(
                '$value $suffix',
                style: AppTextStyles.label(AppColors.brandPrimary),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.brandPrimary,
              thumbColor: AppColors.brandPrimary,
              inactiveTrackColor: AppColors.borderSoft,
              overlayColor: AppColors.brandPrimary.withValues(alpha: 0.12),
              valueIndicatorColor: AppColors.brandPrimary,
            ),
            child: Slider(
              value: value.toDouble(),
              min: min.toDouble(),
              max: max.toDouble(),
              divisions: divisions,
              label: '$value $suffix',
              onChanged: (next) => onChanged(next.round()),
            ),
          ),
        ],
      ),
    );
  }
}

class _StyledSwitch extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _StyledSwitch({
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.s4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTextStyles.bodyLight),
                if (subtitle != null) ...[
                  const SizedBox(height: 2),
                  Text(subtitle!, style: AppTextStyles.captionLight),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppColors.brandPrimary,
            activeThumbColor: Colors.white,
          ),
        ],
      ),
    );
  }
}

class _SectionDivider extends StatelessWidget {
  const _SectionDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      color: AppColors.dividerColor,
      height: AppSpacing.s16,
    );
  }
}
