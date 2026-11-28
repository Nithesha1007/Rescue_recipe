import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../data/datasources/offline_recipe_source.dart';
import '../../domain/services/media_resolver.dart';

class MediaResolverImpl implements MediaResolver {
  MediaResolverImpl({
    required AppConfig config,
    http.Client? client,
    Box<String>? cacheBox,
  })  : _config = config,
        _client = client ?? http.Client(),
        _cacheBox = cacheBox;

  final AppConfig _config;
  final http.Client _client;
  final Box<String>? _cacheBox;

  static const List<String> _foodKeywords = [
    'dish', 'food', 'soup', 'curry', 'sauce', 'rice', 'bread', 'salad', 'snack',
    'chutney', 'pasta', 'cuisine', 'condiment', 'stew', 'fritter', 'beverage',
    'drink', 'dessert', 'sweet', 'pancake', 'noodle', 'vegetable', 'meat',
    'lentil', 'dal', 'roti', 'flatbread', 'pie', 'scramble', 'stir fry', 'hash'
  ];

  static const List<String> _ingredientKeywords = [
    'vegetable', 'fruit', 'spice', 'herb', 'grain', 'dairy', 'egg', 'meat',
    'fish', 'pulse', 'legume', 'food', 'plant', 'ingredient', 'flour', 'oil',
    'cheese', 'seed', 'condiment'
  ];

  @override
  Future<MediaResolutionResult?> resolveRecipeMedia({
    required String recipeTitle,
    String? imageQuery,
    String? cuisine,
    bool allowAiIllustration = false,
  }) async {
    final cleanQuery = (imageQuery != null && imageQuery.trim().isNotEmpty)
        ? imageQuery.trim()
        : _cleanTitle(recipeTitle);

    final cacheKey = 'recipe_${cleanQuery.toLowerCase()}';

    // 1. Check Cache
    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      if (cached.url.isEmpty) return null; // Cached negative
      return cached;
    }

    // 2. Pexels API
    if (_config.hasPexelsKey) {
      try {
        final pexelsResult = await _searchPexels('$cleanQuery dish');
        if (pexelsResult != null) {
          _saveToCache(cacheKey, pexelsResult);
          return pexelsResult;
        }
      } catch (e) {
        DebugLogger.general('Pexels error: $e');
      }
    }

    // 3. TheMealDB API
    try {
      final mealDbResult = await _searchTheMealDb(cleanQuery);
      if (mealDbResult != null) {
        _saveToCache(cacheKey, mealDbResult);
        return mealDbResult;
      }
    } catch (e) {
      DebugLogger.general('TheMealDB error: $e');
    }

    // 4. Wikipedia REST Summary API with Food Keyword Gate
    try {
      final wikiResult = await _searchWikipedia(cleanQuery);
      if (wikiResult != null) {
        _saveToCache(cacheKey, wikiResult);
        return wikiResult;
      }
    } catch (e) {
      DebugLogger.general('Wikipedia error: $e');
    }

    // 5. AI Illustration (Optional, off by default)
    if (allowAiIllustration && _config.hasGeminiKey) {
      try {
        final aiResult = await _generateAiIllustration(cleanQuery);
        if (aiResult != null) {
          _saveToCache(cacheKey, aiResult);
          return aiResult;
        }
      } catch (e) {
        DebugLogger.general('AI Illustration error: $e');
      }
    }

