import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/insights/domain/utils/insights_calculator.dart';

void main() {
  final testToday = DateTime(2026, 11, 26, 12, 0);

  group('InsightsCalculator Counts and Rescued Definition', () {
    test('computes used, discarded, and rescued counts correctly', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Tomato',
          quantity: 2,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '3',
          ingredientName: 'Rice',
          quantity: 1,
          unit: 'kg',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.low,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '4',
          ingredientName: 'Bread',
          quantity: 1,
          unit: 'pack',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);

      expect(summary.itemsUsed, equals(3));
      expect(summary.itemsRescued, equals(2)); // critical and high
      expect(summary.itemsDiscarded, equals(1));
    });

    test('Rescue Score formula and floor at 0', () {
      final entries1 = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Tomato',
          quantity: 2,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '3',
          ingredientName: 'Rice',
          quantity: 1,
          unit: 'kg',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.low,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '4',
          ingredientName: 'Bread',
          quantity: 1,
          unit: 'pack',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
      ];

      final s1 = InsightsCalculator.calculate(entries1, today: testToday);
      expect(s1.rescueScore, equals(19));

      // Test floor at 0 when penalties exceed points
      final entries2 = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Bread',
          quantity: 1,
          unit: 'pack',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Cheese',
          quantity: 1,
          unit: 'pack',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
      ];

      final s2 = InsightsCalculator.calculate(entries2, today: testToday);
      expect(s2.rescueScore, equals(0));
    });
  });

  group('InsightsCalculator Streaks', () {
    test('calculates streak across consecutive days', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Tomato',
          quantity: 1,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday.subtract(const Duration(days: 1)),
        ),
        UsageLogEntry(
          id: '3',
          ingredientName: 'Onion',
          quantity: 1,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.medium,
          timestamp: testToday.subtract(const Duration(days: 2)),
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.currentStreak, equals(3));
      expect(summary.bestStreak, equals(3));
    });

    test('today empty keeps yesterday streak alive', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday.subtract(const Duration(days: 1)),
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Tomato',
          quantity: 1,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday.subtract(const Duration(days: 2)),
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.currentStreak, equals(2));
      expect(summary.bestStreak, equals(2));
    });

    test('gap breaks current streak', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday.subtract(const Duration(days: 2)),
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.currentStreak, equals(0));
      expect(summary.bestStreak, equals(1));
    });

    test('discard-only day does not count towards rescue streak', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Bread',
          quantity: 1,
          unit: 'pack',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday.subtract(const Duration(days: 1)),
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.currentStreak, equals(1));
    });
  });

  group('InsightsCalculator Money Saved & Unpriced Items', () {
    test('calculates estimated money saved with unit conversions', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 500,
          unit: 'ml',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Tomato',
          quantity: 250,
          unit: 'g',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday,
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.estimatedMoneySaved, equals(40.0));
      expect(summary.unpricedRescuedCount, equals(0));
    });

    test('increments unpricedRescuedCount for unknown items or missing quantities', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Dragon Fruit',
          quantity: 1,
          unit: 'piece',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'Milk',
          quantity: null,
          unit: null,
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday,
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      expect(summary.estimatedMoneySaved, equals(0.0));
      expect(summary.unpricedRescuedCount, equals(2));
    });
  });

  group('InsightsCalculator Weekly Buckets', () {
    test('produces exactly 7 daily buckets ending with today', () {
      final summary = InsightsCalculator.calculate([], today: testToday);
      expect(summary.weeklyDays.length, equals(7));
      expect(summary.weeklyDays.last.date.year, equals(testToday.year));
      expect(summary.weeklyDays.last.date.month, equals(testToday.month));
      expect(summary.weeklyDays.last.date.day, equals(testToday.day));
    });
  });

  group('InsightsCalculator Achievements', () {
    test('unlocks achievements based on thresholds', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'Milk',
          quantity: 1,
          unit: 'l',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);
      final firstRescue = summary.achievements.firstWhere((a) => a.id == 'first_rescue');
      expect(firstRescue.isUnlocked, isTrue);

      final rescueRookie = summary.achievements.firstWhere((a) => a.id == 'rescue_rookie');
      expect(rescueRookie.isUnlocked, isFalse);
    });
  });

  group('InsightsCalculator 28-day streak calendar and frequencies', () {
    test('produces 28-day calendar and ranks top rescued and waste watch items', () {
      final entries = [
        UsageLogEntry(
          id: '1',
          ingredientName: 'tomato',
          quantity: 2,
          unit: 'pcs',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.critical,
          timestamp: testToday,
        ),
        UsageLogEntry(
          id: '2',
          ingredientName: 'tomato',
          quantity: 1,
          unit: 'pcs',
          action: UsageAction.used,
          priorityAtUsage: ExpiryPriority.high,
          timestamp: testToday.subtract(const Duration(days: 1)),
        ),
        UsageLogEntry(
          id: '3',
          ingredientName: 'banana',
          quantity: 3,
          unit: 'pcs',
          action: UsageAction.discarded,
          priorityAtUsage: ExpiryPriority.expired,
          timestamp: testToday,
        ),
      ];

      final summary = InsightsCalculator.calculate(entries, today: testToday);

      expect(summary.streakCalendar28Days.length, equals(28));
      expect(summary.streakCalendar28Days.last, isTrue); // today had activity
      expect(summary.streakCalendar28Days[26], isTrue); // yesterday had activity

      expect(summary.rescuedThisWeek, equals(2));
      expect(summary.rescuedLastWeek, equals(0));
      expect(summary.weekOverWeekDiff, equals(2));

      expect(summary.topRescuedIngredients.length, equals(1));
      expect(summary.topRescuedIngredients.first.name, equals('tomato'));
      expect(summary.topRescuedIngredients.first.count, equals(2));

      expect(summary.wasteWatchList.length, equals(1));
      expect(summary.wasteWatchList.first.name, equals('banana'));
      expect(summary.wasteWatchList.first.tip, contains('smoothies'));
    });
  });
}
