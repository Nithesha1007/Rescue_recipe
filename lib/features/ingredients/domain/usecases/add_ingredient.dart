import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

class AddIngredient implements UseCase<void, Ingredient> {
  const AddIngredient(this._repository);

  final IngredientRepository _repository;

  @override
  FutureEither<void> call(Ingredient ingredient) {
    return _repository.addIngredient(ingredient);
  }
}
