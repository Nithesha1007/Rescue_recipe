import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../domain/entities/extracted_ingredient.dart';
import '../../domain/repositories/ingredient_extraction_repository.dart';
import '../../domain/repositories/speech_repository.dart';
import '../../domain/services/audio_recorder_service.dart';
import '../../domain/usecases/apply_voice_correction.dart';
import '../../domain/usecases/confirm_ingredients.dart';
import '../../domain/usecases/extract_ingredients_from_audio.dart';
import '../../domain/usecases/extract_ingredients_from_transcript.dart';

import '../../domain/utils/transcript_accumulator.dart';
import 'voice_input_event.dart';
import 'voice_input_state.dart';

class VoiceInputBloc extends Bloc<VoiceInputEvent, VoiceInputState> {
  VoiceInputBloc({
    required SpeechRepository speechRepository,
    required ExtractIngredientsFromTranscript extractIngredients,
    required ApplyVoiceCorrection applyVoiceCorrection,
    required ConfirmIngredients confirmIngredients,
    AudioRecorderService? audioRecorderService,
    ExtractIngredientsFromAudio? extractIngredientsFromAudio,
  })  : _speechRepository = speechRepository,
        _extractIngredients = extractIngredients,
        _applyVoiceCorrection = applyVoiceCorrection,
        _confirmIngredients = confirmIngredients,
        _audioRecorderService = audioRecorderService ?? AudioRecorderServiceImpl(),
        _extractIngredientsFromAudio = extractIngredientsFromAudio,
        super(const VoiceInputIdle()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeechUpdateReceived>(_onSpeechUpdateReceived);
    on<AudioRecordingAmplitudeReceived>(_onAudioRecordingAmplitudeReceived);
    on<AudioRecordingFinished>(_onAudioRecordingFinished);
    on<TranscriptChanged>(_onTranscriptChanged);
    on<SubmitTranscript>(_onSubmitTranscript);
    on<RemoveExtractedItem>(_onRemoveExtractedItem);
    on<EditExtractedItem>(_onEditExtractedItem);
    on<ApplyCorrectionText>(_onApplyCorrectionText);
    on<ConfirmAllIngredients>(_onConfirmAllIngredients);
    on<CancelVoiceInput>(_onCancelVoiceInput);
    on<ResetToIdle>(_onResetToIdle);
  }

  final SpeechRepository _speechRepository;
  final ExtractIngredientsFromTranscript _extractIngredients;
  final ApplyVoiceCorrection _applyVoiceCorrection;
  final ConfirmIngredients _confirmIngredients;
  final AudioRecorderService _audioRecorderService;
  final ExtractIngredientsFromAudio? _extractIngredientsFromAudio;

  final TranscriptAccumulator _accumulator = TranscriptAccumulator();
  StreamSubscription<SpeechRecognitionUpdate>? _speechSubscription;
  StreamSubscription<double>? _amplitudeSubscription;
  bool _isSpeakingOutput = false;
  bool _userExplicitlyStopped = false;
  String? _selectedLocale;
  bool _isAutoAiMode = false;

  TranscriptAccumulator get accumulator => _accumulator;
  bool get isAutoAiMode => _isAutoAiMode;

  void setLocale(String? localeId) {
    _selectedLocale = localeId;
  }

  void setSpeakingOutput(bool isSpeaking) {
    _isSpeakingOutput = isSpeaking;
    if (isSpeaking) {
      if (_speechRepository.isListening || _audioRecorderService.isRecording) {
        add(const StopListening());
      }
    }
  }

  Future<void> _onStartListening(
    StartListening event,
    Emitter<VoiceInputState> emit,
  ) async {
    if (_isSpeakingOutput) return;

    if (event.localeId != null) {
      _selectedLocale = event.localeId;
    }
    _isAutoAiMode = event.isAutoMode;
    _userExplicitlyStopped = false;
    _accumulator.reset();

    emit(const VoiceInputRequestingPermission());

    // Auto (AI) Mode: record audio clip with AudioRecorderService
    if (_isAutoAiMode && _extractIngredientsFromAudio != null) {
      final hasPerm = await _audioRecorderService.hasPermission();
      if (!hasPerm) {
        emit(const VoiceInputPermissionDenied(isPermanent: false));
        return;
      }

      // Ensure speech recognizer is stopped (never run both simultaneously)
      if (_speechRepository.isListening) {
        await _speechRepository.stop();
      }

      try {
        await _audioRecorderService.startRecording();
        emit(const VoiceInputListening(transcript: 'Listening (Auto AI)...', soundLevel: 0.0));

        _amplitudeSubscription?.cancel();
        _amplitudeSubscription = _audioRecorderService.amplitudeStream.listen((amp) {
          add(AudioRecordingAmplitudeReceived(amp));
        });
        return;
      } catch (e) {
        DebugLogger.speech('Auto (AI) recorder failed: $e, falling back to Live mode');
        _isAutoAiMode = false;
      }
    }

    // Live Mode: speech_to_text continuous accumulator
    final status = await _speechRepository.requestPermission();
    if (status == SpeechPermissionStatus.denied) {
      emit(const VoiceInputPermissionDenied(isPermanent: false));
      return;
    } else if (status == SpeechPermissionStatus.permanentlyDenied ||
        status == SpeechPermissionStatus.restricted) {
      emit(const VoiceInputPermissionDenied(isPermanent: true));
      return;
    }

    final initialized = await _speechRepository.initialize();
    if (!initialized) {
      emit(const VoiceInputError(
        message: 'Speech recognition service is not available on this device.',
        transcript: '',
      ));
      return;
    }

    emit(const VoiceInputListening(transcript: '', soundLevel: 0.0));
    _startContinuousSession(emit);
  }

