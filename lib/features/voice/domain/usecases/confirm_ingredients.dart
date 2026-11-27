import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../ingredients/domain/usecases/add_ingredients.dart';
import '../entities/extracted_ingredient.dart';

class ConfirmIngredientsParams extends Equatable {
  const ConfirmIngredientsParams(this.extractedItems);

  final List<ExtractedIngredient> extractedItems;

  @override
  List<Object?> get props => [extractedItems];
}

class ConfirmIngredients implements UseCase<void, ConfirmIngredientsParams> {
  const ConfirmIngredients(this._addIngredients);

  final AddIngredients _addIngredients;

  @override
  FutureEither<void> call(ConfirmIngredientsParams params) async {
    final DateTime now = DateTime.now();

    final List<Ingredient> ingredientsToSave =
        params.extractedItems.map((extracted) {
      return Ingredient(
        id: '${now.microsecondsSinceEpoch}_${extracted.name}',
        name: extracted.name,
        quantity: extracted.quantity,
        unit: extracted.unit,
        expiryDate: extracted.resolvedExpiry,
        addedAt: now,
      );
    }).toList();

    return _addIngredients(ingredientsToSave);
  }
}
