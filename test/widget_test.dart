import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:rescue_recipe/app.dart';
import 'package:rescue_recipe/core/constants/app_strings.dart';
import 'package:rescue_recipe/core/di/injection.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/utils/responsive.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/delete_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/get_active_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_used.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/resolve_expiry_phrase.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/update_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/get_insights.dart';
import 'package:rescue_recipe/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:rescue_recipe/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/generate_recipes.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/update_diet_preference.dart';
import 'package:rescue_recipe/features/recipes/presentation/bloc/recipes_bloc.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/clear_all_data.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/get_settings.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/update_settings.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:rescue_recipe/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/ingredient_extraction_repository.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/speech_repository.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/apply_voice_correction.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/confirm_ingredients.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/extract_ingredients_from_transcript.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_bloc.dart';

import 'features/ingredients/inventory_cubit_test.dart';
import 'features/recipes/recipes_bloc_test.dart';
import 'features/voice/voice_input_bloc_test.dart';

class FakeSettingsRepo implements SettingsRepository {
  UserPreferences prefs = const UserPreferences();
  @override
  FutureEither<UserPreferences> getPreferences() async => Right(prefs);
  @override
  FutureEither<void> savePreferences(UserPreferences p) async {
    prefs = p;
    return const Right(null);
  }
  @override
  FutureEither<void> clearAllData() async {
    prefs = const UserPreferences();
    return const Right(null);
  }
}

class FakeUsageLogRepo implements UsageLogRepository {
  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async => const Right(null);
  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async => const Right([]);
  @override
  FutureEither<int> getRescuedCount() async => const Right(0);
  @override
  FutureEither<void> clearHistory() async => const Right(null);
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();

    // Register test dependencies
    final fakeRepo = FakeIngredientRepository();
    final fakeSpeech = FakeSpeechRepository();
    final fakeExtraction = FakeExtractionRepo();
    final fakeRecipeRepo = FakeRecipeRepository();

