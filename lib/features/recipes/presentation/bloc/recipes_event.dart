import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/recipe.dart';

abstract class RecipesEvent extends Equatable {
  const RecipesEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecipes extends RecipesEvent {
  const LoadRecipes({
    this.forceRefresh = false,
  });

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshRecipes extends RecipesEvent {
  const RefreshRecipes();
}

class ChangeDiet extends RecipesEvent {
  const ChangeDiet(this.diet);

  final DietTag diet;

  @override
  List<Object?> get props => [diet];
}

class ChangeCuisine extends RecipesEvent {
  final CuisineTag cuisine;

  const ChangeCuisine(this.cuisine);

  @override
  List<Object?> get props => [cuisine];
}

class ApplyRecipeFilter extends RecipesEvent {
  final int? maxMinutes;
  final String? focusIngredient;
  final String? excludeIngredient;
  final DietTag? diet;
  final CuisineTag? cuisine;
  final bool reset;

  const ApplyRecipeFilter({
    this.maxMinutes,
    this.focusIngredient,
    this.excludeIngredient,
    this.diet,
    this.cuisine,
    this.reset = false,
  });

  @override
  List<Object?> get props => [
        maxMinutes,
        focusIngredient,
        excludeIngredient,
        diet,
        cuisine,
        reset,
      ];
}

class ToggleSaveRecipe extends RecipesEvent {
  final Recipe recipe;

  const ToggleSaveRecipe(this.recipe);

  @override
  List<Object?> get props => [recipe];
}

class SwitchRecipeSegment extends RecipesEvent {
  final int segmentIndex; // 0 = suggestions, 1 = saved

  const SwitchRecipeSegment(this.segmentIndex);

  @override
  List<Object?> get props => [segmentIndex];
}
