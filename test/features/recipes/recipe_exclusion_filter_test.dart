import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/services/recipe_exclusion_filter.dart';

void main() {
  group('RecipeExclusionFilter', () {
    const peanutDish = Recipe(
      id: 'r1',
      title: 'Peanut Chutney',
      minutes: 10,
      servings: 2,
      dietTags: {},
      ingredients: [
        RecipeIngredient(name: 'peanuts', quantity: 50, unit: 'g'),
        RecipeIngredient(name: 'green chili', quantity: 2, unit: 'pcs'),
      ],
      steps: [],
      substitutions: [],
      source: RecipeSource.offline,
      difficulty: 'Easy',
      tips: [],
    );

    const dairyDish = Recipe(
      id: 'r2',
      title: 'Paneer Butter Masala',
      minutes: 25,
      servings: 2,
      dietTags: {},
      ingredients: [
        RecipeIngredient(name: 'paneer', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'butter', quantity: 20, unit: 'g'),
        RecipeIngredient(name: 'tomato', quantity: 3, unit: 'pcs'),
      ],
      steps: [],
      substitutions: [],
      source: RecipeSource.offline,
      difficulty: 'Medium',
      tips: [],
    );

    const safeDish = Recipe(
      id: 'r3',
      title: 'Tomato Rasam',
      minutes: 15,
      servings: 2,
      dietTags: {},
      ingredients: [
        RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pcs'),
        RecipeIngredient(name: 'coriander', quantity: 10, unit: 'g'),
      ],
      steps: [],
      substitutions: [],
      source: RecipeSource.offline,
      difficulty: 'Easy',
      tips: [],
    );

    test('excludes dish containing allergen group match', () {
      expect(
        RecipeExclusionFilter.isRecipeExcluded(
          peanutDish,
          allergens: ['peanuts'],
          dislikedIngredients: [],
        ),
        isTrue,
      );

      expect(
        RecipeExclusionFilter.isRecipeExcluded(
          dairyDish,
          allergens: ['dairy'],
          dislikedIngredients: [],
        ),
        isTrue,
      );

      expect(
        RecipeExclusionFilter.isRecipeExcluded(
          safeDish,
          allergens: ['dairy', 'peanuts'],
          dislikedIngredients: [],
        ),
        isFalse,
      );
    });

    test('excludes dish containing disliked ingredient', () {
      expect(
        RecipeExclusionFilter.isRecipeExcluded(
          safeDish,
          allergens: [],
          dislikedIngredients: ['coriander'],
        ),
        isTrue,
      );

      expect(
        RecipeExclusionFilter.isRecipeExcluded(
          peanutDish,
          allergens: [],
          dislikedIngredients: ['coriander'],
        ),
        isFalse,
      );
    });

    test('filters list of recipes removing all violations', () {
      final recipes = [peanutDish, dairyDish, safeDish];
      final filtered = RecipeExclusionFilter.filterRecipes(
        recipes,
        allergens: ['dairy'],
        dislikedIngredients: ['peanuts'],
      );

      expect(filtered.length, 1);
      expect(filtered.first.id, 'r3');
    });
  });
}
