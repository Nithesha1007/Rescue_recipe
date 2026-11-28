import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../../../voice/domain/repositories/speech_repository.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/services/tts_voice_manager.dart';
import '../../domain/services/voice_session_controller.dart';
import '../../domain/utils/command_parser.dart';
import 'tts_service.dart';

class VoiceSessionControllerImpl implements VoiceSessionController {
  final TtsService _ttsService;
  final SpeechRepository _speechRepository;
  final TtsVoiceManager _ttsVoiceManager;

  final _stateController = StreamController<AudioSessionState>.broadcast();
  final _commandController = StreamController<VoiceCommand>.broadcast();

  AudioSessionState _currentState = AudioSessionState.idle;
  int _generation = 0;
  int _silentCycles = 0;
  bool _isDisposed = false;
  bool _isPausedContext = false;
  GuideLanguage _guideLanguage = GuideLanguage.english;
  StreamSubscription<SpeechRecognitionUpdate>? _speechSubscription;

  VoiceSessionControllerImpl({
    required TtsService ttsService,
    required SpeechRepository speechRepository,
    TtsVoiceManager? ttsVoiceManager,
  })  : _ttsService = ttsService,
        _speechRepository = speechRepository,
        _ttsVoiceManager = ttsVoiceManager ?? TtsVoiceManager() {
    _init();
  }

  Future<void> _init() async {
    await _ttsService.init();
    _setState(AudioSessionState.idle);
  }

  @override
  Stream<AudioSessionState> get stateStream => _stateController.stream;

  @override
  Stream<VoiceCommand> get commandStream => _commandController.stream;

  @override
  AudioSessionState get currentState => _currentState;

  @override
  GuideLanguage get guideLanguage => _guideLanguage;

  @override
  void setGuideLanguage(GuideLanguage language) {
    _guideLanguage = language;
    _ttsVoiceManager.configureTtsLanguage(language);
  }

  void _setState(AudioSessionState newState) {
    if (_isDisposed) return;
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> speak(String text) async {
    if (_isDisposed) return;

    // Invalidate ongoing speech/listening tasks
    final currentGen = ++_generation;

    // Guarantee listening is completely stopped first
    await _stopListeningInternal();

    if (_isDisposed || currentGen != _generation) return;

    _setState(AudioSessionState.speaking);

    final completer = Completer<void>();
    _ttsService.setCompletionHandler(() {
      if (!completer.isCompleted) completer.complete();
    });
    _ttsService.setErrorHandler((_) {
      if (!completer.isCompleted) completer.complete();
    });

    try {
      await _ttsService.speak(text);
      await completer.future;
    } catch (e) {
      debugPrint('TTS speak error: $e');
    }

    if (_isDisposed || currentGen != _generation) return;

    // 300ms buffer after speech finishes so mic does not pick up echo
    await Future.delayed(const Duration(milliseconds: 300));

    if (_isDisposed || currentGen != _generation) return;

    _setState(AudioSessionState.idle);
  }

  @override
  Future<void> startListening({bool isPausedContext = false}) async {
    if (_isDisposed) return;
    _isPausedContext = isPausedContext;

    final currentGen = ++_generation;

    // Stop any TTS before listening starts
    await _ttsService.stop();

    if (_isDisposed || currentGen != _generation) return;

    // Stop any existing listening
    await _stopListeningInternal();

    if (_isDisposed || currentGen != _generation) return;

    final isAvailable = await _speechRepository.initialize();
    if (!isAvailable || _isDisposed || currentGen != _generation) {
      _setState(AudioSessionState.idle);
      return;
    }

    _setState(AudioSessionState.listening);

    // Cancel old subscription if any
    await _speechSubscription?.cancel();

    // Bilingual listening: When GuideLanguage != English, alternate recognition locale between en_IN and chosen locale on silent cycles
    String? listenLocale = 'en_IN';
    if (_guideLanguage == GuideLanguage.tamil) {
      listenLocale = (_silentCycles % 2 == 0) ? 'ta_IN' : 'en_IN';
    } else if (_guideLanguage == GuideLanguage.hindi) {
      listenLocale = (_silentCycles % 2 == 0) ? 'hi_IN' : 'en_IN';
    } else if (_guideLanguage == GuideLanguage.tanglish) {
      listenLocale = (_silentCycles % 2 == 0) ? 'en_IN' : 'ta_IN';
    }

    final updateStream = _speechRepository.startListening(localeId: listenLocale);
    _speechSubscription = updateStream.listen(
      (update) {
        if (_isDisposed || currentGen != _generation) return;
        final trimmed = update.transcript.trim();
        if (trimmed.isNotEmpty) {
          _handleSpeechResult(trimmed, currentGen);
        }
      },
      onError: (err) {
        if (_isDisposed || currentGen != _generation) return;
        _handleSilenceTimeout(currentGen);
      },
    );
  }

  Future<void> _handleSpeechResult(String transcript, int gen) async {
    if (_isDisposed || gen != _generation) return;

    _silentCycles = 0;
    final cmd = CommandParser.parse(transcript, isPaused: _isPausedContext);

    await _stopListeningInternal();
    if (_isDisposed || gen != _generation) return;

    _setState(AudioSessionState.idle);
    _commandController.add(cmd);
  }

  void _handleSilenceTimeout(int gen) async {
    if (_isDisposed || gen != _generation) return;

    _silentCycles++;
    await _stopListeningInternal();

    if (_isDisposed || gen != _generation) return;

    if (_silentCycles >= 3) {
      _setState(AudioSessionState.idle);
    } else {
      startListening(isPausedContext: _isPausedContext);
    }
  }

  Future<void> _stopListeningInternal() async {
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    await _speechRepository.stop();
  }

  @override
  Future<void> stopAll() async {
    _generation++;
    await _ttsService.stop();
    await _stopListeningInternal();
    if (!_isDisposed) {
      _setState(AudioSessionState.idle);
    }
  }

  @override
  void onAppPaused() {
    _generation++;
    _ttsService.stop();
    _stopListeningInternal();
    if (!_isDisposed) {
      _setState(AudioSessionState.pausedListeningForResume);
    }
  }

  @override
  void onAppResumed() {
    if (!_isDisposed && _currentState == AudioSessionState.pausedListeningForResume) {
      _setState(AudioSessionState.idle);
    }
  }

  @override
  Future<void> dispose() async {
    _isDisposed = true;
    _generation++;
    await _ttsService.stop();
    await _stopListeningInternal();
    _setState(AudioSessionState.disposed);
    await _stateController.close();
    await _commandController.close();
  }
}
