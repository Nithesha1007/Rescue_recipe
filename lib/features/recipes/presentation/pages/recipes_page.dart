import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/models/ai_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/recipe_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../cooking/presentation/pages/cooking_page.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../../shell/presentation/cubit/navigation_cubit.dart';
import '../../../voice/data/datasources/gemini_remote_datasource.dart';
import '../../data/datasources/saved_recipe_repository.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/dish_image_resolver.dart';
import '../../domain/utils/recipe_query_parser.dart';
import '../cubit/rescue_suggestions_cubit.dart';
import '../cubit/rescue_suggestions_state.dart';
import '../widgets/recipe_filter_bottom_sheet.dart';
import '../widgets/rescue_mission_hero_card.dart';
import '../widgets/rescue_plan_bucket_card.dart';
import '../widgets/urgency_strip.dart';
import 'recipe_detail_page.dart';

class RecipesPage extends StatefulWidget {
  const RecipesPage({super.key});

  @override
  State<RecipesPage> createState() => _RecipesPageState();
}

class _RecipesPageState extends State<RecipesPage> {
  final Map<String, String?> _photoUrls = {};

  @override
  void initState() {
    super.initState();
    _silentAiCheck();
  }

  Future<void> _silentAiCheck() async {
    if (sl.isRegistered<GeminiRemoteDataSource>()) {
      await sl<GeminiRemoteDataSource>().testConnection();
      if (mounted) setState(() {});
    }
  }

  void _showConversationalVoiceDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (dlgCtx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.mic, color: AppColors.orange),
            SizedBox(width: 8),
            Text('Ask for a Recipe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Speak or type what you need (e.g. "something in 15 minutes", "without onions", "use tomatoes first", "vegetarian"):',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'e.g. ready in 20 minutes with spinach',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dlgCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final text = controller.text.trim();
              Navigator.of(dlgCtx).pop();
              if (text.isNotEmpty) {
                final parsed = RecipeQueryParser.parse(text);
                _applyParsedQuery(parsed);
              }
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _applyParsedQuery(ParsedRecipeQuery query) {
    final cubit = context.read<RescueSuggestionsCubit>();
    if (query.reset) {
      cubit.resetFilters();
      return;
    }
    cubit.applyFilters(
      maxMinutes: query.maxMinutes,
      focusIngredient: query.focusIngredient,
      excludeIngredient: query.excludeIngredient,
      diet: query.diet,
      cuisine: query.cuisine,
    );
  }

  void _openFilterSheet(BuildContext context) {
    final cubit = context.read<RescueSuggestionsCubit>();
    final state = cubit.state;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => RecipeFilterBottomSheet(
        initialTime: state.activeTimeFilter,
        initialDiet: state.dietPreference,
        initialCuisine: state.cuisinePreference,
        initialExclude: state.activeExcludeFilter,
        onApply: ({maxMinutes, diet, cuisine, excludeIngredient, reset = false}) {
          if (reset) {
            cubit.resetFilters();
          } else {
            cubit.applyFilter(
              maxMinutes: maxMinutes,
              diet: diet,
              cuisine: cuisine,
              excludeIngredient: excludeIngredient,
            );
          }
        },
      ),
    );
  }

