import '../../../../core/domain/ingredient_vocabulary.dart';
import '../../domain/entities/extracted_ingredient.dart';

abstract final class OfflineIngredientParser {
  static const Map<String, double> _numberWords = {
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
    'half': 0.5,
    'half a': 0.5,
    'a': 1,
    'an': 1,
  };

  static const List<String> _units = [
    'kg',
    'kilo',
    'kilos',
    'kilograms',
    'g',
    'grams',
    'litre',
    'litres',
    'l',
    'ml',
    'cup',
    'cups',
    'piece',
    'pieces',
    'bunch',
    'bunches',
    'can',
    'cans',
    'slice',
    'slices',
    'clove',
    'cloves',
    'tablespoon',
    'tablespoons',
    'teaspoon',
    'teaspoons',
  ];

  static List<ExtractedIngredient> parse(String text) {
    if (text.trim().isEmpty) return const [];

    final String clean = text.trim();
    // 1. Extract expiry attachments
    final Map<String, String> expiryMap = _extractExpiryMap(clean);

    // 2. Strip conversational filler prefix
    String cleanedText = clean;
    final List<String> fillerPrefixes = [
      'i have',
      'we have',
      "i've got",
      'i got',
      'there is',
      'there are',
      'here is',
      'here are',
    ];

    for (final prefix in fillerPrefixes) {
      if (cleanedText.toLowerCase().startsWith(prefix)) {
        cleanedText = cleanedText.substring(prefix.length).trim();
      }
    }

    // 3. Remove expiry clauses from ingredient scanning
    // First, remove separate clauses like "my tomatoes expire tomorrow"
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\bmy\s+[a-zA-Z]+\s+(?:expires|expire|expiring)\s+[a-zA-Z0-9\s]+(?:[\.,;]|$)', caseSensitive: false),
      ' ',
    );
    // Next, remove inline expiry phrases like "expiring in 3 days" leaving the ingredient name
    cleanedText = cleanedText.replaceAll(
      RegExp(r'\b(?:expires|expire|expiring)\s+[a-zA-Z0-9\s]+?(?=(?:,|and\b|$))', caseSensitive: false),
      ' ',
    );

