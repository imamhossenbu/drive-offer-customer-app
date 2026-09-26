import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import 'auth_storage.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  SoundService._internal();

  final AudioPlayer _audioPlayer = AudioPlayer();

  static void playTap() {
    HapticFeedback.selectionClick();
  }

  static void playSuccess() {
    instance.playSuccessSound();
  }

  static void playError() {
    instance.playErrorSound();
  }

  static void playNotification() {
    instance.playNotificationSound();
  }

  Future<void> playSuccessSound() async {
    HapticFeedback.mediumImpact();
    if (!AuthStorage.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/success.mp3'));
    } catch (_) {}
  }

  Future<void> playNotificationSound() async {
    HapticFeedback.lightImpact();
    if (!AuthStorage.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/chime.mp3'));
    } catch (_) {}
  }

  Future<void> playErrorSound() async {
    HapticFeedback.heavyImpact();
    if (!AuthStorage.isSoundEnabled()) return;
    try {
      await _audioPlayer.play(AssetSource('sounds/error.mp3'));
    } catch (_) {}
  }
}
