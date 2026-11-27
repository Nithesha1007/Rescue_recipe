import '../../../ingredients/domain/utils/ingredient_merger.dart';
import '../entities/extracted_ingredient.dart';

abstract final class VoiceCorrection {
  static const Map<String, int> _numberWords = {
    'one': 1,
    'two': 2,
    'three': 3,
    'four': 4,
    'five': 5,
    'six': 6,
    'seven': 7,
    'eight': 8,
    'nine': 9,
    'ten': 10,
  };

  static List<ExtractedIngredient> apply(
    List<ExtractedIngredient> currentItems,
    String phrase,
  ) {
    final String clean = phrase.trim().toLowerCase();
    if (clean.isEmpty) return currentItems;

    // 1. Check for removals
    final String? itemToRemove = _detectRemoval(clean);
    if (itemToRemove != null) {
      final String normRemove = IngredientMerger.normalizeName(itemToRemove);
      return currentItems
          .where((item) =>
              IngredientMerger.normalizeName(item.name) != normRemove)
          .toList();
    }

    // 2. Check for quantity adjustments
    final _QuantityCorrection? qtyCorrection = _detectQuantityAdjustment(clean);
    if (qtyCorrection != null) {
      final String normTarget =
          IngredientMerger.normalizeName(qtyCorrection.name);
      return currentItems.map((item) {
        if (IngredientMerger.normalizeName(item.name) == normTarget) {
          return item.copyWith(
            quantity: () => qtyCorrection.quantity,
            unit: qtyCorrection.unit != null ? () => qtyCorrection.unit : null,
          );
        }
        return item;
      }).toList();
    }

    return currentItems;
  }

  static String? _detectRemoval(String text) {
    final patterns = [
      RegExp(r"^(?:actually\s+)?i\s+don't\s+have(?:\s+any)?\s+(.+)$"),
      RegExp(r'^(?:actually\s+)?i\s+dont\s+have(?:\s+any)?\s+(.+)$'),
      RegExp(r'^(?:actually\s+)?remove(?:\s+the)?\s+(.+)$'),
      RegExp(r'^(?:actually\s+)?delete(?:\s+the)?\s+(.+)$'),
      RegExp(r'^(?:actually\s+)?cancel(?:\s+the)?\s+(.+)$'),
      RegExp(r'^no\s+(.+)$'),
      RegExp(r'^without(?:\s+the)?\s+(.+)$'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(text);
      if (match != null) {
        return match.group(1)!.trim();
      }
    }

    return null;
  }

  static _QuantityCorrection? _detectQuantityAdjustment(String text) {
    final RegExp makeIt = RegExp(
        r'^(?:make\s+it|actually|just)\s+(\d+|[a-z]+)\s*(kg|g|grams|litres|litre|cups|cup|pieces|piece)?\s+(.+)$');
    final matchMake = makeIt.firstMatch(text);
    if (matchMake != null) {
      final double? qty = _parseNumber(matchMake.group(1)!);
      if (qty != null) {
        final String? unit = matchMake.group(2);
        final String name = matchMake.group(3)!.trim();
        return _QuantityCorrection(name: name, quantity: qty, unit: unit);
      }
    }

    final RegExp changeTo = RegExp(
        r'^change\s+(.+?)\s+to\s+(\d+|[a-z]+)\s*(kg|g|grams|litres|litre|cups|cup|pieces|piece)?$');
    final matchChange = changeTo.firstMatch(text);
    if (matchChange != null) {
      final String name = matchChange.group(1)!.trim();
      final double? qty = _parseNumber(matchChange.group(2)!);
      if (qty != null) {
        final String? unit = matchChange.group(3);
        return _QuantityCorrection(name: name, quantity: qty, unit: unit);
      }
    }

    final RegExp instead = RegExp(
        r'^(\d+|[a-z]+)\s*(kg|g|grams|litres|litre|cups|cup|pieces|piece)?\s+(.+?)\s+instead$');
    final matchInstead = instead.firstMatch(text);
    if (matchInstead != null) {
      final double? qty = _parseNumber(matchInstead.group(1)!);
      if (qty != null) {
        final String? unit = matchInstead.group(2);
        final String name = matchInstead.group(3)!.trim();
        return _QuantityCorrection(name: name, quantity: qty, unit: unit);
      }
    }

    return null;
  }

  static double? _parseNumber(String token) {
    final double? parsed = double.tryParse(token);
    if (parsed != null) return parsed;
    final int? wordVal = _numberWords[token];
    return wordVal?.toDouble();
  }
}

class _QuantityCorrection {
  const _QuantityCorrection({
    required this.name,
    required this.quantity,
    this.unit,
  });

  final String name;
  final double quantity;
  final String? unit;
}
