import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';

class AudioService {
  AudioService();

  final AudioPlayer _player = AudioPlayer();
  bool _hasAsset = false;

  Future<void> init() async {
    try {
      await rootBundle.load('assets/sounds/beep.wav');
      _hasAsset = true;
    } catch (_) {
      _hasAsset = false;
    }
  }

  Future<void> playBeep({required bool enabled}) async {
    if (!enabled) return;
    await HapticFeedback.mediumImpact();
    if (!_hasAsset) return;
    try {
      await _player.stop();
      await _player.play(AssetSource('sounds/beep.wav'));
    } catch (_) {
      // Haptic already fired
    }
  }

  Future<void> dispose() async {
    await _player.dispose();
  }
}