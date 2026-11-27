import '../../../recipes/domain/entities/recipe.dart';
import '../../../recipes/domain/utils/ingredient_matcher.dart';

/// Resolves user questions like "How much oil do I need?" from recipe ingredients.
class AnswerQuantity {
  /// Returns a human-friendly spoken answer for the requested ingredient query.
  static String answer({
    required Recipe recipe,
    required String query,
  }) {
    if (query.trim().isEmpty) {
      return "Which ingredient would you like to know about?";
    }

    final normQuery = IngredientMatcher.normalize(query);

    // Try finding the matching recipe ingredient
    for (final ingredient in recipe.ingredients) {
      final normIng = IngredientMatcher.normalize(ingredient.name);
      if (normQuery.isNotEmpty && (normQuery == normIng || normIng.contains(normQuery) || normQuery.contains(normIng))) {
        if (ingredient.quantity != null) {
          final qty = _formatQuantity(ingredient.quantity!);
          final unit = (ingredient.unit != null && ingredient.unit!.isNotEmpty)
              ? ' ${ingredient.unit}'
              : '';
          return "You need $qty$unit of ${ingredient.name}.";
        } else {
          return "The recipe calls for ${ingredient.name} to taste, or as needed.";
        }
      }
    }

    return "I couldn't find $query in this recipe.";
  }

  static String _formatQuantity(double quantity) {
    if (quantity == quantity.roundToDouble()) {
      return quantity.toInt().toString();
    }
    final diff05 = (quantity - quantity.floor() - 0.5).abs();
    if (diff05 < 0.01) {
      final whole = quantity.floor();
      return whole == 0 ? '1/2' : '$whole 1/2';
    }
    final diff025 = (quantity - quantity.floor() - 0.25).abs();
    if (diff025 < 0.01) {
      final whole = quantity.floor();
      return whole == 0 ? '1/4' : '$whole 1/4';
    }
    final diff075 = (quantity - quantity.floor() - 0.75).abs();
    if (diff075 < 0.01) {
      final whole = quantity.floor();
      return whole == 0 ? '3/4' : '$whole 3/4';
    }
    return quantity.toStringAsFixed(1).replaceAll(RegExp(r'\.0$'), '');
  }
}
