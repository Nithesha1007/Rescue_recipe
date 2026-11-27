import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../cooking/presentation/pages/cooking_page.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';

class RecipeDetailPage extends StatelessWidget {
  const RecipeDetailPage({
    super.key,
    required this.rankedRecipe,
  });

  final RankedRecipe rankedRecipe;

  @override
  Widget build(BuildContext context) {
    final recipe = rankedRecipe.recipe;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(recipe.title),
      ),
      body: SafeArea(
        child: ContentContainer(
          vertical: AppSpacing.md,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header details
                Text(
                  recipe.title,
                  style: text.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: scheme.onSurface,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  rankedRecipe.reason,
                  style: text.bodyMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Key Facts Row
                _buildKeyFactsRow(context),
                const SizedBox(height: AppSpacing.sm),

                // Badges
                Wrap(
                  spacing: AppSpacing.sm,
                  runSpacing: AppSpacing.xs,
                  children: [
                    for (final badge in rankedRecipe.badges)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: AppSpacing.xs,
                        ),
                        decoration: BoxDecoration(
                          color: scheme.primaryContainer,
                          borderRadius: BorderRadius.circular(AppRadius.pill),
                        ),
                        child: Text(
                          badge.label,
                          style: text.labelSmall?.copyWith(
                            color: scheme.onPrimaryContainer,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),

                // Cooking Tips Card (if any)
                if (recipe.tips.isNotEmpty) ...[
                  _buildTipsCard(context),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Rescue Breakdown Section
                _buildRescueBreakdown(context),
                const SizedBox(height: AppSpacing.xl),

                // Ingredients Section
                _buildIngredientsSection(context),
                const SizedBox(height: AppSpacing.xl),

                // Substitutions Section
                if (recipe.substitutions.isNotEmpty) ...[
                  _buildSubstitutionsSection(context),
                  const SizedBox(height: AppSpacing.xl),
                ],

                // Steps Section
                _buildStepsSection(context),
                const SizedBox(height: AppSpacing.xl),

                // Large orange Start Cooking Button
                AppButton(
                  label: 'Start cooking',
                  icon: Icons.play_arrow,
                  variant: AppButtonVariant.filled,
                  expand: true,
                  onPressed: () {
                    HapticFeedback.mediumImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CookingPage(recipe: rankedRecipe.recipe),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.xl),

                const ExpiryDisclaimer(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKeyFactsRow(BuildContext context) {
    final recipe = rankedRecipe.recipe;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _factItem(context, Icons.timer_outlined, '${recipe.minutes} min'),
          _factItem(context, Icons.people_outline, '${recipe.servings} ${recipe.servings == 1 ? "serving" : "servings"}'),
          _factItem(context, Icons.bar_chart_rounded, recipe.difficulty),
          if (recipe.cuisine != null)
            _factItem(context, Icons.restaurant_rounded, recipe.cuisine!),
        ],
      ),
    );
  }

  Widget _factItem(BuildContext context, IconData icon, String label) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSizes.iconSm, color: AppColors.orange),
        const SizedBox(width: 4),
        Text(
          label,
          style: theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    final tips = rankedRecipe.recipe.tips;
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lightbulb_rounded, color: AppColors.orange, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.xs),
              Text(
                "Chef's Cooking Tips",
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          for (final tip in tips)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                '• $tip',
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.35,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRescueBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final overallPercent = (rankedRecipe.totalScore * 100).toInt().clamp(0, 100);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.orange, size: AppSizes.icon),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  'Rescue score breakdown',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$overallPercent%',
                  style: text.labelMedium?.copyWith(
                    color: AppColors.ink,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Explainable ranking based on urgency, ingredient availability, speed, and dietary preferences.',
            style: text.bodySmall?.copyWith(
              color: scheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _ScoreProgressBar(
            title: 'Expiring items coverage (45%)',
            score: rankedRecipe.coverageScore,
            detail: '${rankedRecipe.coveredExpiringCount} of ${rankedRecipe.totalExpiringCount} expiring items used',
            barColor: AppColors.critical,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Ingredients on hand (30%)',
            score: rankedRecipe.availabilityScore,
            detail: rankedRecipe.missingIngredients.isEmpty && rankedRecipe.needMoreIngredients.isEmpty
                ? 'All required ingredients on hand'
                : '${rankedRecipe.missingIngredients.length + rankedRecipe.needMoreIngredients.length} need attention',
            barColor: AppColors.orange,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Cooking speed (15%)',
            score: rankedRecipe.speedScore,
            detail: '${rankedRecipe.recipe.minutes} minutes',
            barColor: AppColors.low,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Preference match (10%)',
            score: rankedRecipe.preferenceScore,
            detail: 'Matches your diet and cuisine settings',
            barColor: scheme.secondary,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ingredients = rankedRecipe.recipe.ingredients;

    final missingNames = rankedRecipe.missingIngredients.map((i) => i.name.toLowerCase()).toSet();
    final needMoreNames = rankedRecipe.needMoreIngredients.map((i) => i.name.toLowerCase()).toSet();
    final matchedMap = {
      for (final m in rankedRecipe.matchedExpiringIngredients)
        m.name.toLowerCase(): m,
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Ingredients',
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final ing in ingredients) ...[
          _IngredientRow(
            ingredient: ing,
            isMissing: missingNames.contains(ing.name.toLowerCase()),
            isNeedMore: needMoreNames.contains(ing.name.toLowerCase()),
            matchedExpiring: matchedMap[ing.name.toLowerCase()],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildSubstitutionsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final subs = rankedRecipe.recipe.substitutions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Possible Substitutions',
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final s in subs) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.swap_horiz_rounded,
                      color: AppColors.orange,
                      size: AppSizes.iconSm,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        'Missing ${s.missingIngredient}? Use ${s.substitute}',
                        style: text.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                if (s.note.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    s.note,
                    style: text.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;
    final steps = rankedRecipe.recipe.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Instructions',
          style: text.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < steps.length; i++) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: scheme.primaryContainer,
                  child: Text(
                    '${i + 1}',
                    style: text.labelMedium?.copyWith(
                      color: scheme.onPrimaryContainer,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        steps[i].text,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurface,
                        ),
                      ),
                      if (steps[i].minutes != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '~${steps[i].minutes} min',
                          style: text.labelSmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      if (steps[i].tip != null) ...[
                        const SizedBox(height: AppSpacing.xs),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.orange.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(AppRadius.sm),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.tips_and_updates_outlined, size: 14, color: AppColors.orange),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  steps[i].tip!,
                                  style: text.labelSmall?.copyWith(
                                    color: scheme.onSurface,
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
        ],
      ],
    );
  }
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.isMissing,
    this.isNeedMore = false,
    this.matchedExpiring,
  });

  final RecipeIngredient ingredient;
  final bool isMissing;
  final bool isNeedMore;
  final MatchedExpiringIngredient? matchedExpiring;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final IconData icon;
    final Color iconColor;
    final String statusLabel;

    if (isMissing) {
      icon = Icons.warning_amber_rounded;
      iconColor = AppColors.critical;
      statusLabel = 'Missing';
    } else if (isNeedMore) {
      icon = Icons.add_shopping_cart_rounded;
      iconColor = AppColors.orange;
      statusLabel = 'Need more';
    } else if (ingredient.isPantryStaple) {
      icon = Icons.inventory_2_outlined;
      iconColor = scheme.onSurfaceVariant;
      statusLabel = 'Pantry staple';
    } else {
      icon = Icons.check_circle_outline;
      iconColor = AppColors.low;
      statusLabel = 'In stock';
    }

    return AppCard(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
          Icon(icon, color: iconColor, size: AppSizes.iconSm),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.displayName,
                  style: text.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  statusLabel,
                  style: text.labelSmall?.copyWith(
                    color: iconColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          if (matchedExpiring != null) ...[
            PriorityChip(priority: matchedExpiring!.priority),
          ],
        ],
      ),
    );
  }
}

class _ScoreProgressBar extends StatelessWidget {
  const _ScoreProgressBar({
    required this.title,
    required this.score,
    required this.detail,
    required this.barColor,
  });

  final String title;
  final double score;
  final String detail;
  final Color barColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final percent = (score * 100).toInt().clamp(0, 100);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                title,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              '$percent%',
              style: theme.textTheme.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.pill),
          child: LinearProgressIndicator(
            value: score.clamp(0.0, 1.0),
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          detail,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}