  void _startContinuousSession(Emitter<VoiceInputState>? emitter) {
    if (_userExplicitlyStopped || _isSpeakingOutput || _isAutoAiMode) return;

    final gen = _accumulator.startNewSession();
    DebugLogger.speech(
        'Starting speech session generation: $gen (locale: $_selectedLocale)');

    _speechSubscription?.cancel();
    _speechSubscription =
        _speechRepository.startListening(localeId: _selectedLocale).listen(
              (update) {
                _accumulator.onSpeechResult(
                  recognizedWords: update.transcript,
                  isFinal: update.isFinal,
                  generation: gen,
                );
                add(SpeechUpdateReceived(
                  transcript: _accumulator.fullTranscript,
                  soundLevel: update.soundLevel,
                  isFinal: update.isFinal,
                ));
              },
              onDone: () => _handleSessionEnded(gen),
              onError: (err) {
                DebugLogger.speech('Session error: $err');
                _handleSessionEnded(gen);
              },
            );
  }

  void _handleSessionEnded(int generation) {
    if (_userExplicitlyStopped || _isAutoAiMode) return;

    final shouldRestart = _accumulator.onEngineStopped(generation: generation);
    DebugLogger.speech(
      'Session $generation ended. Should restart: $shouldRestart '
      '(silent restarts: ${_accumulator.consecutiveSilentRestarts})',
    );

    if (shouldRestart) {
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_userExplicitlyStopped && state is VoiceInputListening) {
          _startContinuousSession(null);
        }
      });
    } else {
      add(const StopListening());
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceInputState> emit,
  ) async {
    _userExplicitlyStopped = true;

    if (_isAutoAiMode && _audioRecorderService.isRecording) {
      await _amplitudeSubscription?.cancel();
      _amplitudeSubscription = null;
      final recordedPath = await _audioRecorderService.stopRecording();
      if (recordedPath != null) {
        add(AudioRecordingFinished(recordedPath));
        return;
      }
    }

    await _speechSubscription?.cancel();
    _speechSubscription = null;
    await _speechRepository.stop();

    final text = _accumulator.fullTranscript;
    DebugLogger.speech('Final speech transcript: "$text"');
    if (text.trim().isEmpty) {
      emit(const VoiceInputIdle());
    } else {
      emit(VoiceInputEditing(transcript: text));
    }
  }

  void _onAudioRecordingAmplitudeReceived(
    AudioRecordingAmplitudeReceived event,
    Emitter<VoiceInputState> emit,
  ) {
    if (state is VoiceInputListening && _isAutoAiMode) {
      emit(VoiceInputListening(
        transcript: 'Listening (Auto AI)...',
        soundLevel: event.soundLevel,
      ));
    }
  }

  Future<void> _onAudioRecordingFinished(
    AudioRecordingFinished event,
    Emitter<VoiceInputState> emit,
  ) async {
    emit(const VoiceInputExtracting(transcript: 'Analyzing voice clip...'));

    if (_extractIngredientsFromAudio != null) {
      final result = await _extractIngredientsFromAudio(
        AudioExtractParams(audioFilePath: event.filePath),
      );

      result.fold(
        (failure) {
          DebugLogger.speech('Audio extraction failure: ${failure.message}');
          emit(VoiceInputError(
            message: failure.message,
            transcript: '',
          ));
        },
        (audioResult) {
          DebugLogger.speech(
            'Auto AI extracted ${audioResult.ingredients.length} items. Lang: ${audioResult.detectedLanguage}',
          );
          _accumulator.onUserManualEdit(audioResult.transcript);
          emit(VoiceInputConfirming(
            items: audioResult.ingredients,
            source: ExtractionSource.gemini,
            originalTranscript: audioResult.transcript,
          ));
        },
      );
    } else {
      emit(const VoiceInputError(
        message: 'Audio extractor not configured.',
        transcript: '',
      ));
    }
  }

  void _onSpeechUpdateReceived(
    SpeechUpdateReceived event,
    Emitter<VoiceInputState> emit,
  ) {
    if (state is VoiceInputListening && !_isAutoAiMode) {
      emit(VoiceInputListening(
        transcript: event.transcript,
        soundLevel: event.soundLevel,
      ));
    }
  }

  void _onTranscriptChanged(
    TranscriptChanged event,
    Emitter<VoiceInputState> emit,
  ) {
    _accumulator.onUserManualEdit(event.transcript);
    if (state is VoiceInputEditing) {
      emit(VoiceInputEditing(transcript: event.transcript));
    }
  }

  Future<void> _onSubmitTranscript(
    SubmitTranscript event,
    Emitter<VoiceInputState> emit,
  ) async {
    final transcript = _accumulator.fullTranscript.isNotEmpty
        ? _accumulator.fullTranscript
        : (state is VoiceInputEditing
            ? (state as VoiceInputEditing).transcript
            : '');
    final cleanTranscript = transcript.trim();
    if (cleanTranscript.isEmpty) {
      emit(const VoiceInputIdle());
      return;
    }

    emit(VoiceInputExtracting(transcript: cleanTranscript));
    final result =
        await _extractIngredients(ExtractParams(transcript: cleanTranscript));

    result.fold(
      (failure) {
        DebugLogger.speech('Extraction failure: ${failure.message}');
        emit(VoiceInputError(
          message: failure.message,
          transcript: cleanTranscript,
        ));
      },
      (extraction) {
        DebugLogger.speech('Extracted ${extraction.items.length} ingredients');
        emit(VoiceInputConfirming(
          items: extraction.items,
          source: extraction.source,
          originalTranscript: cleanTranscript,
        ));
      },
    );
  }

  void _onRemoveExtractedItem(
    RemoveExtractedItem event,
    Emitter<VoiceInputState> emit,
  ) {
    final s = state;
    if (s is VoiceInputConfirming) {
      final updated = List<ExtractedIngredient>.from(s.items)
        ..removeAt(event.index);
      emit(VoiceInputConfirming(
        items: updated,
        source: s.source,
        originalTranscript: s.originalTranscript,
      ));
    }
  }

  void _onEditExtractedItem(
    EditExtractedItem event,
    Emitter<VoiceInputState> emit,
  ) {
    final s = state;
    if (s is VoiceInputConfirming) {
      final updated = List<ExtractedIngredient>.from(s.items);
      if (event.index >= 0 && event.index < updated.length) {
        updated[event.index] = event.updatedItem;
        emit(VoiceInputConfirming(
          items: updated,
          source: s.source,
          originalTranscript: s.originalTranscript,
        ));
      }
    }
  }

  Future<void> _onApplyCorrectionText(
    ApplyCorrectionText event,
    Emitter<VoiceInputState> emit,
  ) async {
    final s = state;
    if (s is! VoiceInputConfirming) return;

    final correction = event.correction.trim();
    if (correction.isEmpty) return;

    emit(VoiceInputExtracting(transcript: s.originalTranscript));
    final updatedItems = _applyVoiceCorrection(ApplyVoiceCorrectionParams(
      currentItems: s.items,
      correctionPhrase: correction,
    ));

    emit(VoiceInputConfirming(
      items: updatedItems,
      source: s.source,
      originalTranscript: '${s.originalTranscript} + correction: $correction',
    ));
  }

  Future<void> _onConfirmAllIngredients(
    ConfirmAllIngredients event,
    Emitter<VoiceInputState> emit,
  ) async {
    final s = state;
    if (s is! VoiceInputConfirming) return;

    if (s.items.isEmpty) {
      emit(const VoiceInputIdle());
      return;
    }

    emit(const VoiceInputSaving());
    final result = await _confirmIngredients(ConfirmIngredientsParams(s.items));

    result.fold(
      (failure) {
        emit(VoiceInputError(
          message: failure.message,
          transcript: s.originalTranscript,
        ));
      },
      (_) {
        _accumulator.reset();
        emit(VoiceInputSaved(count: s.items.length));
      },
    );
  }

  void _onCancelVoiceInput(
    CancelVoiceInput event,
    Emitter<VoiceInputState> emit,
  ) {
    _userExplicitlyStopped = true;
    _speechSubscription?.cancel();
    _speechSubscription = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _speechRepository.stop();
    _audioRecorderService.cancel();
    _accumulator.reset();
    emit(const VoiceInputIdle());
  }

  void _onResetToIdle(
    ResetToIdle event,
    Emitter<VoiceInputState> emit,
  ) {
    _userExplicitlyStopped = true;
    _speechSubscription?.cancel();
    _speechSubscription = null;
    _amplitudeSubscription?.cancel();
    _amplitudeSubscription = null;
    _accumulator.reset();
    emit(const VoiceInputIdle());
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    _amplitudeSubscription?.cancel();
    _audioRecorderService.dispose();
    return super.close();
  }
}
