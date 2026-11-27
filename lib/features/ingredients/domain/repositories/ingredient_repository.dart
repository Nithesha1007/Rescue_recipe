import '../../../../core/error/failures.dart';
import '../entities/ingredient.dart';

abstract interface class IngredientRepository {
  Stream<List<Ingredient>> watchActiveIngredients();
  FutureEither<List<Ingredient>> getActiveIngredients();
  FutureEither<Ingredient?> getIngredientById(String id);
  FutureEither<void> addIngredient(Ingredient ingredient);
  FutureEither<void> addIngredients(List<Ingredient> ingredients);
  FutureEither<void> updateIngredient(Ingredient ingredient);
  FutureEither<void> deleteIngredient(String id);
  FutureEither<void> markUsed(String id);
  FutureEither<void> markDiscarded(String id);
}
