import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/debug_logger.dart';
import '../../domain/entities/extracted_ingredient.dart';
import '../../domain/repositories/speech_repository.dart';
import '../../domain/usecases/apply_voice_correction.dart';
import '../../domain/usecases/confirm_ingredients.dart';
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
  })  : _speechRepository = speechRepository,
        _extractIngredients = extractIngredients,
        _applyVoiceCorrection = applyVoiceCorrection,
        _confirmIngredients = confirmIngredients,
        super(const VoiceInputIdle()) {
    on<StartListening>(_onStartListening);
    on<StopListening>(_onStopListening);
    on<SpeechUpdateReceived>(_onSpeechUpdateReceived);
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

  final TranscriptAccumulator _accumulator = TranscriptAccumulator();
  StreamSubscription<SpeechRecognitionUpdate>? _speechSubscription;
  bool _isSpeakingOutput = false;
  bool _userExplicitlyStopped = false;
  String? _selectedLocale;

  TranscriptAccumulator get accumulator => _accumulator;

  void setLocale(String? localeId) {
    _selectedLocale = localeId;
  }

  void setSpeakingOutput(bool isSpeaking) {
    _isSpeakingOutput = isSpeaking;
    if (isSpeaking && _speechRepository.isListening) {
      add(const StopListening());
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

    _userExplicitlyStopped = false;
    _accumulator.reset();

    emit(const VoiceInputRequestingPermission());
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
    if (_userExplicitlyStopped || _isSpeakingOutput) return;

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
    if (_userExplicitlyStopped) return;

    final shouldRestart = _accumulator.onEngineStopped(generation: generation);
    DebugLogger.speech(
      'Session $generation ended. Should restart: $shouldRestart '
      '(silent restarts: ${_accumulator.consecutiveSilentRestarts})',
    );

    if (shouldRestart) {
      // Short debounce before continuous restart to let platform audio thread reset
      Future.delayed(const Duration(milliseconds: 300), () {
        if (!_userExplicitlyStopped && state is VoiceInputListening) {
          _startContinuousSession(null);
        }
      });
    } else {
      // 3 silent restarts exceeded -> automatically finalize listening
      add(const StopListening());
    }
  }

  Future<void> _onStopListening(
    StopListening event,
    Emitter<VoiceInputState> emit,
  ) async {
    _userExplicitlyStopped = true;
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

  void _onSpeechUpdateReceived(
    SpeechUpdateReceived event,
    Emitter<VoiceInputState> emit,
  ) {
    if (state is VoiceInputListening) {
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

  void _onApplyCorrectionText(
    ApplyCorrectionText event,
    Emitter<VoiceInputState> emit,
  ) {
    final s = state;
    if (s is VoiceInputConfirming) {
      final updated = _applyVoiceCorrection(
        ApplyVoiceCorrectionParams(
          currentItems: s.items,
          correctionPhrase: event.correctionText,
        ),
      );
      emit(VoiceInputConfirming(
        items: updated,
        source: s.source,
        originalTranscript: s.originalTranscript,
      ));
    }
  }

  Future<void> _onConfirmAllIngredients(
    ConfirmAllIngredients event,
    Emitter<VoiceInputState> emit,
  ) async {
    final s = state;
    if (s is VoiceInputConfirming) {
      emit(const VoiceInputSaving());
      final count = s.items.length;
      final result =
          await _confirmIngredients(ConfirmIngredientsParams(s.items));
      result.fold(
        (failure) => emit(VoiceInputError(
          message: failure.message,
          transcript: s.originalTranscript,
        )),
        (_) => emit(VoiceInputSaved(count: count)),
      );
    }
  }

  Future<void> _onCancelVoiceInput(
    CancelVoiceInput event,
    Emitter<VoiceInputState> emit,
  ) async {
    _userExplicitlyStopped = true;
    await _speechSubscription?.cancel();
    _speechSubscription = null;
    await _speechRepository.cancel();
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
    _accumulator.reset();
    emit(const VoiceInputIdle());
  }

  @override
  Future<void> close() {
    _speechSubscription?.cancel();
    return super.close();
  }
}
