import 'package:equatable/equatable.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../../domain/entities/voice_command.dart';
import '../../domain/services/voice_session_controller.dart';

abstract class CookingEvent extends Equatable {
  const CookingEvent();

  @override
  List<Object?> get props => [];
}

class CookingStarted extends CookingEvent {
  final Recipe recipe;
  final GuideLanguage guideLanguage;

  const CookingStarted(this.recipe, {this.guideLanguage = GuideLanguage.english});

  @override
  List<Object?> get props => [recipe, guideLanguage];
}

class GuideLanguageChanged extends CookingEvent {
  final GuideLanguage guideLanguage;

  const GuideLanguageChanged(this.guideLanguage);

  @override
  List<Object?> get props => [guideLanguage];
}

class StepNextTriggered extends CookingEvent {
  const StepNextTriggered();
}

class StepPreviousTriggered extends CookingEvent {
  const StepPreviousTriggered();
}

class StepRepeatTriggered extends CookingEvent {
  const StepRepeatTriggered();
}

class StartStepTimer extends CookingEvent {
  final int seconds;
  const StartStepTimer(this.seconds);

  @override
  List<Object?> get props => [seconds];
}

class StopStepTimer extends CookingEvent {
  const StopStepTimer();
}

class TimerTickReceived extends CookingEvent {
  final int remainingSeconds;
  const TimerTickReceived(this.remainingSeconds);

  @override
  List<Object?> get props => [remainingSeconds];
}

class StepGoToTriggered extends CookingEvent {
  final int stepNumber; // 1-based

  const StepGoToTriggered(this.stepNumber);

  @override
  List<Object?> get props => [stepNumber];
}

class CookingPausedTriggered extends CookingEvent {
  const CookingPausedTriggered();
}

class CookingResumedTriggered extends CookingEvent {
  const CookingResumedTriggered();
}

class CookingStartOverTriggered extends CookingEvent {
  const CookingStartOverTriggered();
}

class MicToggled extends CookingEvent {
  const MicToggled();
}

class VoiceCommandReceived extends CookingEvent {
  final VoiceCommand command;

  const VoiceCommandReceived(this.command);

  @override
  List<Object?> get props => [command];
}

class AudioSessionStateChanged extends CookingEvent {
  final AudioSessionState state;

  const AudioSessionStateChanged(this.state);

  @override
  List<Object?> get props => [state];
}

class AppLifecycleStatusChanged extends CookingEvent {
  final bool isInBackground;

  const AppLifecycleStatusChanged(this.isInBackground);

  @override
  List<Object?> get props => [isInBackground];
}

class FinishCookingRequested extends CookingEvent {
  const FinishCookingRequested();
}

class DeductionProposalToggled extends CookingEvent {
  final String ingredientId;

  const DeductionProposalToggled(this.ingredientId);

  @override
  List<Object?> get props => [ingredientId];
}

class ConfirmDeductionsAndFinish extends CookingEvent {
  const ConfirmDeductionsAndFinish();
}

class CookingExited extends CookingEvent {
  const CookingExited();
}
