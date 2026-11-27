import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/delete_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/get_active_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_used.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/update_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'package:rescue_recipe/features/notifications/domain/entities/planned_alert.dart';
import 'package:rescue_recipe/features/notifications/domain/services/notification_scheduler.dart';
import 'package:rescue_recipe/features/notifications/domain/usecases/sync_expiry_alerts.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';

class MockIngredientRepository implements IngredientRepository {
  final List<Ingredient> items = [];

  @override
  Stream<List<Ingredient>> watchActiveIngredients() => Stream.value(items);

  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async =>
      Right(items.where((i) => i.status == IngredientStatus.active).toList());

  @override
  FutureEither<Ingredient?> getIngredientById(String id) async {
    final matched = items.where((i) => i.id == id).toList();
    return Right(matched.isEmpty ? null : matched.first);
  }

  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async {
    items.add(ingredient);
    return const Right(null);
  }

  @override
  FutureEither<void> addIngredients(List<Ingredient> newItems) async {
    items.addAll(newItems);
    return const Right(null);
  }

  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async {
    final idx = items.indexWhere((i) => i.id == ingredient.id);
    if (idx != -1) items[idx] = ingredient;
    return const Right(null);
  }

  @override
  FutureEither<void> deleteIngredient(String id) async {
    items.removeWhere((i) => i.id == id);
    return const Right(null);
  }

  @override
  FutureEither<void> markUsed(String id) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items[idx] = Ingredient(
        id: items[idx].id,
        name: items[idx].name,
        quantity: items[idx].quantity,
        unit: items[idx].unit,
        expiryDate: items[idx].expiryDate,
        addedAt: items[idx].addedAt,
        status: IngredientStatus.used,
      );
    }
    return const Right(null);
  }

  @override
  FutureEither<void> markDiscarded(String id) async {
    final idx = items.indexWhere((i) => i.id == id);
    if (idx != -1) {
      items[idx] = Ingredient(
        id: items[idx].id,
        name: items[idx].name,
        quantity: items[idx].quantity,
        unit: items[idx].unit,
        expiryDate: items[idx].expiryDate,
        addedAt: items[idx].addedAt,
        status: IngredientStatus.discarded,
      );
    }
    return const Right(null);
  }
}

class MockSettingsRepo implements SettingsRepository {
  @override
  FutureEither<UserPreferences> getPreferences() async =>
      const Right(UserPreferences());

  @override
  FutureEither<void> savePreferences(UserPreferences prefs) async =>
      const Right(null);

  @override
  FutureEither<void> clearAllData() async => const Right(null);
}

class MockNotificationScheduler implements NotificationScheduler {
  int scheduleCount = 0;

  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {}

  @override
  Future<bool> checkPermission() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  FutureEither<void> scheduleAlerts(List<PlannedAlert> alerts) async {
    scheduleCount++;
    return const Right(null);
  }

  @override
  FutureEither<void> cancelAlert(int alertId) async => const Right(null);

  @override
  FutureEither<void> cancelAllAlerts() async => const Right(null);
}

void main() {
  late MockIngredientRepository ingredientRepo;
  late MockSettingsRepo settingsRepo;
  late MockNotificationScheduler scheduler;
  late SyncExpiryAlerts syncExpiryAlerts;
  late InventoryCubit cubit;

  setUp(() {
    ingredientRepo = MockIngredientRepository();
    settingsRepo = MockSettingsRepo();
    scheduler = MockNotificationScheduler();

    syncExpiryAlerts = SyncExpiryAlerts(
      ingredientRepository: ingredientRepo,
      settingsRepository: settingsRepo,
      scheduler: scheduler,
    );

    cubit = InventoryCubit(
      getActiveIngredients: GetActiveIngredients(ingredientRepo),
      addIngredient: AddIngredient(ingredientRepo),
      addIngredients: AddIngredients(ingredientRepo),
      updateIngredient: UpdateIngredient(ingredientRepo),
      deleteIngredient: DeleteIngredient(ingredientRepo),
      markIngredientUsed: MarkIngredientUsed(ingredientRepo),
      markIngredientDiscarded: MarkIngredientDiscarded(ingredientRepo),
      syncExpiryAlerts: syncExpiryAlerts,
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('adding ingredient triggers syncExpiryAlerts', () async {
    final item = Ingredient(
      id: '1',
      name: 'Milk',
      expiryDate: DateTime(2026, 12, 1),
      addedAt: DateTime(2026, 11, 26),
    );

    await cubit.add(item);
    expect(scheduler.scheduleCount, equals(1));
  });

  test('deleting ingredient triggers syncExpiryAlerts', () async {
    final item = Ingredient(
      id: '1',
      name: 'Milk',
      expiryDate: DateTime(2026, 12, 1),
      addedAt: DateTime(2026, 11, 26),
    );
    await cubit.add(item);
    expect(scheduler.scheduleCount, equals(1));

    await cubit.delete('1');
    expect(scheduler.scheduleCount, equals(2));
  });
}
