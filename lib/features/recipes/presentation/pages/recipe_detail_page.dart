import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../cooking/presentation/pages/cooking_page.dart';
import '../../../cooking/presentation/widgets/language_chip_switcher.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../../data/datasources/saved_recipe_repository.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../../domain/services/dish_image_resolver.dart';
import '../../domain/services/step_ingredient_linker.dart';
import '../../domain/services/video_cooking_helper.dart';
import '../../domain/usecases/translate_recipe_content.dart';
import '../../domain/utils/servings_scaler.dart';
import '../widgets/recipe_image.dart';

class RecipeDetailPage extends StatefulWidget {
  const RecipeDetailPage({
    super.key,
    required this.rankedRecipe,
  });

  final RankedRecipe rankedRecipe;

  @override
  State<RecipeDetailPage> createState() => _RecipeDetailPageState();
}

class _RecipeDetailPageState extends State<RecipeDetailPage> {
  late int _targetServings;
  late Recipe _currentRecipe;
  String? _photoUrl;
  bool _isSaved = false;
  GuideLanguage _selectedLanguage = GuideLanguage.english;
  bool _isTranslating = false;

  @override
  void initState() {
    super.initState();
    _targetServings = widget.rankedRecipe.recipe.servings > 0
        ? widget.rankedRecipe.recipe.servings
        : 2;
    _currentRecipe = widget.rankedRecipe.recipe;

    _checkSavedStatus();
    _resolveImage();
  }

  void _checkSavedStatus() {
    if (sl.isRegistered<SavedRecipeRepository>()) {
      setState(() {
        _isSaved = sl<SavedRecipeRepository>().isSaved(_currentRecipe.id);
      });
    }
  }

  Future<void> _resolveImage() async {
    if (sl.isRegistered<DishImageResolver>()) {
      final url = await sl<DishImageResolver>().resolvePhotoUrl(
        imageQuery: _currentRecipe.imageQuery,
        title: _currentRecipe.title,
        cuisine: _currentRecipe.cuisine,
      );
      if (mounted && url != null) {
        setState(() => _photoUrl = url);
      }
    }
  }

  void _onServingsChanged(int newServings) {
    if (newServings < 1 || newServings > 12) return;
    setState(() {
      _targetServings = newServings;
      _currentRecipe = ServingsScaler.scaleRecipe(
        widget.rankedRecipe.recipe,
        newServings,
      );
    });
  }

