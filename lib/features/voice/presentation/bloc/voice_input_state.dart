import 'package:equatable/equatable.dart';

import '../../domain/entities/extracted_ingredient.dart';
import '../../domain/repositories/ingredient_extraction_repository.dart';

sealed class VoiceInputState extends Equatable {
  const VoiceInputState();

  @override
  List<Object?> get props => [];
}

class VoiceInputIdle extends VoiceInputState {
  const VoiceInputIdle();
}

class VoiceInputRequestingPermission extends VoiceInputState {
  const VoiceInputRequestingPermission();
}

class VoiceInputPermissionDenied extends VoiceInputState {
  const VoiceInputPermissionDenied({required this.isPermanent});

  final bool isPermanent;

  @override
  List<Object?> get props => [isPermanent];
}

class VoiceInputListening extends VoiceInputState {
  const VoiceInputListening({
    required this.transcript,
    required this.soundLevel,
  });

  final String transcript;
  final double soundLevel;

  @override
  List<Object?> get props => [transcript, soundLevel];
}

class VoiceInputEditing extends VoiceInputState {
  const VoiceInputEditing({required this.transcript});

  final String transcript;

  @override
  List<Object?> get props => [transcript];
}

class VoiceInputExtracting extends VoiceInputState {
  const VoiceInputExtracting({required this.transcript});

  final String transcript;

  @override
  List<Object?> get props => [transcript];
}

class VoiceInputConfirming extends VoiceInputState {
  const VoiceInputConfirming({
    required this.items,
    required this.source,
    required this.originalTranscript,
  });

  final List<ExtractedIngredient> items;
  final ExtractionSource source;
  final String originalTranscript;

  @override
  List<Object?> get props => [items, source, originalTranscript];
}

class VoiceInputSaving extends VoiceInputState {
  const VoiceInputSaving();
}

class VoiceInputSaved extends VoiceInputState {
  const VoiceInputSaved({required this.count});

  final int count;

  @override
  List<Object?> get props => [count];
}

class VoiceInputError extends VoiceInputState {
  const VoiceInputError({
    required this.message,
    required this.transcript,
  });

  final String message;
  final String transcript;

  @override
  List<Object?> get props => [message, transcript];
}
