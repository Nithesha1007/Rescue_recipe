import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/utils/expiry_date_resolver.dart';

void main() {
  group('ExpiryDateResolver', () {
    // 2026-11-26 is a Thursday
    final DateTime baseToday = DateTime(2026, 11, 26);

    test('today', () {
      final res = ExpiryDateResolver.resolve('today', today: baseToday);
      expect(res, DateTime(2026, 11, 26));
    });

    test('tomorrow', () {
      final res = ExpiryDateResolver.resolve('tomorrow', today: baseToday);
      expect(res, DateTime(2026, 11, 27));
    });

    test('day after tomorrow', () {
      final res =
          ExpiryDateResolver.resolve('day after tomorrow', today: baseToday);
      expect(res, DateTime(2026, 11, 28));
    });

    test('in 3 days', () {
      final res = ExpiryDateResolver.resolve('in 3 days', today: baseToday);
      expect(res, DateTime(2026, 11, 29));
    });

    test('in two days (word number)', () {
      final res = ExpiryDateResolver.resolve('in two days', today: baseToday);
      expect(res, DateTime(2026, 11, 28));
    });

    test('expires in two days', () {
      final res =
          ExpiryDateResolver.resolve('expires in two days', today: baseToday);
      expect(res, DateTime(2026, 11, 28));
    });

    test('next week (+7 days)', () {
      final res = ExpiryDateResolver.resolve('next week', today: baseToday);
      expect(res, DateTime(2026, 12, 3));
    });

    test('Friday on Thursday (upcoming next day)', () {
      final res = ExpiryDateResolver.resolve('on Friday', today: baseToday);
      expect(res, DateTime(2026, 11, 27));
    });

    test('Friday on a Friday resolves to next week Friday (never today)', () {
      final DateTime friday = DateTime(2026, 11, 27);
      final res = ExpiryDateResolver.resolve('Friday', today: friday);
      expect(res, DateTime(2026, 12, 4));
    });

    test('yesterday', () {
      final res = ExpiryDateResolver.resolve('yesterday', today: baseToday);
      expect(res, DateTime(2026, 11, 25));
    });

    test('3 days ago', () {
      final res = ExpiryDateResolver.resolve('3 days ago', today: baseToday);
      expect(res, DateTime(2026, 11, 23));
    });

    test('vague phrases return null and never guess', () {
      expect(ExpiryDateResolver.resolve('some time soon'), isNull);
      expect(ExpiryDateResolver.resolve('a bit'), isNull);
      expect(ExpiryDateResolver.resolve('unknown'), isNull);
      expect(ExpiryDateResolver.resolve(''), isNull);
      expect(ExpiryDateResolver.resolve(null), isNull);
    });
  });
}
