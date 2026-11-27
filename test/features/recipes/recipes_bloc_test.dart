import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/data/datasources/offline_recipe_source.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/generate_recipes.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/update_diet_preference.dart';
import 'package:rescue_recipe/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:rescue_recipe/features/recipes/presentation/bloc/recipes_event.dart';
import 'package:rescue_recipe/features/recipes/presentation/bloc/recipes_state.dart';

import '../ingredients/inventory_cubit_test.dart';

class FakeRecipeRepository implements RecipeRepository {
  DietTag currentDiet = DietTag.none;
  bool returnFailure = false;
  int getCandidateCalls = 0;

  @override
  FutureEither<RecipeCandidateResult> getRecipeCandidates({
    required List<IngredientCandidateParam> ingredients,
    required DietTag dietPreference,
    bool forceRefresh = false,
  }) async {
    getCandidateCalls++;
    if (returnFailure) {
      return const Left(NetworkFailure('Failed to generate recipes.'));
    }

    return const Right(RecipeCandidateResult(
      recipes: OfflineRecipeSource.recipes,
      source: RecipeSource.offline,
    ));
  }

  @override
  FutureEither<DietTag> getDietPreference() async {
    return Right(currentDiet);
  }

  @override
  FutureEither<void> updateDietPreference(DietTag diet) async {
    currentDiet = diet;
    return const Right(null);
  }
}

void main() {
  group('RecipesBloc', () {
    late FakeIngredientRepository fakeIngredientRepo;
    late FakeRecipeRepository fakeRecipeRepo;
    late GenerateRecipes generateRecipes;
    late UpdateDietPreference updateDietPreference;

    final today = DateTime(2026, 11, 26);

    setUp(() {
      fakeIngredientRepo = FakeIngredientRepository();
      fakeRecipeRepo = FakeRecipeRepository();
      generateRecipes = GenerateRecipes(
        ingredientRepository: fakeIngredientRepo,
        recipeRepository: fakeRecipeRepo,
      );
      updateDietPreference = UpdateDietPreference(fakeRecipeRepo);
    });

    test('initial state is RecipesInitial', () {
      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );
      expect(bloc.state, isA<RecipesInitial>());
      bloc.close();
    });

    test('emits [RecipesLoading, RecipesNoMatches] when inventory is empty', () async {
      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );

      final expected = [
        isA<RecipesLoading>(),
        isA<RecipesNoMatches>(),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const LoadRecipes());

      await future;
      await bloc.close();
    });

    test('emits [RecipesLoading, RecipesLoaded] when matching ingredients are in inventory', () async {
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '1',
        name: 'tomato',
        quantity: 2,
        unit: 'pieces',
        expiryDate: today.add(const Duration(days: 1)),
        addedAt: today,
      ));
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '2',
        name: 'spinach',
        quantity: 100,
        unit: 'g',
        expiryDate: today,
        addedAt: today,
      ));

      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );

      final expected = [
        isA<RecipesLoading>(),
        isA<RecipesLoaded>().having((s) => s.recipes.isNotEmpty, 'recipes not empty', isTrue),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const LoadRecipes());

      await future;
      await bloc.close();
    });

    test('emits [RecipesLoading, RecipesError] when recipe repository fails', () async {
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '1',
        name: 'tomato',
        addedAt: today,
      ));
      fakeRecipeRepo.returnFailure = true;

      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );

      final expected = [
        isA<RecipesLoading>(),
        isA<RecipesError>(),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const LoadRecipes());

      await future;
      await bloc.close();
    });

    test('ChangeDiet updates preference and reloads recipes', () async {
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '1',
        name: 'tomato',
        quantity: 2,
        unit: 'pieces',
        addedAt: today,
      ));
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '2',
        name: 'spinach',
        quantity: 100,
        unit: 'g',
        addedAt: today,
      ));

      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );

      final future = expectLater(
        bloc.stream,
        emitsThrough(
          isA<RecipesLoaded>().having(
            (s) => s.dietPreference,
            'dietPreference',
            DietTag.vegetarian,
          ),
        ),
      );

      bloc.add(const ChangeDiet(DietTag.vegetarian));

      await future;
      expect(fakeRecipeRepo.currentDiet, DietTag.vegetarian);
      await bloc.close();
    });

    test('RefreshRecipes forces refresh and reloads', () async {
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '1',
        name: 'potato',
        addedAt: today,
      ));
      await fakeIngredientRepo.addIngredient(Ingredient(
        id: '2',
        name: 'onion',
        addedAt: today,
      ));

      final bloc = RecipesBloc(
        generateRecipes: generateRecipes,
        updateDietPreference: updateDietPreference,
      );

      final expected = [
        isA<RecipesLoading>(),
        isA<RecipesLoaded>(),
      ];

      final future = expectLater(bloc.stream, emitsInOrder(expected));
      bloc.add(const RefreshRecipes());

      await future;
      await bloc.close();
    });
  });
}
