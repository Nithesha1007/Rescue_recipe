import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../repositories/ingredient_repository.dart';

class DeleteIngredient implements UseCase<void, String> {
  const DeleteIngredient(this._repository);

  final IngredientRepository _repository;

  @override
  FutureEither<void> call(String id) {
    return _repository.deleteIngredient(id);
  }
}
