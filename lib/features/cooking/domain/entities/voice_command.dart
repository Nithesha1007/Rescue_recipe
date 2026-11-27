import 'package:equatable/equatable.dart';

sealed class VoiceCommand extends Equatable {
  const VoiceCommand();

  @override
  List<Object?> get props => [];
}

class CommandNext extends VoiceCommand {
  const CommandNext();
}

class CommandPrevious extends VoiceCommand {
  const CommandPrevious();
}

class CommandRepeat extends VoiceCommand {
  const CommandRepeat();
}

class CommandPause extends VoiceCommand {
  const CommandPause();
}

class CommandResume extends VoiceCommand {
  const CommandResume();
}

class CommandStartOver extends VoiceCommand {
  const CommandStartOver();
}

class CommandGoToStep extends VoiceCommand {
  final int stepNumber; // 1-based index as understood by humans

  const CommandGoToStep(this.stepNumber);

  @override
  List<Object?> get props => [stepNumber];
}

class CommandAskQuantity extends VoiceCommand {
  final String ingredientName;

  const CommandAskQuantity(this.ingredientName);

  @override
  List<Object?> get props => [ingredientName];
}

class CommandListIngredients extends VoiceCommand {
  const CommandListIngredients();
}

class CommandTip extends VoiceCommand {
  const CommandTip();
}

class CommandFinish extends VoiceCommand {
  const CommandFinish();
}

class CommandExit extends VoiceCommand {
  const CommandExit();
}

class CommandUnknown extends VoiceCommand {
  final String rawText;

  const CommandUnknown(this.rawText);

  @override
  List<Object?> get props => [rawText];
}
