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
import '../../../shell/presentation/cubit/navigation_cubit.dart';
import '../../../voice/data/datasources/gemini_remote_datasource.dart';
import '../../data/datasources/saved_recipe_repository.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/services/dish_image_resolver.dart';
import '../../domain/utils/recipe_query_parser.dart';
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
  int _selectedSegment = 0; // 0 = suggestions, 1 = saved
  int? _activeTimeFilter;
  String? _activeFocusFilter;
  String? _activeExcludeFilter;
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
    if (query.reset) {
      setState(() {
        _activeTimeFilter = null;
        _activeFocusFilter = null;
        _activeExcludeFilter = null;
      });
      context.read<RecipesBloc>().add(const ApplyRecipeFilter(reset: true));
      return;
    }

    setState(() {
      if (query.maxMinutes != null) _activeTimeFilter = query.maxMinutes;
      if (query.focusIngredient != null) _activeFocusFilter = query.focusIngredient;
      if (query.excludeIngredient != null) _activeExcludeFilter = query.excludeIngredient;
    });

    context.read<RecipesBloc>().add(ApplyRecipeFilter(
      maxMinutes: query.maxMinutes,
      focusIngredient: query.focusIngredient,
      excludeIngredient: query.excludeIngredient,
      diet: query.diet,
      cuisine: query.cuisine,
    ));
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rescue Recipes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.mic_none_rounded),
            tooltip: 'Ask for a recipe by voice',
            onPressed: () => _showConversationalVoiceDialog(context),
          ),
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
          vertical: AppSpacing.sm,
          child: BlocBuilder<RecipesBloc, RecipesState>(
            builder: (context, state) {
              final RecipeSource? source = state is RecipesLoaded ? state.source : null;
              return Column(
                children: [
                  _buildAiStatusBar(context, source: source),
                  _buildSegmentControls(context),
                  if (_selectedSegment == 0) _buildQuickFilterChips(context),
                  Expanded(
                    child: Builder(
                      builder: (context) {
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
                            onRetry: () => context.read<RecipesBloc>().add(const RefreshRecipes()),
                          );
                        }
                        if (state is RecipesLoaded) {
                          return _buildLoadedView(context, state);
                        }
                        return const SizedBox.shrink();
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
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

  Widget _buildSegmentControls(BuildContext context) {
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
                child: Text('Suggestions', maxLines: 1),
              ),
              icon: Icon(Icons.auto_awesome_outlined, size: 14),
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
          selected: {_selectedSegment},
          onSelectionChanged: (selected) {
            setState(() => _selectedSegment = selected.first);
            context.read<RecipesBloc>().add(SwitchRecipeSegment(selected.first));
          },
        ),
      ),
    );
  }

  Widget _buildQuickFilterChips(BuildContext context) {
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
          ChoiceChip(
            label: const Text('Any time'),
            selected: _activeTimeFilter == null,
            onSelected: (_) {
              setState(() => _activeTimeFilter = null);
              context.read<RecipesBloc>().add(const ApplyRecipeFilter(maxMinutes: null));
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('<= 15 min'),
            selected: _activeTimeFilter == 15,
            onSelected: (val) {
              setState(() => _activeTimeFilter = val ? 15 : null);
              context.read<RecipesBloc>().add(ApplyRecipeFilter(maxMinutes: val ? 15 : null));
            },
          ),
          const SizedBox(width: AppSpacing.xs),
          ChoiceChip(
            label: const Text('<= 30 min'),
            selected: _activeTimeFilter == 30,
            onSelected: (val) {
              setState(() => _activeTimeFilter = val ? 30 : null);
              context.read<RecipesBloc>().add(ApplyRecipeFilter(maxMinutes: val ? 30 : null));
            },
          ),
          if (_activeFocusFilter != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InputChip(
              label: Text('Using: $_activeFocusFilter'),
              onDeleted: () {
                setState(() => _activeFocusFilter = null);
                context.read<RecipesBloc>().add(const ApplyRecipeFilter(focusIngredient: ''));
              },
            ),
          ],
          if (_activeExcludeFilter != null) ...[
            const SizedBox(width: AppSpacing.xs),
            InputChip(
              label: Text('No: $_activeExcludeFilter'),
              onDeleted: () {
                setState(() => _activeExcludeFilter = null);
                context.read<RecipesBloc>().add(const ApplyRecipeFilter(excludeIngredient: ''));
              },
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

  Widget _buildEmptyView(BuildContext context) {
    if (_selectedSegment == 1) {
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
        icon: Icons.kitchen_outlined,
        title: 'Your kitchen is empty',
        message: 'Add ingredients first so we can rank rescue recipes based on what is about to expire.',
        actionLabel: 'Go to kitchen',
        onAction: () => context.read<NavigationCubit>().select(NavTab.kitchen),
      ),
    );
  }

  Widget _buildNoMatchesView(BuildContext context, RecipesNoMatches state) {
    return Center(
      child: EmptyState(
        icon: Icons.filter_alt_off_outlined,
        title: 'No recipes match',
        message: state.reason,
        actionLabel: 'Reset filters',
        onAction: () {
          setState(() {
            _activeTimeFilter = null;
            _activeFocusFilter = null;
            _activeExcludeFilter = null;
          });
          context.read<RecipesBloc>().add(const ApplyRecipeFilter(reset: true));
        },
      ),
    );
  }

  Widget _buildLoadedView(BuildContext context, RecipesLoaded state) {
    final recipes = state.recipes;
    if (recipes.isEmpty) return _buildEmptyView(context);

    for (final r in recipes) {
      _resolveRecipeImage(r.recipe);
    }

    final topPick = recipes.first;
    final otherRecipes = recipes.length > 1 ? recipes.sublist(1) : <RankedRecipe>[];

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SectionHeader(
            title: _selectedSegment == 1 ? 'Saved Recipes' : 'Top Recommendations',
            subtitle: 'Ranked for maximum rescue',
          ),
          const SizedBox(height: AppSpacing.sm),
          // Featured Hero Card
          _buildRecipeItem(context, topPick, featured: true),
          const SizedBox(height: AppSpacing.lg),

          // Responsive grid for remaining cards (1 column on compact, 2 on medium/expanded)
          if (otherRecipes.isNotEmpty) ...[
            SectionHeader(
              title: _selectedSegment == 1 ? 'All Saved Dishes' : 'More Rescue Options',
              subtitle: 'Tailored to your ingredients and dietary filters',
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final isTwoCol = constraints.maxWidth >= 600;
                if (!isTwoCol) {
                  return Column(
                    children: otherRecipes.map((r) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: _buildRecipeItem(context, r),
                      );
                    }).toList(),
                  );
                }

                // Two columns grid
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 0; i < otherRecipes.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildRecipeItem(context, otherRecipes[i]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        children: [
                          for (int i = 1; i < otherRecipes.length; i += 2)
                            Padding(
                              padding: const EdgeInsets.only(bottom: AppSpacing.md),
                              child: _buildRecipeItem(context, otherRecipes[i]),
                            ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          const ExpiryDisclaimer(),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildRecipeItem(
    BuildContext context,
    RankedRecipe item, {
    bool featured = false,
  }) {
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
      featured: featured,
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
        context.read<RecipesBloc>().add(ToggleSaveRecipe(item.recipe));
        setState(() {});
      },
    );
  }
}
