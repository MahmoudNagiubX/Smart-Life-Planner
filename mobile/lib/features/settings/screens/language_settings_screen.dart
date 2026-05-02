import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../core/widgets/app_error_state.dart';
import '../../../core/widgets/app_loading_state.dart';
import '../providers/app_settings_provider.dart';

class LanguageSettingsScreen extends ConsumerStatefulWidget {
  const LanguageSettingsScreen({super.key});

  @override
  ConsumerState<LanguageSettingsScreen> createState() =>
      _LanguageSettingsScreenState();
}

class _LanguageSettingsScreenState
    extends ConsumerState<LanguageSettingsScreen> {
  String _selectedLanguage = 'en';
  String? _syncedLanguage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appSettingsProvider.notifier).loadSettings();
    });
  }

  void _sync(String language) {
    if (_syncedLanguage == language) return;
    _syncedLanguage = language;
    _selectedLanguage = language == 'ar' ? 'ar' : 'en';
  }

  Future<void> _save() async {
    final success = await ref
        .read(appSettingsProvider.notifier)
        .saveSettings(language: _selectedLanguage);
    if (!mounted) return;
    final message = success
        ? 'Language saved.'
        : ref.read(appSettingsProvider).error ?? 'Failed to save language.';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appSettingsProvider);
    final settings = state.settings;
    if (settings != null) _sync(settings.language);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Language', style: AppTextStyles.h2Light),
      ),
      body: state.isLoading && settings == null
          ? const AppLoadingState(message: 'Loading language settings...')
          : state.error != null && settings == null
          ? AppErrorState(
              title: 'Language settings could not load',
              message: state.error!,
              onRetry: () => ref
                  .read(appSettingsProvider.notifier)
                  .loadSettings(force: true),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.screenH, AppSpacing.s8,
                AppSpacing.screenH, AppSpacing.s32,
              ),
              children: [
                Text(
                  'SELECT LANGUAGE',
                  style: AppTextStyles.label(AppColors.textHint),
                ),
                const SizedBox(height: AppSpacing.s8),
                _LanguageCard(
                  languageCode: 'en',
                  title: 'English',
                  subtitle: 'Use English for app text where localized.',
                  selectedLanguage: _selectedLanguage,
                  onChanged: (value) =>
                      setState(() => _selectedLanguage = value),
                ),
                const SizedBox(height: AppSpacing.s8),
                _LanguageCard(
                  languageCode: 'ar',
                  title: 'العربية',
                  subtitle: 'استخدم العربية للنصوص المتوفرة في التطبيق.',
                  selectedLanguage: _selectedLanguage,
                  onChanged: (value) =>
                      setState(() => _selectedLanguage = value),
                ),
                const SizedBox(height: AppSpacing.s16),
                Container(
                  padding: const EdgeInsets.all(AppSpacing.s16),
                  decoration: BoxDecoration(
                    color: AppColors.bgSurface,
                    borderRadius: AppRadius.cardBr,
                    boxShadow: AppShadows.soft,
                    border: Border.all(color: AppColors.borderSoft),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: AppColors.infoSoft,
                          borderRadius: BorderRadius.circular(AppRadius.sm),
                        ),
                        child: const Icon(
                          Icons.info_outline,
                          size: 16,
                          color: AppColors.infoColor,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.s12),
                      Expanded(
                        child: Text(
                          'This preference is saved to your account and applied to localized app surfaces after save.',
                          style: AppTextStyles.bodySmallLight,
                        ),
                      ),
                    ],
                  ),
                ),
                if (state.isSaving) ...[
                  const SizedBox(height: AppSpacing.s16),
                  const LinearProgressIndicator(
                    color: AppColors.brandPrimary,
                  ),
                ],
                if (state.error != null && settings != null) ...[
                  const SizedBox(height: AppSpacing.s12),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: AppTextStyles.caption(AppColors.errorColor),
                  ),
                ],
                const SizedBox(height: AppSpacing.s24),
                _GradientButton(
                  label: 'Save Language',
                  icon: Icons.save_outlined,
                  enabled: !state.isSaving,
                  onTap: state.isSaving ? null : _save,
                ),
              ],
            ),
    );
  }
}

// ── Language card ─────────────────────────────────────────────────────────────

class _LanguageCard extends StatelessWidget {
  final String languageCode;
  final String title;
  final String subtitle;
  final String selectedLanguage;
  final ValueChanged<String> onChanged;

  const _LanguageCard({
    required this.languageCode,
    required this.title,
    required this.subtitle,
    required this.selectedLanguage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final selected = selectedLanguage == languageCode;
    return GestureDetector(
      onTap: () => onChanged(languageCode),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(AppSpacing.s16),
        decoration: BoxDecoration(
          color: selected ? AppColors.bgSurfaceLavender : AppColors.bgSurface,
          borderRadius: AppRadius.cardBr,
          boxShadow: AppShadows.soft,
          border: Border.all(
            color: selected ? AppColors.brandPrimary : AppColors.borderSoft,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.brandPrimary
                    : AppColors.bgSurfaceSoft,
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? AppColors.brandPrimary
                      : AppColors.borderSoft,
                ),
              ),
              child: Icon(
                Icons.check,
                size: 16,
                color: selected ? Colors.white : Colors.transparent,
              ),
            ),
            const SizedBox(width: AppSpacing.s12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.h4(
                      selected
                          ? AppColors.brandPrimary
                          : AppColors.textHeading,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTextStyles.captionLight),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Gradient button ───────────────────────────────────────────────────────────

class _GradientButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool enabled;
  final VoidCallback? onTap;

  const _GradientButton({
    required this.label,
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: AppButtonHeight.primary,
      decoration: BoxDecoration(
        gradient: enabled ? AppGradients.action : null,
        color: enabled ? null : AppColors.borderSoft,
        borderRadius: AppRadius.pillBr,
        boxShadow: enabled ? AppShadows.glowPurple : null,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: AppRadius.pillBr,
          onTap: onTap,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: enabled ? Colors.white : AppColors.textHint,
                size: 20,
              ),
              const SizedBox(width: AppSpacing.s8),
              Text(
                label,
                style: enabled
                    ? AppTextStyles.buttonLight
                    : AppTextStyles.button(AppColors.textHint),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
