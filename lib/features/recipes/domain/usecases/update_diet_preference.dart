import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/diet_tag.dart';
import '../repositories/recipe_repository.dart';

class UpdateDietPreferenceParams extends Equatable {
  const UpdateDietPreferenceParams(this.diet);

  final DietTag diet;

  @override
  List<Object?> get props => [diet];
}

class UpdateDietPreference
    implements UseCase<void, UpdateDietPreferenceParams> {
  const UpdateDietPreference(this._repository);

  final RecipeRepository _repository;

  @override
  FutureEither<void> call(UpdateDietPreferenceParams params) {
    return _repository.updateDietPreference(params.diet);
  }
}
