import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../services/notification_scheduler.dart';

class RequestNotificationPermission implements UseCase<bool, NoParams> {
  final NotificationScheduler _scheduler;

  RequestNotificationPermission(this._scheduler);

  @override
  FutureEither<bool> call(NoParams params) async {
    final granted = await _scheduler.requestPermission();
    return Right(granted);
  }
}
