import 'dart:convert';
import 'package:hive/hive.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../../domain/entities/recipe_step.dart';
import '../../domain/entities/substitution.dart';

/// Hive-backed persistence for user-bookmarked recipes and last successful AI recipe list.
class SavedRecipeRepository {
  final Box<String> _savedRecipesBox;
  final Box<String> _cacheBox;

  static const String _lastAiRecipesKey = 'last_successful_ai_recipes';

  SavedRecipeRepository({
    required Box<String> savedRecipesBox,
    required Box<String> cacheBox,
  })  : _savedRecipesBox = savedRecipesBox,
        _cacheBox = cacheBox;

  /// Saves a full recipe to bookmarks.
  Future<void> saveRecipe(Recipe recipe) async {
    final map = _recipeToMap(recipe.copyWith(source: RecipeSource.saved));
    await _savedRecipesBox.put(recipe.id, jsonEncode(map));
  }

  /// Removes a recipe from bookmarks.
  Future<void> removeRecipe(String recipeId) async {
    await _savedRecipesBox.delete(recipeId);
  }

  /// Whether a recipe is bookmarked.
  bool isSaved(String recipeId) {
    return _savedRecipesBox.containsKey(recipeId);
  }

  /// Returns all saved recipes.
  List<Recipe> getSavedRecipes() {
    final list = <Recipe>[];
    for (final key in _savedRecipesBox.keys) {
      final raw = _savedRecipesBox.get(key);
      if (raw != null) {
        try {
          final map = jsonDecode(raw) as Map<String, dynamic>;
          list.add(_recipeFromMap(map, RecipeSource.saved));
        } catch (_) {}
      }
    }
    return list;
  }

  /// Caches the last successful AI-generated recipe list.
  Future<void> cacheLastAiRecipes(List<Recipe> recipes) async {
    final list = recipes.map(_recipeToMap).toList();
    await _cacheBox.put(_lastAiRecipesKey, jsonEncode(list));
  }

  /// Retrieves the last successful AI-generated recipe list (source = cachedAi).
  List<Recipe> getLastAiRecipes() {
    final raw = _cacheBox.get(_lastAiRecipesKey);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((item) => _recipeFromMap(item as Map<String, dynamic>, RecipeSource.cachedAi))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Map<String, dynamic> _recipeToMap(Recipe r) {
    return {
      'id': r.id,
      'title': r.title,
      'minutes': r.minutes,
      'servings': r.servings,
      'dietTags': r.dietTags.map((d) => d.name).toList(),
      'cuisine': r.cuisine,
      'difficulty': r.difficulty,
      'aiReason': r.aiReason,
      'imageQuery': r.imageQuery,
      'tips': r.tips,
      'ingredients': r.ingredients
          .map((i) => {
                'name': i.name,
                'quantity': i.quantity,
                'unit': i.unit,
                'isOptional': i.isOptional,
                'isPantryStaple': i.isPantryStaple,
              })
          .toList(),
      'steps': r.steps
          .map((s) => {
                'text': s.text,
                'minutes': s.minutes,
                'tip': s.tip,
              })
          .toList(),
      'substitutions': r.substitutions
          .map((s) => {
                'missingIngredient': s.missingIngredient,
                'substitute': s.substitute,
                'note': s.note,
              })
          .toList(),
    };
  }

  Recipe _recipeFromMap(Map<String, dynamic> m, RecipeSource defaultSource) {
    return Recipe(
      id: m['id'] as String,
      title: m['title'] as String,
      minutes: (m['minutes'] as num).toInt(),
      servings: (m['servings'] as num?)?.toInt() ?? 2,
      dietTags: (m['dietTags'] as List<dynamic>?)
              ?.map((name) => DietTag.fromString(name as String))
              .toSet() ??
          {},
      cuisine: m['cuisine'] as String?,
      difficulty: m['difficulty'] as String? ?? 'Easy',
      aiReason: m['aiReason'] as String?,
      imageQuery: m['imageQuery'] as String?,
      tips: (m['tips'] as List<dynamic>?)?.map((t) => t as String).toList() ?? [],
      source: defaultSource,
      ingredients: (m['ingredients'] as List<dynamic>?)
              ?.map((item) => RecipeIngredient(
                    name: item['name'] as String,
                    quantity: (item['quantity'] as num?)?.toDouble(),
                    unit: item['unit'] as String?,
                    isOptional: item['isOptional'] as bool? ?? false,
                    isPantryStaple: item['isPantryStaple'] as bool? ?? false,
                  ))
              .toList() ??
          [],
      steps: (m['steps'] as List<dynamic>?)
              ?.map((item) => RecipeStep(
                    text: item['text'] as String,
                    minutes: (item['minutes'] as num?)?.toInt(),
                    tip: item['tip'] as String?,
                  ))
              .toList() ??
          [],
      substitutions: (m['substitutions'] as List<dynamic>?)
              ?.map((item) => Substitution(
                    missingIngredient: (item['missingIngredient'] ?? item['original'] ?? '') as String,
                    substitute: (item['substitute'] ?? '') as String,
                    note: (item['note'] ?? item['reason'] ?? '') as String,
                  ))
              .toList() ??
          [],
    );
  }
}
