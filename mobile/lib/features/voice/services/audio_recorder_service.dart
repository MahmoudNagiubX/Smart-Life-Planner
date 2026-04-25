import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

class AudioRecorderService {
  final AudioRecorder _recorder = AudioRecorder();
  String? _currentPath;
  String? _currentFilename;
  BytesBuilder? _webAudioBytes;
  StreamSubscription<Uint8List>? _webAudioSubscription;

  String get currentFilename => _currentFilename ?? 'voice_capture.wav';

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  Future<void> startRecording() async {
    if (kIsWeb) {
      await _startWebRecording();
      return;
    }

    final dir = await Directory.systemTemp.createTemp('smart_life_voice_');
    final timestamp = DateTime.now().millisecondsSinceEpoch;

    try {
      await _startWithConfig(
        path: '${dir.path}/voice_capture_$timestamp.m4a',
        config: const RecordConfig(
          encoder: AudioEncoder.aacLc,
          bitRate: 128000,
          sampleRate: 44100,
          numChannels: 1,
          androidConfig: AndroidRecordConfig(
            useLegacy: true,
            audioSource: AndroidAudioSource.mic,
            manageBluetooth: false,
          ),
        ),
      );
    } catch (firstError) {
      await _recorder.cancel();
      try {
        await _startWithConfig(
          path: '${dir.path}/voice_capture_$timestamp.wav',
          config: const RecordConfig(
            encoder: AudioEncoder.wav,
            sampleRate: 16000,
            numChannels: 1,
            androidConfig: AndroidRecordConfig(
              audioSource: AndroidAudioSource.mic,
              manageBluetooth: false,
            ),
          ),
        );
      } catch (fallbackError) {
        throw StateError(
          'Recorder failed to start. First: $firstError. Fallback: $fallbackError',
        );
      }
    }
  }

  Future<void> _startWebRecording() async {
    _webAudioBytes = BytesBuilder(copy: false);
    _currentFilename =
        'voice_capture_${DateTime.now().millisecondsSinceEpoch}.wav';

    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
      ),
    );

    _webAudioSubscription = stream.listen((chunk) {
      _webAudioBytes?.add(chunk);
    });
  }

  Future<void> _startWithConfig({
    required String path,
    required RecordConfig config,
  }) async {
    final supported = await _recorder.isEncoderSupported(config.encoder);
    if (!supported) {
      throw StateError('${config.encoder.name} encoder is not supported');
    }

    _currentPath = path;
    _currentFilename = path.split(Platform.pathSeparator).last;
    await _recorder.start(config, path: path);
  }

  Future<String?> stopRecording() async {
    if (kIsWeb) {
      await _recorder.stop();
      await _webAudioSubscription?.cancel();
      _webAudioSubscription = null;
      return _currentFilename;
    }

    final path = await _recorder.stop();
    return path;
  }

  Future<Uint8List> readRecordingBytes(String path) async {
    if (kIsWeb) {
      final pcmBytes = _webAudioBytes?.takeBytes();
      if (pcmBytes == null || pcmBytes.isEmpty) {
        throw StateError('No recorded audio data was captured.');
      }
      return _wavFromPcm16(pcmBytes, sampleRate: 16000, channels: 1);
    }

    return await File(path).readAsBytes();
  }

  Future<void> deleteRecording(String path) async {
    if (kIsWeb) {
      _webAudioBytes = null;
      return;
    }

    final file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<void> cancelRecording() async {
    await _webAudioSubscription?.cancel();
    _webAudioSubscription = null;
    _webAudioBytes = null;
    await _recorder.cancel();
    if (!kIsWeb && _currentPath != null) {
      final file = File(_currentPath!);
      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  void dispose() {
    _webAudioSubscription?.cancel();
    _recorder.dispose();
  }

  Uint8List _wavFromPcm16(
    Uint8List pcmBytes, {
    required int sampleRate,
    required int channels,
  }) {
    const bitsPerSample = 16;
    final byteRate = sampleRate * channels * bitsPerSample ~/ 8;
    final blockAlign = channels * bitsPerSample ~/ 8;
    final dataSize = pcmBytes.length;
    final fileSize = 36 + dataSize;
    final header = ByteData(44);

    void writeString(int offset, String value) {
      for (var i = 0; i < value.length; i++) {
        header.setUint8(offset + i, value.codeUnitAt(i));
      }
    }

    writeString(0, 'RIFF');
    header.setUint32(4, fileSize, Endian.little);
    writeString(8, 'WAVE');
    writeString(12, 'fmt ');
    header.setUint32(16, 16, Endian.little);
    header.setUint16(20, 1, Endian.little);
    header.setUint16(22, channels, Endian.little);
    header.setUint32(24, sampleRate, Endian.little);
    header.setUint32(28, byteRate, Endian.little);
    header.setUint16(32, blockAlign, Endian.little);
    header.setUint16(34, bitsPerSample, Endian.little);
    writeString(36, 'data');
    header.setUint32(40, dataSize, Endian.little);

    final wavBytes = BytesBuilder(copy: false)
      ..add(header.buffer.asUint8List())
      ..add(pcmBytes);
    return wavBytes.takeBytes();
  }
}
