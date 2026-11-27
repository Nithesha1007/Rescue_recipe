import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';

void main() {
  group('UsageLogEntry', () {
    test('wasRescued is true for used Critical, High, or Medium priority items', () {
      final entryCritical = UsageLogEntry(
        id: '1',
        ingredientName: 'Milk',
        quantity: 500,
        unit: 'ml',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.critical,
        timestamp: DateTime(2026, 11, 26),
      );
      expect(entryCritical.wasRescued, isTrue);

      final entryHigh = UsageLogEntry(
        id: '2',
        ingredientName: 'Apples',
        quantity: 3,
        unit: 'items',
        action: UsageAction.reduced,
        priorityAtUsage: ExpiryPriority.high,
        timestamp: DateTime(2026, 11, 26),
      );
      expect(entryHigh.wasRescued, isTrue);

      final entryMedium = UsageLogEntry(
        id: '3',
        ingredientName: 'Cheese',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.medium,
        timestamp: DateTime(2026, 11, 26),
      );
      expect(entryMedium.wasRescued, isTrue);
    });

    test('wasRescued is false for Low priority or discarded items', () {
      final entryLow = UsageLogEntry(
        id: '4',
        ingredientName: 'Rice',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.low,
        timestamp: DateTime(2026, 11, 26),
      );
      expect(entryLow.wasRescued, isFalse);

      final entryDiscarded = UsageLogEntry(
        id: '5',
        ingredientName: 'Old Bread',
        action: UsageAction.discarded,
        priorityAtUsage: ExpiryPriority.critical,
        timestamp: DateTime(2026, 11, 26),
      );
      expect(entryDiscarded.wasRescued, isFalse);
    });
  });
}
