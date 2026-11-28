import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:rescue_recipe/core/di/injection.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
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
import 'package:rescue_recipe/features/ingredients/presentation/pages/kitchen_page.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/get_insights.dart';
import 'package:rescue_recipe/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:rescue_recipe/features/insights/presentation/pages/insights_page.dart';
import 'package:rescue_recipe/features/recipes/domain/repositories/recipe_repository.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/generate_recipes.dart';
import 'package:rescue_recipe/features/recipes/domain/usecases/update_diet_preference.dart';
import 'package:rescue_recipe/features/recipes/presentation/cubit/rescue_suggestions_cubit.dart';
import 'package:rescue_recipe/features/recipes/presentation/pages/recipes_page.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/watch_active_ingredients.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/clear_all_data.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/get_settings.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/update_settings.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:rescue_recipe/features/shell/presentation/cubit/navigation_cubit.dart';
import 'package:rescue_recipe/features/shell/presentation/pages/home_page.dart';
import 'package:rescue_recipe/core/models/ai_status.dart';
import 'package:rescue_recipe/features/voice/data/datasources/gemini_remote_datasource.dart';
import 'package:rescue_recipe/features/voice/domain/entities/audio_extraction_result.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/ingredient_extraction_repository.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/speech_repository.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/apply_voice_correction.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/confirm_ingredients.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/extract_ingredients_from_transcript.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_bloc.dart';

import '../features/ingredients/inventory_cubit_test.dart';
import '../features/recipes/recipes_bloc_test.dart';
import '../features/voice/voice_input_bloc_test.dart';

