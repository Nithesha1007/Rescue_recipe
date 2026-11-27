import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:fpdart/fpdart.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import '../../../../core/error/failures.dart';
import '../../domain/entities/planned_alert.dart';
import '../../domain/services/notification_scheduler.dart';

class LocalNotificationScheduler implements NotificationScheduler {
  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  LocalNotificationScheduler([FlutterLocalNotificationsPlugin? plugin])
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  static const String channelId = 'expiry_alerts_channel';
  static const String channelName = 'Expiry Alerts';
  static const String channelDescription =
      'Notifications reminding you to use food before it expires';

  @override
  Future<void> init({void Function(String? payload)? onSelectNotification}) async {
    if (_initialized) return;

    tz.initializeTimeZones();
    try {
      final String timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      // Fallback to UTC if timezone query fails
    }

    const androidSettings = AndroidInitializationSettings('ic_notification');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (onSelectNotification != null) {
          onSelectNotification(response.payload);
        }
      },
    );

    _initialized = true;
  }

  @override
  Future<bool> checkPermission() async {
    final status = await Permission.notification.status;
    return status.isGranted;
  }

  @override
  Future<bool> requestPermission() async {
    final androidImpl = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (androidImpl != null) {
      final granted = await androidImpl.requestNotificationsPermission();
      if (granted != null) return granted;
    }
    final status = await Permission.notification.request();
    return status.isGranted;
  }

  @override
  FutureEither<void> scheduleAlerts(List<PlannedAlert> alerts) async {
    if (!_initialized) await init();

    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: 'ic_notification',
      );
      const details = NotificationDetails(android: androidDetails);

      for (final alert in alerts) {
        final tzScheduled = tz.TZDateTime.from(alert.scheduledTime, tz.local);
        await _plugin.zonedSchedule(
          alert.id,
          alert.title,
          alert.body,
          tzScheduled,
          details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: alert.payload,
        );
      }

      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to schedule alerts: $e'));
    }
  }

  @override
  FutureEither<void> cancelAlert(int alertId) async {
    if (!_initialized) await init();
    try {
      await _plugin.cancel(alertId);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to cancel alert: $e'));
    }
  }

  @override
  FutureEither<void> cancelAllAlerts() async {
    if (!_initialized) await init();
    try {
      await _plugin.cancelAll();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to cancel all alerts: $e'));
    }
  }
}
