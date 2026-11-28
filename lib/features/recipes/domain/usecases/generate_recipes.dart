import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/repositories/ingredient_repository.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../entities/diet_tag.dart';
import '../entities/ranked_recipe.dart';
import '../entities/recipe.dart';
import '../repositories/recipe_repository.dart';
import '../services/recipe_exclusion_filter.dart';
import '../utils/rescue_first_ranker.dart';

class GenerateRecipesParams extends Equatable {
  const GenerateRecipesParams({
    this.dietPreference,
    this.cuisinePreference = CuisineTag.any,
    this.forceRefresh = false,
    this.today,
    this.allergens = const [],
    this.dislikedIngredients = const [],
  });

  final DietTag? dietPreference;
  final CuisineTag cuisinePreference;
  final bool forceRefresh;
  final DateTime? today;
  final List<String> allergens;
  final List<String> dislikedIngredients;

  @override
  List<Object?> get props => [
        dietPreference,
        cuisinePreference,
        forceRefresh,
        today,
        allergens,
        dislikedIngredients,
      ];
}

class GenerateRecipesResult extends Equatable {
  const GenerateRecipesResult({
    required this.rankedRecipes,
    required this.source,
    required this.dietPreference,
    this.cuisinePreference = CuisineTag.any,
  });

  final List<RankedRecipe> rankedRecipes;
  final RecipeSource source;
  final DietTag dietPreference;
  final CuisineTag cuisinePreference;

  @override
  List<Object?> get props => [rankedRecipes, source, dietPreference, cuisinePreference];
}

class GenerateRecipes
    implements UseCase<GenerateRecipesResult, GenerateRecipesParams> {
  const GenerateRecipes({
    required IngredientRepository ingredientRepository,
    required RecipeRepository recipeRepository,
  })  : _ingredientRepository = ingredientRepository,
        _recipeRepository = recipeRepository;

  final IngredientRepository _ingredientRepository;
  final RecipeRepository _recipeRepository;

  @override
  FutureEither<GenerateRecipesResult> call(GenerateRecipesParams params) async {
    // 1. Fetch active ingredients
    final ingredientsResult = await _ingredientRepository.getActiveIngredients();
    return ingredientsResult.fold(
      (failure) => Left(failure),
      (activeIngredients) async {
        final now = params.today ?? DateTime.now();
        final todayDate = DateTime(now.year, now.month, now.day);

        // Filter out expired items completely
        final validIngredients = activeIngredients.where((item) {
          final priority = item.priority(today: todayDate);
          return priority != ExpiryPriority.expired;
        }).toList();

        // 2. Fetch diet preference if not provided
        DietTag diet = params.dietPreference ?? DietTag.none;
        if (params.dietPreference == null) {
          final dietResult = await _recipeRepository.getDietPreference();
          diet = dietResult.getOrElse((_) => DietTag.none);
        }

        // If no active valid ingredients exist, return empty list early
        if (validIngredients.isEmpty) {
          return Right(GenerateRecipesResult(
            rankedRecipes: const <RankedRecipe>[],
            source: RecipeSource.gemini,
            dietPreference: diet,
            cuisinePreference: params.cuisinePreference,
          ));
        }

        // 3. Prepare params for Gemini (name, quantity, unit, useSoon: Critical/High/Medium)
        // NO dates, NO priority words, NO expiry phrases
        final candidateParams = validIngredients.map((item) {
          final p = item.priority(today: todayDate);
          final useSoon = p == ExpiryPriority.critical ||
              p == ExpiryPriority.high ||
              p == ExpiryPriority.medium;
          return IngredientCandidateParam(
            name: item.name,
            quantity: item.quantity,
            unit: item.unit,
            useSoon: useSoon,
          );
        }).toList();

        // 4. Fetch recipe candidates
        final recipeCandidatesResult =
            await _recipeRepository.getRecipeCandidates(
          ingredients: candidateParams,
          dietPreference: diet,
          forceRefresh: params.forceRefresh,
        );

        return recipeCandidatesResult.map((result) {
          // Filter candidate recipes against active allergens and disliked ingredients
          final safeRecipes = RecipeExclusionFilter.filterRecipes(
            result.recipes,
            allergens: params.allergens,
            dislikedIngredients: params.dislikedIngredients,
          );

          // 5. Rank recipes with Rescue-First Ranker (pure Dart)
          final ranked = RescueFirstRanker.rank(
            recipes: safeRecipes,
            inventory: validIngredients,
            dietPreference: diet,
            cuisinePreference: params.cuisinePreference,
            today: todayDate,
          );

          return GenerateRecipesResult(
            rankedRecipes: ranked,
            source: result.source,
            dietPreference: diet,
            cuisinePreference: params.cuisinePreference,
          );
        });
      },
    );
  }
}
