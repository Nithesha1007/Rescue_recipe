import '../../../../core/domain/ingredient_vocabulary.dart';
import '../../domain/entities/ingredient.dart';

/// Pure Dart utility to detect and split glued ingredients into distinct entities.
abstract final class GluedIngredientSplitter {
  /// Splits a raw string into separate candidate ingredient names.
  static List<String> tokenize(String input) {
    final lower = input.toLowerCase().trim();
    if (lower.isEmpty) return const [];

    // Check if it contains explicit separators: comma, plus, and, &, or
    final rawParts = lower
        .split(RegExp(r'[,+&]|\band\b|\bor\b'))
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    if (rawParts.length > 1) {
      return rawParts.map((p) => IngredientVocabulary.resolve(p)).toList();
    }

    // Check greedy matching from known sorted aliases
    final found = <String>[];
    String remaining = lower;
    for (final alias in IngredientVocabulary.sortedAliases) {
      if (alias.length < 3) continue;
      final pattern = RegExp('\\b${RegExp.escape(alias)}\\b');
      if (pattern.hasMatch(remaining)) {
        found.add(IngredientVocabulary.resolve(alias));
        remaining = remaining.replaceAll(pattern, ' ').trim();
      }
    }
    if (found.length > 1) {
      return found;
    }

    // If space-separated words each resolve to known items
    final words = lower.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
    if (words.length > 1) {
      final resolved = words
          .where((w) => IngredientVocabulary.aliasToCanonical.containsKey(w))
          .map((w) => IngredientVocabulary.resolve(w))
          .toList();
      if (resolved.length == words.length) {
        return resolved;
      }
    }

    return [input.trim()];
  }

  /// Returns `true` if [ingredient] contains multiple distinct vocabulary items glued together.
  static bool isGlued(Ingredient ingredient) {
    final tokens = tokenize(ingredient.name);
    return tokens.length > 1;
  }

  /// Splits a glued ingredient into multiple individual ingredients, preserving expiry and adding sensible individual quantities.
  static List<Ingredient> split(Ingredient gluedItem) {
    final tokens = tokenize(gluedItem.name);
    if (tokens.length <= 1) return [gluedItem];

    return tokens.asMap().entries.map((entry) {
      final idx = entry.key;
      final name = entry.value;
      return Ingredient(
        id: '${gluedItem.id}_split_$idx',
        name: name,
        quantity: gluedItem.quantity != null
            ? (gluedItem.quantity! / tokens.length).clamp(1.0, 999.0)
            : null,
        unit: gluedItem.unit,
        expiryDate: gluedItem.expiryDate,
        status: gluedItem.status,
        addedAt: gluedItem.addedAt,
      );
    }).toList();
  }
}
