import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/notifications/domain/entities/planned_alert.dart';
import 'package:rescue_recipe/features/notifications/domain/services/notification_scheduler.dart';
import 'package:rescue_recipe/features/notifications/domain/usecases/request_notification_permission.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/clear_all_data.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/get_settings.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/update_settings.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_state.dart';

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
  bool permissionGranted = true;

  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {}

  @override
  Future<bool> checkPermission() async => permissionGranted;

  @override
  Future<bool> requestPermission() async => permissionGranted;

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
  late SettingsCubit cubit;

  setUp(() {
    settingsRepo = MockSettingsRepository();
    scheduler = MockNotificationScheduler();

    cubit = SettingsCubit(
      getSettings: GetSettings(settingsRepo),
      updateSettings: UpdateSettings(settingsRepo),
      clearAllData: ClearAllData(
        settingsRepository: settingsRepo,
        ingredientRepository: _DummyIngredientRepository(),
        notificationScheduler: scheduler,
      ),
      requestNotificationPermission: RequestNotificationPermission(scheduler),
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('loadSettings() emits SettingsStatus.loaded with preferences', () async {
    await cubit.loadSettings();
    expect(cubit.state.status, equals(SettingsStatus.loaded));
    expect(cubit.state.preferences.diet, equals(DietTag.none));
  });

  test('updateDiet() saves and updates state', () async {
    await cubit.loadSettings();
    await cubit.updateDiet(DietTag.vegetarian);

    expect(cubit.state.status, equals(SettingsStatus.loaded));
    expect(cubit.state.preferences.diet, equals(DietTag.vegetarian));
    expect(settingsRepo.preferences.diet, equals(DietTag.vegetarian));
  });

  test('updateThemeMode() updates theme preference', () async {
    await cubit.loadSettings();
    await cubit.updateThemeMode(ThemeMode.dark);

    expect(cubit.state.status, equals(SettingsStatus.loaded));
    expect(cubit.state.preferences.themeMode, equals(ThemeMode.dark));
  });

  test('clearAll() resets to default preferences', () async {
    await cubit.loadSettings();
    await cubit.updateDiet(DietTag.vegan);
    await cubit.clearAll();

    expect(cubit.state.status, equals(SettingsStatus.loaded));
    expect(cubit.state.preferences.diet, equals(DietTag.none));
  });
}
