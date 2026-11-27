import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/recipe_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../../shell/presentation/cubit/navigation_cubit.dart';
import '../../../voice/data/datasources/gemini_remote_datasource.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../bloc/recipes_bloc.dart';
import '../bloc/recipes_event.dart';
import '../bloc/recipes_state.dart';
import 'recipe_detail_page.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  CuisineTag _selectedCuisine = CuisineTag.any;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Regenerate recipes',
            onPressed: () {
              HapticFeedback.lightImpact();
              context.read<RecipesBloc>().add(const RefreshRecipes());
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ContentContainer(
          vertical: AppSpacing.md,
          child: BlocBuilder<RecipesBloc, RecipesState>(
            builder: (context, state) {
              if (state is RecipesInitial) {
                context.read<RecipesBloc>().add(const LoadRecipes());
                return const Center(child: CircularProgressIndicator());
              }

              if (state is RecipesLoading) {
                return _buildLoadingView();
              }

              if (state is RecipesEmpty) {
                return _buildEmptyView(context);
              }

              if (state is RecipesNoMatches) {
                return _buildNoMatchesView(context, state);
              }

              if (state is RecipesError) {
                return ErrorState(
                  message: state.message,
                  retryLabel: 'Try again',
                  onRetry: () {
                    context.read<RecipesBloc>().add(const RefreshRecipes());
                  },
                );
              }

              if (state is RecipesLoaded) {
                return _buildLoadedView(context, state);
              }

              return const SizedBox.shrink();
            },
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingView() {
    return const SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: 'Generating rescue recipes...',
            subtitle: 'Evaluating expiring food to curate the highest-impact dishes.',
          ),
          SizedBox(height: AppSpacing.xl),
          LoadingSkeletonList(count: 3),
        ],
      ),
    );
  }

  Widget _buildEmptyView(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Your kitchen is empty',
        message: 'Add or speak your ingredients first so we can rank rescue recipes based on what is about to expire.',
        actionLabel: 'Go to kitchen',
        onAction: () {
          context.read<NavigationCubit>().select(NavTab.kitchen);
        },
      ),
    );
  }

  Widget _buildNoMatchesView(BuildContext context, RecipesNoMatches state) {
    return Center(
      child: EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No recipes match',
        message: state.reason,
        actionLabel: state.dietPreference != DietTag.none ? 'Clear diet filter' : 'Add more ingredients',
        onAction: () {
          if (state.dietPreference != DietTag.none) {
            context.read<RecipesBloc>().add(const ChangeDiet(DietTag.none));
          } else {
            context.read<NavigationCubit>().select(NavTab.kitchen);
          }
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, RecipesLoaded state) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    // Filter recipes by local cuisine tag if selected
    List<RankedRecipe> filtered = state.recipes;
    if (_selectedCuisine != CuisineTag.any) {
      filtered = state.recipes.where((r) {
        final recCuisine = r.recipe.cuisine?.toLowerCase() ?? '';
        final prefCuisine = _selectedCuisine.displayName.toLowerCase();
        return recCuisine.contains(prefCuisine) || prefCuisine.contains(recCuisine);
      }).toList();
    }

    // Split into Cook Now (all on hand) and Almost There (missing some)
    final cookNow = filtered.where((r) => r.missingIngredients.isEmpty && r.needMoreIngredients.isEmpty).toList();
    final almostThere = filtered.where((r) => r.missingIngredients.isNotEmpty || r.needMoreIngredients.isNotEmpty).toList();

    final topPick = filtered.isNotEmpty ? filtered.first : null;

    final aiStatus = sl<GeminiRemoteDataSource>().lastStatus;

    return RefreshIndicator(
      onRefresh: () async {
        context.read<RecipesBloc>().add(const RefreshRecipes());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // AI / Offline Reason Banner
            if (state.source == RecipeSource.offline) ...[
              AppCard(
                color: AppColors.medium.withValues(alpha: 0.15),
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  children: [
                    const Icon(
                      Icons.cloud_off_rounded,
                      color: AppColors.medium,
                      size: AppSizes.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Showing Bundled Recipes',
                            style: text.labelMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: scheme.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Offline fallback active (${aiStatus.displayLabel}). Connect internet with a configured Gemini key for live AI recipes.',
                            style: text.bodySmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            // Horizontal Diet Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final tag in DietTag.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(tag.displayName),
                        selected: state.dietPreference == tag,
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            context.read<RecipesBloc>().add(ChangeDiet(tag));
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xs),

            // Horizontal Cuisine Filter Bar
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final cuisine in CuisineTag.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpacing.xs),
                      child: ChoiceChip(
                        label: Text(cuisine.displayName),
                        selected: _selectedCuisine == cuisine,
                        selectedColor: AppColors.orange.withValues(alpha: 0.2),
                        onSelected: (selected) {
                          if (selected) {
                            HapticFeedback.selectionClick();
                            setState(() => _selectedCuisine = cuisine);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),

            // Top Pick Featured Recipe Card
            if (topPick != null) ...[
              const SectionHeader(
                title: 'Rescue Pick',
                subtitle: 'Highest priority match for your expiring items',
              ),
              const SizedBox(height: AppSpacing.sm),
              RecipeCard(
                featured: true,
                title: topPick.recipe.title,
                reason: topPick.reason,
                minutes: topPick.recipe.minutes,
                badges: topPick.badges.map((b) => b.label).toList(),
                substitution: topPick.recipe.substitutions.isNotEmpty
                    ? '${topPick.recipe.substitutions.first.missingIngredient} → ${topPick.recipe.substitutions.first.substitute}'
                    : null,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => RecipeDetailPage(rankedRecipe: topPick),
                    ),
                  );
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],

            // Cook Now Section
            if (cookNow.isNotEmpty) ...[
              SectionHeader(
                title: 'Cook Now (${cookNow.length})',
                subtitle: '100% ingredients already on hand in your kitchen',
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final recipe in cookNow) ...[
                if (recipe != topPick) ...[
                  RecipeCard(
                    title: recipe.recipe.title,
                    reason: recipe.reason,
                    minutes: recipe.recipe.minutes,
                    badges: recipe.badges.map((b) => b.label).toList(),
                    substitution: recipe.recipe.substitutions.isNotEmpty
                        ? '${recipe.recipe.substitutions.first.missingIngredient} → ${recipe.recipe.substitutions.first.substitute}'
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecipeDetailPage(rankedRecipe: recipe),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
            ],

            // Almost There Section
            if (almostThere.isNotEmpty) ...[
              SectionHeader(
                title: 'Almost There (${almostThere.length})',
                subtitle: 'Only 1 or 2 small items or pantry staples missing',
              ),
              const SizedBox(height: AppSpacing.sm),
              for (final recipe in almostThere) ...[
                if (recipe != topPick) ...[
                  RecipeCard(
                    title: recipe.recipe.title,
                    reason: recipe.reason,
                    minutes: recipe.recipe.minutes,
                    badges: recipe.badges.map((b) => b.label).toList(),
                    substitution: recipe.recipe.substitutions.isNotEmpty
                        ? '${recipe.recipe.substitutions.first.missingIngredient} → ${recipe.recipe.substitutions.first.substitute}'
                        : null,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => RecipeDetailPage(rankedRecipe: recipe),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),
                ],
              ],
              const SizedBox(height: AppSpacing.lg),
            ],

            const ExpiryDisclaimer(),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
