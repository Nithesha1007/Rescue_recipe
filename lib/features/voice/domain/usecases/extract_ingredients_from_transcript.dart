import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/utils/expiry_date_resolver.dart';
import '../entities/extracted_ingredient.dart';
import '../repositories/ingredient_extraction_repository.dart';

class ExtractParams extends Equatable {
  const ExtractParams({required this.transcript, this.today});

  final String transcript;
  final DateTime? today;

  @override
  List<Object?> get props => [transcript, today];
}

class ExtractIngredientsFromTranscript
    implements UseCase<ExtractionResult, ExtractParams> {
  const ExtractIngredientsFromTranscript(this._repository);

  final IngredientExtractionRepository _repository;

  @override
  FutureEither<ExtractionResult> call(ExtractParams params) async {
    final result = await _repository.extract(params.transcript);

    return result.map((extraction) {
      final List<ExtractedIngredient> resolvedItems = extraction.items.map((item) {
        if (item.expiryPhrase == null || item.expiryPhrase!.trim().isEmpty) {
          return item.copyWith(
            resolvedExpiry: () => null,
            expiryUnderstood: true,
          );
        }

        final DateTime? date = ExpiryDateResolver.resolve(
          item.expiryPhrase,
          today: params.today,
        );

        if (date != null) {
          return item.copyWith(
            resolvedExpiry: () => date,
            expiryUnderstood: true,
          );
        } else {
          return item.copyWith(
            resolvedExpiry: () => null,
            expiryUnderstood: false,
          );
        }
      }).toList();

      return ExtractionResult(
        items: resolvedItems,
        source: extraction.source,
      );
    });
  }
}
