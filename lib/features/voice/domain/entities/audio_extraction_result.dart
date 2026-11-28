import 'package:equatable/equatable.dart';
import '../../domain/entities/extracted_ingredient.dart';

class AudioExtractionResult extends Equatable {
  const AudioExtractionResult({
    required this.transcript,
    required this.detectedLanguage,
    required this.ingredients,
  });

  final String transcript;
  final String detectedLanguage;
  final List<ExtractedIngredient> ingredients;

  @override
  List<Object?> get props => [transcript, detectedLanguage, ingredients];
}
