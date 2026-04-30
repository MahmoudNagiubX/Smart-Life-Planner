import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:just_audio/just_audio.dart';

class FocusAmbientSoundService with WidgetsBindingObserver {
  static const silence = 'silence';
  static const rain = 'rain';
  static const cafe = 'cafe';
  static const whiteNoise = 'white_noise';

  static const supportedKeys = <String>{silence, rain, cafe, whiteNoise};

  static const _assetByKey = <String, String>{
    silence: 'assets/audio/focus_silence.wav',
    rain: 'assets/audio/focus_rain.wav',
    cafe: 'assets/audio/focus_cafe.wav',
    whiteNoise: 'assets/audio/focus_white_noise.wav',
  };

  final AudioPlayer _player;
  String _activeKey = silence;
  String? _loadedAsset;
  bool _shouldPlay = false;
  bool _lifecyclePaused = false;

  FocusAmbientSoundService({AudioPlayer? player})
    : _player = player ?? AudioPlayer() {
    WidgetsBinding.instance.addObserver(this);
  }

  static String normalizeKey(String key) {
    final normalized = key.trim().toLowerCase();
    return supportedKeys.contains(normalized) ? normalized : silence;
  }

  static String? assetForKey(String key) {
    return _assetByKey[normalizeKey(key)];
  }

  static bool isAudibleKey(String key) => normalizeKey(key) != silence;

  Future<void> play(String key) async {
    final normalized = normalizeKey(key);
    _activeKey = normalized;
    _shouldPlay = isAudibleKey(normalized);

    if (!_shouldPlay) {
      await stop();
      return;
    }
    if (_lifecyclePaused) return;

    final asset = assetForKey(normalized);
    if (asset == null) return;
    if (_loadedAsset != asset) {
      await _player.stop();
      await _player.setLoopMode(LoopMode.one);
      await _player.setAsset(asset);
      _loadedAsset = asset;
    }
    await _player.play();
  }

  Future<void> stop() async {
    _shouldPlay = false;
    await _player.stop();
  }

  Future<void> pauseForLifecycle() async {
    _lifecyclePaused = true;
    await _player.pause();
  }

  Future<void> resumeForLifecycle() async {
    _lifecyclePaused = false;
    if (_shouldPlay) {
      await play(_activeKey);
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(resumeForLifecycle());
      return;
    }
    unawaited(pauseForLifecycle());
  }

  Future<void> dispose() async {
    WidgetsBinding.instance.removeObserver(this);
    await _player.dispose();
  }
}
