import 'package:equatable/equatable.dart';
import '../../../../core/domain/ingredient_vocabulary.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../entities/recipe_ingredient.dart';

enum MatchStatus {
  available,
  needMore,
  missing,
}

class ItemMatchResult extends Equatable {
  final MatchStatus status;
  final RecipeIngredient recipeIngredient;
  final Ingredient? inventoryItem;
  final double? requiredQuantity;
  final double? availableQuantity;

  const ItemMatchResult({
    required this.status,
    required this.recipeIngredient,
    this.inventoryItem,
    this.requiredQuantity,
    this.availableQuantity,
  });

  @override
  List<Object?> get props => [
        status,
        recipeIngredient,
        inventoryItem,
        requiredQuantity,
        availableQuantity,
      ];
}

/// Pure Dart ingredient matcher for matching recipe ingredient requirements against
/// active user inventory items.
class IngredientMatcher {
  IngredientMatcher._();

  static const Set<String> _adjectives = <String>{
    'fresh',
    'chopped',
    'diced',
    'sliced',
    'minced',
    'dried',
    'crushed',
    'cooked',
    'raw',
    'organic',
    'ripe',
    'ground',
    'whole',
    'large',
    'small',
    'medium',
    'finely',
    'roughly',
  };

  /// Normalizes ingredient text: lowercases, trims, strips adjectives, and singularizes plurals.
  static String normalize(String text) {
    String cleaned = text.toLowerCase().trim();
    cleaned = cleaned.replaceAll(RegExp(r'[^a-z\s]'), ' ');

    final tokens = cleaned
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && !_adjectives.contains(t))
        .map(_singularize)
        .toList();

    return tokens.join(' ').trim();
  }

  /// Singularizes a single word using English plural rules.
  static String _singularize(String word) {
    if (word == 'tomatoes') return 'tomato';
    if (word == 'potatoes') return 'potato';
    if (word == 'leaves') return 'leaf';
    if (word == 'berries') return 'berry';
    if (word == 'onions') return 'onion';
    if (word == 'cloves') return 'clove';

    if (word.endsWith('ies') && word.length > 3) {
      return '${word.substring(0, word.length - 3)}y';
    }
    if (word.endsWith('es') && word.length > 3) {
      if (word.endsWith('shes') ||
          word.endsWith('ches') ||
          word.endsWith('sses') ||
          word.endsWith('xes')) {
        return word.substring(0, word.length - 2);
      }
    }
    if (word.endsWith('s') && !word.endsWith('ss') && word.length > 2) {
      return word.substring(0, word.length - 1);
    }
    return word;
  }

  /// Checks if a recipe ingredient name matches an active inventory ingredient.
  ///
  /// Integrates vocabulary resolution (Tamil/Hindi/Tanglish aliases),
  /// exact matching, token containment, and disambiguation.
  static bool matches(String recipeItemName, Ingredient inventoryItem) {
    if (inventoryItem.status != IngredientStatus.active) return false;

    final normRecipe = normalize(recipeItemName);
    final normInv = normalize(inventoryItem.name);

    if (normRecipe.isEmpty || normInv.isEmpty) return false;
    if (normRecipe == normInv) return true;

    // Check canonical vocabulary equivalence
    final canonicalRecipe = IngredientVocabulary.resolve(normRecipe);
    final canonicalInv = IngredientVocabulary.resolve(normInv);
    if (canonicalRecipe == canonicalInv && canonicalRecipe.isNotEmpty) {
      return true;
    }

    // Disambiguation rules to prevent false positives:
    // generic 'pepper' should not match 'bell pepper' or 'chili pepper'
    if ((normRecipe == 'pepper' && normInv.contains('pepper') && normInv != 'pepper') ||
        (normInv == 'pepper' && normRecipe.contains('pepper') && normRecipe != 'pepper')) {
      return false;
    }

    // Token set containment
    final recipeTokens = normRecipe.split(' ').toSet();
    final invTokens = normInv.split(' ').toSet();

    if (recipeTokens.containsAll(invTokens) || invTokens.containsAll(recipeTokens)) {
      return true;
    }

    // Whole-word regex match
    final rRegex = RegExp(r'\b' + RegExp.escape(normRecipe) + r'\b');
    final iRegex = RegExp(r'\b' + RegExp.escape(normInv) + r'\b');
    return rRegex.hasMatch(normInv) || iRegex.hasMatch(normRecipe);
  }

  /// Finds the matching active inventory ingredient, or null if none matches.
  static Ingredient? findMatch(String recipeItemName, List<Ingredient> inventory) {
    for (final inv in inventory) {
      if (matches(recipeItemName, inv)) {
        return inv;
      }
    }
    return null;
  }

  /// Evaluates match status, distinguishing between:
  /// - [MatchStatus.available]: In inventory and sufficient or unspecified quantity
  /// - [MatchStatus.needMore]: In inventory but quantity is strictly less than required
  /// - [MatchStatus.missing]: Not found in inventory
  static ItemMatchResult evaluateMatch(
    RecipeIngredient recipeIngredient,
    List<Ingredient> inventory,
  ) {
    final matchedItem = findMatch(recipeIngredient.name, inventory);
    if (matchedItem == null) {
      return ItemMatchResult(
        status: MatchStatus.missing,
        recipeIngredient: recipeIngredient,
      );
    }

    // Check quantities if both specify numbers
    if (recipeIngredient.quantity != null &&
        matchedItem.quantity != null &&
        matchedItem.quantity! > 0) {
      // If units match or are compatible, and inventory quantity is less than required
      final unitsMatch = recipeIngredient.unit == null ||
          matchedItem.unit == null ||
          recipeIngredient.unit?.toLowerCase() == matchedItem.unit?.toLowerCase();

      if (unitsMatch && matchedItem.quantity! < recipeIngredient.quantity!) {
        return ItemMatchResult(
          status: MatchStatus.needMore,
          recipeIngredient: recipeIngredient,
          inventoryItem: matchedItem,
          requiredQuantity: recipeIngredient.quantity,
          availableQuantity: matchedItem.quantity,
        );
      }
    }

    return ItemMatchResult(
      status: MatchStatus.available,
      recipeIngredient: recipeIngredient,
      inventoryItem: matchedItem,
      requiredQuantity: recipeIngredient.quantity,
      availableQuantity: matchedItem.quantity,
    );
  }
}
