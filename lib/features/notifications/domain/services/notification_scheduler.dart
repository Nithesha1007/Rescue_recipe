import '../../../../core/error/failures.dart';
import '../entities/planned_alert.dart';

abstract class NotificationScheduler {
  Future<void> init({void Function(String? payload)? onSelectNotification});
  Future<bool> checkPermission();
  Future<bool> requestPermission();
  FutureEither<void> scheduleAlerts(List<PlannedAlert> alerts);
  FutureEither<void> cancelAlert(int alertId);
  FutureEither<void> cancelAllAlerts();
}
