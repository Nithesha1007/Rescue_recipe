import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/di/injection.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/models/ai_status.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/cooking_session.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/inventory_deduction.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/voice_command.dart';
import 'package:rescue_recipe/features/cooking/domain/services/voice_session_controller.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/compute_inventory_deduction.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/finish_cooking.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/navigate_step.dart';
import 'package:rescue_recipe/features/cooking/domain/usecases/start_cooking.dart';
import 'package:rescue_recipe/features/cooking/presentation/bloc/cooking_bloc.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/recipes/data/datasources/offline_recipe_source.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/ranked_recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/presentation/cubit/rescue_suggestions_cubit.dart';
import 'package:rescue_recipe/features/recipes/presentation/pages/recipe_detail_page.dart';
import 'package:rescue_recipe/features/recipes/presentation/pages/recipes_page.dart';
import 'package:rescue_recipe/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/voice/data/datasources/gemini_remote_datasource.dart';
import 'package:rescue_recipe/features/voice/domain/entities/audio_extraction_result.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';

import 'rescue_suggestions_cubit_test.dart';

class _MockVoiceController implements VoiceSessionController {
  @override
  AudioSessionState get currentState => AudioSessionState.idle;
  @override
  GuideLanguage get guideLanguage => GuideLanguage.english;
  @override
  void setGuideLanguage(GuideLanguage language) {}
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
  Future<void> stopAll() async {}
}

class _MockStartCooking implements StartCooking {
  @override
  Future<Either<Failure, CookingSession>> call(StartCookingParams params) async =>
      Right(CookingSession(recipe: params.recipe, startedAt: DateTime.now()));
}

class _MockNavigateStep implements NavigateStep {
  @override
  Future<Either<Failure, CookingSession>> call(NavigateStepParams params) async =>
      Right(params.session);
}

class _MockComputeDeduction implements ComputeInventoryDeduction {
  @override
  Future<Either<Failure, List<InventoryDeductionProposal>>> call(ComputeInventoryDeductionParams params) async =>
      const Right([]);
}

class _MockFinishCooking implements FinishCooking {
  @override
  Future<Either<Failure, FinishCookingResult>> call(FinishCookingParams params) async =>
      const Right(FinishCookingResult(rescuedCount: 0, totalDeducted: 0));
}

class _FakeGeminiRemoteDataSource implements GeminiRemoteDataSource {
  @override
  AiStatus get lastStatus => const AiStatus(state: AiConnectionState.ok);
  @override
  Future<List<ExtractedIngredient>> extractIngredients(String transcript) async => [];
  @override
  Future<AudioExtractionResult> extractFromAudio({
    required List<int> audioBytes,
    required String mimeType,
  }) async =>
      const AudioExtractionResult(
        transcript: '',
        detectedLanguage: 'en',
        ingredients: [],
      );
  @override
  Future<AiStatus> testConnection() async => const AiStatus(state: AiConnectionState.ok);
}

void main() {
  late NavigationCubit navCubit;
  late StreamController<List<Ingredient>> ingredientsController;
  late FakeWatchActiveIngredients fakeWatch;
  late FakeGenerateRecipes fakeGenerate;
  late FakeUpdateDietPreference fakeUpdateDiet;
  late FakeSavedRecipeRepository fakeSavedRepo;

  final sampleRanked = RankedRecipe(
    recipe: OfflineRecipeSource.recipes.first,
    totalScore: 0.935,
    coverageScore: 1.0,
    availabilityScore: 0.80,
    speedScore: 0.90,
    preferenceScore: 1.0,
    matchedExpiringIngredients: const [],
    missingIngredients: const [
      RecipeIngredient(name: 'egg', quantity: 3, unit: 'pieces'),
    ],
    coveredExpiringCount: 2,
    totalExpiringCount: 2,
    reason: 'Uses your tomatoes and spinach in a quick 15-minute meal.',
    badges: const [
      RankedBadge(badge: RecipeBadge.rescueFirst, label: 'Rescue-first'),
      RankedBadge(badge: RecipeBadge.quick, label: 'Quick'),
      RankedBadge(badge: RecipeBadge.missing, label: 'Missing 1'),
    ],
  );

  setUp(() {
    navCubit = NavigationCubit();
    ingredientsController = StreamController<List<Ingredient>>.broadcast();
    fakeWatch = FakeWatchActiveIngredients(ingredientsController);
    fakeGenerate = FakeGenerateRecipes()..returnedRecipes = [sampleRanked];
    fakeUpdateDiet = FakeUpdateDietPreference();
    fakeSavedRepo = FakeSavedRecipeRepository();

    if (!sl.isRegistered<GeminiRemoteDataSource>()) {
      sl.registerSingleton<GeminiRemoteDataSource>(_FakeGeminiRemoteDataSource());
    }

    if (!sl.isRegistered<CookingBloc>()) {
      final mockVoice = _MockVoiceController();
      sl.registerFactory<CookingBloc>(() => CookingBloc(
        startCooking: _MockStartCooking(),
        navigateStep: _MockNavigateStep(),
        computeInventoryDeduction: _MockComputeDeduction(),
        finishCooking: _MockFinishCooking(),
        voiceController: mockVoice,
      ));
    }
  });

  tearDown(() {
    navCubit.close();
    ingredientsController.close();
  });

  Widget buildAppWith(RescueSuggestionsCubit cubit, Widget child) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>.value(value: navCubit),
        BlocProvider<RescueSuggestionsCubit>.value(value: cubit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: child,
      ),
    );
  }

  testWidgets(
      'RecipesPage does not overflow at 320dp width with text scale 1.5 in loaded state',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final cubit = RescueSuggestionsCubit(
      watchActiveIngredients: fakeWatch,
      generateRecipes: fakeGenerate,
      updateDietPreference: fakeUpdateDiet,
      savedRecipeRepository: fakeSavedRepo,
      enableTimers: false,
    );
    addTearDown(cubit.close);

    final ingredient = Ingredient(
      id: 'ing_1',
      name: 'tomato',
      expiryDate: DateTime.now(),
      addedAt: DateTime.now().subtract(const Duration(days: 2)),
    );

    await tester.pumpWidget(buildAppWith(cubit, const RecipesPage()));
    ingredientsController.add([ingredient]);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pumpAndSettle();

    expect(find.text('Rescue Plan'), findsWidgets);
    expect(find.byType(RecipesPage), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'RecipeDetailPage does not overflow at 320dp width with text scale 1.5 and shows score breakdown',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final cubit = RescueSuggestionsCubit(
      watchActiveIngredients: fakeWatch,
      generateRecipes: fakeGenerate,
      updateDietPreference: fakeUpdateDiet,
      savedRecipeRepository: fakeSavedRepo,
      enableTimers: false,
    );
    addTearDown(cubit.close);

    await tester.pumpWidget(
      buildAppWith(cubit, RecipeDetailPage(rankedRecipe: sampleRanked)),
    );
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Tomato Spinach Scramble'), findsWidgets);
    expect(find.text('Rescue score breakdown'), findsOneWidget);
    expect(find.text('Expiring items coverage (45%)'), findsOneWidget);

    final buttonFinder = find.text('Start cooking');
    expect(buttonFinder, findsOneWidget);

    await tester.ensureVisible(buttonFinder);
    await tester.pumpAndSettle();

    await tester.tap(buttonFinder);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text(sampleRanked.recipe.title), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
