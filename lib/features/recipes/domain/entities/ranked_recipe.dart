import 'package:equatable/equatable.dart';

import '../../../../core/domain/expiry_priority.dart';
import 'recipe.dart';
import 'recipe_ingredient.dart';

enum RecipeBadge {
  rescueFirst('Rescue-first'),
  quick('Quick'),
  allOnHand('All on hand'),
  missing('Missing'),
  usesExpiring('Expiring');

  const RecipeBadge(this.defaultLabel);
  final String defaultLabel;
}

class RankedBadge extends Equatable {
  const RankedBadge({
    required this.badge,
    required this.label,
  });

  final RecipeBadge badge;
  final String label;

  @override
  List<Object?> get props => [badge, label];
}

class MatchedExpiringIngredient extends Equatable {
  const MatchedExpiringIngredient({
    required this.name,
    required this.priority,
  });

  final String name;
  final ExpiryPriority priority;

  @override
  List<Object?> get props => [name, priority];
}

class RankedRecipe extends Equatable {
  const RankedRecipe({
    required this.recipe,
    required this.totalScore,
    required this.coverageScore,
    required this.availabilityScore,
    required this.speedScore,
    required this.preferenceScore,
    required this.matchedExpiringIngredients,
    required this.missingIngredients,
    required this.coveredExpiringCount,
    required this.totalExpiringCount,
    required this.reason,
    required this.badges,
    this.needMoreIngredients = const <RecipeIngredient>[],
  });

  final Recipe recipe;
  final double totalScore;
  final double coverageScore;
  final double availabilityScore;
  final double speedScore;
  final double preferenceScore;
  final List<MatchedExpiringIngredient> matchedExpiringIngredients;
  final List<RecipeIngredient> missingIngredients;
  final List<RecipeIngredient> needMoreIngredients;
  final int coveredExpiringCount;
  final int totalExpiringCount;
  final String reason;
  final List<RankedBadge> badges;

  @override
  List<Object?> get props => [
        recipe,
        totalScore,
        coverageScore,
        availabilityScore,
        speedScore,
        preferenceScore,
        matchedExpiringIngredients,
        missingIngredients,
        needMoreIngredients,
        coveredExpiringCount,
        totalExpiringCount,
        reason,
        badges,
      ];
}
