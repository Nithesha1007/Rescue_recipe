import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/ingredients/domain/utils/expiry_date_resolver.dart';

void main() {
  group('Multilingual ExpiryDateResolver Tests', () {
    final fixedToday = DateTime(2026, 11, 28);

    test('Tamil date phrases resolution', () {
      // இன்று (today)
      final d1 = ExpiryDateResolver.resolve('இன்று', today: fixedToday);
      expect(d1, DateTime(2026, 11, 28));

      // நாளை (tomorrow)
      final d2 = ExpiryDateResolver.resolve('நாளை', today: fixedToday);
      expect(d2, DateTime(2026, 11, 29));

      // நாளை மறுநாள் (day after tomorrow)
      final d3 = ExpiryDateResolver.resolve('நாளை மறுநாள்', today: fixedToday);
      expect(d3, DateTime(2026, 11, 30));

      // மூன்று நாட்களில் (in 3 days)
      final d4 = ExpiryDateResolver.resolve('மூன்று நாட்களில்', today: fixedToday);
      expect(d4, DateTime(2026, 12, 1));
    });

    test('Hindi date phrases resolution', () {
      // आज (today)
      final d1 = ExpiryDateResolver.resolve('आज', today: fixedToday);
      expect(d1, DateTime(2026, 11, 28));

      // कल (tomorrow)
      final d2 = ExpiryDateResolver.resolve('कल', today: fixedToday);
      expect(d2, DateTime(2026, 11, 29));

      // परसों (day after tomorrow)
      final d3 = ExpiryDateResolver.resolve('परसों', today: fixedToday);
      expect(d3, DateTime(2026, 11, 30));

      // चार दिन में (in 4 days)
      final d4 = ExpiryDateResolver.resolve('चार दिन में', today: fixedToday);
      expect(d4, DateTime(2026, 12, 2));
    });

    test('Tanglish & Hinglish phrases resolution', () {
      // inniku (today)
      final d1 = ExpiryDateResolver.resolve('inniku', today: fixedToday);
      expect(d1, DateTime(2026, 11, 28));

      // naalaiki (tomorrow)
      final d2 = ExpiryDateResolver.resolve('naalaiki', today: fixedToday);
      expect(d2, DateTime(2026, 11, 29));

      // kal (tomorrow)
      final d3 = ExpiryDateResolver.resolve('kal', today: fixedToday);
      expect(d3, DateTime(2026, 11, 29));

      // in 5 days
      final d4 = ExpiryDateResolver.resolve('in 5 days', today: fixedToday);
      expect(d4, DateTime(2026, 12, 3));
    });
  });
}
