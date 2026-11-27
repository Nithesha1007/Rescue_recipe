import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/notifications/domain/utils/expiry_alert_planner.dart';

void main() {
  test('Generated notification texts never claim food is safe or fresh enough', () {
    final ingredients = [
      Ingredient(
        id: '1',
        name: 'Milk',
        expiryDate: DateTime(2026, 12, 1),
        addedAt: DateTime(2026, 11, 26),
      ),
      Ingredient(
        id: '2',
        name: 'Chicken',
        expiryDate: DateTime(2026, 11, 28),
        addedAt: DateTime(2026, 11, 26),
      ),
    ];

    final alerts = ExpiryAlertPlanner.planAlerts(
      ingredients: ingredients,
      now: DateTime(2026, 11, 26, 6, 0),
    );

    for (final alert in alerts) {
      final combinedText = '${alert.title} ${alert.body}'.toLowerCase();

      expect(combinedText.contains('safe'), isFalse,
          reason: 'Alert "${alert.body}" must not contain "safe"');
      expect(combinedText.contains('fresh enough'), isFalse,
          reason: 'Alert "${alert.body}" must not contain "fresh enough"');
      expect(combinedText.contains('okay to eat'), isFalse,
          reason: 'Alert "${alert.body}" must not contain "okay to eat"');
      expect(combinedText.contains('good to eat'), isFalse,
          reason: 'Alert "${alert.body}" must not contain "good to eat"');

      // Verify that the cautious guidance is present
      expect(combinedText.contains('check') || combinedText.contains('smell'),
          isTrue,
          reason: 'Alert should prompt user to check or inspect food');
    }
  });
}