    sl.registerFactory<NavigationCubit>(NavigationCubit.new);
    sl.registerLazySingleton<IngredientRepository>(() => fakeRepo);
    sl.registerLazySingleton<GetActiveIngredients>(
      () => GetActiveIngredients(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<AddIngredient>(
      () => AddIngredient(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<AddIngredients>(
      () => AddIngredients(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<UpdateIngredient>(
      () => UpdateIngredient(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<DeleteIngredient>(
      () => DeleteIngredient(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<MarkIngredientUsed>(
      () => MarkIngredientUsed(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<MarkIngredientDiscarded>(
      () => MarkIngredientDiscarded(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<ResolveExpiryPhrase>(
      ResolveExpiryPhrase.new,
    );
    sl.registerFactory<InventoryCubit>(
      () => InventoryCubit(
        getActiveIngredients: sl<GetActiveIngredients>(),
        addIngredient: sl<AddIngredient>(),
        addIngredients: sl<AddIngredients>(),
        updateIngredient: sl<UpdateIngredient>(),
        deleteIngredient: sl<DeleteIngredient>(),
        markIngredientUsed: sl<MarkIngredientUsed>(),
        markIngredientDiscarded: sl<MarkIngredientDiscarded>(),
      ),
    );

    // Voice
    sl.registerLazySingleton<SpeechRepository>(() => fakeSpeech);
    sl.registerLazySingleton<IngredientExtractionRepository>(
        () => fakeExtraction);
    sl.registerLazySingleton<ExtractIngredientsFromTranscript>(
      () => ExtractIngredientsFromTranscript(
          sl<IngredientExtractionRepository>()),
    );
    sl.registerLazySingleton<ApplyVoiceCorrection>(
      ApplyVoiceCorrection.new,
    );
    sl.registerLazySingleton<ConfirmIngredients>(
      () => ConfirmIngredients(sl<AddIngredients>()),
    );
    sl.registerFactory<VoiceInputBloc>(
      () => VoiceInputBloc(
        speechRepository: sl<SpeechRepository>(),
        extractIngredients: sl<ExtractIngredientsFromTranscript>(),
        applyVoiceCorrection: sl<ApplyVoiceCorrection>(),
        confirmIngredients: sl<ConfirmIngredients>(),
      ),
    );

    // Recipes (Phase 4)
    sl.registerLazySingleton<RecipeRepository>(() => fakeRecipeRepo);
    sl.registerLazySingleton<GenerateRecipes>(
      () => GenerateRecipes(
        ingredientRepository: sl<IngredientRepository>(),
        recipeRepository: sl<RecipeRepository>(),
      ),
    );
    sl.registerLazySingleton<UpdateDietPreference>(
      () => UpdateDietPreference(sl<RecipeRepository>()),
    );
    sl.registerFactory<RecipesBloc>(
      () => RecipesBloc(
        generateRecipes: sl<GenerateRecipes>(),
        updateDietPreference: sl<UpdateDietPreference>(),
      ),
    );

    // Phase 6: Settings and Insights
    final fakeSettings = FakeSettingsRepo();
    final fakeUsageLog = FakeUsageLogRepo();

    sl.registerLazySingleton<SettingsRepository>(() => fakeSettings);
    sl.registerLazySingleton<GetSettings>(() => GetSettings(sl<SettingsRepository>()));
    sl.registerLazySingleton<UpdateSettings>(() => UpdateSettings(sl<SettingsRepository>()));
    sl.registerLazySingleton<ClearAllData>(() => ClearAllData(
          ingredientRepository: sl<IngredientRepository>(),
          settingsRepository: sl<SettingsRepository>(),
        ));
    sl.registerFactory<SettingsCubit>(() => SettingsCubit(
          getSettings: sl<GetSettings>(),
          updateSettings: sl<UpdateSettings>(),
          clearAllData: sl<ClearAllData>(),
        ));

    sl.registerLazySingleton<UsageLogRepository>(() => fakeUsageLog);
    sl.registerLazySingleton<GetInsights>(() => GetInsights(sl<UsageLogRepository>()));
    sl.registerFactory<InsightsCubit>(() => InsightsCubit(
          getInsights: sl<GetInsights>(),
        ));
  });

  test('breakpoints: compact < 600, medium 600-840, expanded > 840', () {
    expect(Responsive.sizeFor(320), ScreenSize.compact);
    expect(Responsive.sizeFor(599.9), ScreenSize.compact);
    expect(Responsive.sizeFor(600), ScreenSize.medium);
    expect(Responsive.sizeFor(840), ScreenSize.medium);
    expect(Responsive.sizeFor(840.1), ScreenSize.expanded);
  });

  testWidgets('shows home hero, bottom bar and disclaimer on a phone',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RescueRecipeApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.text(AppStrings.appName), findsWidgets);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byType(NavigationRail), findsNothing);
    expect(find.text('Speak your ingredients'), findsOneWidget);
  });

  testWidgets('switches to a navigation rail on a wide screen',
      (tester) async {
    tester.view.physicalSize = const Size(1000, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RescueRecipeApp());
    await tester.pump(const Duration(seconds: 1));

    expect(find.byType(NavigationRail), findsOneWidget);
    expect(find.byType(NavigationBar), findsNothing);
  });

  testWidgets('does not overflow at 320dp width with text scale 1.5',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(const RescueRecipeApp());
    await tester.pump(const Duration(seconds: 1));

    expect(tester.takeException(), isNull);
  });

  testWidgets('tapping a tab changes the page', (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RescueRecipeApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Kitchen'));
    await tester.pump(const Duration(seconds: 1));

    expect(find.text('My Kitchen'), findsOneWidget);
  });

  testWidgets('tapping Speak your ingredients opens VoiceInputPage',
      (tester) async {
    tester.view.physicalSize = const Size(400, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(const RescueRecipeApp());
    await tester.pump(const Duration(seconds: 1));

    await tester.tap(find.text('Speak your ingredients'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('Voice Rescue'), findsOneWidget);
  });
}
