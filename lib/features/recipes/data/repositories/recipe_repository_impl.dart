import 'package:fpdart/fpdart.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../voice/data/datasources/connectivity_service.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/repositories/recipe_repository.dart';
import '../datasources/gemini_recipe_datasource.dart';
import '../datasources/offline_recipe_source.dart';
import '../datasources/preferences_local_datasource.dart';

class RecipeRepositoryImpl implements RecipeRepository {
  RecipeRepositoryImpl({
    required GeminiRecipeDataSource remoteDataSource,
    required PreferencesLocalDataSource preferencesLocalDataSource,
    required ConnectivityService connectivityService,
    required AppConfig config,
  })  : _remoteDataSource = remoteDataSource,
        _preferencesLocalDataSource = preferencesLocalDataSource,
        _connectivityService = connectivityService,
        _config = config;

  final GeminiRecipeDataSource _remoteDataSource;
  final PreferencesLocalDataSource _preferencesLocalDataSource;
  final ConnectivityService _connectivityService;
  final AppConfig _config;

  // In-memory cache keyed by inventory signature
  String? _cachedSignature;
  List<Recipe>? _cachedRecipes;
  RecipeSource? _cachedSource;

  String _buildSignature(
    List<IngredientCandidateParam> ingredients,
    DietTag diet,
  ) {
    final sorted = List<IngredientCandidateParam>.from(ingredients)
      ..sort((a, b) => a.name.compareTo(b.name));
    final itemsStr = sorted
        .map((i) => '${i.name}_${i.quantity}_${i.unit}_${i.useSoon}')
        .join(';');
    return '${diet.name}|$itemsStr';
  }

  @override
  FutureEither<RecipeCandidateResult> getRecipeCandidates({
    required List<IngredientCandidateParam> ingredients,
    required DietTag dietPreference,
    bool forceRefresh = false,
  }) async {
    final signature = _buildSignature(ingredients, dietPreference);

    // Return cached result if valid and not forcing refresh
    if (!forceRefresh &&
        _cachedSignature == signature &&
        _cachedRecipes != null &&
        _cachedSource != null) {
      return Right(RecipeCandidateResult(
        recipes: _cachedRecipes!,
        source: _cachedSource!,
      ));
    }

    // Check connectivity & Gemini key
    final isConnected = await _connectivityService.isConnected;
    final hasKey = _config.hasGeminiKey;

    if (isConnected && hasKey) {
      try {
        final geminiRecipes = await _remoteDataSource.generateRecipes(
          ingredients: ingredients,
          dietPreference: dietPreference,
        );

        _cachedSignature = signature;
        _cachedRecipes = geminiRecipes;
        _cachedSource = RecipeSource.gemini;

        return Right(RecipeCandidateResult(
          recipes: geminiRecipes,
          source: RecipeSource.gemini,
        ));
      } catch (_) {
        // Fall back gracefully to offline recipes on any failure
      }
    }

    // Offline fallback
    const offlineRecipes = OfflineRecipeSource.recipes;
    _cachedSignature = signature;
    _cachedRecipes = offlineRecipes;
    _cachedSource = RecipeSource.offline;

    return const Right(RecipeCandidateResult(
      recipes: offlineRecipes,
      source: RecipeSource.offline,
    ));
  }

  @override
  FutureEither<DietTag> getDietPreference() async {
    try {
      final diet = await _preferencesLocalDataSource.getDietPreference();
      return Right(diet);
    } catch (e) {
      return Left(StorageFailure('Failed to load diet preference: $e'));
    }
  }

  @override
  FutureEither<void> updateDietPreference(DietTag diet) async {
    try {
      await _preferencesLocalDataSource.saveDietPreference(diet);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to save diet preference: $e'));
    }
  }
}
