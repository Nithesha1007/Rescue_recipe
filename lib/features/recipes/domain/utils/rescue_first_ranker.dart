import '../../../../core/domain/expiry_priority.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../entities/diet_tag.dart';
import '../entities/ranked_recipe.dart';
import '../entities/recipe.dart';
import '../entities/recipe_ingredient.dart';
import 'ingredient_matcher.dart';
import 'reason_validator.dart';

/// Pure Dart ranking engine implementing the Rescue-First formula:
/// score = 0.45 * coverage + 0.30 * availability + 0.15 * speed + 0.10 * preference
class RescueFirstRanker {
  RescueFirstRanker._();

  static const double coverageWeight = 0.45;
  static const double availabilityWeight = 0.30;
  static const double speedWeight = 0.15;
  static const double preferenceWeight = 0.10;

  static const int weightCritical = 3;
  static const int weightHigh = 2;
  static const int weightMedium = 1;

  static int priorityWeight(ExpiryPriority priority) {
    switch (priority) {
      case ExpiryPriority.critical:
        return weightCritical;
      case ExpiryPriority.high:
        return weightHigh;
      case ExpiryPriority.medium:
        return weightMedium;
      default:
        return 0;
    }
  }

  /// Ranks [recipes] against active [inventory] items using [dietPreference] and [cuisinePreference].
  /// Expired, used, or discarded items in [inventory] are strictly excluded.
  static List<RankedRecipe> rank({
    required List<Recipe> recipes,
    required List<Ingredient> inventory,
    required DietTag dietPreference,
    CuisineTag cuisinePreference = CuisineTag.any,
    DateTime? today,
  }) {
    final now = today ?? DateTime.now();
    final todayDate = DateTime(now.year, now.month, now.day);

    // Filter to active, non-expired inventory items only
    final List<Ingredient> activeInventory = inventory.where((item) {
      if (item.status != IngredientStatus.active) return false;
      final priority = item.priority(today: todayDate);
      return priority != ExpiryPriority.expired;
    }).toList();

    // Identify all expiring items (Critical, High, Medium)
    final List<Ingredient> expiringItems = activeInventory.where((item) {
      final p = item.priority(today: todayDate);
      return p == ExpiryPriority.critical ||
          p == ExpiryPriority.high ||
          p == ExpiryPriority.medium;
    }).toList();

    final int totalExpiringWeight = expiringItems.fold<int>(
      0,
      (sum, item) => sum + priorityWeight(item.priority(today: todayDate)),
    );

    final List<RankedRecipe> rankedList = <RankedRecipe>[];

    for (final recipe in recipes) {
      // Preference filter: if a diet is selected, exclude non-matching recipes entirely
      if (dietPreference != DietTag.none) {
        if (!recipe.dietTags.contains(dietPreference)) {
          continue;
        }
      }

      // Check ingredient matching
      final Set<Ingredient> usedActiveIngredients = <Ingredient>{};
      final Set<Ingredient> usedExpiringIngredients = <Ingredient>{};
      final List<RecipeIngredient> missingIngredients = <RecipeIngredient>[];
      final List<RecipeIngredient> needMoreIngredients = <RecipeIngredient>[];
      int requiredCount = 0;
      double availableRequiredCount = 0.0;

      for (final ing in recipe.ingredients) {
        final matchResult = IngredientMatcher.evaluateMatch(ing, activeInventory);

        if (matchResult.inventoryItem != null) {
          usedActiveIngredients.add(matchResult.inventoryItem!);
          final p = matchResult.inventoryItem!.priority(today: todayDate);
          if (p == ExpiryPriority.critical ||
              p == ExpiryPriority.high ||
              p == ExpiryPriority.medium) {
            usedExpiringIngredients.add(matchResult.inventoryItem!);
          }
        }

        // Count non-optional, non-pantry-staple ingredients for availability
        if (!ing.isOptional && !ing.isPantryStaple) {
          requiredCount++;
          if (matchResult.status == MatchStatus.available) {
            availableRequiredCount += 1.0;
          } else if (matchResult.status == MatchStatus.needMore) {
            availableRequiredCount += 0.5; // partial credit
            needMoreIngredients.add(ing);
          } else {
            missingIngredients.add(ing);
          }
        }
      }

      // Rule: Drop recipes that use zero active inventory ingredients
      if (usedActiveIngredients.isEmpty) {
        continue;
      }

      // 1. Availability calculation
      final double availabilityScore = requiredCount == 0
          ? 1.0
          : (availableRequiredCount / requiredCount).clamp(0.0, 1.0);

      // Rule: Drop recipes with availability below 0.4 (too many missing)
      if (availabilityScore < 0.4) {
        continue;
      }

      // 2. Coverage calculation
      final int usedExpiringWeight = usedExpiringIngredients.fold<int>(
        0,
        (sum, item) => sum + priorityWeight(item.priority(today: todayDate)),
      );

      final double coverageScore = totalExpiringWeight == 0
          ? 0.0
          : (usedExpiringWeight / totalExpiringWeight).clamp(0.0, 1.0);

      // 3. Speed calculation: clamp(1 - (minutes - 10) / 50, 0, 1)
      final double speedScore = (1.0 - (recipe.minutes - 10) / 50.0).clamp(0.0, 1.0);

      // 4. Preference score: Average of diet and cuisine components (maintaining 0.10 weight)
      final double dietComponent = dietPreference == DietTag.none ? 0.5 : 1.0;
      final double preferenceScore;
      if (cuisinePreference == CuisineTag.any) {
        preferenceScore = dietComponent;
      } else {
        final recCuisine = recipe.cuisine?.toLowerCase() ?? '';
        final prefCuisine = cuisinePreference.displayName.toLowerCase();
        final double cuisineComponent = (recCuisine.contains(prefCuisine) || prefCuisine.contains(recCuisine))
            ? 1.0
            : 0.2;
        preferenceScore = (dietComponent + cuisineComponent) / 2.0;
      }

      // Total Score
      final double totalScore = (coverageWeight * coverageScore) +
          (availabilityWeight * availabilityScore) +
          (speedWeight * speedScore) +
          (preferenceWeight * preferenceScore);

      // Matched expiring items details
      final List<MatchedExpiringIngredient> matchedExpiring =
          usedExpiringIngredients.map((item) {
        return MatchedExpiringIngredient(
          name: item.name,
          priority: item.priority(today: todayDate),
        );
      }).toList();

      // Badges
      final List<RankedBadge> badges = <RankedBadge>[];

      if (usedExpiringIngredients.isNotEmpty) {
        badges.add(RankedBadge(
          badge: RecipeBadge.usesExpiring,
          label: 'Uses ${usedExpiringIngredients.length} expiring',
        ));
      }

      if (missingIngredients.isEmpty && needMoreIngredients.isEmpty) {
        badges.add(const RankedBadge(
          badge: RecipeBadge.allOnHand,
          label: 'All on hand',
        ));
      } else if (missingIngredients.isNotEmpty || needMoreIngredients.isNotEmpty) {
        final count = missingIngredients.length + needMoreIngredients.length;
        badges.add(RankedBadge(
          badge: RecipeBadge.missing,
          label: 'Missing $count item${count > 1 ? 's' : ''}',
        ));
      }

      if (recipe.minutes <= 20) {
        badges.add(RankedBadge(
          badge: RecipeBadge.quick,
          label: '${recipe.minutes} mins',
        ));
      }

      final coveredCount = usedExpiringIngredients.length;
      final totalCount = expiringItems.length;

      // Construct verified reason (validated for safety and disclaimers)
      final rawReason = _buildSpecificReason(
        recipe: recipe,
        usedExpiringItems: usedExpiringIngredients.toList(),
        today: todayDate,
        isAllOnHand: missingIngredients.isEmpty && needMoreIngredients.isEmpty,
      );
      final validatedReason = ReasonValidator.sanitize(rawReason);

      rankedList.add(RankedRecipe(
        recipe: recipe,
        totalScore: totalScore,
        coverageScore: coverageScore,
        availabilityScore: availabilityScore,
        speedScore: speedScore,
        preferenceScore: preferenceScore,
        matchedExpiringIngredients: matchedExpiring,
        missingIngredients: missingIngredients,
        needMoreIngredients: needMoreIngredients,
        coveredExpiringCount: coveredCount,
        totalExpiringCount: totalCount,
        reason: validatedReason,
        badges: badges,
      ));
    }

    // Sort by totalScore descending
    rankedList.sort((a, b) => b.totalScore.compareTo(a.totalScore));

    // Add 'Rescue-first' badge to top candidate if it covers expiring ingredients
    if (rankedList.isNotEmpty && rankedList.first.coveredExpiringCount > 0) {
      final top = rankedList.first;
      final updatedBadges = [
        const RankedBadge(badge: RecipeBadge.rescueFirst, label: 'Rescue-first'),
        ...top.badges.where((b) => b.badge != RecipeBadge.rescueFirst),
      ];

      rankedList[0] = RankedRecipe(
        recipe: top.recipe,
        totalScore: top.totalScore,
        coverageScore: top.coverageScore,
        availabilityScore: top.availabilityScore,
        speedScore: top.speedScore,
        preferenceScore: top.preferenceScore,
        matchedExpiringIngredients: top.matchedExpiringIngredients,
        missingIngredients: top.missingIngredients,
        needMoreIngredients: top.needMoreIngredients,
        coveredExpiringCount: top.coveredExpiringCount,
        totalExpiringCount: top.totalExpiringCount,
        reason: top.reason,
        badges: updatedBadges,
      );
    }

    return rankedList;
  }

  static String _buildSpecificReason({
    required Recipe recipe,
    required List<Ingredient> usedExpiringItems,
    required DateTime today,
    required bool isAllOnHand,
  }) {
    if (usedExpiringItems.isNotEmpty) {
      final parts = usedExpiringItems.take(2).map((item) {
        final p = item.priority(today: today);
        final label = p.name.substring(0, 1).toUpperCase() + p.name.substring(1);
        return '${item.displayName} ($label priority)';
      }).join(' and ');

      return 'Rescues your $parts';
    }

    if (isAllOnHand) {
      return 'Makes the most of what you already have.';
    }

    return 'Uses your active ingredients with minimal extra items needed';
  }
}
