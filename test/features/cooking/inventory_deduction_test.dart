import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/inventory_deduction.dart';
import 'package:rescue_recipe/features/cooking/domain/utils/inventory_deduction_calculator.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';

void main() {
  group('InventoryDeductionCalculator', () {
    final now = DateTime(2026, 11, 26);

    test('deducts matching units and reduces quantity when remaining > 0', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'Tomatoes',
          quantity: 500,
          unit: 'g',
          addedAt: now,
          status: IngredientStatus.active,
        ),
      ];

      const recipe = Recipe(
        id: 'r1',
        title: 'Tomato Soup',
        minutes: 20,
        servings: 2,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Tomatoes', quantity: 200, unit: 'g'),
        ],
        steps: [
          RecipeStep(text: 'Blend tomatoes'),
          RecipeStep(text: 'Heat'),
        ],
      );

      final deductions = InventoryDeductionCalculator.compute(
        inventory: inventory,
        recipe: recipe,
        today: now,
      );

      expect(deductions.length, 1);
      final d = deductions.first;
      expect(d.ingredientId, '1');
      expect(d.action, DeductionAction.reduce);
      expect(d.deductQuantity, 200.0);
      expect(d.remainingQuantity, 300.0);
    });

    test('marks used when remaining quantity is 0 or less', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'Milk',
          quantity: 500,
          unit: 'ml',
          addedAt: now,
          status: IngredientStatus.active,
        ),
      ];

      const recipe = Recipe(
        id: 'r2',
        title: 'Pancakes',
        minutes: 15,
        servings: 2,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Milk', quantity: 500, unit: 'ml'),
        ],
        steps: [
          RecipeStep(text: 'Mix'),
          RecipeStep(text: 'Cook'),
        ],
      );

      final deductions = InventoryDeductionCalculator.compute(
        inventory: inventory,
        recipe: recipe,
        today: now,
      );

      expect(deductions.length, 1);
      final d = deductions.first;
      expect(d.action, DeductionAction.markUsed);
      expect(d.remainingQuantity, 0.0);
    });

    test('performs unit conversion between kg and g', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'Potatoes',
          quantity: 1.0,
          unit: 'kg',
          addedAt: now,
          status: IngredientStatus.active,
        ),
      ];

      const recipe = Recipe(
        id: 'r3',
        title: 'Mashed Potatoes',
        minutes: 20,
        servings: 2,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Potatoes', quantity: 400, unit: 'g'),
        ],
        steps: [
          RecipeStep(text: 'Boil'),
          RecipeStep(text: 'Mash'),
        ],
      );

      final deductions = InventoryDeductionCalculator.compute(
        inventory: inventory,
        recipe: recipe,
        today: now,
      );

      expect(deductions.length, 1);
      final d = deductions.first;
      expect(d.action, DeductionAction.reduce);
      expect(d.deductQuantity, 0.4);
      expect(d.remainingQuantity, 0.6);
    });

    test('proposes markUsed when units differ without known conversion', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'Eggs',
          quantity: 6,
          unit: 'eggs',
          addedAt: now,
          status: IngredientStatus.active,
        ),
      ];

      const recipe = Recipe(
        id: 'r4',
        title: 'Scrambled Eggs',
        minutes: 5,
        servings: 1,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Eggs', quantity: 100, unit: 'g'),
        ],
        steps: [
          RecipeStep(text: 'Whisk and fry'),
        ],
      );

      final deductions = InventoryDeductionCalculator.compute(
        inventory: inventory,
        recipe: recipe,
        today: now,
      );

      expect(deductions.length, 1);
      final d = deductions.first;
      expect(d.action, DeductionAction.markUsed);
    });

    test('skips pantry staples like salt and water', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'Salt',
          quantity: 1,
          unit: 'kg',
          addedAt: now,
          status: IngredientStatus.active,
        ),
      ];

      const recipe = Recipe(
        id: 'r5',
        title: 'Boiled Water',
        minutes: 5,
        servings: 1,
        dietTags: {},
        ingredients: [
          RecipeIngredient(name: 'Salt', quantity: 1, unit: 'tsp'),
          RecipeIngredient(name: 'Water', quantity: 500, unit: 'ml'),
        ],
        steps: [
          RecipeStep(text: 'Boil'),
        ],
      );

      final deductions = InventoryDeductionCalculator.compute(
        inventory: inventory,
        recipe: recipe,
        today: now,
      );

      expect(deductions, isEmpty);
    });
  });
}
