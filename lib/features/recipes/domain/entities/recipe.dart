import 'package:equatable/equatable.dart';

import 'diet_tag.dart';
import 'recipe_ingredient.dart';
import 'recipe_step.dart';
import 'substitution.dart';

enum RecipeSource {
  gemini('AI recipes'),
  cachedAi('Last AI result'),
  saved('Saved recipes'),
  offline('Bundled recipes');

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
    this.imageQuery,
    this.videoSearchQuery,
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
  final String? imageQuery;
  final String? videoSearchQuery;

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
        imageQuery,
        videoSearchQuery,
      ];

  Recipe copyWith({
    String? id,
    String? title,
    int? minutes,
    int? servings,
    Set<DietTag>? dietTags,
    List<RecipeIngredient>? ingredients,
    List<RecipeStep>? steps,
    List<Substitution>? substitutions,
    String? aiReason,
    RecipeSource? source,
    String? cuisine,
    String? difficulty,
    List<String>? tips,
    String? imageQuery,
    String? videoSearchQuery,
  }) {
    return Recipe(
      id: id ?? this.id,
      title: title ?? this.title,
      minutes: minutes ?? this.minutes,
      servings: servings ?? this.servings,
      dietTags: dietTags ?? this.dietTags,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      substitutions: substitutions ?? this.substitutions,
      aiReason: aiReason ?? this.aiReason,
      source: source ?? this.source,
      cuisine: cuisine ?? this.cuisine,
      difficulty: difficulty ?? this.difficulty,
      tips: tips ?? this.tips,
      imageQuery: imageQuery ?? this.imageQuery,
      videoSearchQuery: videoSearchQuery ?? this.videoSearchQuery,
    );
  }
}
