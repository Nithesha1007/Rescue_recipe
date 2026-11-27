import '../../domain/entities/ingredient.dart';

class DemoIngredients {
  static List<Ingredient> load({DateTime? now}) {
    final base = now ?? DateTime.now();
    return [
      Ingredient(
        id: 'demo_milk',
        name: 'milk',
        quantity: 1,
        unit: 'l',
        expiryDate: base.add(const Duration(days: 0)), // expires today
        addedAt: base.subtract(const Duration(days: 2)),
      ),
      Ingredient(
        id: 'demo_spinach',
        name: 'spinach',
        quantity: 250,
        unit: 'g',
        expiryDate: base.add(const Duration(days: 1)), // expires tomorrow
        addedAt: base.subtract(const Duration(days: 1)),
      ),
      Ingredient(
        id: 'demo_tomato',
        name: 'tomato',
        quantity: 4,
        unit: 'piece',
        expiryDate: base.add(const Duration(days: 2)),
        addedAt: base.subtract(const Duration(days: 1)),
      ),
      Ingredient(
        id: 'demo_bread',
        name: 'bread',
        quantity: 1,
        unit: 'pack',
        expiryDate: base.add(const Duration(days: 3)),
        addedAt: base,
      ),
      Ingredient(
        id: 'demo_paneer',
        name: 'paneer',
        quantity: 200,
        unit: 'g',
        expiryDate: base.add(const Duration(days: 4)),
        addedAt: base,
      ),
      Ingredient(
        id: 'demo_onion',
        name: 'onion',
        quantity: 1,
        unit: 'kg',
        expiryDate: base.add(const Duration(days: 10)),
        addedAt: base,
      ),
    ];
  }
}
