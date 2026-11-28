import '../entities/recipe.dart';
import '../entities/recipe_ingredient.dart';

/// Pure Dart utility to scale recipe quantities for 1 to 12 servings with sensible rounding.
abstract final class ServingsScaler {
  /// Scales a single quantity with human culinary rounding.
  /// Whole units for countable items (pieces, eggs), quarter steps (0.25) for spoons/cups,
  /// 5g/10g increments for grams.
  static double scaleQuantity(double baseQuantity, int baseServings, int targetServings, String unit) {
    if (baseServings <= 0 || targetServings <= 0) return baseQuantity;
    final ratio = targetServings / baseServings;
    final scaled = baseQuantity * ratio;

    final lowerUnit = unit.toLowerCase().trim();
    if (lowerUnit == 'piece' ||
        lowerUnit == 'pieces' ||
        lowerUnit == 'pc' ||
        lowerUnit == 'pcs' ||
        lowerUnit == 'egg' ||
        lowerUnit == 'eggs') {
      return scaled.roundToDouble().clamp(1.0, 999.0);
    }

    if (lowerUnit == 'tbsp' ||
        lowerUnit == 'tsp' ||
        lowerUnit == 'cup' ||
        lowerUnit == 'cups') {
      // Round to nearest 0.25
      return ((scaled * 4).round() / 4.0).clamp(0.25, 999.0);
    }

    if (lowerUnit == 'g' || lowerUnit == 'ml') {
      // Round to nearest 5
      return ((scaled / 5).round() * 5.0).clamp(5.0, 9999.0);
    }

    // Default: round to 1 decimal place
    return double.parse(scaled.toStringAsFixed(1));
  }

  /// Scales all ingredients in a recipe to [targetServings].
  static Recipe scaleRecipe(Recipe recipe, int targetServings) {
    final baseServings = recipe.servings > 0 ? recipe.servings : 2;
    if (baseServings == targetServings) return recipe;

    final scaledIngredients = recipe.ingredients.map((ing) {
      if (ing.quantity == null) return ing;
      final scaled = scaleQuantity(
        ing.quantity!,
        baseServings,
        targetServings,
        ing.unit ?? '',
      );
      return RecipeIngredient(
        name: ing.name,
        quantity: scaled,
        unit: ing.unit,
        isOptional: ing.isOptional,
        isPantryStaple: ing.isPantryStaple,
      );
    }).toList();

    return recipe.copyWith(
      servings: targetServings,
      ingredients: scaledIngredients,
    );
  }
}
