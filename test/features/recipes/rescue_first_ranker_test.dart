import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/rescue_first_ranker.dart';
import 'package:rescue_recipe/features/settings/domain/entities/cuisine_tag.dart';

void main() {
  group('RescueFirstRanker', () {
    final today = DateTime(2026, 11, 26);

    test('exact formula calculation matches hand-computed numbers', () {
      // Inventory:
      // - spinach: Critical (expires today, 0 days left) -> weight 3
      // - tomatoes: High (expires tomorrow, 1 day left) -> weight 2
      // - onions: Low (expires in 10 days) -> weight 0
      // - potatoes: Unknown (no expiry date) -> weight 0
      // Total expiring weight = 3 + 2 = 5
      final inventory = [
        Ingredient(
          id: '1',
          name: 'spinach',
          quantity: 200,
          unit: 'g',
          expiryDate: today, // 0 days left -> Critical
          addedAt: today,
        ),
        Ingredient(
          id: '2',
          name: 'tomatoes',
          quantity: 3,
          unit: 'pieces',
          expiryDate: today.add(const Duration(days: 1)), // 1 day left -> High
          addedAt: today,
        ),
        Ingredient(
          id: '3',
          name: 'onions',
          quantity: 2,
          unit: 'pieces',
          expiryDate: today.add(const Duration(days: 10)), // 10 days left -> Low
          addedAt: today,
        ),
        Ingredient(
          id: '4',
          name: 'potatoes',
          quantity: 4,
          unit: 'pieces',
          expiryDate: null, // Unknown
          addedAt: today,
        ),
      ];

      // Recipe 1: Tomato Spinach Scramble (15 min)
      // Ingredients: tomato, spinach (both on hand, non-staple)
      // coverage = (2 + 3) / 5 = 1.0
      // availability = 2 / 2 = 1.0
      // speed = 1 - (15 - 10) / 50 = 1 - 0.1 = 0.90
      // preference (none selected) = 0.5
      // totalScore = 0.45 * 1.0 + 0.30 * 1.0 + 0.15 * 0.90 + 0.10 * 0.5
      //            = 0.45 + 0.30 + 0.135 + 0.05 = 0.935
      const recipe1 = Recipe(
        id: 'r1',
        title: 'Tomato Spinach Scramble',
        minutes: 15,
        servings: 2,
        dietTags: {DietTag.vegetarian},
        ingredients: [
          RecipeIngredient(name: 'tomatoes'),
          RecipeIngredient(name: 'spinach'),
        ],
        steps: [RecipeStep(text: 'Cook.')],
      );

      // Recipe 2: Potato Onion Hash (25 min)
      // Ingredients: potato, onion (both on hand)
      // coverage = (0 + 0) / 5 = 0.0
      // availability = 2 / 2 = 1.0
      // speed = 1 - (25 - 10) / 50 = 1 - 15/50 = 0.70
      // preference = 0.5
      // totalScore = 0.45 * 0.0 + 0.30 * 1.0 + 0.15 * 0.70 + 0.10 * 0.5
      //            = 0.0 + 0.30 + 0.105 + 0.05 = 0.455
      const recipe2 = Recipe(
        id: 'r2',
        title: 'Potato Onion Hash',
        minutes: 25,
        servings: 2,
        dietTags: {DietTag.vegan},
        ingredients: [
          RecipeIngredient(name: 'potatoes'),
          RecipeIngredient(name: 'onions'),
        ],
        steps: [RecipeStep(text: 'Fry.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [recipe1, recipe2],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked.length, 2);

      // Verify Recipe 1 exact scores
      final r1 = ranked.firstWhere((r) => r.recipe.id == 'r1');
      expect(r1.coverageScore, closeTo(1.0, 0.001));
      expect(r1.availabilityScore, closeTo(1.0, 0.001));
      expect(r1.speedScore, closeTo(0.90, 0.001));
      expect(r1.preferenceScore, closeTo(0.50, 0.001));
      expect(r1.totalScore, closeTo(0.935, 0.001));

      // Verify Recipe 2 exact scores
      final r2 = ranked.firstWhere((r) => r.recipe.id == 'r2');
      expect(r2.coverageScore, closeTo(0.0, 0.001));
      expect(r2.availabilityScore, closeTo(1.0, 0.001));
      expect(r2.speedScore, closeTo(0.70, 0.001));
      expect(r2.preferenceScore, closeTo(0.50, 0.001));
      expect(r2.totalScore, closeTo(0.455, 0.001));

      // Recipe 1 ranks on top
      expect(ranked.first.recipe.id, 'r1');
      expect(ranked.first.reason, contains('Spinach'));
      expect(ranked.first.reason, contains('Tomatoes'));
    });

    test('Critical (weight 3) counts more than Medium (weight 1)', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'spinach',
          expiryDate: today, // Critical -> 3
          addedAt: today,
        ),
        Ingredient(
          id: '2',
          name: 'carrots',
          expiryDate: today.add(const Duration(days: 4)), // Medium -> 1
          addedAt: today,
        ),
      ];
      // Total expiring weight = 3 + 1 = 4

      const criticalRecipe = Recipe(
        id: 'c1',
        title: 'Spinach Dish',
        minutes: 20,
        servings: 2,
        dietTags: {DietTag.vegetarian},
        ingredients: [RecipeIngredient(name: 'spinach')],
        steps: [RecipeStep(text: 'Cook.')],
      );

      const mediumRecipe = Recipe(
        id: 'm1',
        title: 'Carrot Dish',
        minutes: 20,
        servings: 2,
        dietTags: {DietTag.vegetarian},
        ingredients: [RecipeIngredient(name: 'carrots')],
        steps: [RecipeStep(text: 'Cook.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [criticalRecipe, mediumRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      final cRank = ranked.firstWhere((r) => r.recipe.id == 'c1');
      final mRank = ranked.firstWhere((r) => r.recipe.id == 'm1');

      // spinach coverage: 3/4 = 0.75
      // carrot coverage: 1/4 = 0.25
      expect(cRank.coverageScore, closeTo(0.75, 0.001));
      expect(mRank.coverageScore, closeTo(0.25, 0.001));
      expect(cRank.totalScore, greaterThan(mRank.totalScore));
    });

    test('when no items are expiring, coverage is 0 and ranking still functions', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'potatoes',
          expiryDate: null,
          addedAt: today,
        ),
      ];

      const recipe = Recipe(
        id: 'r1',
        title: 'Baked Potato',
        minutes: 30,
        servings: 1,
        dietTags: {DietTag.vegan},
        ingredients: [RecipeIngredient(name: 'potatoes')],
        steps: [RecipeStep(text: 'Bake.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [recipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked.length, 1);
      expect(ranked.first.coverageScore, 0.0);
      expect(ranked.first.reason, 'Makes the most of what you already have.');
    });

    test('expired items are completely excluded and treated as missing', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomatoes',
          expiryDate: today.subtract(const Duration(days: 1)), // Expired (-1 days)
          addedAt: today,
        ),
        Ingredient(
          id: '2',
          name: 'onions',
          expiryDate: today.add(const Duration(days: 2)), // High
          addedAt: today,
        ),
      ];

      const recipeNeedingExpired = Recipe(
        id: 'r1',
        title: 'Tomato Onion Stew',
        minutes: 20,
        servings: 2,
        dietTags: {DietTag.vegan},
        ingredients: [
          RecipeIngredient(name: 'tomatoes'),
          RecipeIngredient(name: 'onions'),
        ],
        steps: [RecipeStep(text: 'Stew.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [recipeNeedingExpired],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked.length, 1);
      final r = ranked.first;

      // Tomatoes is expired, so only onions is available
      // availability = 1 / 2 = 0.5
      expect(r.availabilityScore, closeTo(0.5, 0.001));
      // Tomatoes must appear in missing ingredients
      expect(r.missingIngredients.any((i) => i.name == 'tomatoes'), isTrue);
      // Tomatoes must not be in matchedExpiringIngredients
      expect(r.matchedExpiringIngredients.any((m) => m.name.toLowerCase() == 'tomatoes'), isFalse);
    });

    test('diet filter excludes non-matching recipes, matching scores 1.0, none scores 0.5', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'beans',
          expiryDate: today.add(const Duration(days: 1)),
          addedAt: today,
        ),
      ];

      const veganRecipe = Recipe(
        id: 'v1',
        title: 'Vegan Bean Salad',
        minutes: 10,
        servings: 2,
        dietTags: {DietTag.vegan, DietTag.vegetarian},
        ingredients: [RecipeIngredient(name: 'beans')],
        steps: [RecipeStep(text: 'Mix.')],
      );

      const meatRecipe = Recipe(
        id: 'm1',
        title: 'Meat and Beans',
        minutes: 10,
        servings: 2,
        dietTags: {DietTag.nonVegetarian},
        ingredients: [RecipeIngredient(name: 'beans')],
        steps: [RecipeStep(text: 'Cook.')],
      );

      // With Vegan selected: meatRecipe must be dropped completely
      final veganRanked = RescueFirstRanker.rank(
        recipes: const [veganRecipe, meatRecipe],
        inventory: inventory,
        dietPreference: DietTag.vegan,
        today: today,
      );

      expect(veganRanked.length, 1);
      expect(veganRanked.first.recipe.id, 'v1');
      expect(veganRanked.first.preferenceScore, 1.0);

      // With None selected: both remain and score 0.5 for preference
      final noneRanked = RescueFirstRanker.rank(
        recipes: const [veganRecipe, meatRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(noneRanked.length, 2);
      expect(noneRanked[0].preferenceScore, 0.5);
      expect(noneRanked[1].preferenceScore, 0.5);
    });

    test('drops recipes using zero active ingredients or availability below 0.4', () {
      final inventory = [
        Ingredient(id: '1', name: 'apple', addedAt: today),
      ];

      const zeroMatchRecipe = Recipe(
        id: 'z1',
        title: 'Pasta',
        minutes: 15,
        servings: 2,
        dietTags: {DietTag.vegan},
        ingredients: [RecipeIngredient(name: 'pasta'), RecipeIngredient(name: 'tomato')],
        steps: [RecipeStep(text: 'Boil.')],
      );

      const lowAvailRecipe = Recipe(
        id: 'low1',
        title: 'Apple Feast',
        minutes: 15,
        servings: 2,
        dietTags: {DietTag.vegan},
        ingredients: [
          RecipeIngredient(name: 'apple'), // 1 match
          RecipeIngredient(name: 'flour'),
          RecipeIngredient(name: 'milk'),
          RecipeIngredient(name: 'cinnamon'),
          RecipeIngredient(name: 'butter'), // 1 / 5 = 0.20 < 0.4
        ],
        steps: [RecipeStep(text: 'Bake.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [zeroMatchRecipe, lowAvailRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked, isEmpty);
    });

    test('demo test: tomatoes expiring tomorrow puts tomato recipe on top with tomato in reason', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomatoes',
          expiryDate: today.add(const Duration(days: 1)), // High priority
          addedAt: today,
        ),
        Ingredient(
          id: '2',
          name: 'potatoes',
          expiryDate: today.add(const Duration(days: 15)), // Low priority
          addedAt: today,
        ),
      ];

      const tomatoRecipe = Recipe(
        id: 'tomato_pick',
        title: 'Fresh Tomato Toast',
        minutes: 10,
        servings: 1,
        dietTags: {DietTag.vegan},
        ingredients: [RecipeIngredient(name: 'tomatoes')],
        steps: [RecipeStep(text: 'Toast and slice.')],
      );

      const potatoRecipe = Recipe(
        id: 'potato_pick',
        title: 'Mashed Potatoes',
        minutes: 20,
        servings: 2,
        dietTags: {DietTag.vegan},
        ingredients: [RecipeIngredient(name: 'potatoes')],
        steps: [RecipeStep(text: 'Boil and mash.')],
      );

      final ranked = RescueFirstRanker.rank(
        recipes: const [potatoRecipe, tomatoRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        today: today,
      );

      expect(ranked.first.recipe.id, 'tomato_pick');
      expect(ranked.first.reason, contains('Tomatoes'));
    });

    test('cuisine preference boosts matching cuisine score without altering 0.10 weight', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomato',
          addedAt: today,
          status: IngredientStatus.active,
        ),
      ];

      const southIndianRecipe = Recipe(
        id: 'si_recipe',
        title: 'Tomato Rasam',
        minutes: 15,
        servings: 2,
        cuisine: 'South Indian',
        dietTags: {DietTag.vegetarian},
        ingredients: [RecipeIngredient(name: 'tomato')],
        steps: [RecipeStep(text: 'Simmer.')],
      );

      const continentalRecipe = Recipe(
        id: 'cont_recipe',
        title: 'Tomato Salad',
        minutes: 15,
        servings: 2,
        cuisine: 'Continental',
        dietTags: {DietTag.vegetarian},
        ingredients: [RecipeIngredient(name: 'tomato')],
        steps: [RecipeStep(text: 'Toss.')],
      );

      final rankedAny = RescueFirstRanker.rank(
        recipes: const [southIndianRecipe, continentalRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        cuisinePreference: CuisineTag.any,
        today: today,
      );
      // Both have identical scores when cuisine is any
      expect(rankedAny[0].totalScore, rankedAny[1].totalScore);

      final rankedSouthIndian = RescueFirstRanker.rank(
        recipes: const [continentalRecipe, southIndianRecipe],
        inventory: inventory,
        dietPreference: DietTag.none,
        cuisinePreference: CuisineTag.southIndian,
        today: today,
      );
      // South Indian recipe ranks higher
      expect(rankedSouthIndian.first.recipe.id, 'si_recipe');
      expect(rankedSouthIndian.first.preferenceScore > rankedSouthIndian[1].preferenceScore, isTrue);
    });
  });
}
