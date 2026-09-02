import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class SoundService {
  static final SoundService instance = SoundService._internal();
  factory SoundService() => instance;
  SoundService._internal();

  AudioPlayer? _player;
  bool _isPlaying = false;

  bool get isPlaying => _isPlaying;

  Future<void> _ensurePlayerInitialized() async {
    if (_player == null) {
      _player = AudioPlayer();
      try {
        await _player!.setAudioContext(
          AudioContext(
            android: const AudioContextAndroid(
              isSpeakerphoneOn: true,
              stayAwake: true,
              contentType: AndroidContentType.sonification,
              usageType: AndroidUsageType.notificationEvent,
              audioFocus: AndroidAudioFocus.gainTransientMayDuck,
            ),
            iOS: AudioContextIOS(
              category: AVAudioSessionCategory.playback,
              options: const {
                AVAudioSessionOptions.duckOthers,
                AVAudioSessionOptions.defaultToSpeaker,
              },
            ),
          ),
        );
      } catch (e) {
        debugPrint('AudioContext setting note: $e');
      }
    }
  }

  /// Plays the incoming appointment / visit request buzzer sound.
  /// If [loop] is true, the sound repeats continuously until [stopBuzzer] is called.
  Future<void> playBuzzer({bool loop = true}) async {
    try {
      await _ensurePlayerInitialized();
      if (_player == null) return;

      await _player!.stop();
      if (loop) {
        await _player!.setReleaseMode(ReleaseMode.loop);
      } else {
        await _player!.setReleaseMode(ReleaseMode.release);
      }
      await _player!.setVolume(1.0);

      // 1. Attempt playing via AssetSource (standard Flutter path)
      bool played = false;
      try {
        await _player!.play(AssetSource('audio/buzzer_sound.mp3'));
        played = true;
      } catch (e) {
        debugPrint('AssetSource audio/buzzer_sound.mp3 failed: $e, trying buzzer sound.mp3');
      }

      if (!played) {
        try {
          await _player!.play(AssetSource('audio/buzzer sound.mp3'));
          played = true;
        } catch (e) {
          debugPrint('AssetSource audio/buzzer sound.mp3 failed: $e, trying rootBundle BytesSource');
        }
      }

      // 2. Direct binary ByteSource fallback if AssetSource failed
      if (!played) {
        try {
          ByteData data;
          try {
            data = await rootBundle.load('assets/audio/buzzer_sound.mp3');
          } catch (_) {
            data = await rootBundle.load('assets/audio/buzzer sound.mp3');
          }
          final Uint8List bytes = data.buffer.asUint8List();
          await _player!.play(BytesSource(bytes));
          played = true;
        } catch (e) {
          debugPrint('BytesSource fallback failed: $e');
        }
      }

      _isPlaying = played;
      if (played) {
        debugPrint('✅ Buzzer sound playing successfully.');
      }
    } catch (e) {
      debugPrint('Error playing buzzer sound: $e');
    }
  }

  /// Stops the buzzer sound immediately.
  Future<void> stopBuzzer() async {
    try {
      _isPlaying = false;
      if (_player != null) {
        await _player!.stop();
        debugPrint('⏹️ Buzzer sound stopped.');
      }
    } catch (e) {
      debugPrint('Error stopping buzzer sound: $e');
    }
  }

  void dispose() {
    _isPlaying = false;
    _player?.dispose();
    _player = null;
  }
}
