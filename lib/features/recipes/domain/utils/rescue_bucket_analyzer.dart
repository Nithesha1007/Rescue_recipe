import '../../../../core/domain/expiry_priority.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../entities/ranked_recipe.dart';
import '../entities/rescue_plan_bucket.dart';
import 'ingredient_matcher.dart';

/// Pure Dart utility analyzing active inventory into time-based rescue buckets.
abstract final class RescueBucketAnalyzer {
  static List<RescuePlanBucket> analyze({
    required List<Ingredient> inventory,
    required List<RankedRecipe> rankedRecipes,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Active, non-expired items
    final activeItems = inventory.where((item) {
      if (!item.status.isActive) return false;
      final p = item.priority(today: todayDate);
      return p != ExpiryPriority.expired;
    }).toList();

    final criticalItems = <Ingredient>[];
    final highItems = <Ingredient>[];
    final mediumItems = <Ingredient>[];

    for (final item in activeItems) {
      switch (item.priority(today: todayDate)) {
        case ExpiryPriority.critical:
          criticalItems.add(item);
          break;
        case ExpiryPriority.high:
          highItems.add(item);
          break;
        case ExpiryPriority.medium:
          mediumItems.add(item);
          break;
        default:
          break;
      }
    }

    final buckets = <RescuePlanBucket>[];

    if (criticalItems.isNotEmpty) {
      final best = _findBestRecipeForItems(criticalItems, rankedRecipes);
      buckets.add(RescuePlanBucket(
        type: RescueBucketType.cookToday,
        title: 'Cook today',
        subtitle: '${criticalItems.length} ${criticalItems.length == 1 ? 'item needs' : 'items need'} immediate rescue',
        items: criticalItems,
        bestRecipe: best,
      ));
    }

    if (highItems.isNotEmpty) {
      final best = _findBestRecipeForItems(highItems, rankedRecipes);
      buckets.add(RescuePlanBucket(
        type: RescueBucketType.within2Days,
        title: 'Within 2 days',
        subtitle: '${highItems.length} ${highItems.length == 1 ? 'item reaches' : 'items reach'} peak urgency soon',
        items: highItems,
        bestRecipe: best,
      ));
    }

    if (mediumItems.isNotEmpty) {
      final best = _findBestRecipeForItems(mediumItems, rankedRecipes);
      buckets.add(RescuePlanBucket(
        type: RescueBucketType.thisWeek,
        title: 'This week',
        subtitle: '${mediumItems.length} ${mediumItems.length == 1 ? 'item should' : 'items should'} be used this week',
        items: mediumItems,
        bestRecipe: best,
      ));
    }

    return buckets;
  }

  static RankedRecipe? _findBestRecipeForItems(
    List<Ingredient> targetItems,
    List<RankedRecipe> recipes,
  ) {
    if (recipes.isEmpty) return null;

    RankedRecipe? bestMatch;
    int maxCovered = 0;
    double highestScore = -1.0;

    for (final ranked in recipes) {
      int covered = 0;
      for (final recipeIng in ranked.recipe.ingredients) {
        if (IngredientMatcher.evaluateMatch(recipeIng, targetItems).inventoryItem != null) {
          covered++;
        }
      }

      if (covered > maxCovered || (covered == maxCovered && ranked.totalScore > highestScore)) {
        maxCovered = covered;
        highestScore = ranked.totalScore;
        bestMatch = ranked;
      }
    }

    return bestMatch ?? recipes.firstOrNull;
  }
}
