import 'package:flutter/foundation.dart';

/// Release-safe, structured debug logger for speech recognition, TTS, and AI HTTP events.
/// Never prints or exposes API keys or full response payloads in release builds.
abstract final class DebugLogger {
  static void log(String tag, String message) {
    if (kDebugMode) {
      debugPrint('[$tag] $message');
    }
  }

  static void speech(String message) => log('SPEECH', message);

  static void tts(String message) => log('TTS', message);

  static void ai(String message) => log('GEMINI-AI', message);

  static void error(String tag, String message, [Object? error, StackTrace? stack]) {
    if (kDebugMode) {
      debugPrint('[$tag ERROR] $message');
      if (error != null) debugPrint('[$tag DETAILS] $error');
      if (stack != null) debugPrint('[$tag STACK] $stack');
    }
  }
}
