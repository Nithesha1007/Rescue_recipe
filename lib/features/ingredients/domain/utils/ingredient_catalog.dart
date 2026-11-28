import '../../../../core/domain/ingredient_vocabulary.dart';

enum IngredientCategory {
  vegetables('Vegetables', '🥦'),
  fruits('Fruits', '🍎'),
  dairyEggs('Dairy and Eggs', '🥛'),
  grainsPulses('Grains and Pulses', '🌾'),
  meatFish('Meat and Fish', '🍗'),
  spicesStaples('Spices and Staples', '🧂');

  const IngredientCategory(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

class IngredientCatalog {
  const IngredientCatalog._();

  static const Map<String, ({IngredientCategory category, String defaultUnit, int shelfLifeDays})> _meta = {
    // Vegetables
    'tomato': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 5),
    'onion': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 14),
    'potato': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 21),
    'spinach': (category: IngredientCategory.vegetables, defaultUnit: 'g', shelfLifeDays: 3),
    'carrot': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 10),
    'garlic': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 30),
    'ginger': (category: IngredientCategory.vegetables, defaultUnit: 'g', shelfLifeDays: 14),
    'bell pepper': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 7),
    'capsicum': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 7),
    'broccoli': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 5),
    'cucumber': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 6),
    'cabbage': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 12),
    'cauliflower': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 7),
    'eggplant': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 5),
    'green chili': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 7),
    'beetroot': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 14),
    'radish': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 8),
    'mushroom': (category: IngredientCategory.vegetables, defaultUnit: 'g', shelfLifeDays: 4),
    'sweet potato': (category: IngredientCategory.vegetables, defaultUnit: 'pcs', shelfLifeDays: 14),
    'green peas': (category: IngredientCategory.vegetables, defaultUnit: 'g', shelfLifeDays: 5),

    // Fruits
    'apple': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 14),
    'banana': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 4),
    'lemon': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 14),
    'orange': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 10),
    'mango': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 5),
    'watermelon': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 7),
    'avocado': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 4),
    'coconut': (category: IngredientCategory.fruits, defaultUnit: 'pcs', shelfLifeDays: 20),

    // Dairy & Eggs
    'milk': (category: IngredientCategory.dairyEggs, defaultUnit: 'l', shelfLifeDays: 5),
    'curd': (category: IngredientCategory.dairyEggs, defaultUnit: 'cup', shelfLifeDays: 5),
    'yogurt': (category: IngredientCategory.dairyEggs, defaultUnit: 'cup', shelfLifeDays: 7),
    'paneer': (category: IngredientCategory.dairyEggs, defaultUnit: 'g', shelfLifeDays: 4),
    'cheese': (category: IngredientCategory.dairyEggs, defaultUnit: 'g', shelfLifeDays: 14),
    'butter': (category: IngredientCategory.dairyEggs, defaultUnit: 'tbsp', shelfLifeDays: 30),
    'ghee': (category: IngredientCategory.dairyEggs, defaultUnit: 'tbsp', shelfLifeDays: 90),
    'egg': (category: IngredientCategory.dairyEggs, defaultUnit: 'pcs', shelfLifeDays: 14),

    // Grains & Pulses
    'rice': (category: IngredientCategory.grainsPulses, defaultUnit: 'kg', shelfLifeDays: 180),
    'toor dal': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 180),
    'moong dal': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 180),
    'urad dal': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 180),
    'chana dal': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 180),
    'flour': (category: IngredientCategory.grainsPulses, defaultUnit: 'kg', shelfLifeDays: 90),
    'atta': (category: IngredientCategory.grainsPulses, defaultUnit: 'kg', shelfLifeDays: 90),
    'poha': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 90),
    'oats': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 90),
    'pasta': (category: IngredientCategory.grainsPulses, defaultUnit: 'g', shelfLifeDays: 180),

    // Meat & Fish
    'chicken': (category: IngredientCategory.meatFish, defaultUnit: 'g', shelfLifeDays: 2),
    'fish': (category: IngredientCategory.meatFish, defaultUnit: 'g', shelfLifeDays: 2),
    'mutton': (category: IngredientCategory.meatFish, defaultUnit: 'g', shelfLifeDays: 3),
    'prawns': (category: IngredientCategory.meatFish, defaultUnit: 'g', shelfLifeDays: 2),

    // Spices & Staples
    'cooking oil': (category: IngredientCategory.spicesStaples, defaultUnit: 'tbsp', shelfLifeDays: 180),
    'oil': (category: IngredientCategory.spicesStaples, defaultUnit: 'tbsp', shelfLifeDays: 180),
    'mustard seeds': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'cumin': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'turmeric': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'chili powder': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'coriander powder': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'garam masala': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 365),
    'salt': (category: IngredientCategory.spicesStaples, defaultUnit: 'tsp', shelfLifeDays: 730),
    'sugar': (category: IngredientCategory.spicesStaples, defaultUnit: 'tbsp', shelfLifeDays: 730),
    'tamarind': (category: IngredientCategory.spicesStaples, defaultUnit: 'g', shelfLifeDays: 180),
  };

  /// Smart default unit for ingredient name.
  static String getDefaultUnit(String ingredientName) {
    final canonical = IngredientVocabulary.resolve(ingredientName);
    return _meta[canonical]?.defaultUnit ?? 'pcs';
  }

  /// Shelf life suggestion in days for general guidance (approximate, not safety guarantee).
  static int? getTypicalShelfLifeDays(String ingredientName) {
    final canonical = IngredientVocabulary.resolve(ingredientName);
    return _meta[canonical]?.shelfLifeDays;
  }

  /// Alias for getTypicalShelfLifeDays.
  static int? getShelfLifeDays(String ingredientName) => getTypicalShelfLifeDays(ingredientName);

  /// Category for ingredient.
  static IngredientCategory getCategory(String ingredientName) {
    final canonical = IngredientVocabulary.resolve(ingredientName);
    return _meta[canonical]?.category ?? IngredientCategory.vegetables;
  }

  /// All unique canonical ingredients grouped by category for browse grid.
  static List<String> getIngredientsForCategory(IngredientCategory category) {
    return _meta.entries
        .where((e) => e.value.category == category)
        .map((e) => e.key)
        .toList();
  }

  /// Calculates Levenshtein distance between two strings for "Did you mean" detection.
  static int editDistance(String s1, String s2) {
    final a = s1.toLowerCase().trim();
    final b = s2.toLowerCase().trim();
    if (a == b) return 0;
    if (a.isEmpty) return b.length;
    if (b.isEmpty) return a.length;

    List<int> prev = List<int>.generate(b.length + 1, (i) => i);
    List<int> curr = List<int>.filled(b.length + 1, 0);

    for (int i = 0; i < a.length; i++) {
      curr[0] = i + 1;
      for (int j = 0; j < b.length; j++) {
        final cost = (a[i] == b[j]) ? 0 : 1;
        curr[j + 1] = [
          curr[j] + 1,       // insertion
          prev[j + 1] + 1,   // deletion
          prev[j] + cost,    // substitution
        ].reduce((min, val) => val < min ? val : min);
      }
      prev = List<int>.from(curr);
    }
    return curr[b.length];
  }

  /// Finds the best near miss in vocabulary for misspelled inputs (e.g. "Brocoli" -> "broccoli").
  static String? findDidYouMean(String query) {
    final clean = query.trim().toLowerCase();
    if (clean.length < 3) return null;

    String? bestCandidate;
    int minDistance = 999;

    // Check all canonicals and aliases
    final allKeys = {
      ..._meta.keys,
      ...IngredientVocabulary.aliasToCanonical.keys,
    };

    for (final candidate in allKeys) {
      if (candidate == clean) return null; // Exact match, no suggestion needed
      final dist = editDistance(clean, candidate);
      if (dist <= 2 && dist < minDistance && dist < clean.length ~/ 2 + 1) {
        minDistance = dist;
        bestCandidate = IngredientVocabulary.resolve(candidate);
      }
    }

    return bestCandidate;
  }

  /// Alias for findDidYouMean.
  static String? suggestCorrection(String query) => findDidYouMean(query);
}
