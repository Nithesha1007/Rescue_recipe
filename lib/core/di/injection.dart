import 'package:get_it/get_it.dart';
import 'package:hive/hive.dart';
import 'package:http/http.dart' as http;

import '../../features/cooking/data/models/usage_log_model.dart';
import '../../features/cooking/data/repositories/usage_log_repository_impl.dart';
import '../../features/cooking/data/services/tts_service.dart';
import '../../features/cooking/data/services/voice_session_controller_impl.dart';
import '../../features/cooking/domain/repositories/usage_log_repository.dart';
import '../../features/cooking/domain/services/voice_session_controller.dart';
import '../../features/cooking/domain/usecases/compute_inventory_deduction.dart';
import '../../features/cooking/domain/usecases/finish_cooking.dart';
import '../../features/cooking/domain/usecases/get_speech_rate.dart';
import '../../features/cooking/domain/usecases/navigate_step.dart';
import '../../features/cooking/domain/usecases/start_cooking.dart';
import '../../features/cooking/presentation/bloc/cooking_bloc.dart';
import '../../features/ingredients/data/datasources/ingredient_local_datasource.dart';
import '../../features/ingredients/data/models/ingredient_model.dart';
import '../../features/ingredients/data/repositories/ingredient_repository_impl.dart';
import '../../features/ingredients/domain/repositories/ingredient_repository.dart';
import '../../features/ingredients/domain/usecases/add_ingredient.dart';
import '../../features/ingredients/domain/usecases/add_ingredients.dart';
import '../../features/ingredients/domain/usecases/delete_ingredient.dart';
import '../../features/ingredients/domain/usecases/get_active_ingredients.dart';
import '../../features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import '../../features/ingredients/domain/usecases/mark_ingredient_used.dart';
import '../../features/ingredients/domain/usecases/resolve_expiry_phrase.dart';
import '../../features/ingredients/domain/usecases/update_ingredient.dart';
import '../../features/ingredients/presentation/cubit/inventory_cubit.dart';
import '../../features/insights/domain/usecases/clear_usage_history.dart';
import '../../features/insights/domain/usecases/get_insights.dart';
import '../../features/insights/presentation/cubit/insights_cubit.dart';
import '../../features/notifications/data/services/local_notification_scheduler.dart';
import '../../features/notifications/domain/services/notification_scheduler.dart';
import '../../features/notifications/domain/usecases/cancel_alerts_for_ingredient.dart';
import '../../features/notifications/domain/usecases/request_notification_permission.dart';
import '../../features/notifications/domain/usecases/sync_expiry_alerts.dart';
import '../../features/recipes/data/datasources/gemini_recipe_datasource.dart';
import '../../features/recipes/data/datasources/preferences_local_datasource.dart';
import '../../features/recipes/data/datasources/saved_recipe_repository.dart';
import '../../features/recipes/data/repositories/recipe_repository_impl.dart';
import '../../features/recipes/domain/repositories/recipe_repository.dart';
import '../../features/recipes/domain/services/dish_image_resolver.dart';
import '../../features/recipes/domain/usecases/generate_recipes.dart';
import '../../features/recipes/domain/usecases/get_diet_preference.dart';
import '../../features/recipes/domain/usecases/get_recipe_by_id.dart';
import '../../features/recipes/domain/usecases/rank_recipes.dart';
import '../../features/recipes/domain/usecases/update_diet_preference.dart';
import '../../features/recipes/presentation/bloc/recipes_bloc.dart';
import '../../features/settings/data/datasources/settings_local_datasource.dart';
import '../../features/settings/data/repositories/settings_repository_impl.dart';
import '../../features/settings/domain/repositories/settings_repository.dart';
import '../../features/settings/domain/usecases/clear_all_data.dart';
import '../../features/settings/domain/usecases/get_settings.dart';
import '../../features/settings/domain/usecases/update_settings.dart';
import '../../features/settings/presentation/cubit/settings_cubit.dart';
import '../../features/shell/presentation/cubit/navigation_cubit.dart';
import '../../features/voice/data/datasources/connectivity_service.dart';
import '../../features/voice/data/datasources/gemini_remote_datasource.dart';
import '../../features/voice/data/repositories/ingredient_extraction_repository_impl.dart';
import '../../features/voice/data/repositories/speech_repository_impl.dart';
import '../../features/voice/domain/repositories/ingredient_extraction_repository.dart';
import '../../features/voice/domain/repositories/speech_repository.dart';
import '../../features/voice/domain/usecases/apply_voice_correction.dart';
import '../../features/voice/domain/usecases/confirm_ingredients.dart';
import '../../features/voice/domain/usecases/extract_ingredients_from_transcript.dart';
import '../../features/voice/presentation/bloc/voice_input_bloc.dart';
import '../config/app_config.dart';

