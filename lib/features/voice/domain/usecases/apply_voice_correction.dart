import 'package:equatable/equatable.dart';

import '../entities/extracted_ingredient.dart';
import '../utils/voice_correction.dart';

class ApplyVoiceCorrectionParams extends Equatable {
  const ApplyVoiceCorrectionParams({
    required this.currentItems,
    required this.correctionPhrase,
  });

  final List<ExtractedIngredient> currentItems;
  final String correctionPhrase;

  @override
  List<Object?> get props => [currentItems, correctionPhrase];
}

class ApplyVoiceCorrection {
  const ApplyVoiceCorrection();

  List<ExtractedIngredient> call(ApplyVoiceCorrectionParams params) {
    return VoiceCorrection.apply(
      params.currentItems,
      params.correctionPhrase,
    );
  }
}
