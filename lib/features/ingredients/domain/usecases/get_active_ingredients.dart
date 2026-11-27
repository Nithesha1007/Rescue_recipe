import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

class GetActiveIngredients implements UseCase<List<Ingredient>, NoParams> {
  const GetActiveIngredients(this._repository);

  final IngredientRepository _repository;

  @override
  FutureEither<List<Ingredient>> call(NoParams params) {
    return _repository.getActiveIngredients();
  }
}
