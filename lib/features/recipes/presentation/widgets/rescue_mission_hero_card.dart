import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/ranked_recipe.dart';
import 'recipe_image.dart';

class RescueMissionHeroCard extends StatelessWidget {
  const RescueMissionHeroCard({
    super.key,
    required this.rankedRecipe,
    required this.photoUrl,
    required this.onViewRecipe,
    required this.onStartCooking,
  });

  final RankedRecipe rankedRecipe;
  final String? photoUrl;
  final VoidCallback onViewRecipe;
  final VoidCallback onStartCooking;

  @override
  Widget build(BuildContext context) {
    final recipe = rankedRecipe.recipe;
    final totalExpiring = rankedRecipe.totalExpiringCount;
    final covered = rankedRecipe.coveredExpiringCount;
    final theme = Theme.of(context);

    final double coverageFraction = totalExpiring > 0
        ? (covered / totalExpiring).clamp(0.0, 1.0)
        : (rankedRecipe.coverageScore).clamp(0.0, 1.0);

    return AppCard(
      padding: EdgeInsets.zero,
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Stack(
            children: [
              RecipeImage(
                recipe: recipe,
                photoUrl: photoUrl,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(AppRadius.lg),
                  topRight: Radius.circular(AppRadius.lg),
                ),
              ),
              Positioned(
                top: AppSpacing.sm,
                left: AppSpacing.sm,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.orange,
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.bolt_rounded, size: 14, color: AppColors.white),
                      SizedBox(width: 4),
                      Text(
                        "Today's Rescue Mission",
                        style: AppTypography.badgeTiny,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  recipe.title,
                  style: context.text.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  rankedRecipe.reason,
                  style: context.text.bodyMedium?.copyWith(
                    color: context.colors.onSurfaceVariant,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),

                // Expiring items rescue meter
                Container(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(AppRadius.sm),
                    border: Border.all(color: theme.dividerColor.withValues(alpha: 0.15)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Flexible(
                            child: Text(
                              totalExpiring > 0
                                  ? 'Cook this to use $covered of $totalExpiring expiring items'
                                  : 'Maximizes your pantry ingredients',
                              style: context.text.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            '${(coverageFraction * 100).toInt()}%',
                            style: context.text.labelSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.orange,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                        child: LinearProgressIndicator(
                          value: coverageFraction,
                          backgroundColor: theme.dividerColor.withValues(alpha: 0.2),
                          color: AppColors.orange,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // Action buttons
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.sm,
                  children: [
                    AppButton(
                      label: 'View Recipe',
                      variant: AppButtonVariant.outlined,
                      icon: Icons.menu_book_rounded,
                      onPressed: onViewRecipe,
                    ),
                    AppButton(
                      label: 'Start Cooking',
                      variant: AppButtonVariant.filled,
                      icon: Icons.play_arrow_rounded,
                      onPressed: onStartCooking,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
