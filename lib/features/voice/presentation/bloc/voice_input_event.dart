import 'package:equatable/equatable.dart';

import '../../domain/entities/extracted_ingredient.dart';

sealed class VoiceInputEvent extends Equatable {
  const VoiceInputEvent();

  @override
  List<Object?> get props => [];
}

class StartListening extends VoiceInputEvent {
  const StartListening({this.localeId, this.isAutoMode = false});

  final String? localeId;
  final bool isAutoMode;

  @override
  List<Object?> get props => [localeId, isAutoMode];
}

class StopListening extends VoiceInputEvent {
  const StopListening();
}

class SpeechUpdateReceived extends VoiceInputEvent {
  const SpeechUpdateReceived({
    required this.transcript,
    required this.soundLevel,
    required this.isFinal,
  });

  final String transcript;
  final double soundLevel;
  final bool isFinal;

  @override
  List<Object?> get props => [transcript, soundLevel, isFinal];
}

class AudioRecordingAmplitudeReceived extends VoiceInputEvent {
  const AudioRecordingAmplitudeReceived(this.soundLevel);

  final double soundLevel;

  @override
  List<Object?> get props => [soundLevel];
}

class AudioRecordingFinished extends VoiceInputEvent {
  const AudioRecordingFinished(this.filePath);

  final String filePath;

  @override
  List<Object?> get props => [filePath];
}

class TranscriptChanged extends VoiceInputEvent {
  const TranscriptChanged(this.transcript);

  final String transcript;

  @override
  List<Object?> get props => [transcript];
}

class SubmitTranscript extends VoiceInputEvent {
  const SubmitTranscript();
}

class RemoveExtractedItem extends VoiceInputEvent {
  const RemoveExtractedItem(this.index);

  final int index;

  @override
  List<Object?> get props => [index];
}

class EditExtractedItem extends VoiceInputEvent {
  const EditExtractedItem({
    required this.index,
    required this.updatedItem,
  });

  final int index;
  final ExtractedIngredient updatedItem;

  @override
  List<Object?> get props => [index, updatedItem];
}

class ApplyCorrectionText extends VoiceInputEvent {
  const ApplyCorrectionText(this.correction);

  final String correction;

  @override
  List<Object?> get props => [correction];
}

class ConfirmAllIngredients extends VoiceInputEvent {
  const ConfirmAllIngredients();
}

class CancelVoiceInput extends VoiceInputEvent {
  const CancelVoiceInput();
}

class ResetToIdle extends VoiceInputEvent {
  const ResetToIdle();
}
