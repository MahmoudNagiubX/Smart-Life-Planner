import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
      appBar: AppBar(
        title: const Text(
          'Language and Localization',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
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
              padding: const EdgeInsets.all(24),
              children: [
                _LanguageCard(
                  languageCode: 'en',
                  title: 'English',
                  subtitle: 'Use English for app text where localized.',
                  selectedLanguage: _selectedLanguage,
                  onChanged: (value) =>
                      setState(() => _selectedLanguage = value),
                ),
                const SizedBox(height: 12),
                _LanguageCard(
                  languageCode: 'ar',
                  title: 'العربية',
                  subtitle: 'استخدم العربية للنصوص المتوفرة في التطبيق.',
                  selectedLanguage: _selectedLanguage,
                  onChanged: (value) =>
                      setState(() => _selectedLanguage = value),
                ),
                const SizedBox(height: 18),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardTheme.color,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.18),
                    ),
                  ),
                  child: const Text(
                    'This preference is saved to your account and applied to localized app surfaces after save.',
                  ),
                ),
                if (state.isSaving) ...[
                  const SizedBox(height: 16),
                  const LinearProgressIndicator(color: AppColors.primary),
                ],
                if (state.error != null && settings != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    state.error!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.error),
                  ),
                ],
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  onPressed: state.isSaving ? null : _save,
                  icon: const Icon(Icons.save_outlined),
                  label: const Text('Save Language'),
                ),
              ],
            ),
    );
  }
}

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
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => onChanged(languageCode),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).cardTheme.color,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.textSecondary.withValues(alpha: 0.22),
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_unchecked,
              color: selected ? AppColors.primary : AppColors.textSecondary,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
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
          ],
        ),
      ),
    );
  }
}