class _FakeSettingsRepo implements SettingsRepository {
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

class _FakeUsageLogRepo implements UsageLogRepository {
  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async => const Right(null);
  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async => const Right([]);
  @override
  FutureEither<int> getRescuedCount() async => const Right(0);
  @override
  FutureEither<void> clearHistory() async => const Right(null);
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

Widget _buildMatrixScreen({
  required Widget child,
  required Size size,
  required double textScale,
  required Brightness brightness,
}) {
  return MultiBlocProvider(
    providers: [
      BlocProvider<NavigationCubit>(create: (_) => sl<NavigationCubit>()),
      BlocProvider<InventoryCubit>(create: (_) => sl<InventoryCubit>()..loadIngredients()),
      BlocProvider<RescueSuggestionsCubit>(create: (_) => sl<RescueSuggestionsCubit>()),
      BlocProvider<VoiceInputBloc>(create: (_) => sl<VoiceInputBloc>()),
      BlocProvider<SettingsCubit>(create: (_) => sl<SettingsCubit>()..loadSettings()),
      BlocProvider<InsightsCubit>(create: (_) => sl<InsightsCubit>()..loadInsights()),
    ],
    child: MaterialApp(
      theme: brightness == Brightness.light ? AppTheme.light() : AppTheme.dark(),
      home: MediaQuery(
        data: MediaQueryData(
          size: size,
          textScaler: TextScaler.linear(textScale),
          platformBrightness: brightness,
        ),
        child: SizedBox(
          width: size.width,
          height: size.height,
          child: Scaffold(
            body: child,
          ),
        ),
      ),
    ),
  );
}

void main() {
  setUp(() async {
    await GetIt.instance.reset();

    final fakeRepo = FakeIngredientRepository();
    await fakeRepo.addIngredient(
      Ingredient(
        id: '1',
        name: 'Organic Tomatoes',
        quantity: 3,
        unit: 'pieces',
        expiryDate: DateTime.now().add(const Duration(days: 1)),
        addedAt: DateTime.now(),
      ),
    );
    final fakeSpeech = FakeSpeechRepository();
    final fakeExtraction = FakeExtractionRepo();
    final fakeRecipeRepo = FakeRecipeRepository();
    final fakeSettings = _FakeSettingsRepo();
    final fakeUsageLog = _FakeUsageLogRepo();

    sl.registerFactory<NavigationCubit>(NavigationCubit.new);
    sl.registerLazySingleton<IngredientRepository>(() => fakeRepo);
    sl.registerLazySingleton<GetActiveIngredients>(() => GetActiveIngredients(sl<IngredientRepository>()));
    sl.registerLazySingleton<AddIngredient>(() => AddIngredient(sl<IngredientRepository>()));
    sl.registerLazySingleton<AddIngredients>(() => AddIngredients(sl<IngredientRepository>()));
    sl.registerLazySingleton<UpdateIngredient>(() => UpdateIngredient(sl<IngredientRepository>()));
    sl.registerLazySingleton<DeleteIngredient>(() => DeleteIngredient(sl<IngredientRepository>()));
    sl.registerLazySingleton<MarkIngredientUsed>(() => MarkIngredientUsed(sl<IngredientRepository>()));
    sl.registerLazySingleton<MarkIngredientDiscarded>(() => MarkIngredientDiscarded(sl<IngredientRepository>()));
    sl.registerLazySingleton<ResolveExpiryPhrase>(ResolveExpiryPhrase.new);

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

    sl.registerLazySingleton<SpeechRepository>(() => fakeSpeech);
    sl.registerLazySingleton<IngredientExtractionRepository>(() => fakeExtraction);
    sl.registerLazySingleton<ExtractIngredientsFromTranscript>(
      () => ExtractIngredientsFromTranscript(sl<IngredientExtractionRepository>()),
    );
    sl.registerLazySingleton<ApplyVoiceCorrection>(ApplyVoiceCorrection.new);
    sl.registerLazySingleton<ConfirmIngredients>(() => ConfirmIngredients(sl<AddIngredients>()));
    sl.registerFactory<VoiceInputBloc>(
      () => VoiceInputBloc(
        speechRepository: sl<SpeechRepository>(),
        extractIngredients: sl<ExtractIngredientsFromTranscript>(),
        applyVoiceCorrection: sl<ApplyVoiceCorrection>(),
        confirmIngredients: sl<ConfirmIngredients>(),
      ),
    );

    sl.registerLazySingleton<RecipeRepository>(() => fakeRecipeRepo);
    sl.registerLazySingleton<GeminiRemoteDataSource>(() => _FakeGeminiRemoteDataSource());
    sl.registerLazySingleton<GenerateRecipes>(
      () => GenerateRecipes(
        ingredientRepository: sl<IngredientRepository>(),
        recipeRepository: sl<RecipeRepository>(),
      ),
    );
    sl.registerLazySingleton<UpdateDietPreference>(() => UpdateDietPreference(sl<RecipeRepository>()));
    sl.registerLazySingleton<WatchActiveIngredients>(
      () => WatchActiveIngredients(sl<IngredientRepository>()),
    );
    sl.registerLazySingleton<RescueSuggestionsCubit>(
      () => RescueSuggestionsCubit(
        watchActiveIngredients: sl<WatchActiveIngredients>(),
        generateRecipes: sl<GenerateRecipes>(),
        updateDietPreference: sl<UpdateDietPreference>(),
        enableTimers: false,
      ),
    );

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

  tearDown(() async {
    await GetIt.instance.reset();
  });

  group('Responsive Matrix: 320dp width, landscape, text scale 1.5, dark mode', () {
    const screens = <String, Widget Function()>{
      'Home': HomePage.new,
      'Kitchen': KitchenPage.new,
      'Recipes': RecipesPage.new,
      'Insights': InsightsPage.new,
    };

    final configs = <Map<String, dynamic>>[
      {
        'desc': '320x568 compact light 1.0x',
        'size': const Size(320, 568),
        'scale': 1.0,
        'bright': Brightness.light,
      },
      {
        'desc': '320x568 compact dark 1.5x text scale',
        'size': const Size(320, 568),
        'scale': 1.5,
        'bright': Brightness.dark,
      },
      {
        'desc': '360x640 standard light 1.5x text scale',
        'size': const Size(360, 640),
        'scale': 1.5,
        'bright': Brightness.light,
      },
      {
        'desc': '412x915 modern tall dark 1.0x',
        'size': const Size(412, 915),
        'scale': 1.0,
        'bright': Brightness.dark,
      },
      {
        'desc': '800x400 landscape light 1.2x',
        'size': const Size(800, 400),
        'scale': 1.2,
        'bright': Brightness.light,
      },
      {
        'desc': '1024x768 tablet dark 1.0x',
        'size': const Size(1024, 768),
        'scale': 1.0,
        'bright': Brightness.dark,
      },
    ];

    for (final entry in screens.entries) {
      for (final config in configs) {
        testWidgets('${entry.key} renders without overflow under ${config['desc']}',
            (tester) async {
          final size = config['size'] as Size;
          final scale = config['scale'] as double;
          final bright = config['bright'] as Brightness;

          tester.view.physicalSize = size * tester.view.devicePixelRatio;

          await tester.pumpWidget(
            _buildMatrixScreen(
              child: entry.value(),
              size: size,
              textScale: scale,
              brightness: bright,
            ),
          );

          await tester.pump();
          await tester.pump(const Duration(milliseconds: 300));

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
