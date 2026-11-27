import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../services/notification_scheduler.dart';

class CancelAlertsForIngredient implements UseCase<void, int> {
  final NotificationScheduler _scheduler;

  CancelAlertsForIngredient(this._scheduler);

  @override
  FutureEither<void> call(int alertId) {
    return _scheduler.cancelAlert(alertId);
  }
}
