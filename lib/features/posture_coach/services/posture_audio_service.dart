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
      await _tts.setSpeechRate(0.52);
      await _tts.setVolume(1.0);
      await _tts.setPitch(1.0);
      _initialized = true;
    } catch (_) {}
  }

  /// Announces rep completion immediately (e.g. "1", "2", "3")
  static Future<void> speakRep(int rep) async {
    await init();
    try {
      await _tts.stop();
      await _tts.speak('$rep');
      _lastSpeakTime = DateTime.now();
    } catch (_) {}
  }

  /// Speaks form feedback with smart cooldown (urgent injury alerts bypass throttle)
  static Future<void> speak(String message, {bool isUrgent = false}) async {
    if (message.isEmpty) return;
    await init();
    final now = DateTime.now();
    final elapsedMs = now.difference(_lastSpeakTime).inMilliseconds;

    // Cooldown logic: 2800ms between normal coaching tips, 5000ms for exact duplicate
    if (!isUrgent && elapsedMs < 2800) return;
    if (!isUrgent && message == _lastSpoken && elapsedMs < 5000) return;

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
