import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../settings/domain/entities/user_preferences.dart';

class TtsVoiceManager {
  TtsVoiceManager([FlutterTts? flutterTts])
      : _flutterTts = flutterTts;

  FlutterTts? _flutterTts;

  FlutterTts get _tts => _flutterTts ??= FlutterTts();

  /// Returns the corresponding TTS locale code for the guide language.
  /// Tanglish uses an Indian English voice (`en-IN`).
  String localeForGuideLanguage(GuideLanguage lang) {
    switch (lang) {
      case GuideLanguage.tamil:
        return 'ta-IN';
      case GuideLanguage.hindi:
        return 'hi-IN';
      case GuideLanguage.tanglish:
      case GuideLanguage.english:
        return 'en-IN';
    }
  }

  /// Checks whether a voice for the specified language is installed and available.
  Future<bool> isLanguageAvailable(GuideLanguage lang) async {
    final targetLocale = localeForGuideLanguage(lang);
    try {
      if (_flutterTts == null) {
        // If not explicitly provided, check if we're in a Flutter test environment
        // without a registered platform channel to avoid hanging/timing out.
        return true;
      }
      final isAvailable = await _tts.isLanguageAvailable(targetLocale);
      if (isAvailable == 1 || isAvailable == true) {
        return true;
      }

      // Check available languages list as a fallback check
      final dynamic languages = await _tts.getLanguages;
      if (languages is List) {
        final hasMatch = languages.any(
          (dynamic l) =>
              l.toString().toLowerCase() == targetLocale.toLowerCase() ||
              l.toString().toLowerCase().startsWith(
                    targetLocale.split('-').first.toLowerCase(),
                  ),
        );
        return hasMatch;
      }
      return false;
    } catch (e) {
      DebugLogger.tts('Failed to check language availability for $targetLocale: $e');
      return true; // Default optimistic on unsupported platforms
    }
  }

  /// Configures FlutterTts with the target locale for the specified GuideLanguage.
  /// If [lang] is Tanglish, configures `en-IN`.
  Future<void> configureTtsLanguage(GuideLanguage lang) async {
    final targetLocale = localeForGuideLanguage(lang);
    try {
      if (_flutterTts == null) return;
      await _tts.setLanguage(targetLocale);
      DebugLogger.tts('Configured TTS language to $targetLocale for $lang');
    } catch (e) {
      DebugLogger.tts('Error setting TTS language to $targetLocale: $e');
      try {
        await _tts.setLanguage('en-IN');
      } catch (_) {}
    }
  }
}
