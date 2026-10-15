import 'package:flutter_tts/flutter_tts.dart';

class PostureAudioService {
  static final FlutterTts _tts = FlutterTts();
  static bool _initialized = false;
  static String? _lastSpoken;
  static DateTime _lastSpeakTime = DateTime(2000);

  static Future<void> init() async {
    if (_initialized) return;
    try {
      await _tts.setLanguage('en-US');
      await _tts.setSpeechRate(0.5);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (_) {}
  }

  // Speak only if message changed or 4 seconds passed
  static Future<void> speak(String message) async {
    await init();
    final now = DateTime.now();
    final elapsed = now.difference(_lastSpeakTime).inSeconds;

    if (message == _lastSpoken && elapsed < 4) return;

    _lastSpoken = message;
    _lastSpeakTime = now;
    try {
      await _tts.stop();
      await _tts.speak(message);
    } catch (_) {}
  }

  static Future<void> stop() async {
    try {
      await _tts.stop();
    } catch (_) {}
  }

  static Future<void> dispose() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _initialized = false;
  }
}
