import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/recipe.dart';

class GetRecipeByIdParams extends Equatable {
  const GetRecipeByIdParams({
    required this.id,
    required this.recipes,
  });

  final String id;
  final List<Recipe> recipes;

  @override
  List<Object?> get props => [id, recipes];
}

class GetRecipeById implements UseCase<Recipe, GetRecipeByIdParams> {
  const GetRecipeById();

  @override
  FutureEither<Recipe> call(GetRecipeByIdParams params) async {
    for (final recipe in params.recipes) {
      if (recipe.id == params.id) {
        return Right(recipe);
      }
    }
    return Left(UnexpectedFailure('Recipe with ID "${params.id}" not found.'));
  }
}
