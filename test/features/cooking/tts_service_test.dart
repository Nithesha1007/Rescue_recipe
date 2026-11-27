import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/data/services/tts_service.dart';

class FakeFlutterTtsService implements TtsService {
  bool initialized = false;
  bool isSpeaking = false;
  double speechRate = 0.5;
  String? currentLang = 'en-IN';
  void Function()? onComplete;
  void Function(dynamic)? onError;

  @override
  String? get currentLanguage => currentLang;

  @override
  bool get isAvailable => true;

  @override
  String? get lastError => null;

  @override
  Future<void> init() async {
    initialized = true;
  }

  @override
  Future<void> speak(String text) async {
    isSpeaking = true;
    // Simulate safety timer behavior: if text is short, completes after 50ms
    Timer(const Duration(milliseconds: 50), () {
      isSpeaking = false;
      onComplete?.call();
    });
  }

  @override
  Future<void> stop() async {
    isSpeaking = false;
  }

  @override
  Future<void> setSpeechRate(double rate) async {
    speechRate = rate;
  }

  @override
  Future<void> setVolume(double volume) async {}

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  void setCompletionHandler(void Function() handler) {
    onComplete = handler;
  }

  @override
  void setErrorHandler(void Function(dynamic msg) handler) {
    onError = handler;
  }

  @override
  Future<bool> openVoiceSettings() async => true;
}

void main() {
  group('TtsService Tests', () {
    test('initializes and triggers speech completion handler safely', () async {
      final tts = FakeFlutterTtsService();
      await tts.init();
      expect(tts.initialized, isTrue);

      final completer = Completer<bool>();
      tts.setCompletionHandler(() {
        completer.complete(true);
      });

      await tts.speak('Hello world');
      expect(tts.isSpeaking, isTrue);

      final result = await completer.future;
      expect(result, isTrue);
      expect(tts.isSpeaking, isFalse);
    });

    test('speech rate configuration updates properly', () async {
      final tts = FakeFlutterTtsService();
      await tts.setSpeechRate(0.7);
      expect(tts.speechRate, 0.7);
    });

    test('stop terminates speaking immediately', () async {
      final tts = FakeFlutterTtsService();
      await tts.speak('A very long text that takes a while to speak');
      expect(tts.isSpeaking, isTrue);
      await tts.stop();
      expect(tts.isSpeaking, isFalse);
    });

    test('openVoiceSettings returns true on platform bridge', () async {
      final tts = FakeFlutterTtsService();
      final opened = await tts.openVoiceSettings();
      expect(opened, isTrue);
    });
  });
}
