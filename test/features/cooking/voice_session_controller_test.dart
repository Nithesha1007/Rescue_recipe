import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/data/services/tts_service.dart';
import 'package:rescue_recipe/features/cooking/data/services/voice_session_controller_impl.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/services/voice_session_controller.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/speech_repository.dart';

class FakeTtsService implements TtsService {
  bool isSpeaking = false;
  void Function()? completionHandler;
  void Function(dynamic msg)? errorHandler;

  @override
  String? get currentLanguage => 'en_IN';

  @override
  bool get isAvailable => true;

  @override
  String? get lastError => null;

  @override
  Future<bool> openVoiceSettings() async => true;

  @override
  Future<void> init() async {}

  @override
  Future<void> speak(String text) async {
    isSpeaking = true;
    completionHandler?.call();
    isSpeaking = false;
  }

  @override
  Future<void> stop() async {
    isSpeaking = false;
  }

  @override
  Future<void> setPitch(double pitch) async {}

  @override
  Future<void> setSpeechRate(double rate) async {}

  @override
  Future<void> setVolume(double volume) async {}

  @override
  void setCompletionHandler(void Function() handler) {
    completionHandler = handler;
  }

  @override
  void setErrorHandler(void Function(dynamic msg) handler) {
    errorHandler = handler;
  }
}

class FakeSpeechRepository implements SpeechRepository {
  bool _isListening = false;
  final _updateController = StreamController<SpeechRecognitionUpdate>.broadcast();

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<SpeechPermissionStatus> checkPermission() async => SpeechPermissionStatus.granted;

  @override
  Future<SpeechPermissionStatus> requestPermission() async => SpeechPermissionStatus.granted;

  @override
  Stream<SpeechRecognitionUpdate> startListening({String? localeId}) {
    _isListening = true;
    return _updateController.stream;
  }

  @override
  Future<List<String>> getAvailableLocales() async => ['en_IN', 'en_US'];

  @override
  Future<void> stop() async {
    _isListening = false;
  }

  @override
  Future<void> cancel() async {
    _isListening = false;
  }

  void emitTranscript(String text) {
    _updateController.add(SpeechRecognitionUpdate(
      transcript: text,
      soundLevel: 0.5,
      isFinal: true,
    ));
  }

  void emitError(dynamic err) {
    _updateController.addError(err);
  }
}

void main() {
  group('VoiceSessionControllerImpl', () {
    late FakeTtsService fakeTts;
    late FakeSpeechRepository fakeSpeech;
    late VoiceSessionControllerImpl controller;

    setUp(() {
      fakeTts = FakeTtsService();
      fakeSpeech = FakeSpeechRepository();
      controller = VoiceSessionControllerImpl(
        ttsService: fakeTts,
        speechRepository: fakeSpeech,
      );
    });

    tearDown(() async {
      await controller.dispose();
    });

    test('speaking and listening never overlap', () async {
      await controller.startListening();
      expect(fakeSpeech.isListening, isTrue);
      expect(fakeTts.isSpeaking, isFalse);

      final speakFuture = controller.speak('Test speech');
      await speakFuture;
      expect(fakeSpeech.isListening, isFalse);
      expect(controller.currentState, AudioSessionState.idle);
    });

    test('parses speech transcript and delivers command to commandStream', () async {
      final commands = <VoiceCommand>[];
      final sub = controller.commandStream.listen(commands.add);

      await controller.startListening();
      expect(controller.currentState, AudioSessionState.listening);

      fakeSpeech.emitTranscript('next step');

      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(commands.length, 1);
      expect(commands.first, isA<CommandNext>());
      expect(controller.currentState, AudioSessionState.idle);

      await sub.cancel();
    });

    test('stops auto-listening after 3 silent timeout cycles', () async {
      await controller.startListening();

      fakeSpeech.emitError('silence');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      fakeSpeech.emitError('silence');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      fakeSpeech.emitError('silence');
      await Future<void>.delayed(const Duration(milliseconds: 30));

      expect(controller.currentState, AudioSessionState.idle);
    });

    test('pauses audio when app goes to background', () {
      controller.onAppPaused();
      expect(controller.currentState, AudioSessionState.pausedListeningForResume);

      controller.onAppResumed();
      expect(controller.currentState, AudioSessionState.idle);
    });
  });
}
