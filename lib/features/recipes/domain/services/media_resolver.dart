import 'package:equatable/equatable.dart';

enum MediaSourceType {
  cache,
  pexels,
  theMealDb,
  wikipedia,
  aiIllustration,
  dishArt,
}

class MediaResolutionResult extends Equatable {
  const MediaResolutionResult({
    required this.url,
    required this.sourceType,
    this.photographer,
    this.photographerUrl,
    this.altText,
    this.isAiGenerated = false,
  });

  final String url;
  final MediaSourceType sourceType;
  final String? photographer;
  final String? photographerUrl;
  final String? altText;
  final bool isAiGenerated;

  /// Pexels attribution credit string as required by Pexels API guidelines.
  String? get creditText {
    if (sourceType == MediaSourceType.pexels && photographer != null && photographer!.isNotEmpty) {
      return 'Photo by $photographer on Pexels';
    }
    if (isAiGenerated) {
      return 'AI-generated illustration';
    }
    if (sourceType == MediaSourceType.theMealDb) {
      return 'Photo via TheMealDB';
    }
    if (sourceType == MediaSourceType.wikipedia) {
      return 'Photo via Wikipedia';
    }
    return null;
  }

  @override
  List<Object?> get props => [url, sourceType, photographer, photographerUrl, altText, isAiGenerated];
}

abstract class MediaResolver {
  /// Resolves recipe photo through the priority chain:
  /// 1. Hive / disk cache (30-day expiry)
  /// 2. Pexels API
  /// 3. TheMealDB API
  /// 4. Wikipedia REST summary API
  /// 5. Optional Gemini image generation (when setting is enabled)
  /// 6. null (triggers DishArt fallback)
  Future<MediaResolutionResult?> resolveRecipeMedia({
    required String recipeTitle,
    String? imageQuery,
    String? cuisine,
    bool allowAiIllustration = false,
  });

  /// Resolves an ingredient thumbnail photo via MediaResolver in ingredient mode with keyword gate.
  Future<MediaResolutionResult?> resolveIngredientMedia({
    required String ingredientName,
  });

  /// Prefetches and caches photos for the 12 bundled recipes in the background.
  Future<void> prefetchBundledRecipePhotos();
}
