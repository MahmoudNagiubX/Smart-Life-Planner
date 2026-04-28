import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/voice_provider.dart';
import 'voice_confirmation_screen.dart';
import 'voice_future_capabilities_screen.dart';

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
      end: 1.2,
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
              '🎙️ Microphone permission required. Please enable it in settings.',
            ),
            backgroundColor: AppColors.error,
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

  Future<void> _showVoiceActionsMenu() async {
    final capability = await showModalBottomSheet<VoiceFutureCapability>(
      context: context,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => const _VoiceActionsMenu(),
    );
    if (capability == null || !mounted) return;
    context.push('/home/voice-capture/future/${capability.id}');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(voiceProvider);

    // Navigate to confirmation when preview is ready
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
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () async {
            await ref.read(voiceProvider.notifier).cancelRecording();
            if (!context.mounted) return;
            Navigator.pop(context);
          },
        ),
        title: const Text(
          '🎙️ Voice Capture',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            tooltip: 'Voice actions',
            onPressed: _showVoiceActionsMenu,
            icon: const Icon(Icons.more_horiz, color: Colors.white),
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // State display
              _buildStateDisplay(state),
              const SizedBox(height: 48),

              // Mic button
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
    );
  }

  Widget _buildStateDisplay(VoiceState state) {
    switch (state.screenState) {
      case VoiceScreenState.idle:
        return Column(
          children: [
            const Text('🎙️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            const Text(
              'Tap to start recording',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Speak naturally in Arabic or English\nMax 60 seconds',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.3),
                ),
              ),
              child: const Text(
                '"Tomorrow I need to finish the assignment,\nprepare the slides, and buy milk"',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          ],
        );

      case VoiceScreenState.listening:
        return Column(
          children: [
            const Text('🔴', style: TextStyle(fontSize: 48)),
            const SizedBox(height: 16),
            const Text(
              'Listening...',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _formatTime(state.recordingSeconds),
              style: const TextStyle(
                color: AppColors.error,
                fontSize: 32,
                fontWeight: FontWeight.bold,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the button to stop',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.5),
                fontSize: 13,
              ),
            ),
          ],
        );

      default:
        return const SizedBox.shrink();
    }
  }

  Widget _buildIdleButton() {
    return GestureDetector(
      onTap: _startRecording,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: AppColors.primary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 30,
              spreadRadius: 5,
            ),
          ],
        ),
        child: const Icon(Icons.mic, color: Colors.white, size: 44),
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
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.5),
                    blurRadius: 30,
                    spreadRadius: 8,
                  ),
                ],
              ),
              child: const Icon(Icons.stop, color: Colors.white, size: 44),
            ),
          ),
        ),
        const SizedBox(height: 24),
        LinearProgressIndicator(
          value: state.recordingSeconds / 60,
          backgroundColor: Colors.white.withValues(alpha: 0.1),
          valueColor: const AlwaysStoppedAnimation<Color>(AppColors.error),
          minHeight: 4,
        ),
        const SizedBox(height: 8),
        Text(
          '${60 - state.recordingSeconds}s remaining',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildProcessingState() {
    return Column(
      children: [
        const CircularProgressIndicator(color: AppColors.primary),
        const SizedBox(height: 24),
        const Text(
          'Processing your voice...',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        const SizedBox(height: 8),
        Text(
          '🤖 Transcribing → Organizing tasks',
          style: TextStyle(
            color: Colors.white.withValues(alpha: 0.5),
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildFailedState(VoiceState state) {
    return Column(
      children: [
        const Text('❌', style: TextStyle(fontSize: 48)),
        const SizedBox(height: 16),
        Text(
          state.error ?? 'Something went wrong',
          textAlign: TextAlign.center,
          style: const TextStyle(color: AppColors.error, fontSize: 16),
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => ref.read(voiceProvider.notifier).reset(),
          icon: const Icon(Icons.refresh),
          label: const Text('Try Again'),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => ref.read(voiceProvider.notifier).startManualEntry(),
          icon: const Icon(Icons.edit_note),
          label: const Text('Enter Manually'),
        ),
      ],
    );
  }
}

class _VoiceActionsMenu extends StatelessWidget {
  const _VoiceActionsMenu();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView.separated(
        shrinkWrap: true,
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
        itemCount: voiceFutureCapabilities.length + 1,
        separatorBuilder: (context, index) => const SizedBox(height: 8),
        itemBuilder: (context, index) {
          if (index == 0) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Voice Actions',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
            );
          }
          final capability = voiceFutureCapabilities[index - 1];
          return ListTile(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            tileColor: Theme.of(context).cardTheme.color,
            leading: Icon(capability.icon, color: AppColors.primary),
            title: Text(capability.title),
            subtitle: Text(capability.description),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => Navigator.pop(context, capability),
          );
        },
      ),
    );
  }
}
