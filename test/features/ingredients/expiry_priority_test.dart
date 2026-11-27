import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';

void main() {
  group('ExpiryPriority boundary calculations', () {
    final DateTime today = DateTime(2026, 11, 26);

    test('days left < 0: Expired', () {
      expect(ExpiryPriority.fromDaysLeft(-1), ExpiryPriority.expired);
      expect(ExpiryPriority.fromDaysLeft(-5), ExpiryPriority.expired);
      final DateTime yesterday = DateTime(2026, 11, 25);
      expect(ExpiryPriority.fromDate(yesterday, today: today),
          ExpiryPriority.expired);
    });

    test('days left == 0: Critical', () {
      expect(ExpiryPriority.fromDaysLeft(0), ExpiryPriority.critical);
      final DateTime date = DateTime(2026, 11, 26, 15, 30);
      expect(
          ExpiryPriority.fromDate(date, today: today), ExpiryPriority.critical);
    });

    test('days left 1 to 2: High', () {
      expect(ExpiryPriority.fromDaysLeft(1), ExpiryPriority.high);
      expect(ExpiryPriority.fromDaysLeft(2), ExpiryPriority.high);
      expect(
          ExpiryPriority.fromDate(DateTime(2026, 11, 27), today: today),
          ExpiryPriority.high);
      expect(
          ExpiryPriority.fromDate(DateTime(2026, 11, 28), today: today),
          ExpiryPriority.high);
    });

    test('days left 3 to 5: Medium', () {
      expect(ExpiryPriority.fromDaysLeft(3), ExpiryPriority.medium);
      expect(ExpiryPriority.fromDaysLeft(4), ExpiryPriority.medium);
      expect(ExpiryPriority.fromDaysLeft(5), ExpiryPriority.medium);
      expect(
          ExpiryPriority.fromDate(DateTime(2026, 11, 29), today: today),
          ExpiryPriority.medium);
      expect(
          ExpiryPriority.fromDate(DateTime(2026, 12, 1), today: today),
          ExpiryPriority.medium);
    });

    test('days left > 5: Low', () {
      expect(ExpiryPriority.fromDaysLeft(6), ExpiryPriority.low);
      expect(ExpiryPriority.fromDaysLeft(14), ExpiryPriority.low);
      expect(
          ExpiryPriority.fromDate(DateTime(2026, 12, 2), today: today),
          ExpiryPriority.low);
    });

    test('null date: Unknown', () {
      expect(ExpiryPriority.fromDaysLeft(null), ExpiryPriority.unknown);
      expect(ExpiryPriority.fromDate(null, today: today),
          ExpiryPriority.unknown);
    });
  });
}
