import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/diet_tag.dart';
import '../repositories/recipe_repository.dart';

class GetDietPreference implements UseCase<DietTag, NoParams> {
  const GetDietPreference(this._repository);

  final RecipeRepository _repository;

  @override
  FutureEither<DietTag> call(NoParams params) {
    return _repository.getDietPreference();
  }
}
