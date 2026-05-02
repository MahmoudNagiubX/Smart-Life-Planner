import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_shadows.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/theme/app_tokens.dart';
import '../providers/voice_provider.dart';
import 'voice_confirmation_screen.dart';

class VoiceCaptureScreen extends ConsumerStatefulWidget {
  const VoiceCaptureScreen({super.key});

  @override
  ConsumerState<VoiceCaptureScreen> createState() => _VoiceCaptureScreenState();
}

class _VoiceCaptureScreenState extends ConsumerState<VoiceCaptureScreen>
    with SingleTickerProviderStateMixin {
  Timer? _timer;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.12,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _startRecording() async {
    final notifier = ref.read(voiceProvider.notifier);
    final hasPermission = await notifier.checkPermission();
    if (!hasPermission) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Microphone permission is required. Please enable it in settings.',
            ),
            backgroundColor: AppColors.errorColor,
          ),
        );
      }
      return;
    }

    await notifier.startRecording();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      ref.read(voiceProvider.notifier).tickTimer();
    });
  }

  Future<void> _stopRecording() async {
    _timer?.cancel();
    await ref.read(voiceProvider.notifier).stopAndProcess();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceProvider);

    ref.listen<VoiceState>(voiceProvider, (prev, next) {
      if (next.screenState == VoiceScreenState.transcriptPreview &&
          next.result != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const VoiceConfirmationScreen()),
        );
      }
    });

    return Scaffold(
      backgroundColor: AppColors.bgApp,
      appBar: AppBar(
        backgroundColor: AppColors.bgApp,
        surfaceTintColor: AppColors.bgApp,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: AppColors.textHeading),
          onPressed: () async {
            await ref.read(voiceProvider.notifier).cancelRecording();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Voice Capture', style: AppTextStyles.h3Light),
            Text(
              'Speak naturally, then review.',
              style: AppTextStyles.caption(AppColors.textHint),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.screenH,
            AppSpacing.s16,
            AppSpacing.screenH,
            AppSpacing.s32,
          ),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildStateDisplay(state),
                        const SizedBox(height: AppSpacing.s32),
                        if (state.screenState == VoiceScreenState.idle)
                          _buildIdleButton(),
                        if (state.screenState == VoiceScreenState.listening)
                          _buildRecordingButton(state),
                        if (state.screenState == VoiceScreenState.processing)
                          _buildProcessingState(),
                        if (state.screenState == VoiceScreenState.failed)
                          _buildFailedState(state),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStateDisplay(VoiceState state) {
    switch (state.screenState) {
      case VoiceScreenState.idle:
        return _StateCard(
          icon: Icons.mic_none_outlined,
          title: 'Tap to start recording',
          subtitle: 'Speak naturally in Arabic or English. Max 60 seconds.',
          accentColor: AppColors.brandPrimary,
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppSpacing.s12),
            decoration: BoxDecoration(
              color: AppColors.bgSurfaceLavender,
              borderRadius: AppRadius.circular(AppRadius.lg),
              border: Border.all(color: AppColors.borderSoft),
            ),
            child: Text(
              '"Tomorrow I need to finish the assignment, prepare the slides, and buy milk"',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodySmall(AppColors.brandPrimary),
            ),
          ),
        );

      case VoiceScreenState.listening:
        return _StateCard(
          icon: Icons.graphic_eq,
          title: 'Listening...',
          subtitle: 'Tap the button when you are done.',
          accentColor: AppColors.errorColor,
          child: Column(
            children: [
              Text(
                _formatTime(state.recordingSeconds),
                style: AppTextStyles.timerNumber(
                  AppColors.errorColor,
                ).copyWith(fontFeatures: const [FontFeature.tabularFigures()]),
              ),
              const SizedBox(height: AppSpacing.s12),
              const _Waveform(),
            ],
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        width: 112,
        height: 112,
        decoration: BoxDecoration(
          gradient: AppGradients.action,
          shape: BoxShape.circle,
          boxShadow: AppShadows.glowPurple,
        ),
        child: const Icon(Icons.mic, color: AppColors.bgSurface, size: 46),
      ),
    );
  }

  Widget _buildRecordingButton(VoiceState state) {
    return Column(
      children: [
        ScaleTransition(
          scale: _pulseAnimation,
          child: GestureDetector(
            onTap: _stopRecording,
            child: Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.errorColor,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.errorColor.withValues(alpha: 0.32),
                    blurRadius: 30,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: const Icon(
                Icons.stop,
                color: AppColors.bgSurface,
                size: 46,
              ),
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.s24),
        ClipRRect(
          borderRadius: AppRadius.pillBr,
          child: LinearProgressIndicator(
            value: state.recordingSeconds / 60,
            backgroundColor: AppColors.errorSoft,
            valueColor: const AlwaysStoppedAnimation<Color>(
              AppColors.errorColor,
            ),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: AppSpacing.s8),
        Text(
          '${60 - state.recordingSeconds}s remaining',
          style: AppTextStyles.captionLight,
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return _StateCard(
      icon: Icons.auto_awesome,
      title: 'Processing your voice...',
      subtitle: 'Transcribing and organizing your capture.',
      accentColor: AppColors.brandPrimary,
      child: const Padding(
        padding: EdgeInsets.only(top: AppSpacing.s8),
        child: CircularProgressIndicator(color: AppColors.brandPrimary),
      ),
    );
  }

  Widget _buildFailedState(VoiceState state) {
    return _StateCard(
      icon: Icons.error_outline,
      title: 'Voice capture failed',
      subtitle: state.error ?? 'Something went wrong.',
      accentColor: AppColors.errorColor,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => ref.read(voiceProvider.notifier).reset(),
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ),
          const SizedBox(height: AppSpacing.s12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () =>
                  ref.read(voiceProvider.notifier).startManualEntry(),
              icon: const Icon(Icons.edit_note),
              label: const Text('Enter Manually'),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color accentColor;
  final Widget child;

  const _StateCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.cardPad),
      decoration: BoxDecoration(
        color: AppColors.bgSurface,
        borderRadius: AppRadius.cardBr,
        border: Border.all(color: AppColors.borderSoft),
        boxShadow: AppShadows.card,
      ),
      child: Column(
        children: [
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: accentColor.withValues(alpha: 0.24)),
            ),
            child: Icon(icon, color: accentColor, size: 36),
          ),
          const SizedBox(height: AppSpacing.s16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.h3Light,
          ),
          const SizedBox(height: AppSpacing.s8),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodySmallLight,
          ),
          const SizedBox(height: AppSpacing.s20),
          child,
        ],
      ),
    );
  }
}

class _Waveform extends StatelessWidget {
  const _Waveform();

  @override
  Widget build(BuildContext context) {
    const heights = [18.0, 34.0, 24.0, 44.0, 28.0, 38.0, 20.0];
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: heights
          .map(
            (height) => Container(
              width: 8,
              height: height,
              margin: const EdgeInsets.symmetric(horizontal: AppSpacing.s4),
              decoration: BoxDecoration(
                gradient: AppGradients.action,
                borderRadius: AppRadius.pillBr,
              ),
            ),
          )
          .toList(),
    );
  }
}
