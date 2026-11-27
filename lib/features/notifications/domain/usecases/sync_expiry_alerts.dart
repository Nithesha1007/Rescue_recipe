import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/repositories/ingredient_repository.dart';
import '../../../settings/domain/repositories/settings_repository.dart';
import '../services/notification_scheduler.dart';
import '../utils/expiry_alert_planner.dart';

class SyncExpiryAlerts implements UseCase<void, NoParams> {
  final IngredientRepository _ingredientRepository;
  final SettingsRepository _settingsRepository;
  final NotificationScheduler _scheduler;

  SyncExpiryAlerts({
    required IngredientRepository ingredientRepository,
    required SettingsRepository settingsRepository,
    required NotificationScheduler scheduler,
  })  : _ingredientRepository = ingredientRepository,
        _settingsRepository = settingsRepository,
        _scheduler = scheduler;

  @override
  FutureEither<void> call(NoParams params) async {
    try {
      final ingredientsResult = await _ingredientRepository.getActiveIngredients();
      final settingsResult = await _settingsRepository.getPreferences();

      if (ingredientsResult.isLeft() || settingsResult.isLeft()) {
        return const Right(null);
      }

      final ingredients = ingredientsResult.getOrElse((_) => []);
      final settings = settingsResult.getOrElse((_) => throw Exception());

      final alerts = ExpiryAlertPlanner.plan(
        ingredients: ingredients,
        now: DateTime.now(),
        settings: settings,
      );

      // Cancel all existing scheduled alerts and schedule fresh list (idempotent)
      await _scheduler.cancelAllAlerts();
      await _scheduler.scheduleAlerts(alerts);

      return const Right(null);
    } catch (_) {
      // Non-blocking: Notification scheduling errors never break user actions
      return const Right(null);
    }
  }
}
