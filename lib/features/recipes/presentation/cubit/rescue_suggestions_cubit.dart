import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/domain/expiry_priority.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../ingredients/domain/usecases/watch_active_ingredients.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../data/datasources/offline_recipe_source.dart';
import '../../data/datasources/saved_recipe_repository.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/ranked_recipe.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/usecases/generate_recipes.dart';
import '../../domain/usecases/update_diet_preference.dart';
import '../../domain/utils/rescue_bucket_analyzer.dart';
import '../../domain/utils/rescue_first_ranker.dart';
import 'rescue_suggestions_state.dart';

class RescueSuggestionsCubit extends Cubit<RescueSuggestionsState>
    with WidgetsBindingObserver {
  RescueSuggestionsCubit({
    required WatchActiveIngredients watchActiveIngredients,
    required GenerateRecipes generateRecipes,
    required UpdateDietPreference updateDietPreference,
    SavedRecipeRepository? savedRecipeRepository,
    bool enableTimers = true,
  })  : _watchActiveIngredients = watchActiveIngredients,
        _generateRecipes = generateRecipes,
        _updateDietPreference = updateDietPreference,
        _savedRecipeRepository = savedRecipeRepository,
        _enableTimers = enableTimers,
        super(RescueSuggestionsState(lastUpdated: DateTime.now())) {
    WidgetsBinding.instance.addObserver(this);
    _init();
  }

  final WatchActiveIngredients _watchActiveIngredients;
  final GenerateRecipes _generateRecipes;
  final UpdateDietPreference _updateDietPreference;
  final SavedRecipeRepository? _savedRecipeRepository;
  final bool _enableTimers;

  StreamSubscription<List<Ingredient>>? _inventorySubscription;
  Timer? _debounceTimer;
  Timer? _midnightTimer;
  Timer? _highlightTimer;

  int _generationToken = 0;
  bool _isRequestInFlight = false;
  DateTime _lastNetworkCall = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime? _rateLimitedUntil;

  String _previousNamesSignature = '';
  String _previousFullSignature = '';
  DateTime _currentDay = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);

  List<Recipe> _recipePool = [];
  static const int _maxPoolSize = 20;
  static const Duration _debounceDuration = Duration(milliseconds: 1500);
  static const Duration _minNetworkInterval = Duration(seconds: 10);

  Future<void> _init() async {
    if (_enableTimers) _scheduleMidnightRollover();
    _recipePool = List<Recipe>.from(OfflineRecipeSource.recipes);
    _reRankCurrentPool();

    _inventorySubscription = _watchActiveIngredients().listen(
      (items) => _onInventoryChanged(items),
      onError: (err) {
        DebugLogger.recipes('Inventory watch stream error: $err');
      },
    );
  }

  void _scheduleMidnightRollover() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight = tomorrow.difference(now) + const Duration(seconds: 2);

    _midnightTimer = Timer(durationUntilMidnight, () {
      _onDateRollover();
      _scheduleMidnightRollover();
    });
  }

  void _onDateRollover() {
    final now = DateTime.now();
    _currentDay = DateTime(now.year, now.month, now.day);
    DebugLogger.recipes('Midnight rollover triggered for date: $_currentDay');
    _previousFullSignature = '';
    _reRankCurrentPool();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      if (today.isAfter(_currentDay)) {
        DebugLogger.recipes('App resumed with new calendar day: $today');
        _onDateRollover();
      }
    }
  }

  void _onInventoryChanged(List<Ingredient> items) {
    final validItems = items.where((i) {
      if (!i.status.isActive) return false;
      final p = i.priority(today: _currentDay);
      return p != ExpiryPriority.expired;
    }).toList();

    final namesSig = _computeNamesSignature(validItems);
    final fullSig = _computeFullSignature(validItems, _currentDay);

    if (fullSig == _previousFullSignature && namesSig == _previousNamesSignature) {
      return;
    }

    final bool namesChanged = namesSig != _previousNamesSignature;
    _previousNamesSignature = namesSig;
    _previousFullSignature = fullSig;

    emit(state.copyWith(activeIngredients: validItems));

    if (!namesChanged) {
      DebugLogger.recipes('Ingredient priorities/quantities changed. 0ms pure Dart re-rank.');
      _reRankCurrentPool(items: validItems);
      return;
    }

    DebugLogger.recipes('Ingredient names changed. Re-ranking pool immediately.');
    _reRankCurrentPool(items: validItems);

    _debounceTimer?.cancel();
    if (validItems.isEmpty) return;

    if (_enableTimers) {
      _debounceTimer = Timer(_debounceDuration, () {
        _performGeminiTopUp(validItems);
      });
    }
  }

  String _computeNamesSignature(List<Ingredient> items) {
    final names = items.map((i) => i.name.toLowerCase().trim()).toSet().toList()..sort();
    return names.join(',');
  }

  String _computeFullSignature(List<Ingredient> items, DateTime today) {
    final sorted = List<Ingredient>.from(items)
      ..sort((a, b) => a.id.compareTo(b.id));
    return sorted
        .map((i) => '${i.id}:${i.name}:${i.quantity}:${i.unit}:${i.priority(today: today).name}')
        .join(';');
  }

  void _reRankCurrentPool({List<Ingredient>? items}) {
    final inventory = items ?? state.activeIngredients;
    final ranked = RescueFirstRanker.rank(
      recipes: _recipePool,
      inventory: inventory,
      dietPreference: state.dietPreference,
      cuisinePreference: state.cuisinePreference,
      today: _currentDay,
    );

    final buckets = RescueBucketAnalyzer.analyze(
      inventory: inventory,
      rankedRecipes: ranked,
      today: _currentDay,
    );

    final hero = ranked.isNotEmpty ? ranked.first : null;
    final display = _filterRecipes(ranked);

    emit(state.copyWith(
      allRankedPool: ranked,
      displayRecipes: display,
      buckets: buckets,
      heroRecipe: () => hero,
      lastUpdated: DateTime.now(),
    ));
  }

  Future<void> _performGeminiTopUp(List<Ingredient> items, {bool force = false}) async {
    if (_isRequestInFlight) {
      DebugLogger.recipes('Gemini top-up skipped: request already in flight.');
      return;
    }

    final now = DateTime.now();
    if (_rateLimitedUntil != null && now.isBefore(_rateLimitedUntil!)) {
      DebugLogger.recipes('Gemini top-up paused due to rate-limit holdoff.');
      return;
    }

    if (!force && now.difference(_lastNetworkCall) < _minNetworkInterval) {
      DebugLogger.recipes('Gemini top-up throttled by 10s cooldown.');
      return;
    }

    _isRequestInFlight = true;
    _lastNetworkCall = now;
    final currentGen = ++_generationToken;

    emit(state.copyWith(isUpdatingSuggestions: true));

    try {
      final result = await _generateRecipes(
        GenerateRecipesParams(
          dietPreference: state.dietPreference,
          cuisinePreference: state.cuisinePreference,
          forceRefresh: force,
          today: _currentDay,
        ),
      );

      if (currentGen != _generationToken) {
        DebugLogger.recipes('Stale generation $currentGen ignored (current is $_generationToken).');
        return;
      }

      result.fold(
        (failure) {
          DebugLogger.recipes('Gemini top-up failed: ${failure.message}');
          if (failure.message.contains('429') || failure.message.toLowerCase().contains('quota')) {
            _rateLimitedUntil = DateTime.now().add(const Duration(seconds: 45));
          }
          emit(state.copyWith(isUpdatingSuggestions: false, source: RecipeSource.offline));
        },
        (res) {
          final newRecipes = res.rankedRecipes.map((r) => r.recipe).toList();
          _integrateNewRecipes(newRecipes, res.source);
        },
      );
    } catch (e) {
      DebugLogger.recipes('Gemini top-up uncaught exception: $e');
      emit(state.copyWith(isUpdatingSuggestions: false));
    } finally {
      _isRequestInFlight = false;
    }
  }

  void _integrateNewRecipes(List<Recipe> newRecipes, RecipeSource source) {
    if (newRecipes.isEmpty) {
      emit(state.copyWith(isUpdatingSuggestions: false, source: source));
      return;
    }

    final existingTitles = _recipePool.map((r) => _normalizeTitle(r.title)).toSet();
    final addedList = <Recipe>[];

    for (final r in newRecipes) {
      final norm = _normalizeTitle(r.title);
      if (!existingTitles.contains(norm)) {
        addedList.add(r);
        existingTitles.add(norm);
      }
    }

    if (addedList.isNotEmpty) {
      _recipePool.insertAll(0, addedList);
      if (_recipePool.length > _maxPoolSize) {
        _recipePool = _recipePool.sublist(0, _maxPoolSize);
      }

      final ranked = RescueFirstRanker.rank(
        recipes: _recipePool,
        inventory: state.activeIngredients,
        dietPreference: state.dietPreference,
        cuisinePreference: state.cuisinePreference,
        today: _currentDay,
      );

      final buckets = RescueBucketAnalyzer.analyze(
        inventory: state.activeIngredients,
        rankedRecipes: ranked,
        today: _currentDay,
      );

      final hero = ranked.isNotEmpty ? ranked.first : null;
      final display = _filterRecipes(ranked);

      final newlyAddedId = addedList.first.id;
      _highlightTimer?.cancel();
      _highlightTimer = Timer(const Duration(milliseconds: 1400), () {
        if (!isClosed) emit(state.copyWith(highlightedRecipeId: () => null));
      });

      emit(state.copyWith(
        allRankedPool: ranked,
        displayRecipes: display,
        buckets: buckets,
        heroRecipe: () => hero,
        isUpdatingSuggestions: false,
        source: source,
        highlightedRecipeId: () => newlyAddedId,
        lastUpdated: DateTime.now(),
      ));
    } else {
      emit(state.copyWith(isUpdatingSuggestions: false, source: source));
    }
  }

  String _normalizeTitle(String s) =>
      s.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  List<RankedRecipe> _filterRecipes(List<RankedRecipe> list) {
    var filtered = List<RankedRecipe>.from(list);

    if (state.activeTimeFilter != null) {
      filtered = filtered.where((r) => r.recipe.minutes <= state.activeTimeFilter!).toList();
    }

    if (state.activeExcludeFilter != null && state.activeExcludeFilter!.isNotEmpty) {
      final excl = state.activeExcludeFilter!.toLowerCase();
      filtered = filtered.where((r) {
        return !r.recipe.ingredients.any((i) => i.name.toLowerCase().contains(excl));
      }).toList();
    }

    if (state.activeFocusFilter != null && state.activeFocusFilter!.isNotEmpty) {
      final focus = state.activeFocusFilter!.toLowerCase();
      filtered.sort((a, b) {
        final aHas = a.recipe.ingredients.any((i) => i.name.toLowerCase().contains(focus));
        final bHas = b.recipe.ingredients.any((i) => i.name.toLowerCase().contains(focus));
        if (aHas && !bHas) return -1;
        if (!aHas && bHas) return 1;
        return b.totalScore.compareTo(a.totalScore);
      });
    }

    return filtered;
  }

  void applyFilter({
    int? maxMinutes,
    String? focusIngredient,
    String? excludeIngredient,
    DietTag? diet,
    CuisineTag? cuisine,
    bool reset = false,
  }) {
    if (reset) {
      emit(state.copyWith(
        activeTimeFilter: () => null,
        activeFocusFilter: () => null,
        activeExcludeFilter: () => null,
      ));
      _reRankCurrentPool();
      return;
    }

    final newDiet = diet ?? state.dietPreference;
    final newCuisine = cuisine ?? state.cuisinePreference;
    final newTime = maxMinutes != null ? () => maxMinutes : state.activeTimeFilter != null ? () => state.activeTimeFilter : null;
    final newFocus = focusIngredient != null
        ? () => focusIngredient.isEmpty ? null : focusIngredient
        : state.activeFocusFilter != null ? () => state.activeFocusFilter : null;
    final newExclude = excludeIngredient != null
        ? () => excludeIngredient.isEmpty ? null : excludeIngredient
        : state.activeExcludeFilter != null ? () => state.activeExcludeFilter : null;

    emit(state.copyWith(
      dietPreference: newDiet,
      cuisinePreference: newCuisine,
      activeTimeFilter: newTime,
      activeFocusFilter: newFocus,
      activeExcludeFilter: newExclude,
    ));

    _reRankCurrentPool();
  }

  void resetFilters() {
    applyFilter(reset: true);
  }

  void applyFilters({
    int? maxMinutes,
    String? focusIngredient,
    String? excludeIngredient,
    DietTag? diet,
    CuisineTag? cuisine,
  }) {
    applyFilter(
      maxMinutes: maxMinutes,
      focusIngredient: focusIngredient,
      excludeIngredient: excludeIngredient,
      diet: diet,
      cuisine: cuisine,
    );
  }

  void toggleFocusIngredient(String ingredientName) {
    if (state.activeFocusFilter?.toLowerCase() == ingredientName.toLowerCase()) {
      applyFilter(focusIngredient: '');
    } else {
      applyFilter(focusIngredient: ingredientName);
    }
  }

  Future<void> forceRegenerate() async {
    _lastNetworkCall = DateTime.fromMillisecondsSinceEpoch(0);
    _rateLimitedUntil = null;
    await _performGeminiTopUp(state.activeIngredients, force: true);
  }

  Future<void> forceRefresh() => forceRegenerate();

  void setSegment(RescueSuggestionsSegment segment) {
    final segIdx = segment == RescueSuggestionsSegment.saved ? 1 : 0;
    switchSegment(segIdx);
  }

  void switchSegment(int segment) {
    if (segment == 1 && _savedRecipeRepository != null) {
      _loadSavedRecipes();
      return;
    }
    emit(state.copyWith(selectedSegment: 0));
    _reRankCurrentPool();
  }

  Future<void> _loadSavedRecipes() async {
    if (_savedRecipeRepository == null) return;
    try {
      final saved = _savedRecipeRepository.getSavedRecipes();
      final ranked = RescueFirstRanker.rank(
        recipes: saved,
        inventory: state.activeIngredients,
        dietPreference: state.dietPreference,
        cuisinePreference: state.cuisinePreference,
        today: _currentDay,
      );
      emit(state.copyWith(
        selectedSegment: 1,
        displayRecipes: _filterRecipes(ranked),
      ));
    } catch (e) {
      DebugLogger.recipes('Failed to load saved recipes: $e');
    }
  }

  Future<void> toggleSaveRecipe(Recipe recipe) async {
    if (_savedRecipeRepository == null) return;
    if (_savedRecipeRepository.isSaved(recipe.id)) {
      await _savedRecipeRepository.removeRecipe(recipe.id);
    } else {
      await _savedRecipeRepository.saveRecipe(recipe);
    }
    if (state.selectedSegment == 1) {
      await _loadSavedRecipes();
    } else {
      emit(state.copyWith(lastUpdated: DateTime.now()));
    }
  }

  Future<void> updateDiet(DietTag tag) async {
    emit(state.copyWith(dietPreference: tag));
    await _updateDietPreference(UpdateDietPreferenceParams(tag));
    _reRankCurrentPool();
  }

  @override
  Future<void> close() {
    WidgetsBinding.instance.removeObserver(this);
    _inventorySubscription?.cancel();
    _debounceTimer?.cancel();
    _midnightTimer?.cancel();
    _highlightTimer?.cancel();
    return super.close();
  }
}
