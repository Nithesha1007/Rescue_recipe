import 'package:equatable/equatable.dart';

import '../../../../core/domain/expiry_priority.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/rescue_plan_bucket.dart';

enum RescueSuggestionsSegment {
  suggestions,
  saved;
}

class RescueSuggestionsState extends Equatable {
  const RescueSuggestionsState({
    this.allRankedPool = const [],
    this.displayRecipes = const [],
    this.activeIngredients = const [],
    this.buckets = const [],
    this.heroRecipe,
    this.isUpdatingSuggestions = false,
    this.isLoading = false,
    this.errorMessage,
    this.source = RecipeSource.offline,
    this.dietPreference = DietTag.none,
    this.cuisinePreference = CuisineTag.any,
    this.activeTimeFilter,
    this.activeFocusFilter,
    this.activeExcludeFilter,
    this.selectedSegment = 0,
    this.highlightedRecipeId,
    required this.lastUpdated,
  });

  final List<RankedRecipe> allRankedPool;
  final List<RankedRecipe> displayRecipes;
  final List<Ingredient> activeIngredients;
  final List<RescuePlanBucket> buckets;
  final RankedRecipe? heroRecipe;
  final bool isUpdatingSuggestions;
  final bool isLoading;
  final String? errorMessage;
  final RecipeSource source;
  final DietTag dietPreference;
  final CuisineTag cuisinePreference;
  final int? activeTimeFilter;
  final String? activeFocusFilter;
  final String? activeExcludeFilter;
  final int selectedSegment; // 0 = suggestions, 1 = saved
  final String? highlightedRecipeId;
  final DateTime lastUpdated;

  RescueSuggestionsSegment get currentSegment =>
      selectedSegment == 1 ? RescueSuggestionsSegment.saved : RescueSuggestionsSegment.suggestions;

  List<Ingredient> get atRiskIngredients {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return activeIngredients.where((i) {
      if (!i.status.isActive) return false;
      final p = i.priority(today: today);
      return p == ExpiryPriority.critical || p == ExpiryPriority.high || p == ExpiryPriority.medium;
    }).toList();
  }

  bool get isEmpty => activeIngredients.isEmpty && allRankedPool.isEmpty && !isLoading;
  bool get hasActiveFilters =>
      activeTimeFilter != null ||
      activeFocusFilter != null ||
      activeExcludeFilter != null ||
      dietPreference != DietTag.none ||
      cuisinePreference != CuisineTag.any;

  RescueSuggestionsState copyWith({
    List<RankedRecipe>? allRankedPool,
    List<RankedRecipe>? displayRecipes,
    List<Ingredient>? activeIngredients,
    List<RescuePlanBucket>? buckets,
    RankedRecipe? Function()? heroRecipe,
    bool? isUpdatingSuggestions,
    bool? isLoading,
    String? Function()? errorMessage,
    RecipeSource? source,
    DietTag? dietPreference,
    CuisineTag? cuisinePreference,
    int? Function()? activeTimeFilter,
    String? Function()? activeFocusFilter,
    String? Function()? activeExcludeFilter,
    int? selectedSegment,
    String? Function()? highlightedRecipeId,
    DateTime? lastUpdated,
  }) {
    return RescueSuggestionsState(
      allRankedPool: allRankedPool ?? this.allRankedPool,
      displayRecipes: displayRecipes ?? this.displayRecipes,
      activeIngredients: activeIngredients ?? this.activeIngredients,
      buckets: buckets ?? this.buckets,
      heroRecipe: heroRecipe != null ? heroRecipe() : this.heroRecipe,
      isUpdatingSuggestions: isUpdatingSuggestions ?? this.isUpdatingSuggestions,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage != null ? errorMessage() : this.errorMessage,
      source: source ?? this.source,
      dietPreference: dietPreference ?? this.dietPreference,
      cuisinePreference: cuisinePreference ?? this.cuisinePreference,
      activeTimeFilter: activeTimeFilter != null ? activeTimeFilter() : this.activeTimeFilter,
      activeFocusFilter: activeFocusFilter != null ? activeFocusFilter() : this.activeFocusFilter,
      activeExcludeFilter: activeExcludeFilter != null ? activeExcludeFilter() : this.activeExcludeFilter,
      selectedSegment: selectedSegment ?? this.selectedSegment,
      highlightedRecipeId: highlightedRecipeId != null ? highlightedRecipeId() : this.highlightedRecipeId,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  @override
  List<Object?> get props => [
        allRankedPool,
        displayRecipes,
        activeIngredients,
        buckets,
        heroRecipe,
        isUpdatingSuggestions,
        isLoading,
        errorMessage,
        source,
        dietPreference,
        cuisinePreference,
        activeTimeFilter,
        activeFocusFilter,
        activeExcludeFilter,
        selectedSegment,
        highlightedRecipeId,
        lastUpdated,
      ];
}
