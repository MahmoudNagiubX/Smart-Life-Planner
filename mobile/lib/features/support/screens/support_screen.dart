import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/feedback_provider.dart';

class SupportScreen extends ConsumerStatefulWidget {
  const SupportScreen({super.key});

  @override
  ConsumerState<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends ConsumerState<SupportScreen> {
  static const _categories = <String, String>{
    'bug': 'Bug',
    'idea': 'Idea',
    'account': 'Account',
    'reminder': 'Reminder',
    'ai': 'AI',
    'other': 'Other',
  };

  final _messageController = TextEditingController();
  String _category = 'bug';

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final message = _messageController.text.trim();
    if (message.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Write at least 10 characters of feedback.'),
        ),
      );
      return;
    }

    final success = await ref
        .read(feedbackProvider.notifier)
        .submit(category: _category, message: message);
    if (!mounted) return;
    final state = ref.read(feedbackProvider);
    if (success) {
      _messageController.clear();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.successMessage ?? 'Feedback received')),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(state.error ?? 'Failed to send feedback')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(feedbackProvider);

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        titleSpacing: AppSpacing.screenH,
        title: Text('Support', style: AppTextStyles.h2Light),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.screenH, AppSpacing.s8,
          AppSpacing.screenH, AppSpacing.s32,
        ),
        children: [
          Container(
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
                        color: AppColors.featAISoft,
                        borderRadius: BorderRadius.circular(AppRadius.md),
                      ),
                      child: const Icon(
                        Icons.support_agent_outlined,
                        color: AppColors.featAI,
                        size: AppIconSize.cardHeader,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.s12),
                    Text('Send Feedback', style: AppTextStyles.h4Light),
                  ],
                ),
                const SizedBox(height: AppSpacing.s20),
                DropdownButtonFormField<String>(
                  initialValue: _category,
                  decoration: const InputDecoration(
                    labelText: 'Category',
                    prefixIcon: Icon(Icons.category_outlined),
                  ),
                  items: _categories.entries
                      .map(
                        (entry) => DropdownMenuItem(
                          value: entry.key,
                          child: Text(entry.value),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value != null) setState(() => _category = value);
                  },
                ),
                const SizedBox(height: AppSpacing.s16),
                TextField(
                  controller: _messageController,
                  minLines: 6,
                  maxLines: 10,
                  textInputAction: TextInputAction.newline,
                  style: AppTextStyles.bodyLight,
                  decoration: const InputDecoration(
                    labelText: 'Message',
                    alignLabelWithHint: true,
                    prefixIcon: Padding(
                      padding: EdgeInsets.only(bottom: 100),
                      child: Icon(Icons.edit_note_outlined),
                    ),
                    hintText: 'Describe what happened or what would help.',
                  ),
                ),
                const SizedBox(height: AppSpacing.s20),
                _GradientButton(
                  label: state.isSubmitting ? 'Sending...' : 'Send Feedback',
                  icon: Icons.send_outlined,
                  enabled: !state.isSubmitting,
                  onTap: state.isSubmitting ? null : _submit,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            'Feedback is stored with your account so the team can triage it. Do not include passwords, tokens, or private secrets.',
            style: AppTextStyles.captionLight,
            textAlign: TextAlign.center,
          ),
        ],
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
