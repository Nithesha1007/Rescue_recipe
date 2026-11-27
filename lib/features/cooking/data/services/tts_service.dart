import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../../core/utils/debug_logger.dart';

abstract class TtsService {
  Future<void> init();
  Future<void> speak(String text);
  Future<void> stop();
  Future<void> setSpeechRate(double rate);
  Future<void> setVolume(double volume);
  Future<void> setPitch(double pitch);
  void setCompletionHandler(void Function() handler);
  void setErrorHandler(void Function(dynamic msg) handler);
  Future<bool> openVoiceSettings();
  String? get currentLanguage;
  bool get isAvailable;
  String? get lastError;
}

class FlutterTtsServiceImpl implements TtsService {
  final FlutterTts _flutterTts;
  bool _initialized = false;
  double _speechRate = 0.5;
  String? _currentLanguage;
  bool _isAvailable = false;
  String? _lastError;

  void Function()? _externalCompletionHandler;
  void Function(dynamic msg)? _externalErrorHandler;
  Timer? _safetyTimer;

  static const MethodChannel _settingsChannel = MethodChannel('com.rescue_recipe/settings');

  FlutterTtsServiceImpl([FlutterTts? flutterTts])
      : _flutterTts = flutterTts ?? FlutterTts();

  @override
  String? get currentLanguage => _currentLanguage;

  @override
  bool get isAvailable => _isAvailable;

  @override
  String? get lastError => _lastError;

  @override
  Future<void> init() async {
    if (_initialized) return;

    try {
      DebugLogger.tts('Initializing TTS engine...');
      await _flutterTts.awaitSpeakCompletion(true);
      await _flutterTts.setSpeechRate(_speechRate);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.setPitch(1.0);

      // Check available engines
      try {
        final engines = await _flutterTts.getEngines;
        DebugLogger.tts('Available TTS engines: $engines');
        _isAvailable = engines is List && engines.isNotEmpty;
      } catch (e) {
        DebugLogger.tts('Failed to inspect TTS engines: $e');
        _isAvailable = true; // Assume available on standard platforms
      }

      // Check available languages with fallback: en-IN -> en-US -> device default
      try {
        final languages = await _flutterTts.getLanguages;
        DebugLogger.tts('Available TTS languages count: ${languages is List ? languages.length : 0}');

        if (languages is List) {
          if (languages.contains('en-IN')) {
            await _flutterTts.setLanguage('en-IN');
            _currentLanguage = 'en-IN';
          } else if (languages.contains('en-US')) {
            await _flutterTts.setLanguage('en-US');
            _currentLanguage = 'en-US';
          } else if (languages.contains('en')) {
            await _flutterTts.setLanguage('en');
            _currentLanguage = 'en';
          } else {
            _currentLanguage = 'default';
          }
        }
      } catch (e) {
        DebugLogger.tts('Language configuration fallback due to: $e');
        try {
          await _flutterTts.setLanguage('en-US');
          _currentLanguage = 'en-US';
        } catch (_) {
          _currentLanguage = 'default';
        }
      }

      _flutterTts.setCompletionHandler(() {
        DebugLogger.tts('TTS engine reported completion');
        _safetyTimer?.cancel();
        _safetyTimer = null;
        _externalCompletionHandler?.call();
      });

      _flutterTts.setErrorHandler((msg) {
        _lastError = msg.toString();
        DebugLogger.tts('TTS error: $msg');
        _safetyTimer?.cancel();
        _safetyTimer = null;
        _externalErrorHandler?.call(msg);
      });

      _initialized = true;
      DebugLogger.tts('TTS initialized successfully (Language: $_currentLanguage)');
    } catch (e) {
      _lastError = e.toString();
      DebugLogger.tts('TTS initialization failed: $e');
    }
  }

  @override
  Future<void> speak(String text) async {
    if (!_initialized) await init();

    _safetyTimer?.cancel();

    // Completion timeout safety: (text.length / (speechRate * 15) * 1000) + 3000 ms
    // Ensures audio session deadlock never occurs if an OEM engine misses the completion event.
    final timeoutMs = ((text.length / (_speechRate * 15)) * 1000).toInt() + 3000;
    final safetyDuration = Duration(milliseconds: timeoutMs.clamp(3000, 30000));

    _safetyTimer = Timer(safetyDuration, () {
      DebugLogger.tts(
        'Safety timeout triggered after ${safetyDuration.inMilliseconds}ms for text length ${text.length}',
      );
      _safetyTimer = null;
      _externalCompletionHandler?.call();
    });

    try {
      DebugLogger.tts('Speaking (${text.length} chars): "$text"');
      await _flutterTts.speak(text);
    } catch (e) {
      _lastError = e.toString();
      DebugLogger.tts('Failed to speak text: $e');
      _safetyTimer?.cancel();
      _safetyTimer = null;
      _externalCompletionHandler?.call();
    }
  }

  @override
  Future<void> stop() async {
    _safetyTimer?.cancel();
    _safetyTimer = null;
    await _flutterTts.stop();
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    _speechRate = rate;
    await _flutterTts.setSpeechRate(rate);
  }

  @override
  Future<void> setVolume(double volume) async {
    await _flutterTts.setVolume(volume);
  }

  @override
  Future<void> setPitch(double pitch) async {
    await _flutterTts.setPitch(pitch);
  }

  @override
  void setCompletionHandler(void Function() handler) {
    _externalCompletionHandler = handler;
  }

  @override
  void setErrorHandler(void Function(dynamic msg) handler) {
    _externalErrorHandler = handler;
  }

  @override
  Future<bool> openVoiceSettings() async {
    try {
      DebugLogger.tts('Opening voice settings via platform channel...');
      final result = await _settingsChannel.invokeMethod<bool>('openTtsSettings');
      return result ?? false;
    } catch (e) {
      DebugLogger.tts('Failed to open voice settings: $e');
      return false;
    }
  }
}
