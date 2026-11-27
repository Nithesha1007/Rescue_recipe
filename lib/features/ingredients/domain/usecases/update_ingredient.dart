import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

class UpdateIngredient implements UseCase<void, Ingredient> {
  const UpdateIngredient(this._repository);

  final IngredientRepository _repository;

  @override
  FutureEither<void> call(Ingredient ingredient) {
    return _repository.updateIngredient(ingredient);
  }
}
