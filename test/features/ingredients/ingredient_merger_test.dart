import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/utils/ingredient_merger.dart';

void main() {
  group('IngredientMerger', () {
    final DateTime dateA = DateTime(2026, 11, 27);
    final DateTime dateB = DateTime(2026, 11, 28);
    final DateTime now = DateTime(2026, 11, 26);

    test('same name, unit, and date merges and sums quantity', () {
      final existing = [
        Ingredient(
          id: '1',
          name: 'tomato',
          quantity: 2,
          unit: 'pieces',
          expiryDate: dateA,
          addedAt: now,
        ),
      ];
      final incoming = [
        Ingredient(
          id: '2',
          name: 'tomatoes', // plural
          quantity: 3,
          unit: 'pieces',
          expiryDate: dateA,
          addedAt: now,
        ),
      ];

      final merged = IngredientMerger.merge(existing, incoming);
      expect(merged.length, 1);
      expect(merged.first.quantity, 5);
      expect(merged.first.name, 'tomato');
    });

    test('different expiry date stays separate', () {
      final existing = [
        Ingredient(
          id: '1',
          name: 'tomato',
          quantity: 2,
          unit: 'pieces',
          expiryDate: dateA,
          addedAt: now,
        ),
      ];
      final incoming = [
        Ingredient(
          id: '2',
          name: 'tomato',
          quantity: 3,
          unit: 'pieces',
          expiryDate: dateB,
          addedAt: now,
        ),
      ];

      final merged = IngredientMerger.merge(existing, incoming);
      expect(merged.length, 2);
    });

    test('different unit stays separate', () {
      final existing = [
        Ingredient(
          id: '1',
          name: 'onion',
          quantity: 2,
          unit: 'pieces',
          expiryDate: dateA,
          addedAt: now,
        ),
      ];
      final incoming = [
        Ingredient(
          id: '2',
          name: 'onions',
          quantity: 500,
          unit: 'g',
          expiryDate: dateA,
          addedAt: now,
        ),
      ];

      final merged = IngredientMerger.merge(existing, incoming);
      expect(merged.length, 2);
    });

    test('null quantity stays null and does not invent a number', () {
      final existing = [
        Ingredient(
          id: '1',
          name: 'spinach',
          quantity: null,
          unit: null,
          expiryDate: dateA,
          addedAt: now,
        ),
      ];
      final incoming = [
        Ingredient(
          id: '2',
          name: 'spinach',
          quantity: 1,
          unit: null,
          expiryDate: dateA,
          addedAt: now,
        ),
      ];

      final merged = IngredientMerger.merge(existing, incoming);
      expect(merged.length, 1);
      expect(merged.first.quantity, isNull);
    });

    test('sorting order: Expired, Critical, High, Medium, Low, Unknown', () {
      final items = [
        Ingredient(
          id: 'unknown',
          name: 'potato',
          expiryDate: null,
          addedAt: now,
        ),
        Ingredient(
          id: 'expired',
          name: 'milk',
          expiryDate: DateTime(2026, 11, 24), // -2 days
          addedAt: now,
        ),
        Ingredient(
          id: 'low',
          name: 'apple',
          expiryDate: DateTime(2026, 12, 10), // +14 days
          addedAt: now,
        ),
        Ingredient(
          id: 'high',
          name: 'bread',
          expiryDate: DateTime(2026, 11, 27), // +1 day
          addedAt: now,
        ),
        Ingredient(
          id: 'critical',
          name: 'fish',
          expiryDate: DateTime(2026, 11, 26), // 0 days
          addedAt: now,
        ),
        Ingredient(
          id: 'medium',
          name: 'cheese',
          expiryDate: DateTime(2026, 11, 30), // +4 days
          addedAt: now,
        ),
      ];

      final sorted = IngredientMerger.sortInventory(items, today: now);
      final ids = sorted.map((i) => i.id).toList();

      expect(ids, [
        'expired',
        'critical',
        'high',
        'medium',
        'low',
        'unknown',
      ]);
    });
  });
}
