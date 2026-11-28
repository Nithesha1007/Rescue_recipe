import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hive/hive.dart';
import '../../../../core/utils/debug_logger.dart';

/// Pure domain/data resolver for Wikipedia food photos with 30-day cache and strict food keyword verification.
class DishImageResolver {
  final http.Client _client;
  final Box<String>? _cacheBox;

  static const List<String> _foodKeywords = [
    'dish',
    'food',
    'soup',
    'curry',
    'sauce',
    'rice',
    'bread',
    'salad',
    'snack',
    'chutney',
    'pasta',
    'cuisine',
    'condiment',
    'stew',
    'fritter',
    'beverage',
    'drink',
    'dessert',
    'sweet',
    'pancake',
    'noodle',
    'vegetable',
    'meat',
    'lentil',
    'dal',
    'roti',
    'flatbread',
  ];

  DishImageResolver({http.Client? client, Box<String>? cacheBox})
      : _client = client ?? http.Client(),
        _cacheBox = cacheBox;

  /// Resolves a photo URL for the given dish or candidate queries.
  /// Returns `null` if no verified food photo is found, or if offline.
  Future<String?> resolvePhotoUrl({
    String? imageQuery,
    required String title,
    String? cuisine,
  }) async {
    final candidates = <String>[];
    if (imageQuery != null && imageQuery.trim().isNotEmpty) {
      candidates.add(imageQuery.trim());
    }

    // Clean title (remove brackets, "rescue", "leftover")
    final cleanTitle = title
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\b(rescue|leftover|quick|easy)\b', caseSensitive: false), '')
        .trim();
    if (cleanTitle.isNotEmpty && !candidates.contains(cleanTitle)) {
      candidates.add(cleanTitle);
    }

    // First two words of title
    final words = cleanTitle.split(RegExp(r'\s+'));
    if (words.length >= 2) {
      final twoWords = '${words[0]} ${words[1]}';
      if (!candidates.contains(twoWords)) {
        candidates.add(twoWords);
      }
    }

    if (cuisine != null && cuisine.trim().isNotEmpty && !candidates.contains(cuisine.trim())) {
      candidates.add(cuisine.trim());
    }

    for (final candidate in candidates) {
      final cacheKey = 'wiki_${candidate.toLowerCase().replaceAll(RegExp(r'\s+'), '_')}';
      if (_cacheBox != null) {
        final cached = _cacheBox.get(cacheKey);
        if (cached != null) {
          if (cached == 'NULL') return null;
          return cached;
        }
      }

      try {
        final url = await _fetchWikiSummary(candidate);
        if (_cacheBox != null) {
          await _cacheBox.put(cacheKey, url ?? 'NULL');
        }
        if (url != null) return url;
      } catch (e) {
        DebugLogger.ai('DishImageResolver error for $candidate: $e');
      }
    }

    return null;
  }

  Future<String?> _fetchWikiSummary(String title) async {
    final encoded = Uri.encodeComponent(title);
    final uri = Uri.parse('https://en.wikipedia.org/api/rest_v1/page/summary/$encoded');

    final response = await _client.get(
      uri,
      headers: {
        'User-Agent': 'RescueRecipe/1.0 (https://github.com/example/rescue_recipe; foodrescue@example.com)',
        'Accept': 'application/json',
      },
    ).timeout(const Duration(seconds: 4));

    if (response.statusCode != 200) return null;

    final data = jsonDecode(response.body) as Map<String, dynamic>;

    // Reject disambiguation pages
    final type = data['type'] as String?;
    if (type == 'disambiguation') return null;

    // Check thumbnail existence
    final thumbnail = data['thumbnail'] as Map<String, dynamic>?;
    final source = thumbnail?['source'] as String?;
    if (source == null || source.isEmpty) return null;

    // Verify description or extract contains food keyword
    final description = (data['description'] as String? ?? '').toLowerCase();
    final extract = (data['extract'] as String? ?? '').toLowerCase();
    final textToCheck = '$description $extract';

    final isFood = _foodKeywords.any((kw) => textToCheck.contains(kw));
    if (!isFood) return null;

    return source;
  }
}
