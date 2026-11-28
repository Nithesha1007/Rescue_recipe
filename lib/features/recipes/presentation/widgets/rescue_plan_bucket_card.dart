import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/rescue_plan_bucket.dart';
import 'dish_art.dart';

class RescuePlanBucketCard extends StatelessWidget {
  const RescuePlanBucketCard({
    super.key,
    required this.bucket,
    required this.onTapRecipe,
  });

  final RescuePlanBucket bucket;
  final ValueChanged<RankedRecipe> onTapRecipe;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final (color, icon) = switch (bucket.type) {
      RescueBucketType.cookToday => (AppColors.critical, Icons.alarm_rounded),
      RescueBucketType.within2Days => (AppColors.orange, Icons.schedule_rounded),
      RescueBucketType.thisWeek => (AppColors.medium, Icons.calendar_today_rounded),
    };

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  bucket.title,
                  style: context.text.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              Text(
                '${bucket.items.length} ${bucket.items.length == 1 ? 'item' : 'items'}',
                style: context.text.labelSmall?.copyWith(
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            bucket.subtitle,
            style: context.text.bodySmall?.copyWith(
              color: context.colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Items pill chips
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: bucket.items.map((item) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                  border: Border.all(color: color.withValues(alpha: 0.25)),
                ),
                child: Text(
                  item.displayName,
                  style: context.text.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            }).toList(),
          ),

          if (bucket.bestRecipe != null) ...[
            const SizedBox(height: AppSpacing.md),
            InkWell(
              onTap: () => onTapRecipe(bucket.bestRecipe!),
              borderRadius: BorderRadius.circular(AppRadius.sm),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(AppRadius.sm),
                  border: Border.all(color: theme.dividerColor.withValues(alpha: 0.2)),
                ),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      child: SizedBox(
                        width: 48,
                        height: 48,
                        child: DishArt(recipe: bucket.bestRecipe!.recipe),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            bucket.bestRecipe!.recipe.title,
                            style: context.text.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Best match for this bucket • ${bucket.bestRecipe!.recipe.minutes} min',
                            style: context.text.bodySmall?.copyWith(
                              color: context.colors.onSurfaceVariant,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right_rounded, size: AppSizes.iconSm),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
