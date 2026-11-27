import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cooking/domain/repositories/usage_log_repository.dart';
import '../../../ingredients/domain/repositories/ingredient_repository.dart';
import '../../../notifications/domain/services/notification_scheduler.dart';
import '../repositories/settings_repository.dart';

class ClearAllData implements UseCase<void, NoParams> {
  final IngredientRepository _ingredientRepository;
  final SettingsRepository _settingsRepository;
  final UsageLogRepository? _usageLogRepository;
  final NotificationScheduler? _notificationScheduler;

  ClearAllData({
    required IngredientRepository ingredientRepository,
    required SettingsRepository settingsRepository,
    UsageLogRepository? usageLogRepository,
    NotificationScheduler? notificationScheduler,
  })  : _ingredientRepository = ingredientRepository,
        _settingsRepository = settingsRepository,
        _usageLogRepository = usageLogRepository,
        _notificationScheduler = notificationScheduler;

  @override
  FutureEither<void> call(NoParams params) async {
    // Delete all ingredients
    final ingredientsResult = await _ingredientRepository.getActiveIngredients();
    if (ingredientsResult.isRight()) {
      final items = ingredientsResult.getOrElse((_) => []);
      for (final item in items) {
        await _ingredientRepository.deleteIngredient(item.id);
      }
    }

    // Reset settings
    await _settingsRepository.clearAllData();

    // Clear usage history if available
    if (_usageLogRepository != null) {
      await _usageLogRepository.clearHistory();
    }

    // Cancel all notifications if available
    if (_notificationScheduler != null) {
      await _notificationScheduler.cancelAllAlerts();
    }

    return const Right(null);
  }
}
