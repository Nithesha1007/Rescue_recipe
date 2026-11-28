import '../../../../core/domain/ingredient_vocabulary.dart';
import '../entities/recipe_ingredient.dart';
import '../entities/recipe_step.dart';

/// Links ingredients from the recipe's ingredient list to individual steps.
/// Matches against step.uses and scans step text for ingredient canonical names,
/// aliases, and plurals.
class StepIngredientLinker {
  const StepIngredientLinker._();

  /// Returns the subset of [recipeIngredients] used in [step].
  /// Matches first by explicit `step.uses` names, then by tokenizing and scanning
  /// the step text against ingredient names and their vocabulary aliases.
  static List<RecipeIngredient> linkIngredientsForStep({
    required RecipeStep step,
    required List<RecipeIngredient> recipeIngredients,
  }) {
    if (recipeIngredients.isEmpty) return const [];

    final matched = <RecipeIngredient>{};

    // 1. Explicit uses from Gemini
    if (step.uses.isNotEmpty) {
      final usesSet = step.uses.map((u) => u.toLowerCase().trim()).toSet();
      for (final ing in recipeIngredients) {
        final canonical = ing.name.toLowerCase().trim();
        if (usesSet.contains(canonical) ||
            usesSet.any((u) => u.contains(canonical) || canonical.contains(u))) {
          matched.add(ing);
        }
      }
    }

    // 2. Text scanning fallback/enhancement
    final stepTextLower = ' ${step.text.toLowerCase()} ';
    for (final ing in recipeIngredients) {
      if (matched.contains(ing)) continue;

      final canonical = ing.name.toLowerCase().trim();
      final aliases = _aliasesForIngredient(canonical);

      for (final alias in aliases) {
        // Match word boundaries so 'oil' does not match 'boil'
        final pattern = RegExp(r'\b' + RegExp.escape(alias) + r'\b', caseSensitive: false);
        if (pattern.hasMatch(stepTextLower)) {
          matched.add(ing);
          break;
        }
      }
    }

    return matched.toList();
  }

  /// Formats ingredient chip label with scaled quantity (e.g. "tomato 2 pcs" or "oil 1 tbsp").
  /// Ingredients with null quantity format as "tomato (as needed)".
  static String formatChipLabel(RecipeIngredient ing) {
    if (ing.quantity != null && ing.quantity! > 0) {
      final formattedQty = (ing.quantity! % 1 == 0)
          ? ing.quantity!.toInt().toString()
          : ing.quantity!.toStringAsFixed(1);
      final unitStr = (ing.unit != null && ing.unit!.isNotEmpty) ? ' ${ing.unit}' : '';
      return '${ing.displayName} $formattedQty$unitStr';
    }
    return '${ing.displayName} (as needed)';
  }

  /// Formats spoken ingredients string for TTS recital (e.g. "Take 2 tomatoes and 1 tablespoon of oil").
  static String formatSpokenList(List<RecipeIngredient> ingredients) {
    if (ingredients.isEmpty) return '';
    final parts = ingredients.map((i) {
      if (i.quantity != null && i.quantity! > 0) {
        final formattedQty = (i.quantity! % 1 == 0)
            ? i.quantity!.toInt().toString()
            : i.quantity!.toStringAsFixed(1);
        final unitStr = (i.unit != null && i.unit!.isNotEmpty) ? ' ${i.unit}' : '';
        return '$formattedQty$unitStr ${i.displayName}';
      }
      return i.displayName;
    }).toList();

    if (parts.length == 1) return 'Using ${parts.first}';
    if (parts.length == 2) return 'Using ${parts[0]} and ${parts[1]}';
    return 'Using ${parts.sublist(0, parts.length - 1).join(', ')}, and ${parts.last}';
  }

  /// Builds natural spoken step text reciting linked ingredients and quantities before the instruction.
  static String buildSpokenStepText({
    required RecipeStep step,
    required List<RecipeIngredient> recipeIngredients,
  }) {
    final linked = linkIngredientsForStep(step: step, recipeIngredients: recipeIngredients);
    final prefix = formatSpokenList(linked);
    if (prefix.isNotEmpty) {
      return '$prefix. ${step.text}';
    }
    return step.text;
  }

  static Set<String> _aliasesForIngredient(String canonicalName) {
    final results = <String>{canonicalName};

    // Plural / singular variations
    if (canonicalName.endsWith('s')) {
      results.add(canonicalName.substring(0, canonicalName.length - 1));
    } else {
      results.add('${canonicalName}s');
      results.add('${canonicalName}es');
    }

    // Vocabulary mappings
    IngredientVocabulary.aliasToCanonical.forEach((alias, target) {
      if (target.toLowerCase() == canonicalName) {
        results.add(alias.toLowerCase());
      }
    });

    return results;
  }
}
