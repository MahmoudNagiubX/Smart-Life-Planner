import 'dart:io';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    final dir = await getTemporaryDirectory();
    _currentPath =
        '${dir.path}/voice_capture_${DateTime.now().millisecondsSinceEpoch}.m4a';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
      ),
      path: _currentPath!,
    );
  }

  Future<String?> stopRecording() async {
    final path = await _recorder.stop();
    return path;
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<void> cancelRecording() async {
    await _recorder.cancel();
    if (_currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}