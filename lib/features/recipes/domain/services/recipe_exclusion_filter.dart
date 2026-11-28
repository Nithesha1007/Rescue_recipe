import '../../../../core/domain/ingredient_vocabulary.dart';
import '../entities/recipe.dart';

/// Pure Dart exclusion filter enforcing hard dietary constraints:
/// allergens and disliked ingredients.
/// Applied both to Gemini generated recipes and offline fallback recipes.
class RecipeExclusionFilter {
  const RecipeExclusionFilter._();

  static const Map<String, Set<String>> allergenGroups = {
    'dairy': {
      'milk',
      'curd',
      'yogurt',
      'yoghurt',
      'paneer',
      'cheese',
      'butter',
      'ghee',
      'cream',
      'dahi',
      'malai',
    },
    'gluten': {
      'wheat',
      'flour',
      'atta',
      'maida',
      'all-purpose flour',
      'bread',
      'pasta',
      'semolina',
      'rava',
      'sooji',
      'noodles',
      'roti',
    },
    'peanuts': {
      'peanut',
      'peanuts',
      'groundnut',
      'groundnuts',
      'peanut butter',
    },
    'tree nuts': {
      'cashew',
      'cashews',
      'almond',
      'almonds',
      'walnut',
      'walnuts',
      'pistachio',
      'pistachios',
      'nut',
      'nuts',
      'kaju',
      'badam',
    },
    'eggs': {
      'egg',
      'eggs',
      'anda',
    },
    'soy': {
      'soy',
      'soya',
      'tofu',
      'soy sauce',
      'edamame',
    },
    'shellfish': {
      'shrimp',
      'prawn',
      'prawns',
      'crab',
      'lobster',
    },
    'fish': {
      'fish',
      'salmon',
      'tuna',
    },
    'sesame': {
      'sesame',
      'sesame seeds',
      'til',
      'tahini',
    },
  };

  /// Checks if a [recipe] contains any ingredient that violates [allergens] or [dislikedIngredients].
  static bool isRecipeExcluded(
    Recipe recipe, {
    required List<String> allergens,
    required List<String> dislikedIngredients,
  }) {
    if (allergens.isEmpty && dislikedIngredients.isEmpty) {
      return false;
    }

    final forbiddenWords = <String>{};

    // 1. Resolve allergens to specific ingredient words
    for (final allergen in allergens) {
      final lowerAllergen = allergen.toLowerCase().trim();
      forbiddenWords.add(lowerAllergen);
      if (allergenGroups.containsKey(lowerAllergen)) {
        forbiddenWords.addAll(allergenGroups[lowerAllergen]!);
      }
    }

    // 2. Resolve dislikes
    for (final dislike in dislikedIngredients) {
      final canonical = IngredientVocabulary.resolve(dislike.toLowerCase().trim());
      forbiddenWords.add(canonical);
      forbiddenWords.add(dislike.toLowerCase().trim());
    }

    // 3. Check every recipe ingredient
    for (final ing in recipe.ingredients) {
      final ingName = ing.name.toLowerCase().trim();
      final canonical = IngredientVocabulary.resolve(ingName);

      for (final forbidden in forbiddenWords) {
        if (canonical == forbidden ||
            ingName == forbidden ||
            ingName.contains(forbidden) ||
            forbidden.contains(ingName)) {
          return true;
        }
      }
    }

    return false;
  }

  /// Filters a list of recipes removing any that violate exclusions.
  static List<Recipe> filterRecipes(
    List<Recipe> recipes, {
    required List<String> allergens,
    required List<String> dislikedIngredients,
  }) {
    if (allergens.isEmpty && dislikedIngredients.isEmpty) {
      return recipes;
    }
    return recipes
        .where((r) => !isRecipeExcluded(
              r,
              allergens: allergens,
              dislikedIngredients: dislikedIngredients,
            ))
        .toList();
  }
}
