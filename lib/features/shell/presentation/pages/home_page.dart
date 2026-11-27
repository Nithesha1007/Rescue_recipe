import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/ingredient_tile.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/priority_chip.dart';
import '../../../../core/widgets/recipe_card.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../ingredients/presentation/cubit/inventory_cubit.dart';
import '../../../ingredients/presentation/cubit/inventory_state.dart';
import '../../../insights/presentation/cubit/insights_cubit.dart';
import '../../../insights/presentation/cubit/insights_state.dart';
import '../../../recipes/presentation/bloc/recipes_bloc.dart';
import '../../../recipes/presentation/bloc/recipes_state.dart';
import '../../../recipes/presentation/pages/recipe_detail_page.dart';
import '../../../voice/presentation/bloc/voice_input_bloc.dart';
import '../../../voice/presentation/bloc/voice_input_event.dart';
import '../../../voice/presentation/pages/voice_input_page.dart';
import '../cubit/navigation_cubit.dart';

const List<String> _foodWasteTips = [
  'Store potatoes and onions separately: onions emit ethylene gas that makes potatoes sprout faster.',
  'Place limp celery, carrots, or radishes in an ice-water bath for 30 minutes to restore their crisp crunch.',
  'Freeze overripe brown bananas for smoothies, banana bread, or dairy-free nice cream.',
  'Save vegetable peels, carrot tops, and onion skins in a freezer bag to boil rich vegetable stock.',
  'Wrap fresh herbs in a damp paper towel and store in an airtight container to double their fridge life.',
  'Store tomatoes stem-side down at room temperature to keep them juicy and prevent mealy texture.',
  'Bread stays fresh longer when sliced and frozen; pop slices straight into the toaster as needed.',
  'Revive stale bread or dinner rolls by sprinkling with drops of water and baking at 180°C for 5 minutes.',
  'Keep an "Eat Me First" bin or front row in your fridge for anything expiring in the next 48 hours.',
  'Store apples away from other fruits unless you intentionally want to speed up their ripening.',
  'Pickle leftover cucumber, carrot, or radish slices in warm vinegar, salt, and water for quick pickles.',
  'Freeze leftover tomato paste or coconut milk in ice cube trays for easy single-portion recipe cooking.',
  'Blend leftover wilted greens, spinach, or herbs with garlic, oil, and nuts into a vibrant quick pesto.',
  'Wash berries only right before eating them—moisture in the carton promotes mold growth.',
  'Cooked rice cools and separates best overnight, making it ideal for flavorful fried rice or pulao.',
];

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _tipIndex = 0;

  @override
  void initState() {
    super.initState();
    context.read<InsightsCubit>().loadInsights();
    _tipIndex = Random().nextInt(_foodWasteTips.length);
  }

  void _nextTip() {
    setState(() {
      _tipIndex = (_tipIndex + 1) % _foodWasteTips.length;
    });
  }

  void _openVoiceInput() {
    context.read<VoiceInputBloc>().add(const StartListening());
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => const VoiceInputPage(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(child: _HeroHeader(onSpeak: _openVoiceInput)),
        SliverSafeArea(
          top: false,
          sliver: SliverToBoxAdapter(
            child: ContentContainer(
              vertical: AppSpacing.xl,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _HomeScoreAndStreakSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _RescueRadarBarSection(),
                  const SizedBox(height: AppSpacing.xl),
                  _FoodWasteTipCard(
                    tip: _foodWasteTips[_tipIndex],
                    onNext: _nextTip,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const _HomeExpiryAlertsSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _CookThisNowSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const _UseTheseFirstSection(),
                  const SizedBox(height: AppSpacing.xl),
                  const ExpiryDisclaimer(),
                  const SizedBox(height: AppSpacing.lg),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.onSpeak});

  final VoidCallback onSpeak;

  @override
  Widget build(BuildContext context) {
    final tokens = context.tokens;
    final text = context.text;

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [tokens.heroStart, tokens.heroEnd],
        ),
        borderRadius: const BorderRadius.vertical(
          bottom: Radius.circular(AppRadius.xl),
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: ContentContainer(
          vertical: AppSpacing.xl,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                AppStrings.appName,
                style: text.headlineMedium?.copyWith(color: tokens.onHero),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                AppStrings.tagline,
                style: text.bodyMedium?.copyWith(color: tokens.onHeroMuted),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xl),
              GestureDetector(
                onTap: onSpeak,
                child: const VoiceOrb(
                  size: AppSizes.orb,
                  semanticLabel: 'Tap to speak ingredients',
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Speak your ingredients',
                icon: Icons.mic,
                variant: AppButtonVariant.onHero,
                onPressed: onSpeak,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeScoreAndStreakSection extends StatelessWidget {
  const _HomeScoreAndStreakSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InsightsCubit, InsightsState>(
      builder: (context, state) {
        int score = 0;
        int streak = 0;
        if (state.status == InsightsStatus.loaded && state.summary != null) {
          score = state.summary!.rescueScore;
          streak = state.summary!.currentStreak;
        }

        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    context.read<NavigationCubit>().select(NavTab.insights);
                  },
                  child: StatTile(
                    value: '$score',
                    label: 'Rescue Score',
                    caption: 'Illustrative game score',
                    icon: Icons.star_outline_rounded,
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(AppRadius.md),
                  onTap: () {
                    context.read<NavigationCubit>().select(NavTab.insights);
                  },
                  child: StatTile(
                    value: '$streak ${streak == 1 ? "day" : "days"}',
                    label: 'Rescue Streak',
                    caption: 'Illustrative streak',
                    icon: Icons.local_fire_department_outlined,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _RescueRadarBarSection extends StatelessWidget {
  const _RescueRadarBarSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is! InventoryLoaded || state.items.isEmpty) {
          return const SizedBox.shrink();
        }

        final today = DateTime.now();
        int critical = 0;
        int high = 0;
        int medium = 0;
        int low = 0;
        int expired = 0;

        for (final item in state.items) {
          final p = item.priority(today: today);
          switch (p) {
            case ExpiryPriority.critical:
              critical++;
              break;
            case ExpiryPriority.high:
              high++;
              break;
            case ExpiryPriority.medium:
              medium++;
              break;
            case ExpiryPriority.low:
              low++;
              break;
            case ExpiryPriority.expired:
              expired++;
              break;
            default:
              break;
          }
        }

        final total = state.items.length;
        final theme = Theme.of(context);

        return AppCard(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Rescue Radar',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '$total active items',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              // Multi-segment progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(AppRadius.pill),
                child: SizedBox(
                  height: 10,
                  child: Row(
                    children: [
                      if (expired > 0)
                        Expanded(flex: expired, child: Container(color: AppColors.expired)),
                      if (critical > 0)
                        Expanded(flex: critical, child: Container(color: AppColors.critical)),
                      if (high > 0)
                        Expanded(flex: high, child: Container(color: AppColors.orange)),
                      if (medium > 0)
                        Expanded(flex: medium, child: Container(color: AppColors.medium)),
                      if (low > 0)
                        Expanded(flex: low, child: Container(color: AppColors.low)),
                      if (total - (expired + critical + high + medium + low) > 0)
                        Expanded(
                          flex: total - (expired + critical + high + medium + low),
                          child: Container(color: AppColors.unknown),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.md,
                runSpacing: 4,
                children: [
                  if (critical > 0) _legendItem(context, AppColors.critical, '$critical Critical'),
                  if (high > 0) _legendItem(context, AppColors.orange, '$high High'),
                  if (medium > 0) _legendItem(context, AppColors.medium, '$medium Medium'),
                  if (low > 0) _legendItem(context, AppColors.low, '$low Fresh'),
                  if (expired > 0) _legendItem(context, AppColors.expired, '$expired Expired'),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _legendItem(BuildContext context, Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          text,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      ],
    );
  }
}

class _FoodWasteTipCard extends StatelessWidget {
  const _FoodWasteTipCard({
    required this.tip,
    required this.onNext,
  });

  final String tip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      color: theme.colorScheme.primaryContainer.withValues(alpha: 0.25),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.lightbulb_rounded,
                    color: AppColors.orange,
                    size: AppSizes.iconSm,
                  ),
                  const SizedBox(width: AppSpacing.xs),
                  Text(
                    'Food Rescue Tip',
                    style: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.orange,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.refresh_rounded, size: AppSizes.iconSm),
                tooltip: 'Next tip',
                onPressed: onNext,
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            tip,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeExpiryAlertsSection extends StatelessWidget {
  const _HomeExpiryAlertsSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoaded) {
          final today = DateTime.now();
          final urgentOrExpired = state.items.where((i) {
            final p = i.priority(today: today);
            return p == ExpiryPriority.expired || p == ExpiryPriority.critical;
          }).toList();

          if (urgentOrExpired.isEmpty) {
            return const SizedBox.shrink();
          }

          final text = context.text;
          final scheme = context.colors;

          return AppCard(
            color: AppColors.critical.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.warning_amber_rounded,
                      color: AppColors.critical,
                      size: AppSizes.icon,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Expiry Alerts',
                        style: text.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.critical,
                        ),
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        context.read<NavigationCubit>().select(NavTab.kitchen);
                      },
                      child: const Text('Manage'),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Expired: check before use or discard. Look, smell, and taste to decide if edible.',
                  style: text.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final item in urgentOrExpired.take(3)) ...[
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                    child: Row(
                      children: [
                        PriorityChip(priority: item.priority(today: today)),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            item.displayName,
                            style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          item.priority(today: today) == ExpiryPriority.expired
                              ? 'Expired'
                              : 'Expires today',
                          style: text.labelSmall?.copyWith(
                            color: AppColors.critical,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}

class _CookThisNowSection extends StatelessWidget {
  const _CookThisNowSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RecipesBloc, RecipesState>(
      builder: (context, state) {
        if (state is RecipesLoading) {
          return const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Cook this now',
                subtitle: 'Finding rescue recipes for what is expiring...',
              ),
              SizedBox(height: AppSpacing.md),
              LoadingSkeletonList(count: 2),
            ],
          );
        }

        if (state is RecipesLoaded && state.recipes.isNotEmpty) {
          final topRecipes = state.recipes.take(3).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Cook this now',
                subtitle: 'Highest rescue-impact recipes using your current food.',
                actionLabel: 'See all (${state.recipes.length})',
                onAction: () {
                  context.read<NavigationCubit>().select(NavTab.recipes);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              for (int i = 0; i < topRecipes.length; i++) ...[
                RecipeCard(
                  featured: i == 0,
                  title: topRecipes[i].recipe.title,
                  reason: topRecipes[i].reason,
                  minutes: topRecipes[i].recipe.minutes,
                  badges: topRecipes[i].badges.map((b) => b.label).toList(),
                  substitution: topRecipes[i].recipe.substitutions.isNotEmpty
                      ? '${topRecipes[i].recipe.substitutions.first.missingIngredient} → ${topRecipes[i].recipe.substitutions.first.substitute}'
                      : null,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => RecipeDetailPage(rankedRecipe: topRecipes[i]),
                      ),
                    );
                  },
                ),
                if (i < topRecipes.length - 1) const SizedBox(height: AppSpacing.md),
              ],
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}

class _UseTheseFirstSection extends StatelessWidget {
  const _UseTheseFirstSection();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<InventoryCubit, InventoryState>(
      builder: (context, state) {
        if (state is InventoryLoading) {
          return const LoadingSkeletonList(count: 3);
        }

        if (state is InventoryLoaded) {
          final today = DateTime.now();
          final urgent = state.items.where((i) {
            final p = i.priority(today: today);
            return p == ExpiryPriority.critical || p == ExpiryPriority.high;
          }).toList();

          if (urgent.isEmpty) {
            return const SizedBox.shrink();
          }

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'Use these first',
                subtitle: 'Items at critical or high risk of expiring.',
                actionLabel: 'See all',
                onAction: () {
                  context.read<NavigationCubit>().select(NavTab.kitchen);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              for (final Ingredient item in urgent.take(3)) ...[
                IngredientTile(
                  name: item.displayName,
                  quantityLabel: item.quantityLabel,
                  daysLeft: item.daysLeft(today: today),
                  priority: item.priority(today: today),
                  onTap: () {
                    context.read<NavigationCubit>().select(NavTab.kitchen);
                  },
                ),
                const SizedBox(height: AppSpacing.sm),
              ],
            ],
          );
        }

        return const SizedBox.shrink();
      },
    );
  }
}
