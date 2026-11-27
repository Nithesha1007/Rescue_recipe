import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/ingredient_matcher.dart';

void main() {
  group('IngredientMatcher V2 Tests', () {
    test('matches canonical English to regional aliases (vengayam -> onion, thakkali -> tomato)', () {
      final inventoryItem = Ingredient(
        id: '1',
        name: 'vengayam',
        addedAt: DateTime.now(),
        status: IngredientStatus.active,
      );

      expect(IngredientMatcher.matches('onion', inventoryItem), isTrue);
      expect(IngredientMatcher.matches('onions', inventoryItem), isTrue);
      expect(IngredientMatcher.matches('potato', inventoryItem), isFalse);
    });

    test('matches thakkali to tomato and plural forms', () {
      final inventoryItem = Ingredient(
        id: '2',
        name: 'thakkali',
        addedAt: DateTime.now(),
        status: IngredientStatus.active,
      );

      expect(IngredientMatcher.matches('tomato', inventoryItem), isTrue);
      expect(IngredientMatcher.matches('tomatoes', inventoryItem), isTrue);
    });

    test('disambiguates pepper from bell pepper and chili pepper', () {
      final bellPepper = Ingredient(
        id: '3',
        name: 'bell pepper',
        addedAt: DateTime.now(),
        status: IngredientStatus.active,
      );

      expect(IngredientMatcher.matches('pepper', bellPepper), isFalse);
      expect(IngredientMatcher.matches('bell pepper', bellPepper), isTrue);
    });

    test('evaluates MatchStatus.available when quantity is sufficient or unspecified', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomato',
          quantity: 4,
          unit: 'pieces',
          addedAt: DateTime.now(),
          status: IngredientStatus.active,
        ),
      ];

      const recipeReq = RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pieces');
      final result = IngredientMatcher.evaluateMatch(recipeReq, inventory);

      expect(result.status, MatchStatus.available);
      expect(result.inventoryItem, isNotNull);
    });

    test('evaluates MatchStatus.needMore when inventory has some but less than recipe requirement', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomato',
          quantity: 1,
          unit: 'pieces',
          addedAt: DateTime.now(),
          status: IngredientStatus.active,
        ),
      ];

      const recipeReq = RecipeIngredient(name: 'tomato', quantity: 3, unit: 'pieces');
      final result = IngredientMatcher.evaluateMatch(recipeReq, inventory);

      expect(result.status, MatchStatus.needMore);
      expect(result.inventoryItem, isNotNull);
      expect(result.availableQuantity, 1.0);
      expect(result.requiredQuantity, 3.0);
    });

    test('evaluates MatchStatus.missing when ingredient is not in inventory', () {
      final inventory = [
        Ingredient(
          id: '1',
          name: 'tomato',
          addedAt: DateTime.now(),
          status: IngredientStatus.active,
        ),
      ];

      const recipeReq = RecipeIngredient(name: 'spinach', quantity: 100, unit: 'g');
      final result = IngredientMatcher.evaluateMatch(recipeReq, inventory);

      expect(result.status, MatchStatus.missing);
      expect(result.inventoryItem, isNull);
    });
  });
}
