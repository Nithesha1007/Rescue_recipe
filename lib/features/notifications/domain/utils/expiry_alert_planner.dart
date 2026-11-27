import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../entities/planned_alert.dart';

class ExpiryAlertPlanner {
  /// Plans notification alerts for active ingredients.
  /// Strict safety rules:
  /// - Only active items with an expiryDate.
  /// - "Tomorrow" alert scheduled at (expiry minus 1 day) at chosen time.
  /// - "Today" alert scheduled on expiry day at chosen time.
  /// - Skip past times.
  /// - Skip used, discarded, deleted, or dateless items.
  /// - Cap at 50 alerts soonest first.
  /// - Never claim food is safe or fresh.
  static List<PlannedAlert> plan({
    required List<Ingredient> ingredients,
    required DateTime now,
    UserPreferences? settings,
    bool? notifyDayBefore,
    bool? notifyOnDay,
    int? notificationHour,
    int? notificationMinute,
  }) {
    final prefs = settings ?? const UserPreferences();
    final notificationsEnabled = prefs.notificationsEnabled;
    if (!notificationsEnabled) {
      return const [];
    }

    final dayBeforeEnabled = notifyDayBefore ?? prefs.notifyDayBefore;
    final onDayEnabled = notifyOnDay ?? prefs.notifyOnExpiryDay;
    final hour = notificationHour ?? prefs.notifyHour;
    final minute = notificationMinute ?? prefs.notifyMinute;

    final alerts = <PlannedAlert>[];

    // Filter to active ingredients with an expiryDate
    final activeDated = ingredients.where(
      (i) => i.status == IngredientStatus.active && i.expiryDate != null,
    );

    for (final item in activeDated) {
      final expiry = item.expiryDate!;

      // 1. Day before alert (if enabled)
      if (dayBeforeEnabled) {
        final dayBeforeDate = expiry.subtract(const Duration(days: 1));
        final scheduledTime = DateTime(
          dayBeforeDate.year,
          dayBeforeDate.month,
          dayBeforeDate.day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(now)) {
          alerts.add(PlannedAlert(
            id: _generateId(item.id, AlertType.dayBefore),
            ingredientId: item.id,
            ingredientName: item.displayName,
            alertType: AlertType.dayBefore,
            scheduledTime: scheduledTime,
            title: '${item.displayName} expires tomorrow',
            body:
                'Cook it soon with a rescue recipe. Check it looks and smells fine before using.',
            payload: 'tab:kitchen',
          ));
        }
      }

      // 2. On expiry day alert (if enabled)
      if (onDayEnabled) {
        final scheduledTime = DateTime(
          expiry.year,
          expiry.month,
          expiry.day,
          hour,
          minute,
        );

        if (scheduledTime.isAfter(now)) {
          alerts.add(PlannedAlert(
            id: _generateId(item.id, AlertType.onDay),
            ingredientId: item.id,
            ingredientName: item.displayName,
            alertType: AlertType.onDay,
            scheduledTime: scheduledTime,
            title: '${item.displayName} expires today',
            body:
                'Use it today with a rescue recipe. Check it looks and smells fine before using.',
            payload: 'tab:kitchen',
          ));
        }
      }
    }

    // Sort soonest first
    alerts.sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    // Cap at 50 pending alerts
    if (alerts.length > 50) {
      return alerts.sublist(0, 50);
    }

    return alerts;
  }

  /// Alias for plan with optional parameters for tests
  static List<PlannedAlert> planAlerts({
    required List<Ingredient> ingredients,
    required DateTime now,
    UserPreferences? settings,
    bool notifyDayBefore = true,
    bool notifyOnDay = true,
    int notificationHour = 8,
    int notificationMinute = 0,
  }) {
    return plan(
      ingredients: ingredients,
      now: now,
      settings: settings ??
          UserPreferences(
            notifyDayBefore: notifyDayBefore,
            notifyOnExpiryDay: notifyOnDay,
            notifyHour: notificationHour,
            notifyMinute: notificationMinute,
          ),
      notifyDayBefore: notifyDayBefore,
      notifyOnDay: notifyOnDay,
      notificationHour: notificationHour,
      notificationMinute: notificationMinute,
    );
  }

  /// Generates a stable positive 31-bit integer ID from ingredient ID string + alert type.
  static int _generateId(String ingredientId, AlertType type) {
    int hash = 17;
    for (int i = 0; i < ingredientId.length; i++) {
      hash = (37 * hash + ingredientId.codeUnitAt(i)) & 0x7FFFFFFF;
    }
    hash = (37 * hash + (type == AlertType.dayBefore ? 1 : 2)) & 0x7FFFFFFF;
    return hash;
  }
}
