import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/utils/glued_ingredient_splitter.dart';

void main() {
  group('GluedIngredientSplitter', () {
    test('detects and splits comma-separated ingredients', () {
      final item = Ingredient(
        id: 'glued_1',
        name: 'tomato, onion, garlic',
        quantity: 3,
        unit: 'pcs',
        addedAt: DateTime(2025, 1, 1),
      );

      expect(GluedIngredientSplitter.isGlued(item), isTrue);
      final split = GluedIngredientSplitter.split(item);
      expect(split.length, equals(3));
      expect(split[0].name, equals('tomato'));
      expect(split[1].name, equals('onion'));
      expect(split[2].name, equals('garlic'));
      expect(split[0].quantity, equals(1.0));
    });

    test('detects and splits "and" separated ingredients', () {
      final item = Ingredient(
        id: 'glued_2',
        name: 'potatoes and carrots',
        quantity: 2,
        addedAt: DateTime(2025, 1, 1),
      );

      expect(GluedIngredientSplitter.isGlued(item), isTrue);
      final split = GluedIngredientSplitter.split(item);
      expect(split.length, equals(2));
      expect(split[0].name, equals('potato'));
      expect(split[1].name, equals('carrot'));
    });

    test('detects and splits space-separated known ingredients', () {
      final item = Ingredient(
        id: 'glued_3',
        name: 'tomato potato onion',
        addedAt: DateTime(2025, 1, 1),
      );

      expect(GluedIngredientSplitter.isGlued(item), isTrue);
      final split = GluedIngredientSplitter.split(item);
      expect(split.length, equals(3));
      expect(split.map((i) => i.name).toList(), containsAll(['tomato', 'potato', 'onion']));
    });

    test('does not split single ingredient with alias or space', () {
      final single = Ingredient(
        id: 'single_1',
        name: 'bell pepper',
        quantity: 2,
        addedAt: DateTime(2025, 1, 1),
      );

      expect(GluedIngredientSplitter.isGlued(single), isFalse);
      final split = GluedIngredientSplitter.split(single);
      expect(split.length, equals(1));
      expect(split.first.name, equals('bell pepper'));
    });
  });
}
