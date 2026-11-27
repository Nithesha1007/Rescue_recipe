import 'dart:async';
import 'package:flutter/foundation.dart';
import '../../../voice/domain/repositories/speech_repository.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/services/voice_session_controller.dart';
import '../../domain/utils/command_parser.dart';
import 'tts_service.dart';

class VoiceSessionControllerImpl implements VoiceSessionController {
  final TtsService _ttsService;
  final SpeechRepository _speechRepository;

  final _stateController = StreamController<AudioSessionState>.broadcast();
  final _commandController = StreamController<VoiceCommand>.broadcast();

  AudioSessionState _currentState = AudioSessionState.idle;
  int _generation = 0;
  int _silentCycles = 0;
  bool _isDisposed = false;
  bool _isPausedContext = false;
  StreamSubscription<SpeechRecognitionUpdate>? _speechSubscription;

  VoiceSessionControllerImpl({
    required TtsService ttsService,
    required SpeechRepository speechRepository,
  })  : _ttsService = ttsService,
        _speechRepository = speechRepository {
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

  void _setState(AudioSessionState newState) {
    if (_isDisposed) return;
    _currentState = newState;
    _stateController.add(newState);
  }

  @override
  Future<void> speak(String text) async {
    if (_isDisposed) return;

    // 1. Invalidate ongoing speech/listening tasks
    final currentGen = ++_generation;

    // 2. Guarantee listening is completely stopped first
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

    // 300ms buffer after speech finishes so the mic does not hear room echo or TTS tail
    await Future.delayed(const Duration(milliseconds: 300));

    if (_isDisposed || currentGen != _generation) return;

    // Transition back to idle
    _setState(AudioSessionState.idle);
  }

  @override
  Future<void> startListening({bool isPausedContext = false}) async {
    if (_isDisposed) return;
    _isPausedContext = isPausedContext;

    final currentGen = ++_generation;

    // 1. Stop any TTS before listening starts
    await _ttsService.stop();

    if (_isDisposed || currentGen != _generation) return;

    // 2. Stop any existing listening
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

    final updateStream = _speechRepository.startListening();
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

    // Reset silent cycles on speech input
    _silentCycles = 0;

    // Parse command
    final cmd = CommandParser.parse(transcript, isPaused: _isPausedContext);

    // Stop listening before processing
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
      // Stop auto-listening after 3 silent cycles to save battery
      _setState(AudioSessionState.idle);
    } else {
      // Try listening one more round
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
