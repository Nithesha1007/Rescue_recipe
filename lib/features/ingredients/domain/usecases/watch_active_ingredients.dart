import '../entities/ingredient.dart';
import '../repositories/ingredient_repository.dart';

/// Exposes a continuous stream of active, sorted inventory items.
/// Emits immediately upon subscription and on every inventory modification.
class WatchActiveIngredients {
  const WatchActiveIngredients(this._repository);

  final IngredientRepository _repository;

  Stream<List<Ingredient>> call() {
    return _repository.watchActiveIngredients();
  }
}
