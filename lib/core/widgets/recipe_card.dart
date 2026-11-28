import 'package:flutter/material.dart';

import '../theme/app_theme.dart';
import '../../features/recipes/domain/entities/recipe.dart';
import '../../features/recipes/presentation/widgets/recipe_image.dart';
import 'app_card.dart';

class RecipeCard extends StatelessWidget {
  const RecipeCard({
    super.key,
    required this.title,
    required this.reason,
    required this.minutes,
    this.badges = const <String>[],
    this.substitution,
    this.featured = false,
    this.isSaved = false,
    this.recipe,
    this.photoUrl,
    this.onTap,
    this.onBookmarkTap,
  });

  final String title;
  final String reason;
  final int minutes;
  final List<String> badges;
  final String? substitution;
  final bool featured;
  final bool isSaved;
  final Recipe? recipe;
  final String? photoUrl;
  final VoidCallback? onTap;
  final VoidCallback? onBookmarkTap;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    final Color fg = featured ? scheme.onPrimaryContainer : scheme.onSurface;
    final Color muted = featured ? scheme.onPrimaryContainer : scheme.onSurfaceVariant;

    // Filter out badges that duplicate time (e.g. "15 mins" when "$minutes min" is shown)
    final filteredBadges = badges.where((b) {
      final lower = b.toLowerCase();
      if (lower.contains('min') || lower.contains('minute')) return false;
      return true;
    }).toList();

    return AppCard(
      onTap: onTap,
      color: featured ? scheme.primaryContainer : null,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Visual Image or DishArt
          if (recipe != null)
            Stack(
              children: [
                RecipeImage(
                  recipe: recipe!,
                  photoUrl: photoUrl,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(AppRadius.lg),
                    topRight: Radius.circular(AppRadius.lg),
                  ),
                ),
                if (featured)
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
                            'Top Rescue Pick',
                            style: AppTypography.badgeTiny,
                          ),
                        ],
                      ),
                    ),
                  ),
                if (onBookmarkTap != null)
                  Positioned(
                    top: AppSpacing.xs,
                    right: AppSpacing.xs,
                    child: IconButton(
                      icon: Icon(
                        isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                        color: isSaved ? AppColors.orange : AppColors.white,
                      ),
                      tooltip: isSaved ? 'Remove from saved' : 'Save recipe',
                      onPressed: onBookmarkTap,
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
                  title,
                  style: text.titleLarge?.copyWith(color: fg),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  reason,
                  style: text.bodyMedium?.copyWith(color: muted),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: AppSpacing.md),
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: [
                    _Pill(label: '$minutes min', icon: Icons.timer_outlined),
                    for (final String badge in filteredBadges) _Pill(label: badge),
                  ],
                ),
                if (substitution != null && substitution!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.md),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.swap_horiz_rounded, size: AppSizes.iconSm, color: AppColors.orange),
                      const SizedBox(width: AppSpacing.xs),
                      Expanded(
                        child: Text(
                          substitution!,
                          style: text.bodySmall?.copyWith(color: muted),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({required this.label, this.icon});

  final String label;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final text = context.text;
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: scheme.secondaryContainer,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: scheme.onSecondaryContainer),
            const SizedBox(width: AppSpacing.xs),
          ],
          Flexible(
            child: Text(
              label,
              style: text.labelSmall?.copyWith(
                color: scheme.onSecondaryContainer,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
