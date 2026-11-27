import '../../../../core/error/failures.dart';
import '../entities/extracted_ingredient.dart';

enum ExtractionSource {
  gemini('AI extracted'),
  offline('Basic parsing (offline)');

  const ExtractionSource(this.label);
  final String label;
}

class ExtractionResult {
  const ExtractionResult({
    required this.items,
    required this.source,
  });

  final List<ExtractedIngredient> items;
  final ExtractionSource source;
}

abstract interface class IngredientExtractionRepository {
  FutureEither<ExtractionResult> extract(String transcript);
}
