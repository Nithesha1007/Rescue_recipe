import 'package:url_launcher/url_launcher.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../entities/recipe_step.dart';

/// Utilities for launching cooking videos and technique tutorials via YouTube.
class VideoCookingHelper {
  const VideoCookingHelper._();

  static const Map<String, String> _cookingVerbs = {
    'dice': 'how to dice',
    'chop': 'how to chop',
    'saute': 'how to saute',
    'sauté': 'how to saute',
    'temper': 'how to temper spices tadka',
    'whisk': 'how to whisk',
    'knead': 'how to knead dough',
    'blend': 'how to blend',
    'boil': 'how to boil',
    'simmer': 'how to simmer',
    'fry': 'how to fry',
    'roast': 'how to roast',
    'grind': 'how to grind spices',
    'julienne': 'how to julienne cut',
    'mince': 'how to mince',
    'steam': 'how to steam',
    'sear': 'how to sear',
  };

  /// Derives technique tutorials matching any cooking verb in the step text.
  /// Returns a map of verb display name to search query (e.g. {'dice': 'how to dice tomatoes'}).
  static List<({String verb, String query})> findTechniquesInStep(String stepText) {
    final lower = stepText.toLowerCase();
    final results = <({String verb, String query})>[];

    for (final entry in _cookingVerbs.entries) {
      final verb = entry.key;
      final pattern = RegExp(r'\b' + RegExp.escape(verb) + r'(?:d|ing|s)?\b', caseSensitive: false);
      if (pattern.hasMatch(lower)) {
        // Extract words following the verb for context (up to 3 words)
        final match = pattern.firstMatch(lower);
        String context = '';
        if (match != null) {
          final remainder = lower.substring(match.end).trim();
          final words = remainder.split(RegExp(r'\s+')).take(2).join(' ');
          context = words.replaceAll(RegExp(r'[^a-z0-9 ]'), '');
        }

        final query = context.isNotEmpty
            ? '${entry.value} $context'
            : '${entry.value} technique';
        results.add((verb: verb, query: query));
      }
    }
    return results;
  }

  /// Builds a YouTube search URL for the dish with optional language modifier.
  static String buildDishVideoQuery({
    required String dishTitle,
    String? customQuery,
    GuideLanguage guideLanguage = GuideLanguage.english,
  }) {
    if (customQuery != null && customQuery.trim().isNotEmpty) {
      return customQuery.trim();
    }

    final langWord = switch (guideLanguage) {
      GuideLanguage.tamil => 'tamil',
      GuideLanguage.hindi => 'hindi',
      GuideLanguage.tanglish => 'tamil english',
      GuideLanguage.english => '',
    };

    final cleanTitle = dishTitle
        .replaceAll(RegExp(r'\([^)]*\)'), '')
        .replaceAll(RegExp(r'\b(rescue|leftover)\b', caseSensitive: false), '')
        .trim();

    return langWord.isNotEmpty
        ? '$cleanTitle recipe $langWord'
        : '$cleanTitle recipe';
  }

  /// Launches a YouTube search query using url_launcher.
  static Future<bool> launchYouTubeSearch(String query) async {
    final encoded = Uri.encodeComponent(query);
    final url = Uri.parse('https://www.youtube.com/results?search_query=$encoded');
    try {
      if (await canLaunchUrl(url)) {
        return await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(url, mode: LaunchMode.platformDefault);
      }
    } catch (e) {
      DebugLogger.general('Error launching YouTube URL: $e');
      return false;
    }
  }

  /// Extracts cooking technique verbs from a RecipeStep.
  static List<String> extractTechniquesFromStep(RecipeStep step) {
    return findTechniquesInStep(step.text).map((t) => t.verb).toList();
  }

  /// Builds a YouTube search query from a Recipe entity.
  static String buildVideoQuery(dynamic recipe) {
    final title = recipe.title as String;
    final customQuery = recipe.videoSearchQuery as String?;
    return buildDishVideoQuery(
      dishTitle: title,
      customQuery: customQuery,
    );
  }

  /// Generates a technique search query with recipe context.
  static String buildTechniqueQuery({required String technique, required String recipeTitle}) {
    return 'how to $technique $recipeTitle cooking technique';
  }
}
