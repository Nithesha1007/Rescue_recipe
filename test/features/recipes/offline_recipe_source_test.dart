import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/data/datasources/offline_recipe_source.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/rescue_first_ranker.dart';

void main() {
  group('OfflineRecipeSource', () {
    test('provides twelve complete bundled recipes with valid fields', () {
      const recipes = OfflineRecipeSource.recipes;
      expect(recipes.length, 12);

      final titles = recipes.map((r) => r.title).toList();
      expect(titles, contains('Tomato Spinach Scramble'));
      expect(titles, contains('Potato Onion Hash'));
      expect(titles, contains('Rustic Tomato Onion Soup'));
      expect(titles, contains('South Indian Tomato Rice'));
      expect(titles, contains('Quick Pepper Rasam'));
      expect(titles, contains('Quick Onion Tomato Chutney'));
      expect(titles, contains('Spiced Potato Poriyal'));
      expect(titles, contains('Homestyle Vegetable Upma'));
      expect(titles, contains('Garlic Olive Oil Pasta'));
      expect(titles, contains('Quick Vegetable Stir-Fry Rice'));
      expect(titles, contains('Spiced Paneer Bhurji'));
      expect(titles, contains('Quick Masala Egg Roast'));

      for (final r in recipes) {
        expect(r.minutes, inInclusiveRange(10, 60));
        expect(r.servings, greaterThan(0));
        expect(r.ingredients, isNotEmpty);
        expect(r.steps, isNotEmpty);
        expect(r.substitutions, isNotEmpty);
        expect(r.source, RecipeSource.offline);
        for (final s in r.steps) {
          expect(s.text, isNotEmpty);
        }
      }
    });

    test('bundled recipes rank correctly through RescueFirstRanker', () {
      final today = DateTime(2026, 11, 26);
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomato',
          expiryDate: today.add(const Duration(days: 1)),
          addedAt: today,
        ),
        Ingredient(
          id: '2',
          name: 'spinach',
          expiryDate: today,
          addedAt: today,
        ),
      ];

      final ranked = RescueFirstRanker.rank(
        recipes: OfflineRecipeSource.recipes,
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked, isNotEmpty);
      expect(ranked.first.recipe.title, 'Tomato Spinach Scramble');
      expect(ranked.first.recipe.source, RecipeSource.offline);
    });
  });
}
