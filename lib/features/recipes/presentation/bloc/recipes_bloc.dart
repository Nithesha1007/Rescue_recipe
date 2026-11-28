import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../data/datasources/saved_recipe_repository.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/generate_recipes.dart';
import '../../domain/usecases/update_diet_preference.dart';
import 'recipes_event.dart';
import 'recipes_state.dart';

class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  RecipesBloc({
    required GenerateRecipes generateRecipes,
    required UpdateDietPreference updateDietPreference,
    SavedRecipeRepository? savedRecipeRepository,
  })  : _generateRecipes = generateRecipes,
        _updateDietPreference = updateDietPreference,
        _savedRecipeRepository = savedRecipeRepository,
        super(const RecipesInitial()) {
    on<LoadRecipes>(_onLoadRecipes);
    on<RefreshRecipes>(_onRefreshRecipes);
    on<ChangeDiet>(_onChangeDiet);
    on<ChangeCuisine>(_onChangeCuisine);
    on<ApplyRecipeFilter>(_onApplyRecipeFilter);
    on<ToggleSaveRecipe>(_onToggleSaveRecipe);
    on<SwitchRecipeSegment>(_onSwitchRecipeSegment);
  }

  final GenerateRecipes _generateRecipes;
  final UpdateDietPreference _updateDietPreference;
  final SavedRecipeRepository? _savedRecipeRepository;

  DietTag _currentDiet = DietTag.none;
  CuisineTag _currentCuisine = CuisineTag.any;
  int? _maxMinutesFilter;
  String? _focusIngredientFilter;
  String? _excludeIngredientFilter;
  int _currentSegment = 0; // 0 = suggestions, 1 = saved

  List<RankedRecipe> _allGenerated = [];
  RecipeSource _currentSource = RecipeSource.gemini;

  Future<void> _onLoadRecipes(
    LoadRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    if (_currentSegment == 1) {
      _emitSavedRecipes(emit);
      return;
    }

    emit(const RecipesLoading());

    final result = await _generateRecipes(GenerateRecipesParams(
      dietPreference: _currentDiet,
      cuisinePreference: _currentCuisine,
      forceRefresh: event.forceRefresh,
    ));

    result.fold(
      (failure) {
        // Fallback to last successful AI or saved recipes if available
        final cached = _savedRecipeRepository?.getLastAiRecipes() ?? [];
        if (cached.isNotEmpty) {
          _allGenerated = cached.map((r) => RankedRecipe(
            recipe: r,
            totalScore: 0.8,
            coverageScore: 0.8,
            availabilityScore: 0.8,
            speedScore: 0.8,
            preferenceScore: 0.8,
            matchedExpiringIngredients: const [],
            missingIngredients: const [],
            coveredExpiringCount: 0,
            totalExpiringCount: 0,
            reason: 'From previous session (Offline)',
            badges: const [],
          )).toList();
          _currentSource = RecipeSource.cachedAi;
          _applyCurrentFilters(emit);
        } else {
          emit(RecipesError(message: failure.message));
        }
      },
      (data) {
        _currentDiet = data.dietPreference;
        _allGenerated = data.rankedRecipes;
        _currentSource = data.source;

        // Cache last successful AI list
        if (data.source == RecipeSource.gemini && _savedRecipeRepository != null) {
          _savedRecipeRepository.cacheLastAiRecipes(
            data.rankedRecipes.map((r) => r.recipe).toList(),
          );
        }

        _applyCurrentFilters(emit);
      },
    );
  }

  void _applyCurrentFilters(Emitter<RecipesState> emit) {
    var filtered = List<RankedRecipe>.from(_allGenerated);

    // Apply time filter
    if (_maxMinutesFilter != null) {
      filtered = filtered.where((r) => r.recipe.minutes <= _maxMinutesFilter!).toList();
    }

    // Apply exclude ingredient
    if (_excludeIngredientFilter != null && _excludeIngredientFilter!.isNotEmpty) {
      final excl = _excludeIngredientFilter!.toLowerCase();
      filtered = filtered.where((r) {
        return !r.recipe.ingredients.any((i) => i.name.toLowerCase().contains(excl));
      }).toList();
    }

    // Apply focus ingredient boost
    if (_focusIngredientFilter != null && _focusIngredientFilter!.isNotEmpty) {
      final focus = _focusIngredientFilter!.toLowerCase();
      filtered.sort((a, b) {
        final aHas = a.recipe.ingredients.any((i) => i.name.toLowerCase().contains(focus));
        final bHas = b.recipe.ingredients.any((i) => i.name.toLowerCase().contains(focus));
        if (aHas && !bHas) return -1;
        if (!aHas && bHas) return 1;
        return b.totalScore.compareTo(a.totalScore);
      });
    }

    if (filtered.isEmpty) {
      emit(RecipesNoMatches(
        dietPreference: _currentDiet,
        reason: 'No recipes match your current filters. Try resetting time or ingredient restrictions.',
      ));
    } else {
      emit(RecipesLoaded(
        recipes: filtered,
        source: _currentSource,
        dietPreference: _currentDiet,
      ));
    }
  }

  void _emitSavedRecipes(Emitter<RecipesState> emit) {
    final saved = _savedRecipeRepository?.getSavedRecipes() ?? [];
    if (saved.isEmpty) {
      emit(const RecipesEmpty());
      return;
    }

    final rankedSaved = saved.map((r) => RankedRecipe(
      recipe: r,
      totalScore: 1.0,
      coverageScore: 1.0,
      availabilityScore: 1.0,
      speedScore: 1.0,
      preferenceScore: 1.0,
      matchedExpiringIngredients: const [],
      missingIngredients: const [],
      coveredExpiringCount: 0,
      totalExpiringCount: 0,
      reason: 'Bookmarked by you',
      badges: const [],
    )).toList();

    emit(RecipesLoaded(
      recipes: rankedSaved,
      source: RecipeSource.saved,
      dietPreference: _currentDiet,
    ));
  }

  Future<void> _onRefreshRecipes(
    RefreshRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    add(const LoadRecipes(forceRefresh: true));
  }

  Future<void> _onChangeDiet(
    ChangeDiet event,
    Emitter<RecipesState> emit,
  ) async {
    _currentDiet = event.diet;
    await _updateDietPreference(UpdateDietPreferenceParams(event.diet));
    add(const LoadRecipes(forceRefresh: false));
  }

  void _onChangeCuisine(
    ChangeCuisine event,
    Emitter<RecipesState> emit,
  ) {
    _currentCuisine = event.cuisine;
    add(const LoadRecipes(forceRefresh: false));
  }

  void _onApplyRecipeFilter(
    ApplyRecipeFilter event,
    Emitter<RecipesState> emit,
  ) {
    if (event.reset) {
      _maxMinutesFilter = null;
      _focusIngredientFilter = null;
      _excludeIngredientFilter = null;
    } else {
      if (event.maxMinutes != null) _maxMinutesFilter = event.maxMinutes;
      if (event.focusIngredient != null) _focusIngredientFilter = event.focusIngredient;
      if (event.excludeIngredient != null) _excludeIngredientFilter = event.excludeIngredient;
      if (event.diet != null) _currentDiet = event.diet!;
      if (event.cuisine != null) _currentCuisine = event.cuisine!;
    }
    _applyCurrentFilters(emit);
  }

  Future<void> _onToggleSaveRecipe(
    ToggleSaveRecipe event,
    Emitter<RecipesState> emit,
  ) async {
    final repo = _savedRecipeRepository;
    if (repo == null) return;
    if (repo.isSaved(event.recipe.id)) {
      await repo.removeRecipe(event.recipe.id);
    } else {
      await repo.saveRecipe(event.recipe);
    }

    if (_currentSegment == 1) {
      _emitSavedRecipes(emit);
    }
  }

  void _onSwitchRecipeSegment(
    SwitchRecipeSegment event,
    Emitter<RecipesState> emit,
  ) {
    _currentSegment = event.segmentIndex;
    if (_currentSegment == 1) {
      _emitSavedRecipes(emit);
    } else {
      _applyCurrentFilters(emit);
    }
  }
}
