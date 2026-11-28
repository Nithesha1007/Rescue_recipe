import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import 'package:rescue_recipe/core/di/injection.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/cooking/domain/services/voice_session_controller.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/compute_inventory_deduction.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/finish_cooking.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/get_speech_rate.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/navigate_step.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/start_cooking.dart';
import 'package:rescue_recipe/features/cooking/presentation/bloc/cooking_bloc.dart';
import 'package:rescue_recipe/features/cooking/presentation/pages/cooking_page.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';

class MockIngredientRepository implements IngredientRepository {
  @override
  Stream<List<Ingredient>> watchActiveIngredients() => Stream.value([]);
  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async => const Right([]);
  @override
  FutureEither<Ingredient?> getIngredientById(String id) async => const Right(null);
  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async => const Right(null);
  @override
  FutureEither<void> addIngredients(List<Ingredient> ingredients) async => const Right(null);
  @override
  FutureEither<void> deleteIngredient(String id) async => const Right(null);
  @override
  FutureEither<void> markDiscarded(String id) async => const Right(null);
  @override
  FutureEither<void> markUsed(String id) async => const Right(null);
  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async => const Right(null);
}

class MockUsageLogRepository implements UsageLogRepository {
  @override
  FutureEither<int> getRescuedCount() async => const Right(0);
  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async => const Right([]);
  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async => const Right(null);
  @override
  FutureEither<void> clearHistory() async => const Right(null);
}

class MockVoiceSessionController implements VoiceSessionController {
  @override
  AudioSessionState get currentState => AudioSessionState.idle;

  @override
  Stream<VoiceCommand> get commandStream => const Stream.empty();

  @override
  Stream<AudioSessionState> get stateStream => const Stream.empty();

  @override
  Future<void> dispose() async {}

  @override
  void onAppPaused() {}

  @override
  void onAppResumed() {}

  @override
  Future<void> speak(String text) async {}

  @override
  Future<void> startListening({bool isPausedContext = false}) async {}

  @override
  GuideLanguage get guideLanguage => GuideLanguage.english;

  @override
  void setGuideLanguage(GuideLanguage language) {}

  @override
  Future<void> stopAll() async {}
}

class FakeBox<T> implements Box<T> {
  final Map<dynamic, T> _map = {};

  @override
  Iterable<T> get values => _map.values;

  @override
  Future<void> put(dynamic key, T value) async {
    _map[key] = value;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  const testRecipe = Recipe(
    id: 'r_widget',
    title: 'Veggie Stir Fry',
    minutes: 15,
    servings: 2,
    dietTags: {},
    ingredients: [
      RecipeIngredient(name: 'Bell Pepper', quantity: 1, unit: 'item'),
      RecipeIngredient(name: 'Soy Sauce', quantity: 2, unit: 'tbsp'),
    ],
    steps: [
      RecipeStep(text: 'Chop the bell peppers into thin slices'),
      RecipeStep(text: 'Heat oil in a wok and stir fry peppers'),
      RecipeStep(text: 'Add soy sauce and serve hot'),
    ],
  );

  setUp(() async {
    await sl.reset();
    final mockIngRepo = MockIngredientRepository();
    final mockUsageRepo = MockUsageLogRepository();
    final mockVoiceCtrl = MockVoiceSessionController();

    sl.registerSingleton<IngredientRepository>(mockIngRepo);
    sl.registerSingleton<UsageLogRepository>(mockUsageRepo);
    sl.registerSingleton<VoiceSessionController>(mockVoiceCtrl);

    sl.registerFactory<StartCooking>(StartCooking.new);
    sl.registerFactory<NavigateStep>(NavigateStep.new);
    sl.registerFactory<ComputeInventoryDeduction>(() => ComputeInventoryDeduction(mockIngRepo));
    sl.registerFactory<FinishCooking>(() => FinishCooking(mockIngRepo, mockUsageRepo));
    sl.registerFactory<GetSpeechRate>(GetSpeechRate.new);

    sl.registerFactory<CookingBloc>(
      () => CookingBloc(
        startCooking: sl<StartCooking>(),
        navigateStep: sl<NavigateStep>(),
        computeInventoryDeduction: sl<ComputeInventoryDeduction>(),
        finishCooking: sl<FinishCooking>(),
        voiceController: sl<VoiceSessionController>(),
      ),
    );
  });

  tearDown(() async {
    await sl.reset();
  });

  testWidgets('renders CookingPage and steps at standard dimensions', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const CookingPage(recipe: testRecipe),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Veggie Stir Fry'), findsOneWidget);
    expect(find.textContaining('Chop the bell peppers'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(find.text('Back'), findsOneWidget);
  });

  testWidgets('renders CookingPage at 320dp width without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const CookingPage(recipe: testRecipe),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Veggie Stir Fry'), findsOneWidget);
  });

  testWidgets('renders CookingPage in landscape orientation without overflow', (tester) async {
    tester.view.physicalSize = const Size(800 * 2, 400 * 2);
    tester.view.devicePixelRatio = 2.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: const CookingPage(recipe: testRecipe),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(tester.takeException(), isNull);
    expect(find.text('Veggie Stir Fry'), findsOneWidget);
    expect(find.textContaining('Chop the bell peppers'), findsOneWidget);
  });
}
