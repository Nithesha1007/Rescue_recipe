import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/utils/ingredient_catalog.dart';

void main() {
  group('IngredientCatalog', () {
    test('resolves default unit correctly', () {
      expect(IngredientCatalog.getDefaultUnit('tomato'), 'pcs');
      expect(IngredientCatalog.getDefaultUnit('spinach'), 'g');
      expect(IngredientCatalog.getDefaultUnit('milk'), 'l');
      expect(IngredientCatalog.getDefaultUnit('oil'), 'tbsp');
      expect(IngredientCatalog.getDefaultUnit('cooking oil'), 'tbsp');
      expect(IngredientCatalog.getDefaultUnit('unknown_special_leaf'), 'pcs');
    });

    test('returns typical shelf life advisory days', () {
      expect(IngredientCatalog.getShelfLifeDays('tomato'), 5);
      expect(IngredientCatalog.getShelfLifeDays('potato'), 21);
      expect(IngredientCatalog.getShelfLifeDays('spinach'), 3);
      expect(IngredientCatalog.getShelfLifeDays('onion'), 14);
      expect(IngredientCatalog.getShelfLifeDays('milk'), 5);
    });

    test('retrieves ingredients by category', () {
      final veggies = IngredientCatalog.getIngredientsForCategory(IngredientCategory.vegetables);
      expect(veggies, contains('tomato'));
      expect(veggies, contains('onion'));
      expect(veggies, contains('spinach'));

      final fruits = IngredientCatalog.getIngredientsForCategory(IngredientCategory.fruits);
      expect(fruits, contains('banana'));
      expect(fruits, contains('apple'));
    });

    test('computes edit distance and suggests fuzzy "Did you mean?" for typos', () {
      expect(IngredientCatalog.suggestCorrection('tomaot'), 'tomato');
      expect(IngredientCatalog.suggestCorrection('tomatos'), 'tomato');
      expect(IngredientCatalog.suggestCorrection('onioon'), 'onion');
      expect(IngredientCatalog.suggestCorrection('garlicc'), 'garlic');

      // Exact match returns null because no typo correction needed
      expect(IngredientCatalog.suggestCorrection('tomato'), isNull);
    });
  });
}