    // 4. Tokenize and segment by matching vocabulary and punctuation
    return _segmentText(cleanedText, expiryMap);
  }

  /// Re-segments glued multi-word strings into distinct individual ingredients
  static List<ExtractedIngredient> reSegment(String text) {
    return _segmentText(text, {});
  }

  static List<ExtractedIngredient> _segmentText(String text, Map<String, String> expiryMap) {
    final List<ExtractedIngredient> results = [];
    final lower = text.toLowerCase();

    // Scan for vocabulary matches in order of descending length
    final List<_MatchSpan> spans = [];

    for (final alias in IngredientVocabulary.sortedAliases) {
      final reg = RegExp(r'\b' + RegExp.escape(alias) + r'\b');
      for (final match in reg.allMatches(lower)) {
        // Prevent overlapping with already claimed spans
        final collides = spans.any((s) => (match.start < s.end && match.end > s.start));
        if (!collides) {
          spans.add(_MatchSpan(
            start: match.start,
            end: match.end,
            alias: alias,
            canonical: IngredientVocabulary.resolve(alias),
          ));
        }
      }
    }

    // Sort spans by start position in sentence
    spans.sort((a, b) => a.start.compareTo(b.start));

    if (spans.isEmpty) {
      // Fallback: if no vocabulary words detected, split by commas/and
      final tokens = text.split(RegExp(r'[\.,;\n]|\s+and\s+', caseSensitive: false))
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty);
      for (final tok in tokens) {
        final parsed = _parseSingleToken(tok, expiryMap);
        if (parsed != null) results.add(parsed);
      }
      return results;
    }

    // Process each detected span with preceding text context
    int lastEnd = 0;
    for (int i = 0; i < spans.length; i++) {
      final currentSpan = spans[i];
      final precedingText = text.substring(lastEnd, currentSpan.start).trim();
      lastEnd = currentSpan.end;

      // Extract quantity and unit from preceding slice
      final (double? qty, String? unit) = _extractQuantityAndUnit(precedingText);

      // Check if this canonical item has an attached expiry phrase
      final expiryPhrase = expiryMap[currentSpan.canonical] ?? expiryMap[currentSpan.alias];

      results.add(ExtractedIngredient(
        name: currentSpan.canonical,
        spokenName: currentSpan.alias,
        quantity: qty,
        unit: unit,
        expiryPhrase: expiryPhrase,
      ));
    }

    return results;
  }

  static (double?, String?) _extractQuantityAndUnit(String text) {
    if (text.isEmpty) return (null, null);

    final clean = text.replaceAll(RegExp(r'\bof(?:\s+the)?\s*$', caseSensitive: false), '').trim();
    final lower = clean.toLowerCase();

    // Check vague quantities
    if (lower.endsWith('some') || lower.endsWith('a bit') || lower.endsWith('a handful') || lower.endsWith('handful')) {
      return (null, null);
    }

    // Check numeric digit
    final digitMatch = RegExp(r'(\d+(?:\.\d+)?)\s*([a-zA-Z]+)?$').firstMatch(lower);
    if (digitMatch != null) {
      final val = double.tryParse(digitMatch.group(1)!);
      final rawUnit = digitMatch.group(2);
      String? unit;
      if (rawUnit != null && _units.contains(rawUnit)) {
        unit = rawUnit;
      }
      return (val, unit);
    }

    // Check number words
    for (final entry in _numberWords.entries) {
      final reg = RegExp(r'\b' + entry.key + r'(?:\s+([a-zA-Z]+))?$');
      final match = reg.firstMatch(lower);
      if (match != null) {
        final rawUnit = match.group(1);
        String? unit;
        if (rawUnit != null && _units.contains(rawUnit)) {
          unit = rawUnit;
        }
        return (entry.value, unit);
      }
    }

    return (null, null);
  }

  static ExtractedIngredient? _parseSingleToken(String raw, Map<String, String> expiryMap) {
    final lower = raw.toLowerCase().trim();
    if (lower.isEmpty) return null;

    final (qty, unit) = _extractQuantityAndUnit(lower);
    String name = lower;
    if (qty != null) {
      name = name.replaceAll(RegExp(r'\b\d+(?:\.\d+)?\b'), '').trim();
    }
    for (final numWord in _numberWords.keys) {
      name = name.replaceAll(RegExp(r'\b' + numWord + r'\b'), '').trim();
    }
    if (unit != null) {
      name = name.replaceAll(RegExp(r'\b' + unit + r'\b'), '').trim();
    }

    name = IngredientVocabulary.resolve(name);
    if (name.isEmpty) return null;

    return ExtractedIngredient(
      name: name,
      quantity: qty,
      unit: unit,
      expiryPhrase: expiryMap[name],
    );
  }

  static Map<String, String> _extractExpiryMap(String text) {
    final Map<String, String> map = {};
    final RegExp expiryPattern = RegExp(
      r'(?:my\s+)?([a-zA-Z]+)\s+(?:expires|expire|expiring)\s+(.+?)(?:[\.,;]|and\b|$)',
      caseSensitive: false,
    );

    for (final match in expiryPattern.allMatches(text)) {
      final rawName = match.group(1)?.toLowerCase().trim() ?? '';
      final rawPhrase = match.group(2)?.trim() ?? '';
      if (rawName.isNotEmpty && rawPhrase.isNotEmpty) {
        final canonical = IngredientVocabulary.resolve(rawName);
        map[canonical] = rawPhrase;
        map[rawName] = rawPhrase;
      }
    }
    return map;
  }
}

class _MatchSpan {
  final int start;
  final int end;
  final String alias;
  final String canonical;

  _MatchSpan({
    required this.start,
    required this.end,
    required this.alias,
    required this.canonical,
  });
}
