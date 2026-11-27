import 'package:equatable/equatable.dart';

import 'diet_tag.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';
import 'substitution.dart';

enum RecipeSource {
  gemini('AI recipes'),
  offline('Offline recipes');

  const RecipeSource(this.label);
  final String label;
}

class Recipe extends Equatable {
  const Recipe({
    required this.id,
    required this.title,
    required this.minutes,
    required this.servings,
    required this.dietTags,
    required this.ingredients,
    required this.steps,
    this.substitutions = const <Substitution>[],
    this.aiReason,
    this.source = RecipeSource.gemini,
    this.cuisine,
    this.difficulty = 'Easy',
    this.tips = const <String>[],
  });

  final String id;
  final String title;
  final int minutes;
  final int servings;
  final Set<DietTag> dietTags;
  final List<RecipeIngredient> ingredients;
  final List<RecipeStep> steps;
  final List<Substitution> substitutions;
  final String? aiReason;
  final RecipeSource source;
  final String? cuisine;
  final String difficulty;
  final List<String> tips;

  @override
  List<Object?> get props => [
        id,
        title,
        minutes,
        servings,
        dietTags,
        ingredients,
        steps,
        substitutions,
        aiReason,
        source,
        cuisine,
        difficulty,
        tips,
      ];
}