final GetIt sl = GetIt.instance;

Future<void> configureDependencies({
  Box<IngredientModel>? box,
  Box<String>? preferencesBox,
  Box<UsageLogModel>? usageLogBox,
  http.Client? httpClient,
  SpeechRepository? speechRepository,
  ConnectivityService? connectivityService,
  GeminiRecipeDataSource? geminiRecipeDataSource,
  RecipeRepository? recipeRepository,
  TtsService? ttsService,
  VoiceSessionController? voiceSessionController,
  UsageLogRepository? usageLogRepository,
  SettingsRepository? settingsRepository,
  NotificationScheduler? notificationScheduler,
}) async {
  // App Config
  if (!sl.isRegistered<AppConfig>()) {
    sl.registerSingleton<AppConfig>(AppConfig.fromEnvironment());
  }

  // Shell Cubit
  if (!sl.isRegistered<NavigationCubit>()) {
    sl.registerFactory<NavigationCubit>(NavigationCubit.new);
  }

  // Hive Box - Ingredients
  if (!sl.isRegistered<Box<IngredientModel>>()) {
    final Box<IngredientModel> ingredientBox =
        box ?? Hive.box<IngredientModel>('ingredients');
    sl.registerSingleton<Box<IngredientModel>>(ingredientBox);
  }

  // Hive Box - Preferences
  if (!sl.isRegistered<Box<String>>()) {
    if (preferencesBox != null) {
      sl.registerSingleton<Box<String>>(preferencesBox);
    } else if (Hive.isBoxOpen('preferences')) {
      sl.registerSingleton<Box<String>>(Hive.box<String>('preferences'));
    }
  }

  // Hive Box - Usage Log
  if (!sl.isRegistered<Box<UsageLogModel>>()) {
    if (usageLogBox != null) {
      sl.registerSingleton<Box<UsageLogModel>>(usageLogBox);
    } else if (Hive.isBoxOpen('usage_log')) {
      sl.registerSingleton<Box<UsageLogModel>>(Hive.box<UsageLogModel>('usage_log'));
    }
  }

  // Local Data Source - Ingredients
  if (!sl.isRegistered<IngredientLocalDataSource>()) {
    sl.registerLazySingleton<IngredientLocalDataSource>(
      () => IngredientLocalDataSourceImpl(sl<Box<IngredientModel>>()),
    );
  }

  // Ingredients Repository
  if (!sl.isRegistered<IngredientRepository>()) {
    sl.registerLazySingleton<IngredientRepository>(
      () => IngredientRepositoryImpl(sl<IngredientLocalDataSource>()),
    );
  }

  // Usage Log Repository
  if (!sl.isRegistered<UsageLogRepository>()) {
    if (usageLogRepository != null) {
      sl.registerSingleton<UsageLogRepository>(usageLogRepository);
    } else if (sl.isRegistered<Box<UsageLogModel>>()) {
      sl.registerLazySingleton<UsageLogRepository>(
        () => UsageLogRepositoryImpl(sl<Box<UsageLogModel>>()),
      );
    }
  }

  // Notification Scheduler
  if (!sl.isRegistered<NotificationScheduler>()) {
    sl.registerLazySingleton<NotificationScheduler>(
      () => notificationScheduler ?? LocalNotificationScheduler(),
    );
  }

  // Settings Local Data Source & Repository
  if (!sl.isRegistered<SettingsLocalDataSource>()) {
    if (sl.isRegistered<Box<String>>()) {
      sl.registerLazySingleton<SettingsLocalDataSource>(
        () => SettingsLocalDataSourceImpl(sl<Box<String>>()),
      );
    }
  }

  if (!sl.isRegistered<SettingsRepository>()) {
    if (settingsRepository != null) {
      sl.registerSingleton<SettingsRepository>(settingsRepository);
    } else if (sl.isRegistered<SettingsLocalDataSource>()) {
      sl.registerLazySingleton<SettingsRepository>(
        () => SettingsRepositoryImpl(sl<SettingsLocalDataSource>()),
      );
    }
  }

  // Settings Use Cases
  if (!sl.isRegistered<GetSettings>()) {
    sl.registerLazySingleton<GetSettings>(
      () => GetSettings(sl<SettingsRepository>()),
    );
  }
  if (!sl.isRegistered<UpdateSettings>()) {
    sl.registerLazySingleton<UpdateSettings>(
      () => UpdateSettings(sl<SettingsRepository>()),
    );
  }
  if (!sl.isRegistered<ClearAllData>()) {
    sl.registerLazySingleton<ClearAllData>(
      () => ClearAllData(
        settingsRepository: sl<SettingsRepository>(),
        ingredientRepository: sl<IngredientRepository>(),
        usageLogRepository: sl.isRegistered<UsageLogRepository>() ? sl<UsageLogRepository>() : null,
        notificationScheduler: sl<NotificationScheduler>(),
      ),
    );
  }

  // Notification Use Cases
  if (!sl.isRegistered<SyncExpiryAlerts>()) {
    sl.registerLazySingleton<SyncExpiryAlerts>(
      () => SyncExpiryAlerts(
        ingredientRepository: sl<IngredientRepository>(),
        settingsRepository: sl<SettingsRepository>(),
        scheduler: sl<NotificationScheduler>(),
      ),
    );
  }
  if (!sl.isRegistered<CancelAlertsForIngredient>()) {
    sl.registerLazySingleton<CancelAlertsForIngredient>(
      () => CancelAlertsForIngredient(sl<NotificationScheduler>()),
    );
  }
  if (!sl.isRegistered<RequestNotificationPermission>()) {
    sl.registerLazySingleton<RequestNotificationPermission>(
      () => RequestNotificationPermission(sl<NotificationScheduler>()),
    );
  }

  // Settings Cubit
  if (!sl.isRegistered<SettingsCubit>()) {
    sl.registerFactory<SettingsCubit>(
      () => SettingsCubit(
        getSettings: sl<GetSettings>(),
        updateSettings: sl<UpdateSettings>(),
        clearAllData: sl<ClearAllData>(),
        requestNotificationPermission: sl<RequestNotificationPermission>(),
        syncExpiryAlerts: sl<SyncExpiryAlerts>(),
      ),
    );
  }

  // Insights Use Cases & Cubit
  if (!sl.isRegistered<GetInsights>()) {
    sl.registerLazySingleton<GetInsights>(
      () => GetInsights(sl<UsageLogRepository>()),
    );
  }
  if (!sl.isRegistered<ClearUsageHistory>()) {
    sl.registerLazySingleton<ClearUsageHistory>(
      () => ClearUsageHistory(sl<UsageLogRepository>()),
    );
  }
  if (!sl.isRegistered<InsightsCubit>()) {
    sl.registerFactory<InsightsCubit>(
      () => InsightsCubit(
        getInsights: sl<GetInsights>(),
        clearUsageHistory: sl<ClearUsageHistory>(),
      ),
    );
  }

  // Ingredients Use Cases
  if (!sl.isRegistered<GetActiveIngredients>()) {
    sl.registerLazySingleton<GetActiveIngredients>(
      () => GetActiveIngredients(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<AddIngredient>()) {
    sl.registerLazySingleton<AddIngredient>(
      () => AddIngredient(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<AddIngredients>()) {
    sl.registerLazySingleton<AddIngredients>(
      () => AddIngredients(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<UpdateIngredient>()) {
    sl.registerLazySingleton<UpdateIngredient>(
      () => UpdateIngredient(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<DeleteIngredient>()) {
    sl.registerLazySingleton<DeleteIngredient>(
      () => DeleteIngredient(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<MarkIngredientUsed>()) {
    sl.registerLazySingleton<MarkIngredientUsed>(
      () => MarkIngredientUsed(
        sl<IngredientRepository>(),
        sl.isRegistered<UsageLogRepository>() ? sl<UsageLogRepository>() : null,
      ),
    );
  }
  if (!sl.isRegistered<MarkIngredientDiscarded>()) {
    sl.registerLazySingleton<MarkIngredientDiscarded>(
      () => MarkIngredientDiscarded(
        sl<IngredientRepository>(),
        sl.isRegistered<UsageLogRepository>() ? sl<UsageLogRepository>() : null,
      ),
    );
  }
  if (!sl.isRegistered<ResolveExpiryPhrase>()) {
    sl.registerLazySingleton<ResolveExpiryPhrase>(
      ResolveExpiryPhrase.new,
    );
  }

  // Inventory Cubit
  if (!sl.isRegistered<InventoryCubit>()) {
    sl.registerFactory<InventoryCubit>(
      () => InventoryCubit(
        getActiveIngredients: sl<GetActiveIngredients>(),
        addIngredient: sl<AddIngredient>(),
        addIngredients: sl<AddIngredients>(),
        updateIngredient: sl<UpdateIngredient>(),
        deleteIngredient: sl<DeleteIngredient>(),
        markIngredientUsed: sl<MarkIngredientUsed>(),
        markIngredientDiscarded: sl<MarkIngredientDiscarded>(),
        syncExpiryAlerts: sl.isRegistered<SyncExpiryAlerts>() ? sl<SyncExpiryAlerts>() : null,
      ),
    );
  }

  // HTTP Client
  if (!sl.isRegistered<http.Client>()) {
    sl.registerLazySingleton<http.Client>(() => httpClient ?? http.Client());
  }

  // Connectivity
  if (!sl.isRegistered<ConnectivityService>()) {
    sl.registerLazySingleton<ConnectivityService>(
      () => connectivityService ?? ConnectivityServiceImpl(),
    );
  }

  // Speech Repository
  if (!sl.isRegistered<SpeechRepository>()) {
    sl.registerLazySingleton<SpeechRepository>(
      () => speechRepository ?? SpeechRepositoryImpl(),
    );
  }

  // Gemini Remote Data Source
  if (!sl.isRegistered<GeminiRemoteDataSource>()) {
    sl.registerLazySingleton<GeminiRemoteDataSource>(
      () => GeminiRemoteDataSourceImpl(
        config: sl<AppConfig>(),
        client: sl<http.Client>(),
      ),
    );
  }

  // Ingredient Extraction Repository
  if (!sl.isRegistered<IngredientExtractionRepository>()) {
    sl.registerLazySingleton<IngredientExtractionRepository>(
      () => IngredientExtractionRepositoryImpl(
        remoteDataSource: sl<GeminiRemoteDataSource>(),
        connectivityService: sl<ConnectivityService>(),
        config: sl<AppConfig>(),
      ),
    );
  }

  // Voice Input Use Cases
  if (!sl.isRegistered<ExtractIngredientsFromTranscript>()) {
    sl.registerLazySingleton<ExtractIngredientsFromTranscript>(
      () => ExtractIngredientsFromTranscript(
        sl<IngredientExtractionRepository>(),
      ),
    );
  }
  if (!sl.isRegistered<ApplyVoiceCorrection>()) {
    sl.registerLazySingleton<ApplyVoiceCorrection>(
      ApplyVoiceCorrection.new,
    );
  }
  if (!sl.isRegistered<ConfirmIngredients>()) {
    sl.registerLazySingleton<ConfirmIngredients>(
      () => ConfirmIngredients(
        sl<AddIngredients>(),
      ),
    );
  }

  // Voice Input Bloc
  if (!sl.isRegistered<VoiceInputBloc>()) {
    sl.registerFactory<VoiceInputBloc>(
      () => VoiceInputBloc(
        speechRepository: sl<SpeechRepository>(),
        extractIngredients: sl<ExtractIngredientsFromTranscript>(),
        applyVoiceCorrection: sl<ApplyVoiceCorrection>(),
        confirmIngredients: sl<ConfirmIngredients>(),
      ),
    );
  }

  // Preferences Local Data Source
  if (!sl.isRegistered<PreferencesLocalDataSource>()) {
    sl.registerLazySingleton<PreferencesLocalDataSource>(
      () => PreferencesLocalDataSourceImpl(sl<Box<String>>()),
    );
  }

  // Gemini Recipe Data Source
  if (!sl.isRegistered<GeminiRecipeDataSource>()) {
    sl.registerLazySingleton<GeminiRecipeDataSource>(
      () =>
          geminiRecipeDataSource ??
          GeminiRecipeDataSourceImpl(
            config: sl<AppConfig>(),
            client: sl<http.Client>(),
          ),
    );
  }

  // Recipe Repository
  if (!sl.isRegistered<RecipeRepository>()) {
    sl.registerLazySingleton<RecipeRepository>(
      () =>
          recipeRepository ??
          RecipeRepositoryImpl(
            remoteDataSource: sl<GeminiRecipeDataSource>(),
            preferencesLocalDataSource: sl<PreferencesLocalDataSource>(),
            connectivityService: sl<ConnectivityService>(),
            config: sl<AppConfig>(),
          ),
    );
  }

  // Recipe Use Cases
  if (!sl.isRegistered<GenerateRecipes>()) {
    sl.registerLazySingleton<GenerateRecipes>(
      () => GenerateRecipes(
        ingredientRepository: sl<IngredientRepository>(),
        recipeRepository: sl<RecipeRepository>(),
      ),
    );
  }
  if (!sl.isRegistered<RankRecipes>()) {
    sl.registerLazySingleton<RankRecipes>(
      RankRecipes.new,
    );
  }
  if (!sl.isRegistered<GetRecipeById>()) {
    sl.registerLazySingleton<GetRecipeById>(
      GetRecipeById.new,
    );
  }
  if (!sl.isRegistered<GetDietPreference>()) {
    sl.registerLazySingleton<GetDietPreference>(
      () => GetDietPreference(sl<RecipeRepository>()),
    );
  }
  if (!sl.isRegistered<UpdateDietPreference>()) {
    sl.registerLazySingleton<UpdateDietPreference>(
      () => UpdateDietPreference(sl<RecipeRepository>()),
    );
  }

  // Saved Recipe Repository & Dish Image Resolver
  if (!sl.isRegistered<SavedRecipeRepository>()) {
    sl.registerLazySingleton<SavedRecipeRepository>(
      () => SavedRecipeRepository(
        savedRecipesBox: Hive.isBoxOpen('saved_recipes')
            ? Hive.box<String>('saved_recipes')
            : preferencesBox ?? Hive.box<String>('preferences'),
        cacheBox: Hive.isBoxOpen('recipe_cache')
            ? Hive.box<String>('recipe_cache')
            : preferencesBox ?? Hive.box<String>('preferences'),
      ),
    );
  }

  if (!sl.isRegistered<DishImageResolver>()) {
    sl.registerLazySingleton<DishImageResolver>(
      () => DishImageResolver(
        client: sl<http.Client>(),
        cacheBox: Hive.isBoxOpen('recipe_cache') ? Hive.box<String>('recipe_cache') : null,
      ),
    );
  }

  // Recipes Bloc
  if (!sl.isRegistered<RecipesBloc>()) {
    sl.registerFactory<RecipesBloc>(
      () => RecipesBloc(
        generateRecipes: sl<GenerateRecipes>(),
        updateDietPreference: sl<UpdateDietPreference>(),
        savedRecipeRepository: sl<SavedRecipeRepository>(),
      ),
    );
  }

  // Phase 5: TTS Service
  if (!sl.isRegistered<TtsService>()) {
    sl.registerLazySingleton<TtsService>(
      () => ttsService ?? FlutterTtsServiceImpl(),
    );
  }

  // Phase 5: Voice Session Controller
  if (!sl.isRegistered<VoiceSessionController>()) {
    sl.registerFactory<VoiceSessionController>(
      () =>
          voiceSessionController ??
          VoiceSessionControllerImpl(
            ttsService: sl<TtsService>(),
            speechRepository: sl<SpeechRepository>(),
          ),
    );
  }

  // Phase 5: Cooking Use Cases
  if (!sl.isRegistered<StartCooking>()) {
    sl.registerLazySingleton<StartCooking>(StartCooking.new);
  }
  if (!sl.isRegistered<NavigateStep>()) {
    sl.registerLazySingleton<NavigateStep>(NavigateStep.new);
  }
  if (!sl.isRegistered<ComputeInventoryDeduction>()) {
    sl.registerLazySingleton<ComputeInventoryDeduction>(
      () => ComputeInventoryDeduction(sl<IngredientRepository>()),
    );
  }
  if (!sl.isRegistered<FinishCooking>()) {
    sl.registerLazySingleton<FinishCooking>(
      () => FinishCooking(
        sl<IngredientRepository>(),
        sl<UsageLogRepository>(),
      ),
    );
  }
  if (!sl.isRegistered<GetSpeechRate>()) {
    sl.registerLazySingleton<GetSpeechRate>(GetSpeechRate.new);
  }

  // Phase 5: Cooking Bloc
  if (!sl.isRegistered<CookingBloc>()) {
    sl.registerFactory<CookingBloc>(
      () => CookingBloc(
        startCooking: sl<StartCooking>(),
        navigateStep: sl<NavigateStep>(),
        computeInventoryDeduction: sl<ComputeInventoryDeduction>(),
        finishCooking: sl<FinishCooking>(),
        voiceController: sl<VoiceSessionController>(),
      ),
    );
  }
}
