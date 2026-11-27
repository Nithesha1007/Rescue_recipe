import 'package:equatable/equatable.dart';

import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';

abstract class RecipesState extends Equatable {
  const RecipesState();

  @override
  List<Object?> get props => [];
}

class RecipesInitial extends RecipesState {
  const RecipesInitial();
}

class RecipesLoading extends RecipesState {
  const RecipesLoading();
}

class RecipesEmpty extends RecipesState {
  const RecipesEmpty();
}

class RecipesNoMatches extends RecipesState {
  const RecipesNoMatches({
    required this.dietPreference,
    required this.reason,
  });

  final DietTag dietPreference;
  final String reason;

  @override
  List<Object?> get props => [dietPreference, reason];
}

class RecipesLoaded extends RecipesState {
  const RecipesLoaded({
    required this.recipes,
    required this.source,
    required this.dietPreference,
  });

  final List<RankedRecipe> recipes;
  final RecipeSource source;
  final DietTag dietPreference;

  RankedRecipe? get topPick => recipes.isNotEmpty ? recipes.first : null;

  @override
  List<Object?> get props => [recipes, source, dietPreference];
}

class RecipesError extends RecipesState {
  const RecipesError({
    required this.message,
  });

  final String message;

  @override
  List<Object?> get props => [message];
}
