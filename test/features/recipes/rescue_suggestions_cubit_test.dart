import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/watch_active_ingredients.dart';
import 'package:rescue_recipe/features/recipes/data/datasources/saved_recipe_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/ranked_recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/generate_recipes.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/update_diet_preference.dart';
import 'package:rescue_recipe/features/recipes/presentation/cubit/rescue_suggestions_cubit.dart';

class FakeWatchActiveIngredients implements WatchActiveIngredients {
  FakeWatchActiveIngredients(this.controller);
  final StreamController<List<Ingredient>> controller;

  @override
  Stream<List<Ingredient>> call() => controller.stream;
}

class FakeGenerateRecipes implements GenerateRecipes {
  int callCount = 0;
  List<RankedRecipe> returnedRecipes = [];

  @override
  FutureEither<GenerateRecipesResult> call(GenerateRecipesParams params) async {
    callCount++;
    return Right(GenerateRecipesResult(
      rankedRecipes: returnedRecipes,
      source: RecipeSource.gemini,
      dietPreference: params.dietPreference ?? DietTag.none,
    ));
  }
}

class FakeUpdateDietPreference implements UpdateDietPreference {
  DietTag? updatedDiet;

  @override
  FutureEither<void> call(UpdateDietPreferenceParams params) async {
    updatedDiet = params.diet;
    return const Right(null);
  }
}

class FakeSavedRecipeRepository implements SavedRecipeRepository {
  final List<Recipe> saved = [];
  final List<Recipe> cachedAi = [];

  @override
  List<Recipe> getSavedRecipes() => List.unmodifiable(saved);

  @override
  bool isSaved(String id) => saved.any((r) => r.id == id);

  @override
  Future<void> saveRecipe(Recipe recipe) async {
    if (!isSaved(recipe.id)) saved.add(recipe);
  }

  @override
  Future<void> removeRecipe(String id) async {
    saved.removeWhere((r) => r.id == id);
  }

  @override
  Future<void> cacheLastAiRecipes(List<Recipe> recipes) async {
    cachedAi.clear();
    cachedAi.addAll(recipes);
  }

  @override
  List<Recipe> getLastAiRecipes() => List.unmodifiable(cachedAi);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late StreamController<List<Ingredient>> ingredientsController;
  late FakeWatchActiveIngredients fakeWatch;
  late FakeGenerateRecipes fakeGenerate;
  late FakeUpdateDietPreference fakeUpdateDiet;
  late FakeSavedRecipeRepository fakeSavedRepo;

  final testToday = DateTime(2026, 11, 28);

  final sampleIngredient = Ingredient(
    id: 'ing_1',
    name: 'tomato',
    expiryDate: DateTime(2026, 11, 28),
    addedAt: DateTime(2026, 11, 26),
  );

  const sampleRecipe = Recipe(
    id: 'rec_1',
    title: 'Tomato Soup',
    minutes: 20,
    servings: 2,
    dietTags: {DietTag.none},
    ingredients: [RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pieces')],
    steps: [RecipeStep(text: 'Simmer tomatoes')],
  );

  const sampleRanked = RankedRecipe(
    recipe: sampleRecipe,
    totalScore: 0.90,
    coverageScore: 1.0,
    availabilityScore: 1.0,
    speedScore: 1.0,
    preferenceScore: 1.0,
    matchedExpiringIngredients: [],
    missingIngredients: [],
    coveredExpiringCount: 1,
    totalExpiringCount: 1,
    reason: 'Uses tomato',
    badges: [RankedBadge(badge: RecipeBadge.rescueFirst, label: 'Rescue-first')],
  );

  setUp(() {
    ingredientsController = StreamController<List<Ingredient>>.broadcast();
    fakeWatch = FakeWatchActiveIngredients(ingredientsController);
    fakeGenerate = FakeGenerateRecipes()..returnedRecipes = [sampleRanked];
    fakeUpdateDiet = FakeUpdateDietPreference();
    fakeSavedRepo = FakeSavedRecipeRepository();
  });

  tearDown(() {
    ingredientsController.close();
  });

  RescueSuggestionsCubit createCubit() {
    return RescueSuggestionsCubit(
      watchActiveIngredients: fakeWatch,
      generateRecipes: fakeGenerate,
      updateDietPreference: fakeUpdateDiet,
      savedRecipeRepository: fakeSavedRepo,
    );
  }

  group('RescueSuggestionsCubit', () {
    test('initializes and ranks cached pool on first inventory emission', () async {
      final cubit = createCubit();

      ingredientsController.add([sampleIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      expect(cubit.state.activeIngredients.length, 1);
      expect(cubit.state.atRiskIngredients.length, 1);
      expect(cubit.state.allRankedPool.isNotEmpty, isTrue);
      expect(cubit.state.displayRecipes.isNotEmpty, isTrue);

      await cubit.close();
    });

    test('re-ranks immediately without Gemini network call when only dates/quantities change', () async {
      final cubit = createCubit();
      ingredientsController.add([sampleIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      fakeGenerate.callCount = 0;

      // Mutate quantity/expiry only (name stays 'tomato')
      final updatedIngredient = Ingredient(
        id: 'ing_1',
        name: 'tomato',
        quantity: 5,
        expiryDate: testToday.add(const Duration(days: 2)),
        addedAt: testToday.subtract(const Duration(days: 2)),
      );
      ingredientsController.add([updatedIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      // Zero generate recipes calls made
      expect(fakeGenerate.callCount, 0);
      expect(cubit.state.activeIngredients.first.quantity, 5);

      await cubit.close();
    });

    test('debounces Gemini top-up call when ingredient names change', () async {
      final cubit = createCubit();
      ingredientsController.add([sampleIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      fakeGenerate.callCount = 0;

      // Add Spinach
      final spinach = Ingredient(
        id: 'ing_2',
        name: 'spinach',
        expiryDate: testToday.add(const Duration(days: 2)),
        addedAt: testToday,
      );

      ingredientsController.add([sampleIngredient, spinach]);
      // Immediately after: debounce has not fired
      await Future<void>.delayed(const Duration(milliseconds: 300));
      expect(fakeGenerate.callCount, 0);

      // After 1.6s debounce: exactly one Gemini call fired
      await Future<void>.delayed(const Duration(milliseconds: 1400));
      expect(fakeGenerate.callCount, 1);

      await cubit.close();
    });

    test('filters recipes by max minutes and resets correctly', () async {
      final cubit = createCubit();
      ingredientsController.add([sampleIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      cubit.applyFilter(maxMinutes: 10);
      expect(cubit.state.activeTimeFilter, 10);

      cubit.resetFilters();
      expect(cubit.state.activeTimeFilter, isNull);
      expect(cubit.state.displayRecipes.isNotEmpty, isTrue);

      await cubit.close();
    });

    test('switching to saved segment displays saved recipes', () async {
      fakeSavedRepo.saved.add(sampleRecipe);

      final cubit = createCubit();
      ingredientsController.add([sampleIngredient]);
      await Future<void>.delayed(const Duration(milliseconds: 100));

      cubit.switchSegment(1);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(cubit.state.selectedSegment, 1);
      expect(cubit.state.displayRecipes.length, 1);
      expect(cubit.state.displayRecipes.first.recipe.id, 'rec_1');

      await cubit.close();
    });
  });
}

