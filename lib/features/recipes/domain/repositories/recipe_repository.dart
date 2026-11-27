import 'package:equatable/equatable.dart';

import '../../../../core/error/failures.dart';
import '../entities/diet_tag.dart';
import '../entities/recipe.dart';

class IngredientCandidateParam extends Equatable {
  const IngredientCandidateParam({
    required this.name,
    this.quantity,
    this.unit,
    required this.useSoon,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final bool useSoon;

  Map<String, dynamic> toJson() => {
        'name': name,
        'quantity': quantity,
        'unit': unit,
        'useSoon': useSoon,
      };

  @override
  List<Object?> get props => [name, quantity, unit, useSoon];
}

class RecipeCandidateResult extends Equatable {
  const RecipeCandidateResult({
    required this.recipes,
    required this.source,
  });

  final List<Recipe> recipes;
  final RecipeSource source;

  @override
  List<Object?> get props => [recipes, source];
}

abstract class RecipeRepository {
  FutureEither<RecipeCandidateResult> getRecipeCandidates({
    required List<IngredientCandidateParam> ingredients,
    required DietTag dietPreference,
    bool forceRefresh = false,
  });

  FutureEither<DietTag> getDietPreference();

  FutureEither<void> updateDietPreference(DietTag diet);
}
