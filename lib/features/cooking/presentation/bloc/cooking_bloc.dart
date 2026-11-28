import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../../recipes/domain/services/step_ingredient_linker.dart';
import '../../../recipes/domain/usecases/translate_recipe_content.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../../domain/entities/spoken_strings.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/services/tts_voice_manager.dart';
import '../../domain/services/voice_session_controller.dart';
import '../../domain/usecases/compute_inventory_deduction.dart';
import '../../domain/usecases/finish_cooking.dart';
import '../../domain/usecases/navigate_step.dart';
import '../../domain/usecases/start_cooking.dart';
import '../../domain/utils/answer_quantity.dart';
import 'cooking_event.dart';
import 'cooking_state.dart';

class CookingBloc extends Bloc<CookingEvent, CookingState> {
  final StartCooking _startCooking;
  final NavigateStep _navigateStep;
  final ComputeInventoryDeduction _computeInventoryDeduction;
  final FinishCooking _finishCooking;
  final VoiceSessionController _voiceController;
  final TranslateRecipeContent? _translateRecipeContent;
  final TtsVoiceManager _ttsVoiceManager;

  StreamSubscription<AudioSessionState>? _audioStateSub;
  StreamSubscription<VoiceCommand>? _commandSub;
  Timer? _countdownTimer;

  CookingBloc({
    required StartCooking startCooking,
    required NavigateStep navigateStep,
    required ComputeInventoryDeduction computeInventoryDeduction,
    required FinishCooking finishCooking,
    required VoiceSessionController voiceController,
    TranslateRecipeContent? translateRecipeContent,
    TtsVoiceManager? ttsVoiceManager,
  })  : _startCooking = startCooking,
        _navigateStep = navigateStep,
        _computeInventoryDeduction = computeInventoryDeduction,
        _finishCooking = finishCooking,
        _voiceController = voiceController,
        _translateRecipeContent = translateRecipeContent,
        _ttsVoiceManager = ttsVoiceManager ?? TtsVoiceManager(),
        super(const CookingState()) {
    on<CookingStarted>(_onCookingStarted);
    on<GuideLanguageChanged>(_onGuideLanguageChanged);
    on<StepNextTriggered>(_onStepNext);
    on<StepPreviousTriggered>(_onStepPrevious);
    on<StepRepeatTriggered>(_onStepRepeat);
    on<StepGoToTriggered>(_onStepGoTo);
    on<CookingPausedTriggered>(_onCookingPaused);
    on<CookingResumedTriggered>(_onCookingResumed);
    on<CookingStartOverTriggered>(_onCookingStartOver);
    on<MicToggled>(_onMicToggled);
    on<VoiceCommandReceived>(_onVoiceCommandReceived);
    on<AudioSessionStateChanged>(_onAudioSessionStateChanged);
    on<AppLifecycleStatusChanged>(_onAppLifecycleChanged);
    on<FinishCookingRequested>(_onFinishRequested);
    on<DeductionProposalToggled>(_onDeductionToggled);
    on<ConfirmDeductionsAndFinish>(_onConfirmDeductionsAndFinish);
    on<CookingExited>(_onCookingExited);
    on<StartStepTimer>(_onStartStepTimer);
    on<StopStepTimer>(_onStopStepTimer);
    on<TimerTickReceived>(_onTimerTickReceived);

    _audioStateSub = _voiceController.stateStream.listen(
      (state) => add(AudioSessionStateChanged(state)),
    );
    _commandSub = _voiceController.commandStream.listen(
      (cmd) => add(VoiceCommandReceived(cmd)),
    );
  }

