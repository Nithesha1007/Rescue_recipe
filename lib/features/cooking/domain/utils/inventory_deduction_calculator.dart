import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../../recipes/domain/utils/ingredient_matcher.dart';
import '../entities/inventory_deduction.dart';

/// Calculates proposed inventory deductions after a cooking session completes.
class InventoryDeductionCalculator {
  static const Set<String> _pantryStaples = {
    'salt',
    'water',
    'cooking oil',
    'vegetable oil',
    'olive oil',
    'black pepper',
    'sugar',
  };

  static bool isPantryStaple(String name) {
    final norm = IngredientMatcher.normalize(name);
    return _pantryStaples.contains(norm);
  }

  /// Computes deduction proposals for active inventory items used in [recipe].
  /// [today] is used to evaluate the priority of each item.
  static List<InventoryDeductionProposal> compute({
    required List<Ingredient> inventory,
    required Recipe recipe,
    required DateTime today,
  }) {
    final proposals = <InventoryDeductionProposal>[];

    // Only active (not used or discarded) items can be deducted
    final activeItems = inventory.where((item) => item.status == IngredientStatus.active).toList();

    for (final recipeIng in recipe.ingredients) {
      // Skip pantry staples (salt, water, cooking oil, etc.)
      if (isPantryStaple(recipeIng.name)) {
        continue;
      }

      // Find best matching active inventory item
      Ingredient? bestMatch;
      for (final invItem in activeItems) {
        if (IngredientMatcher.matches(recipeIng.name, invItem)) {
          bestMatch = invItem;
          break;
        }
      }

      if (bestMatch == null) {
        continue;
      }

      final itemPriority = bestMatch.priority(today: today);

      // Check if unit and quantity can be compared/reduced safely
      final deduction = _calculateDeduction(
        inventoryItem: bestMatch,
        recipeQuantity: recipeIng.quantity,
        recipeUnit: recipeIng.unit,
        priority: itemPriority,
      );

      if (deduction != null) {
        // Prevent duplicate proposals for the same item ID
        if (!proposals.any((p) => p.ingredientId == deduction.ingredientId)) {
          proposals.add(deduction);
        }
      }
    }

    return proposals;
  }

  static InventoryDeductionProposal? _calculateDeduction({
    required Ingredient inventoryItem,
    required double? recipeQuantity,
    required String? recipeUnit,
    required dynamic priority,
  }) {
    final invQty = inventoryItem.quantity;
    final invUnit = inventoryItem.unit?.trim().toLowerCase() ?? '';
    final rUnit = recipeUnit?.trim().toLowerCase() ?? '';

    // If inventory has no quantity or recipe has no quantity: fallback to markUsed
    if (invQty == null || recipeQuantity == null || recipeQuantity <= 0) {
      return InventoryDeductionProposal(
        ingredientId: inventoryItem.id,
        ingredientName: inventoryItem.name,
        currentQuantity: invQty ?? 1.0,
        deductQuantity: null,
        remainingQuantity: null,
        unit: inventoryItem.unit ?? 'item',
        action: DeductionAction.markUsed,
        priority: priority,
        isConfirmed: true,
      );
    }

    // Attempt safe conversion if units differ
    final convertedRecipeQty = _convertQuantity(
      fromQty: recipeQuantity,
      fromUnit: rUnit,
      toUnit: invUnit,
    );

    if (convertedRecipeQty == null) {
      return InventoryDeductionProposal(
        ingredientId: inventoryItem.id,
        ingredientName: inventoryItem.name,
        currentQuantity: invQty,
        deductQuantity: null,
        remainingQuantity: null,
        unit: inventoryItem.unit ?? '',
        action: DeductionAction.markUsed,
        priority: priority,
        isConfirmed: true,
      );
    }

    final remaining = invQty - convertedRecipeQty;
    if (remaining <= 0.001) {
      return InventoryDeductionProposal(
        ingredientId: inventoryItem.id,
        ingredientName: inventoryItem.name,
        currentQuantity: invQty,
        deductQuantity: invQty,
        remainingQuantity: 0.0,
        unit: inventoryItem.unit ?? '',
        action: DeductionAction.markUsed,
        priority: priority,
        isConfirmed: true,
      );
    } else {
      return InventoryDeductionProposal(
        ingredientId: inventoryItem.id,
        ingredientName: inventoryItem.name,
        currentQuantity: invQty,
        deductQuantity: convertedRecipeQty,
        remainingQuantity: double.parse(remaining.toStringAsFixed(2)),
        unit: inventoryItem.unit ?? '',
        action: DeductionAction.reduce,
        priority: priority,
        isConfirmed: true,
      );
    }
  }

  static double? _convertQuantity({
    required double fromQty,
    required String fromUnit,
    required String toUnit,
  }) {
    if (fromUnit == toUnit) return fromQty;

    // Weight: g <-> kg
    if ((fromUnit == 'g' || fromUnit == 'gram' || fromUnit == 'grams') &&
        (toUnit == 'kg' || toUnit == 'kilogram' || toUnit == 'kgs')) {
      return fromQty / 1000.0;
    }
    if ((fromUnit == 'kg' || fromUnit == 'kilogram' || fromUnit == 'kgs') &&
        (toUnit == 'g' || toUnit == 'gram' || toUnit == 'grams')) {
      return fromQty * 1000.0;
    }

    // Volume: ml <-> l
    if ((fromUnit == 'ml' || fromUnit == 'milliliter' || fromUnit == 'milliliters') &&
        (toUnit == 'l' || toUnit == 'liter' || toUnit == 'liters')) {
      return fromQty / 1000.0;
    }
    if ((fromUnit == 'l' || fromUnit == 'liter' || fromUnit == 'liters') &&
        (toUnit == 'ml' || toUnit == 'milliliter' || toUnit == 'milliliters')) {
      return fromQty * 1000.0;
    }

    return null;
  }
}