    // Cache negative hit for 30 days
    _saveNegativeCache(cacheKey);
    return null;
  }

  @override
  Future<MediaResolutionResult?> resolveIngredientMedia({
    required String ingredientName,
  }) async {
    final cleanName = ingredientName.trim().toLowerCase();
    final cacheKey = 'ingredient_$cleanName';

    final cached = _getFromCache(cacheKey);
    if (cached != null) {
      if (cached.url.isEmpty) return null;
      return cached;
    }

    // 1. Wikipedia for ingredient with ingredient-specific keyword gate
    try {
      final wikiResult = await _searchWikipediaIngredient(cleanName);
      if (wikiResult != null) {
        _saveToCache(cacheKey, wikiResult);
        return wikiResult;
      }
    } catch (e) {
      DebugLogger.general('Wikipedia ingredient error: $e');
    }

    // 2. TheMealDB ingredient search
    try {
      final mealDbUrl = 'https://www.themealdb.com/images/ingredients/${Uri.encodeComponent(cleanName)}.png';
      final head = await _client.head(Uri.parse(mealDbUrl)).timeout(const Duration(seconds: 4));
      if (head.statusCode == 200) {
        final res = MediaResolutionResult(
          url: mealDbUrl,
          sourceType: MediaSourceType.theMealDb,
        );
        _saveToCache(cacheKey, res);
        return res;
      }
    } catch (_) {}

    _saveNegativeCache(cacheKey);
    return null;
  }

  @override
  Future<void> prefetchBundledRecipePhotos() async {
    for (final r in OfflineRecipeSource.recipes) {
      try {
        await resolveRecipeMedia(recipeTitle: r.title, imageQuery: r.imageQuery);
      } catch (_) {}
    }
  }

  // --- Helpers ---

  Future<MediaResolutionResult?> _searchPexels(String query) async {
    final url = Uri.parse(
      'https://api.pexels.com/v1/search?query=${Uri.encodeComponent(query)}&orientation=landscape&per_page=3',
    );
    final response = await _client.get(
      url,
      headers: {'Authorization': _config.pexelsApiKey},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final photos = json['photos'] as List<dynamic>?;
      if (photos != null && photos.isNotEmpty) {
        for (final p in photos) {
          final alt = (p['alt'] as String?)?.toLowerCase() ?? '';
          final photographer = p['photographer'] as String? ?? '';
          final photographerUrl = p['photographer_url'] as String? ?? '';
          final src = p['src'] as Map<String, dynamic>?;
          final mediumUrl = src?['medium'] as String? ?? src?['large'] as String?;

          // Filter out photos whose alt text contradicts food
          if (mediumUrl != null && !_contradictsDish(alt)) {
            return MediaResolutionResult(
              url: mediumUrl,
              sourceType: MediaSourceType.pexels,
              photographer: photographer,
              photographerUrl: photographerUrl,
              altText: alt,
            );
          }
        }
      }
    }
    return null;
  }

  Future<MediaResolutionResult?> _searchTheMealDb(String query) async {
    final url = Uri.parse(
      'https://www.themealdb.com/api/json/v1/1/search.php?s=${Uri.encodeComponent(query)}',
    );
    final response = await _client.get(url).timeout(const Duration(seconds: 5));
    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final meals = json['meals'] as List<dynamic>?;
      if (meals != null && meals.isNotEmpty) {
        final meal = meals.first as Map<String, dynamic>;
        final strMeal = (meal['strMeal'] as String?)?.toLowerCase() ?? '';
        final thumb = meal['strMealThumb'] as String?;

        // Closeness gate: query must share tokens with strMeal
        final queryTokens = query.toLowerCase().split(RegExp(r'\s+')).where((t) => t.length > 2);
        final matches = queryTokens.any((t) => strMeal.contains(t));
        if (thumb != null && thumb.isNotEmpty && matches) {
          return MediaResolutionResult(
            url: thumb,
            sourceType: MediaSourceType.theMealDb,
            altText: meal['strMeal'] as String?,
          );
        }
      }
    }
    return null;
  }

  Future<MediaResolutionResult?> _searchWikipedia(String query) async {
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
    );
    final response = await _client.get(
      url,
      headers: {'User-Agent': 'RescueRecipe/1.0 (contact@rescuerecipe.app)'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final description = (json['description'] as String?)?.toLowerCase() ?? '';
      final extract = (json['extract'] as String?)?.toLowerCase() ?? '';
      final thumbnail = json['thumbnail'] as Map<String, dynamic>?;
      final source = thumbnail?['source'] as String?;

      final combined = '$description $extract';
      final hasFoodKeyword = _foodKeywords.any((kw) => combined.contains(kw));

      if (source != null && source.isNotEmpty && hasFoodKeyword) {
        return MediaResolutionResult(
          url: source,
          sourceType: MediaSourceType.wikipedia,
          altText: json['title'] as String?,
        );
      }
    }
    return null;
  }

  Future<MediaResolutionResult?> _searchWikipediaIngredient(String query) async {
    final url = Uri.parse(
      'https://en.wikipedia.org/api/rest_v1/page/summary/${Uri.encodeComponent(query)}',
    );
    final response = await _client.get(
      url,
      headers: {'User-Agent': 'RescueRecipe/1.0 (contact@rescuerecipe.app)'},
    ).timeout(const Duration(seconds: 5));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final description = (json['description'] as String?)?.toLowerCase() ?? '';
      final extract = (json['extract'] as String?)?.toLowerCase() ?? '';
      final thumbnail = json['thumbnail'] as Map<String, dynamic>?;
      final source = thumbnail?['source'] as String?;

      final combined = '$description $extract';
      final hasIngredientKeyword = _ingredientKeywords.any((kw) => combined.contains(kw));

      if (source != null && source.isNotEmpty && hasIngredientKeyword) {
        return MediaResolutionResult(
          url: source,
          sourceType: MediaSourceType.wikipedia,
          altText: json['title'] as String?,
        );
      }
    }
    return null;
  }

  Future<MediaResolutionResult?> _generateAiIllustration(String dishName) async {
    // Uses Google Imagen 3 API endpoint: imagen-3.0-generate-002
    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/imagen-3.0-generate-002:predict',
    );
    final payload = jsonEncode({
      'instances': [
        {
          'prompt': 'A delicious, appetizing, warm studio food photography of $dishName on a ceramic plate, soft lighting, restaurant quality, safe and fresh presentation'
        }
      ],
      'parameters': {
        'sampleCount': 1,
        'aspectRatio': '16:9',
      }
    });

    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _config.geminiApiKey,
      },
      body: payload,
    ).timeout(const Duration(seconds: 15));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final predictions = json['predictions'] as List<dynamic>?;
      if (predictions != null && predictions.isNotEmpty) {
        final first = predictions.first as Map<String, dynamic>;
        final b64 = first['bytesBase64Encoded'] as String?;
        if (b64 != null && b64.isNotEmpty) {
          final dataUri = 'data:image/png;base64,$b64';
          return MediaResolutionResult(
            url: dataUri,
            sourceType: MediaSourceType.aiIllustration,
            isAiGenerated: true,
          );
        }
      }
    }
    return null;
  }

  bool _contradictsDish(String alt) {
    const forbidden = ['person', 'face', 'portrait', 'building', 'animal', 'car', 'clothing'];
    return forbidden.any((f) => alt.contains(f));
  }

  String _cleanTitle(String title) {
    return title
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\b(rescue|leftover|quick|easy)\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'[^a-zA-Z0-9\s]'), '')
        .trim();
  }

  MediaResolutionResult? _getFromCache(String key) {
    if (_cacheBox == null) return null;
    final cachedJson = _cacheBox.get(key);
    if (cachedJson == null) return null;
    try {
      final map = jsonDecode(cachedJson) as Map<String, dynamic>;
      final expiry = DateTime.parse(map['expiry'] as String);
      if (DateTime.now().isAfter(expiry)) {
        _cacheBox.delete(key);
        return null;
      }
      return MediaResolutionResult(
        url: map['url'] as String,
        sourceType: MediaSourceType.values.byName(map['source'] as String),
        photographer: map['photographer'] as String?,
        photographerUrl: map['photographerUrl'] as String?,
        altText: map['altText'] as String?,
        isAiGenerated: map['isAiGenerated'] == true,
      );
    } catch (_) {
      return null;
    }
  }

  void _saveToCache(String key, MediaResolutionResult res) {
    if (_cacheBox == null) return;
    final expiry = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final data = jsonEncode({
      'url': res.url,
      'source': res.sourceType.name,
      'photographer': res.photographer,
      'photographerUrl': res.photographerUrl,
      'altText': res.altText,
      'isAiGenerated': res.isAiGenerated,
      'expiry': expiry,
    });
    _cacheBox.put(key, data);
  }

  void _saveNegativeCache(String key) {
    if (_cacheBox == null) return;
    final expiry = DateTime.now().add(const Duration(days: 30)).toIso8601String();
    final data = jsonEncode({
      'url': '',
      'source': MediaSourceType.dishArt.name,
      'expiry': expiry,
    });
    _cacheBox.put(key, data);
  }
}
