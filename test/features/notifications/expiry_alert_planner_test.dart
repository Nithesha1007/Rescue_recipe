import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/notifications/domain/utils/expiry_alert_planner.dart';

void main() {
  final now = DateTime(2026, 11, 26, 7, 0); // 7:00 AM on Nov 26

  group('ExpiryAlertPlanner', () {
    test('plans tomorrow and today alerts for upcoming item', () {
      final ingredient = Ingredient(
        id: 'item_1',
        name: 'Milk',
        expiryDate: DateTime(2026, 11, 28), // 2 days away
        addedAt: now,
      );

      final alerts = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: now,
        notifyDayBefore: true,
        notifyOnDay: true,
        notificationHour: 8,
        notificationMinute: 0,
      );

      // Should schedule:
      // 1. Day before: Nov 27 at 8:00 AM
      // 2. On day: Nov 28 at 8:00 AM
      expect(alerts.length, equals(2));
      expect(alerts[0].scheduledTime, equals(DateTime(2026, 11, 27, 8, 0)));
      expect(alerts[1].scheduledTime, equals(DateTime(2026, 11, 28, 8, 0)));
    });

    test('skips alerts scheduled in the past', () {
      final lateNow = DateTime(2026, 11, 26, 10, 0);
      final ingredient = Ingredient(
        id: 'item_today',
        name: 'Bread',
        expiryDate: DateTime(2026, 11, 26), // Expires today
        addedAt: lateNow,
      );

      final alerts = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: lateNow,
        notificationHour: 8,
        notificationMinute: 0,
      );

      expect(alerts.isEmpty, isTrue);
    });

    test('skips items without expiry date or marked used/discarded', () {
      final noDate = Ingredient(
        id: 'no_date',
        name: 'Salt',
        expiryDate: null,
        addedAt: now,
      );
      final usedItem = Ingredient(
        id: 'used',
        name: 'Eggs',
        expiryDate: DateTime(2026, 11, 28),
        addedAt: now,
        status: IngredientStatus.used,
      );
      final discardedItem = Ingredient(
        id: 'discarded',
        name: 'Yogurt',
        expiryDate: DateTime(2026, 11, 28),
        addedAt: now,
        status: IngredientStatus.discarded,
      );

      final alerts = ExpiryAlertPlanner.planAlerts(
        ingredients: [noDate, usedItem, discardedItem],
        now: now,
      );

      expect(alerts.isEmpty, isTrue);
    });

    test('respects notifyDayBefore and notifyOnDay switches', () {
      final ingredient = Ingredient(
        id: 'item_1',
        name: 'Cheese',
        expiryDate: DateTime(2026, 11, 28),
        addedAt: now,
      );

      final alertsOnlyOnDay = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: now,
        notifyDayBefore: false,
        notifyOnDay: true,
      );
      expect(alertsOnlyOnDay.length, equals(1));
      expect(alertsOnlyOnDay.first.scheduledTime.day, equals(28));

      final alertsOnlyDayBefore = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: now,
        notifyDayBefore: true,
        notifyOnDay: false,
      );
      expect(alertsOnlyDayBefore.length, equals(1));
      expect(alertsOnlyDayBefore.first.scheduledTime.day, equals(27));
    });

    test('caps scheduled alerts at 50 soonest first', () {
      final ingredients = List.generate(
        60,
        (i) => Ingredient(
          id: 'item_$i',
          name: 'Item $i',
          expiryDate: DateTime(2026, 11, 27).add(Duration(days: i)),
          addedAt: now,
        ),
      );

      final alerts = ExpiryAlertPlanner.planAlerts(
        ingredients: ingredients,
        now: now,
      );

      expect(alerts.length, lessThanOrEqualTo(50));
    });

    test('generates stable int IDs', () {
      final ingredient = Ingredient(
        id: 'stable_id',
        name: 'Apples',
        expiryDate: DateTime(2026, 11, 28),
        addedAt: now,
      );

      final alerts1 = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: now,
      );
      final alerts2 = ExpiryAlertPlanner.planAlerts(
        ingredients: [ingredient],
        now: now,
      );

      expect(alerts1[0].id, equals(alerts2[0].id));
      expect(alerts1[1].id, equals(alerts2[1].id));
    });
  });
}
