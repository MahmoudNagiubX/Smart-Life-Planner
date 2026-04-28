import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class VoiceFutureCapability {
  final String id;
  final String title;
  final String description;
  final IconData icon;

  const VoiceFutureCapability({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
  });
}

const voiceFutureCapabilities = [
  VoiceFutureCapability(
    id: 'voice-journal',
    title: 'Voice Journaling',
    description:
        'Future flow for turning spoken reflection into an editable journal entry.',
    icon: Icons.edit_note_outlined,
  ),
  VoiceFutureCapability(
    id: 'voice-navigation',
    title: 'Voice Navigation',
    description:
        'Future app navigation commands with preview and confirmation before moving.',
    icon: Icons.navigation_outlined,
  ),
  VoiceFutureCapability(
    id: 'voice-summary',
    title: 'Voice Summary',
    description:
        'Future spoken daily or weekly summaries based only on safe app data.',
    icon: Icons.summarize_outlined,
  ),
];

VoiceFutureCapability voiceCapabilityById(String id) {
  return voiceFutureCapabilities.firstWhere(
    (capability) => capability.id == id,
    orElse: () => voiceFutureCapabilities.first,
  );
}

class VoiceFutureCapabilitiesScreen extends StatelessWidget {
  final String capabilityId;

  const VoiceFutureCapabilitiesScreen({super.key, required this.capabilityId});

  @override
  Widget build(BuildContext context) {
    final capability = voiceCapabilityById(capabilityId);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          capability.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.24),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(capability.icon, color: AppColors.primary, size: 34),
                const SizedBox(height: 14),
                Text(
                  capability.title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  capability.description,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 16),
                const _VoiceSafetyNotice(),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const _PreparedVoiceContract(),
        ],
      ),
    );
  }
}

class _VoiceSafetyNotice extends StatelessWidget {
  const _VoiceSafetyNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Placeholder only: future voice actions will show a transcript preview and require confirmation before write actions.',
        style: Theme.of(context).textTheme.bodySmall,
      ),
    );
  }
}

class _PreparedVoiceContract extends StatelessWidget {
  const _PreparedVoiceContract();

  @override
  Widget build(BuildContext context) {
    const items = [
      'Editable transcript preview',
      'Arabic and English command support',
      'Manual fallback if confidence is low',
      'No full conversational assistant yet',
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Prepared Future Contract',
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...items.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline,
                    color: AppColors.success,
                    size: 18,
                  ),
                  const SizedBox(width: 10),
                  Expanded(child: Text(item)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