  Future<void> _onCookingStarted(
    CookingStarted event,
    Emitter<CookingState> emit,
  ) async {
    emit(state.copyWith(
      flowStatus: CookingFlowStatus.loading,
      guideLanguage: event.guideLanguage,
    ));

    _voiceController.setGuideLanguage(event.guideLanguage);

    // Check voice data availability
    final isVoiceAvailable = await _ttsVoiceManager.isLanguageAvailable(event.guideLanguage);

    Recipe recipeToUse = event.recipe;
    if (event.guideLanguage != GuideLanguage.english && _translateRecipeContent != null) {
      recipeToUse = await _translateRecipeContent.execute(
        recipe: event.recipe,
        targetLanguage: event.guideLanguage,
      );
    }

    final result = await _startCooking(StartCookingParams(recipeToUse));
    await result.fold(
      (failure) async {
        emit(state.copyWith(
          flowStatus: CookingFlowStatus.error,
          errorMessage: failure.message,
        ));
      },
      (session) async {
        emit(state.copyWith(
          flowStatus: CookingFlowStatus.running,
          session: session,
          isSafetyPromptSpoken: true,
          isVoiceDataMissing: !isVoiceAvailable,
        ));

        final safetyLine = SpokenStrings.foodSafetyDisclaimer(event.guideLanguage);
        final firstStep = session.currentStepText;
        final stepPrefix = SpokenStrings.stepOfTotal(1, session.recipe.steps.length, event.guideLanguage);
        
        final linkedIngredients = StepIngredientLinker.linkIngredientsForStep(
          step: session.recipe.steps.first,
          recipeIngredients: session.recipe.ingredients,
        );
        final spokenIngredients = StepIngredientLinker.formatSpokenList(linkedIngredients);
        final introSpeech = spokenIngredients.isNotEmpty
            ? "$safetyLine $stepPrefix: $spokenIngredients $firstStep"
            : "$safetyLine $stepPrefix: $firstStep";

        await _voiceController.speak(introSpeech);
        if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onGuideLanguageChanged(
    GuideLanguageChanged event,
    Emitter<CookingState> emit,
  ) async {
    if (state.guideLanguage == event.guideLanguage) return;

    final session = state.session;
    if (session == null) return;

    _voiceController.setGuideLanguage(event.guideLanguage);
    final isVoiceAvailable = await _ttsVoiceManager.isLanguageAvailable(event.guideLanguage);

    Recipe translatedRecipe = session.recipe;
    if (event.guideLanguage != GuideLanguage.english && _translateRecipeContent != null) {
      translatedRecipe = await _translateRecipeContent.execute(
        recipe: session.recipe,
        targetLanguage: event.guideLanguage,
      );
    }

    final updatedSession = session.copyWith(
      recipe: translatedRecipe,
    );

    emit(state.copyWith(
      guideLanguage: event.guideLanguage,
      session: updatedSession,
      isVoiceDataMissing: !isVoiceAvailable,
    ));

    final stepNum = updatedSession.currentStepIndex + 1;
    final stepPrefix = SpokenStrings.stepOfTotal(stepNum, updatedSession.recipe.steps.length, event.guideLanguage);
    await _voiceController.speak("$stepPrefix: ${updatedSession.currentStepText}");
    if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
      _voiceController.startListening();
    }
  }

  Future<void> _onStepNext(
    StepNextTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    if (session.isLastStep) {
      add(const FinishCookingRequested());
      return;
    }

    final result = await _navigateStep(NavigateStepParams(
      session: session,
      direction: StepNavigationDirection.next,
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (updatedSession) async {
        emit(state.copyWith(
          session: updatedSession,
          spokenFeedback: null,
        ));
        final stepNum = updatedSession.currentStepIndex + 1;
        final currentStep = updatedSession.recipe.steps[updatedSession.currentStepIndex];
        final linkedIngredients = StepIngredientLinker.linkIngredientsForStep(
          step: currentStep,
          recipeIngredients: updatedSession.recipe.ingredients,
        );
        final spokenIngredients = StepIngredientLinker.formatSpokenList(linkedIngredients);
        final stepPrefix = SpokenStrings.stepOfTotal(
          stepNum,
          updatedSession.recipe.steps.length,
          state.guideLanguage,
        );
        final text = spokenIngredients.isNotEmpty
            ? "$stepPrefix: $spokenIngredients ${updatedSession.currentStepText}"
            : "$stepPrefix: ${updatedSession.currentStepText}";
        await _voiceController.speak(text);
        if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onStepPrevious(
    StepPreviousTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null || session.isFirstStep) {
      final firstMsg = SpokenStrings.firstStep(state.guideLanguage);
      await _voiceController.speak(firstMsg);
      return;
    }

    final result = await _navigateStep(NavigateStepParams(
      session: session,
      direction: StepNavigationDirection.previous,
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (updatedSession) async {
        emit(state.copyWith(
          session: updatedSession,
          spokenFeedback: null,
        ));
        final stepNum = updatedSession.currentStepIndex + 1;
        final currentStep = updatedSession.recipe.steps[updatedSession.currentStepIndex];
        final linkedIngredients = StepIngredientLinker.linkIngredientsForStep(
          step: currentStep,
          recipeIngredients: updatedSession.recipe.ingredients,
        );
        final spokenIngredients = StepIngredientLinker.formatSpokenList(linkedIngredients);
        final stepPrefix = SpokenStrings.stepOfTotal(
          stepNum,
          updatedSession.recipe.steps.length,
          state.guideLanguage,
        );
        final text = spokenIngredients.isNotEmpty
            ? "$stepPrefix: $spokenIngredients ${updatedSession.currentStepText}"
            : "$stepPrefix: ${updatedSession.currentStepText}";
        await _voiceController.speak(text);
        if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onStepRepeat(
    StepRepeatTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    final stepNum = session.currentStepIndex + 1;
    final stepPrefix = SpokenStrings.stepOfTotal(
      stepNum,
      session.recipe.steps.length,
      state.guideLanguage,
    );
    final text = "$stepPrefix: ${session.currentStepText}";
    await _voiceController.speak(text);
    if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
      _voiceController.startListening();
    }
  }

  Future<void> _onStepGoTo(
    StepGoToTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    final result = await _navigateStep(NavigateStepParams(
      session: session,
      direction: StepNavigationDirection.goToStep,
      targetStep: event.stepNumber,
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (updatedSession) async {
        emit(state.copyWith(
          session: updatedSession,
          spokenFeedback: null,
        ));
        final stepNum = updatedSession.currentStepIndex + 1;
        final currentStep = updatedSession.recipe.steps[updatedSession.currentStepIndex];
        final linkedIngredients = StepIngredientLinker.linkIngredientsForStep(
          step: currentStep,
          recipeIngredients: updatedSession.recipe.ingredients,
        );
        final spokenIngredients = StepIngredientLinker.formatSpokenList(linkedIngredients);
        final stepPrefix = SpokenStrings.stepOfTotal(
          stepNum,
          updatedSession.recipe.steps.length,
          state.guideLanguage,
        );
        final text = spokenIngredients.isNotEmpty
            ? "$stepPrefix: $spokenIngredients ${updatedSession.currentStepText}"
            : "$stepPrefix: ${updatedSession.currentStepText}";
        await _voiceController.speak(text);
        if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onCookingPaused(
    CookingPausedTriggered event,
    Emitter<CookingState> emit,
  ) async {
    await _voiceController.stopAll();
    emit(state.copyWith(flowStatus: CookingFlowStatus.paused));
    final msg = SpokenStrings.paused(state.guideLanguage);
    await _voiceController.speak(msg);
  }

  Future<void> _onCookingResumed(
    CookingResumedTriggered event,
    Emitter<CookingState> emit,
  ) async {
    emit(state.copyWith(flowStatus: CookingFlowStatus.running));
    final session = state.session;
    if (session != null) {
      final stepNum = session.currentStepIndex + 1;
      final resumedMsg = SpokenStrings.resumed(state.guideLanguage);
      final stepPrefix = SpokenStrings.stepOfTotal(
        stepNum,
        session.recipe.steps.length,
        state.guideLanguage,
      );
      await _voiceController.speak("$resumedMsg $stepPrefix: ${session.currentStepText}");
      if (!isClosed) {
        _voiceController.startListening();
      }
    }
  }

  Future<void> _onCookingStartOver(
    CookingStartOverTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    final result = await _navigateStep(NavigateStepParams(
      session: session,
      direction: StepNavigationDirection.startOver,
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(errorMessage: failure.message)),
      (updatedSession) async {
        emit(state.copyWith(
          session: updatedSession,
          flowStatus: CookingFlowStatus.running,
        ));
        final startOverMsg = SpokenStrings.startedOver(state.guideLanguage);
        final stepPrefix = SpokenStrings.stepOfTotal(
          1,
          updatedSession.recipe.steps.length,
          state.guideLanguage,
        );
        await _voiceController.speak("$startOverMsg $stepPrefix: ${updatedSession.currentStepText}");
        if (!isClosed) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onMicToggled(
    MicToggled event,
    Emitter<CookingState> emit,
  ) async {
    if (state.audioState == AudioSessionState.listening) {
      await _voiceController.stopAll();
    } else {
      await _voiceController.startListening(
        isPausedContext: state.flowStatus == CookingFlowStatus.paused,
      );
    }
  }

  Future<void> _onVoiceCommandReceived(
    VoiceCommandReceived event,
    Emitter<CookingState> emit,
  ) async {
    final cmd = event.command;

    switch (cmd) {
      case CommandNext():
        add(const StepNextTriggered());
        break;
      case CommandPrevious():
        add(const StepPreviousTriggered());
        break;
      case CommandRepeat():
        add(const StepRepeatTriggered());
        break;
      case CommandPause():
        add(const CookingPausedTriggered());
        break;
      case CommandResume():
        add(const CookingResumedTriggered());
        break;
      case CommandStartOver():
        add(const CookingStartOverTriggered());
        break;
      case CommandGoToStep(:final stepNumber):
        add(StepGoToTriggered(stepNumber));
        break;
      case CommandAskQuantity(:final ingredientName):
        final session = state.session;
        if (session != null) {
          final answer = AnswerQuantity.answer(
            recipe: session.recipe,
            query: ingredientName,
          );
          emit(state.copyWith(spokenFeedback: answer));
          await _voiceController.speak(answer);
          if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
            _voiceController.startListening();
          }
        }
        break;
      case CommandListIngredients():
        final session = state.session;
        if (session != null) {
          final items = session.recipe.ingredients.map((i) => i.name).join(', ');
          final answer = "This recipe uses: $items.";
          emit(state.copyWith(spokenFeedback: answer));
          await _voiceController.speak(answer);
          if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
            _voiceController.startListening();
          }
        }
        break;
      case CommandTip():
        final session = state.session;
        if (session != null) {
          final currentStep = session.recipe.steps[session.currentStepIndex];
          final stepTip = currentStep.tip;
          final String tipMessage;
          if (stepTip != null && stepTip.isNotEmpty) {
            tipMessage = stepTip;
          } else if (session.recipe.tips.isNotEmpty) {
            tipMessage = session.recipe.tips.first;
          } else {
            tipMessage = SpokenStrings.noTipAvailable(state.guideLanguage);
          }
          emit(state.copyWith(spokenFeedback: tipMessage));
          await _voiceController.speak(tipMessage);
          if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
            _voiceController.startListening();
          }
        }
        break;
      case CommandStartTimer(:final minutes):
        final stepMinutes = minutes ??
            state.session?.recipe.steps[state.session!.currentStepIndex].minutes ??
            1;
        add(StartStepTimer(stepMinutes * 60));
        break;
      case CommandStopTimer():
        add(const StopStepTimer());
        break;
      case CommandFinish():
        add(const FinishCookingRequested());
        break;
      case CommandExit():
        add(const CookingExited());
        break;
      case CommandUnknown(:final rawText):
        if (rawText.isNotEmpty) {
          emit(state.copyWith(
              spokenFeedback: "Sorry, I didn't catch that. Say next, back, repeat, or pause."));
          await _voiceController.speak("Sorry, I didn't catch that.");
          if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
            _voiceController.startListening();
          }
        }
        break;
    }
  }

  void _onAudioSessionStateChanged(
    AudioSessionStateChanged event,
    Emitter<CookingState> emit,
  ) {
    emit(state.copyWith(audioState: event.state));
  }

  void _onAppLifecycleChanged(
    AppLifecycleStatusChanged event,
    Emitter<CookingState> emit,
  ) {
    if (event.isInBackground) {
      _voiceController.onAppPaused();
    } else {
      _voiceController.onAppResumed();
    }
  }

  Future<void> _onFinishRequested(
    FinishCookingRequested event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    await _voiceController.stopAll();

    final deductionResult = await _computeInventoryDeduction(
      ComputeInventoryDeductionParams(
        recipe: session.recipe,
        today: DateTime.now(),
      ),
    );

    deductionResult.fold(
      (failure) => emit(state.copyWith(errorMessage: failure.message)),
      (proposals) {
        emit(state.copyWith(
          flowStatus: CookingFlowStatus.confirmingFinish,
          deductionProposals: proposals,
        ));
      },
    );
  }

  void _onDeductionToggled(
    DeductionProposalToggled event,
    Emitter<CookingState> emit,
  ) {
    final updated = state.deductionProposals.map((p) {
      if (p.ingredientId == event.ingredientId) {
        return p.copyWith(isConfirmed: !p.isConfirmed);
      }
      return p;
    }).toList();

    emit(state.copyWith(deductionProposals: updated));
  }

  Future<void> _onConfirmDeductionsAndFinish(
    ConfirmDeductionsAndFinish event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    emit(state.copyWith(flowStatus: CookingFlowStatus.loading));

    final result = await _finishCooking(FinishCookingParams(
      recipeId: session.recipe.id,
      confirmedProposals: state.deductionProposals,
      timestamp: DateTime.now(),
    ));

    await result.fold(
      (failure) async => emit(state.copyWith(
        flowStatus: CookingFlowStatus.error,
        errorMessage: failure.message,
      )),
      (finishSummary) async {
        emit(state.copyWith(
          flowStatus: CookingFlowStatus.finished,
          rescuedCount: finishSummary.rescuedCount,
          totalDeducted: finishSummary.totalDeducted,
        ));
        final completedMsg = SpokenStrings.cookingCompleted(state.guideLanguage);
        await _voiceController.speak(completedMsg);
      },
    );
  }

  void _onStartStepTimer(
    StartStepTimer event,
    Emitter<CookingState> emit,
  ) {
    _countdownTimer?.cancel();
    final minutes = (event.seconds / 60).round();
    final timerMsg = SpokenStrings.timerStarted(minutes > 0 ? minutes : 1, state.guideLanguage);
    emit(state.copyWith(
      timerSecondsRemaining: () => event.seconds,
      isTimerActive: true,
      spokenFeedback: timerMsg,
    ));

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final current = state.timerSecondsRemaining ?? 0;
      if (current <= 1) {
        timer.cancel();
        add(const TimerTickReceived(0));
      } else {
        add(TimerTickReceived(current - 1));
      }
    });
  }

  void _onStopStepTimer(
    StopStepTimer event,
    Emitter<CookingState> emit,
  ) {
    _countdownTimer?.cancel();
    final stoppedMsg = SpokenStrings.timerStopped(state.guideLanguage);
    emit(state.copyWith(
      timerSecondsRemaining: () => null,
      isTimerActive: false,
      spokenFeedback: stoppedMsg,
    ));
  }

  Future<void> _onTimerTickReceived(
    TimerTickReceived event,
    Emitter<CookingState> emit,
  ) async {
    if (event.remainingSeconds <= 0) {
      _countdownTimer?.cancel();
      final doneMsg = SpokenStrings.timerDone(state.guideLanguage);
      emit(state.copyWith(
        timerSecondsRemaining: () => 0,
        isTimerActive: false,
        spokenFeedback: doneMsg,
      ));
      await _voiceController.speak(doneMsg);
      if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
        _voiceController.startListening();
      }
    } else {
      emit(state.copyWith(timerSecondsRemaining: () => event.remainingSeconds));
    }
  }

  Future<void> _onCookingExited(
    CookingExited event,
    Emitter<CookingState> emit,
  ) async {
    await _voiceController.stopAll();
    emit(state.copyWith(flowStatus: CookingFlowStatus.finished));
  }

  @override
  Future<void> close() {
    _countdownTimer?.cancel();
    _audioStateSub?.cancel();
    _commandSub?.cancel();
    _voiceController.dispose();
    return super.close();
  }
}
