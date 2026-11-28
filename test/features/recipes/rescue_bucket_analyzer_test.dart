import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/ranked_recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/rescue_plan_bucket.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/rescue_bucket_analyzer.dart';

void main() {
  final testToday = DateTime(2026, 11, 28);

  Ingredient makeIngredient(String id, String name, ExpiryPriority priority) {
    DateTime? exp;
    switch (priority) {
      case ExpiryPriority.critical:
        exp = testToday; // 0 days
        break;
      case ExpiryPriority.high:
        exp = testToday.add(const Duration(days: 2));
        break;
      case ExpiryPriority.medium:
        exp = testToday.add(const Duration(days: 5));
        break;
      case ExpiryPriority.low:
        exp = testToday.add(const Duration(days: 10));
        break;
      case ExpiryPriority.expired:
        exp = testToday.subtract(const Duration(days: 1));
        break;
      case ExpiryPriority.unknown:
        exp = null;
        break;
    }

    return Ingredient(
      id: id,
      name: name,
      expiryDate: exp,
      addedAt: testToday.subtract(const Duration(days: 3)),
    );
  }

  Recipe makeRecipe(String id, String title, List<String> ingredients) {
    return Recipe(
      id: id,
      title: title,
      minutes: 20,
      servings: 2,
      dietTags: const {},
      ingredients: ingredients
          .map((n) => RecipeIngredient(name: n, quantity: 1, unit: 'cup'))
          .toList(),
      steps: const [RecipeStep(text: 'Step 1')],
    );
  }

  RankedRecipe makeRankedRecipe(Recipe recipe, double score, List<String> rescued) {
    return RankedRecipe(
      recipe: recipe,
      totalScore: score,
      coverageScore: 1.0,
      availabilityScore: 1.0,
      speedScore: 1.0,
      preferenceScore: 1.0,
      matchedExpiringIngredients: const [],
      missingIngredients: const [],
      coveredExpiringCount: rescued.length,
      totalExpiringCount: rescued.length,
      reason: 'Uses ${rescued.join(", ")}',
      badges: const [RankedBadge(badge: RecipeBadge.rescueFirst, label: 'Rescue-first')],
    );
  }

  group('RescueBucketAnalyzer', () {
    test('groups at-risk ingredients into correct buckets and ignores low/unknown/expired', () {
      final ingredients = [
        makeIngredient('1', 'spinach', ExpiryPriority.critical),
        makeIngredient('2', 'tomato', ExpiryPriority.high),
        makeIngredient('3', 'carrot', ExpiryPriority.medium),
        makeIngredient('4', 'rice', ExpiryPriority.low),
        makeIngredient('5', 'salt', ExpiryPriority.unknown),
        makeIngredient('6', 'milk', ExpiryPriority.expired),
      ];

      final buckets = RescueBucketAnalyzer.analyze(
        inventory: ingredients,
        rankedRecipes: [],
        today: testToday,
      );

      expect(buckets.length, 3);
      expect(buckets[0].type, RescueBucketType.cookToday);
      expect(buckets[0].items.map((i) => i.name), ['spinach']);

      expect(buckets[1].type, RescueBucketType.within2Days);
      expect(buckets[1].items.map((i) => i.name), ['tomato']);

      expect(buckets[2].type, RescueBucketType.thisWeek);
      expect(buckets[2].items.map((i) => i.name), ['carrot']);
    });

    test('hides empty buckets when there are no items in that urgency level', () {
      final ingredients = [
        makeIngredient('1', 'tomato', ExpiryPriority.high),
      ];

      final buckets = RescueBucketAnalyzer.analyze(
        inventory: ingredients,
        rankedRecipes: [],
        today: testToday,
      );

      expect(buckets.length, 1);
      expect(buckets[0].type, RescueBucketType.within2Days);
      expect(buckets[0].items.first.name, 'tomato');
    });

    test('selects champion recipe covering the most bucket items, breaking ties by score', () {
      final ingredients = [
        makeIngredient('1', 'spinach', ExpiryPriority.critical),
        makeIngredient('2', 'egg', ExpiryPriority.critical),
      ];

      final r1 = makeRecipe('r1', 'Egg Scramble', ['egg']);
      final r2 = makeRecipe('r2', 'Spinach Frittata', ['spinach', 'egg']);
      final r3 = makeRecipe('r3', 'Spinach Salad', ['spinach']);

      final ranked = [
        makeRankedRecipe(r1, 0.50, ['egg']),
        makeRankedRecipe(r2, 0.40, ['spinach', 'egg']), // covers 2 items
        makeRankedRecipe(r3, 0.60, ['spinach']), // higher score, but only covers 1 item
      ];

      final buckets = RescueBucketAnalyzer.analyze(
        inventory: ingredients,
        rankedRecipes: ranked,
        today: testToday,
      );

      expect(buckets.length, 1);
      final cookToday = buckets.first;
      expect(cookToday.bestRecipe, isNotNull);
      expect(cookToday.bestRecipe!.recipe.id, 'r2');
    });
  });
}
