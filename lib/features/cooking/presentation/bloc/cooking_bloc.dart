import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/voice_command.dart';
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

  StreamSubscription<AudioSessionState>? _audioStateSub;
  StreamSubscription<VoiceCommand>? _commandSub;

  CookingBloc({
    required StartCooking startCooking,
    required NavigateStep navigateStep,
    required ComputeInventoryDeduction computeInventoryDeduction,
    required FinishCooking finishCooking,
    required VoiceSessionController voiceController,
  })  : _startCooking = startCooking,
        _navigateStep = navigateStep,
        _computeInventoryDeduction = computeInventoryDeduction,
        _finishCooking = finishCooking,
        _voiceController = voiceController,
        super(const CookingState()) {
    on<CookingStarted>(_onCookingStarted);
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

    // Listen to voice controller streams
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
    emit(state.copyWith(flowStatus: CookingFlowStatus.loading));

    final result = await _startCooking(StartCookingParams(event.recipe));
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
        ));

        // Read safety line once and read step 1
        const safetyMessage =
            "Before we start: if any ingredient looks or smells spoiled, don't use it.";
        final firstStep = session.currentStepText;
        final introSpeech = "$safetyMessage Step 1: $firstStep";

        await _voiceController.speak(introSpeech);
        if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
          _voiceController.startListening();
        }
      },
    );
  }

  Future<void> _onStepNext(
    StepNextTriggered event,
    Emitter<CookingState> emit,
  ) async {
    final session = state.session;
    if (session == null) return;

    if (session.isLastStep) {
      // Last step: prompt completion
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
        final text = "Step $stepNum: ${updatedSession.currentStepText}";
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
    if (session == null || session.isFirstStep) return;

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
        final text = "Step $stepNum: ${updatedSession.currentStepText}";
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
    final text = "Step $stepNum: ${session.currentStepText}";
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
        final text = "Step $stepNum: ${updatedSession.currentStepText}";
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
    await _voiceController.speak("Paused. Say resume when you're ready.");
  }

  Future<void> _onCookingResumed(
    CookingResumedTriggered event,
    Emitter<CookingState> emit,
  ) async {
    emit(state.copyWith(flowStatus: CookingFlowStatus.running));
    final session = state.session;
    if (session != null) {
      final stepNum = session.currentStepIndex + 1;
      await _voiceController
          .speak("Resuming step $stepNum: ${session.currentStepText}");
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
        await _voiceController
            .speak("Starting over. Step 1: ${updatedSession.currentStepText}");
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
          final items =
              session.recipe.ingredients.map((i) => i.name).join(', ');
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
            tipMessage = "Here's a tip: $stepTip";
          } else if (session.recipe.tips.isNotEmpty) {
            tipMessage = "Chef's tip: ${session.recipe.tips.first}";
          } else {
            tipMessage =
                "No specific tip for this step. Take your time and keep cooking!";
          }
          emit(state.copyWith(spokenFeedback: tipMessage));
          await _voiceController.speak(tipMessage);
          if (!isClosed && state.flowStatus == CookingFlowStatus.running) {
            _voiceController.startListening();
          }
        }
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
              spokenFeedback:
                  "Sorry, I didn't catch that. Say next, back, repeat, or pause."));
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
        await _voiceController.speak(
          "Great job! You rescued ${finishSummary.rescuedCount} items and completed ${session.recipe.title}.",
        );
      },
    );
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
    _audioStateSub?.cancel();
    _commandSub?.cancel();
    _voiceController.dispose();
    return super.close();
  }
}
