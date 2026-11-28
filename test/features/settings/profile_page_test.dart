import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:get_it/get_it.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/models/ai_status.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/cooking/data/services/tts_service.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/notifications/domain/entities/planned_alert.dart';
import 'package:rescue_recipe/features/notifications/domain/services/notification_scheduler.dart';
import 'package:rescue_recipe/features/notifications/domain/usecases/request_notification_permission.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/clear_all_data.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/get_settings.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/update_settings.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:rescue_recipe/features/settings/presentation/pages/profile_page.dart';
import 'package:rescue_recipe/features/voice/data/datasources/gemini_remote_datasource.dart';
import 'package:rescue_recipe/features/voice/domain/entities/audio_extraction_result.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';

class _FakeTtsService implements TtsService {
  @override
  Future<void> init() async {}
  @override
  Future<void> speak(String text) async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> setSpeechRate(double rate) async {}
  @override
  Future<void> setVolume(double volume) async {}
  @override
  Future<void> setPitch(double pitch) async {}
  @override
  void setCompletionHandler(void Function() handler) {}
  @override
  void setErrorHandler(void Function(dynamic msg) handler) {}
  @override
  Future<bool> openVoiceSettings() async => true;
  @override
  String? get currentLanguage => 'en-IN';
  @override
  bool get isAvailable => true;
  @override
  String? get lastError => null;
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

class MockSettingsRepository implements SettingsRepository {
  UserPreferences preferences = const UserPreferences();

  @override
  FutureEither<UserPreferences> getPreferences() async => Right(preferences);

  @override
  FutureEither<void> savePreferences(UserPreferences prefs) async {
    preferences = prefs;
    return const Right(null);
  }

  @override
  FutureEither<void> clearAllData() async {
    preferences = const UserPreferences();
    return const Right(null);
  }
}

class MockNotificationScheduler implements NotificationScheduler {
  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {}

  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  FutureEither<void> scheduleAlerts(List<PlannedAlert> alerts) async =>
      const Right(null);

  @override
  FutureEither<void> cancelAlert(int alertId) async => const Right(null);

  @override
  FutureEither<void> cancelAllAlerts() async => const Right(null);
}

class _DummyIngredientRepository implements IngredientRepository {
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
  FutureEither<void> updateIngredient(Ingredient ingredient) async => const Right(null);
  @override
  FutureEither<void> deleteIngredient(String id) async => const Right(null);
  @override
  FutureEither<void> markUsed(String id) async => const Right(null);
  @override
  FutureEither<void> markDiscarded(String id) async => const Right(null);
}

void main() {
  late MockSettingsRepository settingsRepo;
  late MockNotificationScheduler scheduler;

  setUp(() {
    final sl = GetIt.instance;
    if (!sl.isRegistered<TtsService>()) {
      sl.registerSingleton<TtsService>(_FakeTtsService());
    }
    if (!sl.isRegistered<GeminiRemoteDataSource>()) {
      sl.registerSingleton<GeminiRemoteDataSource>(_FakeGeminiRemoteDataSource());
    }

    settingsRepo = MockSettingsRepository();
    scheduler = MockNotificationScheduler();
  });

  Widget buildTestWidget() {
    return MaterialApp(
      theme: AppTheme.light(),
      home: BlocProvider<SettingsCubit>(
        create: (_) => SettingsCubit(
          getSettings: GetSettings(settingsRepo),
          updateSettings: UpdateSettings(settingsRepo),
          clearAllData: ClearAllData(
            settingsRepository: settingsRepo,
            ingredientRepository: _DummyIngredientRepository(),
            notificationScheduler: scheduler,
          ),
          requestNotificationPermission: RequestNotificationPermission(scheduler),
        )..loadSettings(),
        child: const ProfilePage(),
      ),
    );
  }

  testWidgets('renders all preference sections and disclaimers', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Diet & Cuisine Preferences'), findsOneWidget);
    expect(find.text('Speech & Voice Assistant'), findsOneWidget);
    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('Appearance'), findsOneWidget);
    expect(find.text('Data & Storage'), findsOneWidget);
    expect(find.text('Clear All My Data'), findsOneWidget);
  });

  testWidgets('renders cleanly at 320dp width without overflow', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
