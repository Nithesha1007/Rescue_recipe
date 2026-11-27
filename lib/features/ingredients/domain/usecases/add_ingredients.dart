import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

class AddIngredients implements UseCase<void, List<Ingredient>> {
  const AddIngredients(this._repository);

  final IngredientRepository _repository;

  @override
  FutureEither<void> call(List<Ingredient> ingredients) {
    return _repository.addIngredients(ingredients);
  }
}
