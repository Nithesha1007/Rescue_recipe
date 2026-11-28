import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/servings_scaler.dart';

void main() {
  group('ServingsScaler', () {
    test('scales countable items with integer or half rounding', () {
      // 2 eggs for 2 servings -> 4 eggs for 4 servings
      final eggs = ServingsScaler.scaleQuantity(2, 2, 4, '');
      expect(eggs, equals(4.0));

      // 1 tomato for 2 servings -> 3 tomatoes for 6 servings
      final tomatoes = ServingsScaler.scaleQuantity(1, 2, 6, '');
      expect(tomatoes, equals(3.0));

      // 1 egg for 2 servings -> scaled to 3 servings should round sensibly
      final eggThree = ServingsScaler.scaleQuantity(1, 2, 3, '');
      expect(eggThree, equals(1.5));
    });

    test('scales small spices (tsp, tbsp) with 0.25 precision', () {
      // 1 tsp for 2 servings -> 0.5 tsp for 1 serving
      final halfTsp = ServingsScaler.scaleQuantity(1, 2, 1, 'tsp');
      expect(halfTsp, equals(0.5));

      // 1.5 tsp for 2 servings -> 2.25 tsp for 3 servings
      final scaledTsp = ServingsScaler.scaleQuantity(1.5, 2, 3, 'tsp');
      expect(scaledTsp, equals(2.25));
    });

    test('scales metric weights (g, grams) to whole numbers', () {
      // 200g for 2 servings -> 400g for 4 servings
      final grams = ServingsScaler.scaleQuantity(200, 2, 4, 'g');
      expect(grams, equals(400.0));

      // 150g for 2 servings -> 75g for 1 serving
      final oneGrams = ServingsScaler.scaleQuantity(150, 2, 1, 'grams');
      expect(oneGrams, equals(75.0));
    });

    test('scales liquid volume (ml, liters)', () {
      // 250ml for 2 servings -> 500ml for 4 servings
      final ml = ServingsScaler.scaleQuantity(250, 2, 4, 'ml');
      expect(ml, equals(500.0));
    });

    test('scales full recipe entity properly', () {
      const recipe = Recipe(
        id: 'test_recipe',
        title: 'Tomato Dal',
        minutes: 20,
        servings: 2,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Tomato', quantity: 2, unit: ''),
          RecipeIngredient(name: 'Toor Dal', quantity: 100, unit: 'g'),
          RecipeIngredient(name: 'Turmeric', quantity: 0.5, unit: 'tsp'),
          RecipeIngredient(name: 'Salt', isPantryStaple: true),
        ],
        steps: [
          RecipeStep(text: 'Boil dal with tomatoes'),
        ],
      );

      final scaled4 = ServingsScaler.scaleRecipe(recipe, 4);
      expect(scaled4.servings, equals(4));
      expect(scaled4.ingredients[0].quantity, equals(4.0));
      expect(scaled4.ingredients[1].quantity, equals(200.0));
      expect(scaled4.ingredients[2].quantity, equals(1.0));
      expect(scaled4.ingredients[3].quantity, isNull);

      final scaled1 = ServingsScaler.scaleRecipe(recipe, 1);
      expect(scaled1.servings, equals(1));
      expect(scaled1.ingredients[0].quantity, equals(1.0));
      expect(scaled1.ingredients[1].quantity, equals(50.0));
    });
  });
}