  Future<void> _resolveRecipeImage(Recipe recipe) async {
    if (_photoUrls.containsKey(recipe.id)) return;
    if (sl.isRegistered<DishImageResolver>()) {
      final url = await sl<DishImageResolver>().resolvePhotoUrl(
        imageQuery: recipe.imageQuery,
        title: recipe.title,
        cuisine: recipe.cuisine,
      );
      if (mounted) {
        setState(() => _photoUrls[recipe.id] = url);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RescueSuggestionsCubit, RescueSuggestionsState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Rescue Plan'),
            actions: [
              IconButton(
                icon: const Icon(Icons.mic_none_rounded),
                tooltip: 'Ask for a recipe by voice',
                onPressed: () => _showConversationalVoiceDialog(context),
              ),
              IconButton(
                icon: const Icon(Icons.filter_list_rounded),
                tooltip: 'Filter recipes',
                onPressed: () => _openFilterSheet(context),
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Regenerate recipes',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  context.read<RescueSuggestionsCubit>().forceRegenerate();
                },
              ),
            ],
            bottom: state.isUpdatingSuggestions
                ? PreferredSize(
                    preferredSize: const Size.fromHeight(4.0),
                    child: SizedBox(
                      height: 4.0,
                      child: LinearProgressIndicator(
                        backgroundColor: AppColors.orange.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
                      ),
                    ),
                  )
                : null,
          ),
          body: SafeArea(
            child: ContentContainer(
              vertical: AppSpacing.sm,
              child: Column(
                children: [
                  _buildAiStatusBar(context, source: state.source),
                  _buildSegmentControls(context, state),
                  if (state.selectedSegment == 0)
                    _buildActiveFilterChips(context, state),
                  Expanded(
                    child: Builder(
                      builder: (context) {
                        if (state.isLoading && state.displayRecipes.isEmpty) {
                          return _buildLoadingView();
                        }
                        if (state.errorMessage != null && state.displayRecipes.isEmpty) {
                          return ErrorState(
                            message: state.errorMessage!,
                            retryLabel: 'Try again',
                            onRetry: () => context.read<RescueSuggestionsCubit>().forceRegenerate(),
                          );
                        }
                        if (state.activeIngredients.isEmpty && state.selectedSegment != 1) {
                          return _buildEmptyKitchenView(context);
                        }
                        if (state.displayRecipes.isEmpty) {
                          return _buildNoMatchesView(context, state);
                        }
                        return _buildLoadedView(context, state);
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildAiStatusBar(BuildContext context, {RecipeSource? source}) {
    if (source == RecipeSource.offline || source == RecipeSource.cachedAi) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.medium.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(AppRadius.pill),
          border: Border.all(color: AppColors.medium.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.offline_bolt, size: 14, color: AppColors.medium),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                'Offline recipes',
                style: context.text.labelSmall?.copyWith(
                  color: AppColors.medium,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      );
    }
    final geminiDs = sl.isRegistered<GeminiRemoteDataSource>()
        ? sl<GeminiRemoteDataSource>()
        : null;
    final status = geminiDs?.lastStatus ?? const AiStatus(state: AiConnectionState.untested);

    final (color, icon, text) = switch (status.state) {
      AiConnectionState.ok => (AppColors.low, Icons.auto_awesome, 'AI recipes active (${status.activeModel ?? "flash"})'),
      AiConnectionState.noKey => (AppColors.medium, Icons.offline_bolt, 'Running offline (No API key set)'),
      AiConnectionState.authError => (AppColors.critical, Icons.key_off, 'Invalid API key (Using offline recipes)'),
      AiConnectionState.quotaExceeded => (AppColors.medium, Icons.timer, 'Rate limited (Using offline recipes)'),
      AiConnectionState.offline || AiConnectionState.timeout => (AppColors.medium, Icons.wifi_off, 'Offline recipes'),
      _ => (AppColors.unknown, Icons.help_outline, 'Offline recipes'),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              style: context.text.labelSmall?.copyWith(color: color, fontWeight: FontWeight.bold),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSegmentControls(BuildContext context, RescueSuggestionsState state) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: SizedBox(
        width: double.infinity,
        child: SegmentedButton<int>(
          showSelectedIcon: false,
          style: const ButtonStyle(
            padding: WidgetStatePropertyAll(
              EdgeInsets.symmetric(horizontal: AppSpacing.xs, vertical: AppSpacing.xs),
            ),
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: VisualDensity.compact,
          ),
          segments: const [
            ButtonSegment(
              value: 0,
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Rescue Plan', maxLines: 1),
              ),
              icon: Icon(Icons.bolt_rounded, size: 14),
            ),
            ButtonSegment(
              value: 1,
              label: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text('Saved', maxLines: 1),
              ),
              icon: Icon(Icons.bookmark_outline_rounded, size: 14),
            ),
          ],
          selected: {state.selectedSegment},
          onSelectionChanged: (selected) {
            context.read<RescueSuggestionsCubit>().switchSegment(selected.first);
          },
        ),
      ),
    );
  }

  Widget _buildActiveFilterChips(BuildContext context, RescueSuggestionsState state) {
    final cubit = context.read<RescueSuggestionsCubit>();
    final hasFilters = state.activeTimeFilter != null ||
        state.activeFocusFilter != null ||
        state.activeExcludeFilter != null ||
        state.dietPreference != DietTag.none ||
        state.cuisinePreference != CuisineTag.any;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          ActionChip(
            avatar: const Icon(Icons.mic, size: 16, color: AppColors.orange),
            label: const Text('Ask by voice'),
            onPressed: () => _showConversationalVoiceDialog(context),
          ),
          const SizedBox(width: AppSpacing.xs),
          ActionChip(
            avatar: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Filters'),
            onPressed: () => _openFilterSheet(context),
          ),
          if (state.activeTimeFilter != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InputChip(
              label: Text('<= ${state.activeTimeFilter} min'),
              onDeleted: () => cubit.applyFilter(maxMinutes: null),
            ),
          ],
          if (state.activeFocusFilter != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InputChip(
              label: Text('Using: ${state.activeFocusFilter}'),
              onDeleted: () => cubit.toggleFocusIngredient(state.activeFocusFilter!),
            ),
          ],
          if (state.activeExcludeFilter != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InputChip(
              label: Text('No: ${state.activeExcludeFilter}'),
              onDeleted: () => cubit.applyFilter(excludeIngredient: ''),
            ),
          ],
          if (hasFilters) ...[
            const SizedBox(width: AppSpacing.xs),
            TextButton(
              onPressed: () => cubit.resetFilters(),
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              child: const Text('Clear all'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLoadingView() {
    return const SingleChildScrollView(
      padding: EdgeInsets.all(AppSpacing.lg),
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

  Widget _buildEmptyKitchenView(BuildContext context) {
    return Center(
      child: EmptyState(
        icon: Icons.kitchen_outlined,
        title: 'Your kitchen is empty',
        message: 'Add ingredients first so we can rank rescue recipes based on what is about to expire.',
        actionLabel: 'Go to kitchen',
        onAction: () => context.read<NavigationCubit>().select(NavTab.kitchen),
      ),
    );
  }

  Widget _buildNoMatchesView(BuildContext context, RescueSuggestionsState state) {
    if (state.selectedSegment == 1) {
      return const Center(
        child: EmptyState(
          icon: Icons.bookmark_border_rounded,
          title: 'No saved recipes yet',
          message: 'Tap the bookmark icon on any recipe card to save it for offline cooking.',
        ),
      );
    }
    return Center(
      child: EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No recipes match',
        message: 'Try adjusting or clearing your filters to see more rescue ideas.',
        actionLabel: 'Reset filters',
        onAction: () {
          context.read<RescueSuggestionsCubit>().resetFilters();
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, RescueSuggestionsState state) {
    final cubit = context.read<RescueSuggestionsCubit>();
    final recipes = state.displayRecipes;
    for (final r in recipes) {
      _resolveRecipeImage(r.recipe);
    }

    final atRiskCount = state.atRiskIngredients.length;
    final subtitle = atRiskCount > 0
        ? '$atRiskCount ${atRiskCount == 1 ? 'item needs' : 'items need'} attention soon'
        : 'Your food is in great shape!';

    // Filter recipes for "More ideas" section
    final cookNowRecipes = <RankedRecipe>[];
    final almostThereRecipes = <RankedRecipe>[];

    for (final r in recipes) {
      if (r.missingIngredients.isNotEmpty) {
        almostThereRecipes.add(r);
      } else {
        cookNowRecipes.add(r);
      }
    }

    return RefreshIndicator(
      onRefresh: () async {
        HapticFeedback.lightImpact();
        await cubit.forceRegenerate();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header with live rescue subtitle
            SectionHeader(
              title: state.selectedSegment == 1 ? 'Saved Recipes' : 'Rescue Plan',
              subtitle: state.selectedSegment == 1
                  ? '${recipes.length} saved dishes ready offline'
                  : subtitle,
            ),
            const SizedBox(height: AppSpacing.sm),

            if (state.selectedSegment == 0) ...[
              // 1. Urgency Strip
              if (state.atRiskIngredients.isNotEmpty) ...[
                UrgencyStrip(
                  expiringItems: state.atRiskIngredients,
                  activeFocusIngredient: state.activeFocusFilter,
                  onTapItem: (itemName) {
                    cubit.toggleFocusIngredient(itemName);
                  },
                ),
                const SizedBox(height: AppSpacing.md),
              ],

              // 2. Today's Rescue Mission Hero Card
              if (state.heroRecipe != null) ...[
                RescueMissionHeroCard(
                  rankedRecipe: state.heroRecipe!,
                  photoUrl: _photoUrls[state.heroRecipe!.recipe.id],
                  onViewRecipe: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => RecipeDetailPage(rankedRecipe: state.heroRecipe!),
                      ),
                    );
                  },
                  onStartCooking: () {
                    HapticFeedback.lightImpact();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CookingPage(recipe: state.heroRecipe!.recipe),
                      ),
                    );
                  },
                ),
                const SizedBox(height: AppSpacing.lg),
              ],

              // 3. Rescue Plan Buckets
              if (state.buckets.isNotEmpty) ...[
                for (final bucket in state.buckets) ...[
                  RescuePlanBucketCard(
                    bucket: bucket,
                    onTapRecipe: (ranked) {
                      HapticFeedback.lightImpact();
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => RecipeDetailPage(rankedRecipe: ranked),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
                const SizedBox(height: AppSpacing.sm),
              ],
            ],

            // 4. More Ideas / Recipe Grid
            if (state.selectedSegment == 1) ...[
              _buildRecipeGrid(context, recipes),
            ] else ...[
              if (cookNowRecipes.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Cook Now',
                  subtitle: 'Everything in stock - no grocery trips needed',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildRecipeGrid(context, cookNowRecipes),
                const SizedBox(height: AppSpacing.lg),
              ],
              if (almostThereRecipes.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Almost There',
                  subtitle: 'Missing 1 or 2 non-critical ingredients',
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildRecipeGrid(context, almostThereRecipes),
                const SizedBox(height: AppSpacing.lg),
              ],
            ],

            const SizedBox(height: AppSpacing.md),
            const ExpiryDisclaimer(),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  Widget _buildRecipeGrid(BuildContext context, List<RankedRecipe> items) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTwoCol = constraints.maxWidth >= 600;
        if (!isTwoCol) {
          return Column(
            children: items.map((r) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _buildRecipeItem(context, r),
              );
            }).toList(),
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  for (int i = 0; i < items.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildRecipeItem(context, items[i]),
                    ),
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                children: [
                  for (int i = 1; i < items.length; i += 2)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.md),
                      child: _buildRecipeItem(context, items[i]),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRecipeItem(BuildContext context, RankedRecipe item) {
    final isSaved = sl.isRegistered<SavedRecipeRepository>()
        ? sl<SavedRecipeRepository>().isSaved(item.recipe.id)
        : false;

    return RecipeCard(
      title: item.recipe.title,
      reason: item.reason,
      minutes: item.recipe.minutes,
      badges: item.badges.map((b) => b.label).toList(),
      substitution: item.recipe.substitutions.isNotEmpty
          ? 'Substitute with ${item.recipe.substitutions.first.substitute}'
          : null,
      featured: false,
      isSaved: isSaved,
      recipe: item.recipe,
      photoUrl: _photoUrls[item.recipe.id],
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => RecipeDetailPage(rankedRecipe: item),
          ),
        );
      },
      onBookmarkTap: () {
        context.read<RescueSuggestionsCubit>().toggleSaveRecipe(item.recipe);
        setState(() {});
      },
    );
  }
}
