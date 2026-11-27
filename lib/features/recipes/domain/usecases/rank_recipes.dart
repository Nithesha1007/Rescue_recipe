import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../entities/diet_tag.dart';
import '../entities/ranked_recipe.dart';
import '../entities/recipe.dart';
import '../utils/rescue_first_ranker.dart';

class RankRecipesParams extends Equatable {
  const RankRecipesParams({
    required this.recipes,
    required this.inventory,
    required this.dietPreference,
    this.cuisinePreference = CuisineTag.any,
    this.today,
  });

  final List<Recipe> recipes;
  final List<Ingredient> inventory;
  final DietTag dietPreference;
  final CuisineTag cuisinePreference;
  final DateTime? today;

  @override
  List<Object?> get props => [recipes, inventory, dietPreference, cuisinePreference, today];
}

class RankRecipes implements UseCase<List<RankedRecipe>, RankRecipesParams> {
  const RankRecipes();

  @override
  FutureEither<List<RankedRecipe>> call(RankRecipesParams params) async {
    final ranked = RescueFirstRanker.rank(
      recipes: params.recipes,
      inventory: params.inventory,
      dietPreference: params.dietPreference,
      cuisinePreference: params.cuisinePreference,
      today: params.today,
    );
    return Right(ranked);
  }
}
