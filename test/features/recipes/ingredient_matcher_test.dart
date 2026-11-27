import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/ingredient_matcher.dart';

void main() {
  group('IngredientMatcher', () {
    final now = DateTime(2026, 11, 26);

    Ingredient createIngredient({
      required String name,
      IngredientStatus status = IngredientStatus.active,
    }) {
      return Ingredient(
        id: '1',
        name: name,
        addedAt: now,
        status: status,
      );
    }

    test('normalizes plurals correctly', () {
      expect(IngredientMatcher.normalize('tomatoes'), 'tomato');
      expect(IngredientMatcher.normalize('potatoes'), 'potato');
      expect(IngredientMatcher.normalize('onions'), 'onion');
      expect(IngredientMatcher.normalize('spinach leaves'), 'spinach leaf');
      expect(IngredientMatcher.normalize('strawberries'), 'strawberry');
      expect(IngredientMatcher.normalize('garlic cloves'), 'garlic clove');
    });

    test('strips common culinary adjectives', () {
      expect(IngredientMatcher.normalize('fresh organic tomatoes'), 'tomato');
      expect(IngredientMatcher.normalize('finely chopped onions'), 'onion');
      expect(IngredientMatcher.normalize('minced garlic cloves'), 'garlic clove');
      expect(IngredientMatcher.normalize('diced raw potatoes'), 'potato');
    });

    test('matches exact and pluralized active ingredients', () {
      final tomato = createIngredient(name: 'tomato');
      expect(IngredientMatcher.matches('tomatoes', tomato), isTrue);
      expect(IngredientMatcher.matches('fresh tomato', tomato), isTrue);
      expect(IngredientMatcher.matches('chopped tomatoes', tomato), isTrue);
    });

    test('prevents false match between generic pepper and bell pepper', () {
      final bellPepper = createIngredient(name: 'bell pepper');
      final blackPepper = createIngredient(name: 'pepper');

      // Generic pepper in recipe must NOT match bell pepper in kitchen
      expect(IngredientMatcher.matches('pepper', bellPepper), isFalse);
      expect(IngredientMatcher.matches('black pepper', bellPepper), isFalse);

      // Bell pepper in recipe must NOT match generic pepper in kitchen
      expect(IngredientMatcher.matches('bell pepper', blackPepper), isFalse);

      // Bell pepper in recipe must match bell peppers in kitchen
      expect(IngredientMatcher.matches('bell peppers', bellPepper), isTrue);
    });

    test('never matches against used or discarded ingredients', () {
      final usedTomato = createIngredient(
        name: 'tomato',
        status: IngredientStatus.used,
      );
      final discardedTomato = createIngredient(
        name: 'tomato',
        status: IngredientStatus.discarded,
      );

      expect(IngredientMatcher.matches('tomato', usedTomato), isFalse);
      expect(IngredientMatcher.matches('tomato', discardedTomato), isFalse);
    });
  });
}
