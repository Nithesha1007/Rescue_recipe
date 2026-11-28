import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/cooking/data/services/voice_session_controller_impl.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/compute_inventory_deduction.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/finish_cooking.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/navigate_step.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/start_cooking.dart';
import 'package:rescue_recipe/features/cooking/presentation/bloc/cooking_bloc.dart';
import 'package:rescue_recipe/features/cooking/presentation/bloc/cooking_event.dart';
import 'package:rescue_recipe/features/cooking/presentation/bloc/cooking_state.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';

import 'voice_session_controller_test.dart';

class FakeIngredientRepository implements IngredientRepository {
  List<Ingredient> ingredients = [];

  @override
  Stream<List<Ingredient>> watchActiveIngredients() => Stream.value(ingredients);

  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async => Right(ingredients);

  @override
  FutureEither<Ingredient?> getIngredientById(String id) async {
    final matches = ingredients.where((i) => i.id == id).toList();
    return Right(matches.isNotEmpty ? matches.first : null);
  }

  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async {
    ingredients.add(ingredient);
    return const Right(null);
  }

  @override
  FutureEither<void> addIngredients(List<Ingredient> items) async {
    ingredients.addAll(items);
    return const Right(null);
  }

  @override
  FutureEither<void> deleteIngredient(String id) async => const Right(null);

  @override
  FutureEither<void> markDiscarded(String id) async => const Right(null);

  @override
  FutureEither<void> markUsed(String id) async => const Right(null);

  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async => const Right(null);
}

class FakeUsageLogRepo implements UsageLogRepository {
  int logged = 0;

  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async {
    logged++;
    return const Right(null);
  }

  @override
  FutureEither<void> clearHistory() async => const Right(null);

  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async => const Right([]);

  @override
  FutureEither<int> getRescuedCount() async => Right(logged);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CookingBloc', () {
    late CookingBloc bloc;
    late FakeIngredientRepository ingredientRepo;
    late FakeUsageLogRepo usageRepo;
    late VoiceSessionControllerImpl voiceController;

    const testRecipe = Recipe(
      id: 'r_test',
      title: 'Simple Salad',
      minutes: 10,
      servings: 1,
      dietTags: {},
      ingredients: [
        RecipeIngredient(name: 'Cucumber', quantity: 1, unit: 'item'),
      ],
      steps: [
        RecipeStep(text: 'Wash cucumber'),
        RecipeStep(text: 'Slice cucumber'),
        RecipeStep(text: 'Enjoy!'),
      ],
    );

    setUp(() {
      ingredientRepo = FakeIngredientRepository();
      usageRepo = FakeUsageLogRepo();
      voiceController = VoiceSessionControllerImpl(
        ttsService: FakeTtsService(),
        speechRepository: FakeSpeechRepository(),
      );

      bloc = CookingBloc(
        startCooking: StartCooking(),
        navigateStep: NavigateStep(),
        computeInventoryDeduction: ComputeInventoryDeduction(ingredientRepo),
        finishCooking: FinishCooking(ingredientRepo, usageRepo),
        voiceController: voiceController,
      );
    });

    tearDown(() async {
      await bloc.close();
    });

    test('initial state has flowStatus initial', () {
      expect(bloc.state.flowStatus, CookingFlowStatus.initial);
    });

    test('CookingStarted sets state to running and current step 0', () async {
      bloc.add(const CookingStarted(testRecipe));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(bloc.state.flowStatus, CookingFlowStatus.running);
      expect(bloc.state.session?.currentStepIndex, 0);
      expect(bloc.state.isSafetyPromptSpoken, isTrue);
    });

    test('StepNext advances step and Finish on last step', () async {
      bloc.add(const CookingStarted(testRecipe));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(const StepNextTriggered());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.session?.currentStepIndex, 1);

      bloc.add(const StepNextTriggered());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.session?.currentStepIndex, 2);

      // Next on last step requests finish
      bloc.add(const StepNextTriggered());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.flowStatus, CookingFlowStatus.confirmingFinish);
    });

    test('Voice command Next advances step identically to button', () async {
      bloc.add(const CookingStarted(testRecipe));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(const VoiceCommandReceived(CommandNext()));
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.session?.currentStepIndex, 1);
    });

    test('Pause and Resume transitions work cleanly', () async {
      bloc.add(const CookingStarted(testRecipe));
      await Future<void>.delayed(const Duration(milliseconds: 50));

      bloc.add(const CookingPausedTriggered());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.flowStatus, CookingFlowStatus.paused);
      expect(bloc.state.isPaused, isTrue);

      bloc.add(const CookingResumedTriggered());
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(bloc.state.flowStatus, CookingFlowStatus.running);
      expect(bloc.state.isPaused, isFalse);
    });
  });
}