  void _toggleBookmark() async {
    if (!sl.isRegistered<SavedRecipeRepository>()) return;
    final repo = sl<SavedRecipeRepository>();
    if (_isSaved) {
      await repo.removeRecipe(_currentRecipe.id);
    } else {
      await repo.saveRecipe(_currentRecipe);
    }
    if (mounted) {
      setState(() => _isSaved = !_isSaved);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isSaved ? 'Recipe saved to bookmarks!' : 'Recipe removed from bookmarks.'),
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyMissingItems() {
    final missing = widget.rankedRecipe.missingIngredients;
    if (missing.isEmpty) return;

    final text = missing.map((i) => '• ${i.name}').join('\n');
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied missing ingredients to clipboard!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 240,
            pinned: true,
            leading: IconButton(
              icon: const CircleAvatar(
                backgroundColor: AppColors.black45,
                child: Icon(Icons.arrow_back, color: AppColors.white, size: 20),
              ),
              onPressed: () => Navigator.of(context).pop(),
            ),
            actions: [
              IconButton(
                icon: CircleAvatar(
                  backgroundColor: AppColors.black45,
                  child: Icon(
                    _isSaved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
                    color: _isSaved ? AppColors.orange : AppColors.white,
                    size: 20,
                  ),
                ),
                tooltip: _isSaved ? 'Remove from saved' : 'Save recipe',
                onPressed: _toggleBookmark,
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: RecipeImage(
                recipe: _currentRecipe,
                photoUrl: _photoUrl,
                borderRadius: BorderRadius.zero,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: SafeArea(
              top: false,
              child: ContentContainer(
                vertical: AppSpacing.md,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Title only once here (never in app bar)
                      Text(
                        _currentRecipe.title,
                        style: text.headlineSmall?.copyWith(
                          fontFamily: AppTypography.headingFont,
                          fontWeight: FontWeight.w700,
                          color: scheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.rankedRecipe.reason,
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Language Switcher Chips
                      Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          Text('Language: ', style: text.labelSmall),
                          LanguageChipSwitcher(
                            selectedLanguage: _selectedLanguage,
                            onLanguageSelected: (lang) async {
                              if (lang == _selectedLanguage || _isTranslating) return;
                              setState(() {
                                _selectedLanguage = lang;
                                _isTranslating = true;
                              });

                              if (lang == GuideLanguage.english) {
                                setState(() {
                                  _currentRecipe = ServingsScaler.scaleRecipe(
                                    widget.rankedRecipe.recipe,
                                    _targetServings,
                                  );
                                  _isTranslating = false;
                                });
                              } else if (sl.isRegistered<TranslateRecipeContent>()) {
                                final translator = sl<TranslateRecipeContent>();
                                final translated = await translator.execute(
                                  recipe: widget.rankedRecipe.recipe,
                                  targetLanguage: lang,
                                );
                                if (mounted) {
                                  setState(() {
                                    _currentRecipe = ServingsScaler.scaleRecipe(
                                      translated,
                                      _targetServings,
                                    );
                                    _isTranslating = false;
                                  });
                                }
                              } else {
                                setState(() => _isTranslating = false);
                              }
                            },
                          ),
                          if (_isTranslating)
                            const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Pill Facts: 4 equal tiles (time, servings, difficulty, cuisine)
                      _buildPillFactsRow(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Servings Scaler
                      _buildServingsScaler(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Cooking Tips Card (if any)
                      if (_currentRecipe.tips.isNotEmpty) ...[
                        _buildTipsCard(context),
                        const SizedBox(height: AppSpacing.lg),
                      ],

                      // Rescue Breakdown Section
                      _buildRescueBreakdown(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Ingredients Section with Copy Missing Button
                      _buildIngredientsSection(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Substitutions (Only for missing ingredients)
                      _buildSubstitutionsSection(context),
                      const SizedBox(height: AppSpacing.lg),

                      // Steps Section with per-step tip chips
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
                              builder: (_) => CookingPage(recipe: _currentRecipe),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: AppSpacing.sm),

                      // Video Help Button
                      OutlinedButton.icon(
                        icon: const Icon(Icons.play_circle_outline_rounded, color: AppColors.critical),
                        label: const Text('Watch video on YouTube'),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(44),
                          side: BorderSide(color: scheme.outlineVariant),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppRadius.pill),
                          ),
                        ),
                        onPressed: () {
                          final query = VideoCookingHelper.buildDishVideoQuery(
                            dishTitle: _currentRecipe.title,
                            customQuery: _currentRecipe.videoSearchQuery,
                            guideLanguage: _selectedLanguage,
                          );
                          VideoCookingHelper.launchYouTubeSearch(query);
                        },
                      ),
                      const SizedBox(height: AppSpacing.md),

                      // Photo credit
                      if (_photoUrl != null)
                        Center(
                          child: Text(
                            'Photos from Wikipedia under CC-BY-SA',
                            style: text.labelSmall?.copyWith(
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      const ExpiryDisclaimer(),
                      const SizedBox(height: AppSpacing.xxl),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPillFactsRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildFactTile(
            context,
            icon: Icons.timer_outlined,
            title: '${_currentRecipe.minutes}m',
            subtitle: 'Ready',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildFactTile(
            context,
            icon: Icons.people_outline_rounded,
            title: '$_targetServings serv',
            subtitle: 'Yield',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildFactTile(
            context,
            icon: Icons.speed_rounded,
            title: _currentRecipe.difficulty,
            subtitle: 'Skill',
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: _buildFactTile(
            context,
            icon: Icons.ramen_dining_rounded,
            title: _currentRecipe.cuisine ?? 'Everyday',
            subtitle: 'Style',
          ),
        ),
      ],
    );
  }

  Widget _buildFactTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.xs,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(AppRadius.md),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.orange),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              title,
              style: text.labelSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: scheme.onSurface,
              ),
              maxLines: 1,
            ),
          ),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              subtitle,
              style: AppTypography.badgeTiny.copyWith(
                color: scheme.onSurfaceVariant,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServingsScaler(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Adjust Servings',
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Scales all ingredient quantities',
                  style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                color: AppColors.orange,
                onPressed: _targetServings > 1 ? () => _onServingsChanged(_targetServings - 1) : null,
              ),
              Text(
                '$_targetServings',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                color: AppColors.orange,
                onPressed: _targetServings < 12 ? () => _onServingsChanged(_targetServings + 1) : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTipsCard(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tips_and_updates_rounded, color: AppColors.orange, size: AppSizes.iconSm),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  "Chef's Tips",
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          for (final tip in _currentRecipe.tips) ...[
            Text('• $tip', style: text.bodySmall),
            const SizedBox(height: 2),
          ],
        ],
      ),
    );
  }

  Widget _buildRescueBreakdown(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final overallPercent = (widget.rankedRecipe.totalScore * 100).toInt().clamp(0, 100);

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
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.orange,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '$overallPercent%',
                  style: text.labelMedium?.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          // All bars in consistent warm orange family with clear text
          _ScoreProgressBar(
            title: 'Expiring items coverage (45%)',
            score: widget.rankedRecipe.coverageScore,
            detail: '${widget.rankedRecipe.coveredExpiringCount} of ${widget.rankedRecipe.totalExpiringCount} expiring items used',
            barColor: AppColors.breakdownOrangeDark,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Ingredients on hand (30%)',
            score: widget.rankedRecipe.availabilityScore,
            detail: widget.rankedRecipe.missingIngredients.isEmpty && widget.rankedRecipe.needMoreIngredients.isEmpty
                ? 'All required ingredients on hand'
                : '${widget.rankedRecipe.missingIngredients.length} missing, ${widget.rankedRecipe.needMoreIngredients.length} need more',
            barColor: AppColors.orange,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Cooking speed (15%)',
            score: widget.rankedRecipe.speedScore,
            detail: '${_currentRecipe.minutes} minutes',
            barColor: AppColors.breakdownOrangeMed,
          ),
          const SizedBox(height: AppSpacing.sm),
          _ScoreProgressBar(
            title: 'Preferences match (10%)',
            score: widget.rankedRecipe.preferenceScore,
            detail: 'Matches your diet and cuisine settings',
            barColor: AppColors.breakdownOrangeLight,
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final ingredients = _currentRecipe.ingredients;
    final missing = widget.rankedRecipe.missingIngredients;

    final missingNames = missing.map((i) => i.name.toLowerCase()).toSet();
    final needMoreNames = widget.rankedRecipe.needMoreIngredients.map((i) => i.name.toLowerCase()).toSet();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          alignment: WrapAlignment.spaceBetween,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          children: [
            Text(
              'Ingredients (${ingredients.length})',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (missing.isNotEmpty)
              TextButton.icon(
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy missing'),
                onPressed: _copyMissingItems,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        for (final ing in ingredients) ...[
          _IngredientRow(
            ingredient: ing,
            isMissing: missingNames.contains(ing.name.toLowerCase()),
            isNeedMore: needMoreNames.contains(ing.name.toLowerCase()),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildSubstitutionsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final missingNames = widget.rankedRecipe.missingIngredients.map((i) => i.name.toLowerCase()).toSet();

    // Substitutions appear ONLY for missing ingredients
    final relevantSubs = _currentRecipe.substitutions.where(
      (s) => missingNames.contains(s.missingIngredient.toLowerCase()),
    ).toList();

    if (relevantSubs.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Missing Item Substitutions',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (final s in relevantSubs) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.swap_horiz_rounded, color: AppColors.orange),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Replace "${s.missingIngredient}" with "${s.substitute}"',
                        style: text.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 2),
                      Text(s.note, style: text.bodySmall),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
      ],
    );
  }

  Widget _buildStepsSection(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final steps = _currentRecipe.steps;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Preparation Steps (${steps.length})',
          style: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.sm),
        for (int i = 0; i < steps.length; i++) ...[
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Step ${i + 1}',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                    if (steps[i].minutes != null)
                      Text(
                        '${steps[i].minutes} min',
                        style: text.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(steps[i].text, style: text.bodyMedium),

                // Ingredients for this step chips
                Builder(
                  builder: (_) {
                    final stepIngredients = StepIngredientLinker.linkIngredientsForStep(
                      step: steps[i],
                      recipeIngredients: _currentRecipe.ingredients,
                    );
                    if (stepIngredients.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: stepIngredients.map((ing) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.orange.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(AppRadius.sm),
                              border: Border.all(color: AppColors.orange.withValues(alpha: 0.25)),
                            ),
                            child: Text(
                              StepIngredientLinker.formatChipLabel(ing),
                              style: text.labelSmall?.copyWith(
                                color: AppColors.orangeDark,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                // How-to video technique chips
                Builder(
                  builder: (_) {
                    final techniques = VideoCookingHelper.findTechniquesInStep(steps[i].text);
                    if (techniques.isEmpty) return const SizedBox.shrink();
                    return Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.xs),
                      child: Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: techniques.map((tech) {
                          return ActionChip(
                            avatar: const Icon(Icons.ondemand_video_rounded, size: 14, color: AppColors.critical),
                            label: Text('How to ${tech.verb}'),
                            labelStyle: text.labelSmall,
                            onPressed: () {
                              VideoCookingHelper.launchYouTubeSearch(tech.query);
                            },
                          );
                        }).toList(),
                      ),
                    );
                  },
                ),

                if (steps[i].tip != null && steps[i].tip!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Chip(
                    avatar: const Icon(Icons.lightbulb_outline_rounded, size: 14),
                    label: Text(steps[i].tip!, style: text.labelSmall),
                    backgroundColor: AppColors.limeSoft,
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
}

class _IngredientRow extends StatelessWidget {
  const _IngredientRow({
    required this.ingredient,
    required this.isMissing,
    required this.isNeedMore,
  });

  final RecipeIngredient ingredient;
  final bool isMissing;
  final bool isNeedMore;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final text = theme.textTheme;

    final (IconData icon, Color iconColor, String statusLabel) = () {
      if (isMissing) {
        return (Icons.warning_amber_rounded, AppColors.critical, 'Missing');
      }
      if (isNeedMore) {
        return (Icons.add_shopping_cart_rounded, AppColors.orange, 'Need more');
      }
      if (ingredient.isPantryStaple) {
        return (Icons.inventory_2_outlined, scheme.onSurfaceVariant, 'Pantry staple');
      }
      return (Icons.check_circle_outline, AppColors.low, 'In stock');
    }();

    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
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
                  style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
                style: theme.textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            Text(
              '$percent%',
              style: theme.textTheme.labelSmall?.copyWith(fontWeight: FontWeight.bold),
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
