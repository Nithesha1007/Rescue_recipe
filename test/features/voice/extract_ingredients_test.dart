import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/ingredient_extraction_repository.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/extract_ingredients_from_transcript.dart';

class FakeExtractionRepository implements IngredientExtractionRepository {
  FakeExtractionRepository(this.mockResult);

  ExtractionResult mockResult;

  @override
  FutureEither<ExtractionResult> extract(String transcript) async {
    return Right(mockResult);
  }
}

void main() {
  group('ExtractIngredientsFromTranscript', () {
    final DateTime today = DateTime(2026, 11, 26);

    test('resolves "tomorrow" to today+1 and sets priority High', () async {
      final repo = FakeExtractionRepository(
        const ExtractionResult(
          items: [
            ExtractedIngredient(
              name: 'tomato',
              quantity: 3,
              expiryPhrase: 'tomorrow',
            ),
          ],
          source: ExtractionSource.gemini,
        ),
      );

      final useCase = ExtractIngredientsFromTranscript(repo);
      final result = await useCase(
        ExtractParams(transcript: 'test', today: today),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (res) {
          expect(res.items.length, 1);
          final item = res.items[0];
          expect(item.resolvedExpiry, DateTime(2026, 11, 27));
          expect(item.priority(today: today), ExpiryPriority.high);
          expect(item.expiryUnderstood, isTrue);
          expect(res.source, ExtractionSource.gemini);
        },
      );
    });

    test('sets expiryUnderstood false when phrase cannot be resolved', () async {
      final repo = FakeExtractionRepository(
        const ExtractionResult(
          items: [
            ExtractedIngredient(
              name: 'milk',
              expiryPhrase: 'sometime soon',
            ),
          ],
          source: ExtractionSource.offline,
        ),
      );

      final useCase = ExtractIngredientsFromTranscript(repo);
      final result = await useCase(
        ExtractParams(transcript: 'test', today: today),
      );

      expect(result.isRight(), isTrue);
      result.fold(
        (_) => fail('Expected success'),
        (res) {
          expect(res.items.length, 1);
          final item = res.items[0];
          expect(item.resolvedExpiry, isNull);
          expect(item.priority(today: today), ExpiryPriority.unknown);
          expect(item.expiryUnderstood, isFalse);
          expect(res.source, ExtractionSource.offline);
        },
      );
    });
  });
}
