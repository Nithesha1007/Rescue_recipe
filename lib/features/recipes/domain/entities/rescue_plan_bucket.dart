import 'package:equatable/equatable.dart';

import '../../../ingredients/domain/entities/ingredient.dart';
import 'ranked_recipe.dart';

enum RescueBucketType {
  cookToday,
  within2Days,
  thisWeek,
}

/// Pure Dart domain model representing an urgency bucket in the Rescue Plan.
class RescuePlanBucket extends Equatable {
  const RescuePlanBucket({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.items,
    this.bestRecipe,
  });

  final RescueBucketType type;
  final String title;
  final String subtitle;
  final List<Ingredient> items;
  final RankedRecipe? bestRecipe;

  @override
  List<Object?> get props => [type, title, subtitle, items, bestRecipe];
}
