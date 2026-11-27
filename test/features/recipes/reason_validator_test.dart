import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/reason_validator.dart';

void main() {
  group('ReasonValidator', () {
    test('accepts concise, safe, objective reasons', () {
      expect(
        ReasonValidator.isValid('Uses your tomatoes and spinach before they go bad.'),
        isTrue,
      );
      expect(
        ReasonValidator.isValid('Quick 15-minute meal highlighting your on-hand produce.'),
        isTrue,
      );
      expect(
        ReasonValidator.isValid('Great way to pair onions with potatoes in a hearty hash.'),
        isTrue,
      );
    });

    test('rejects empty or whitespace-only reasons', () {
      expect(ReasonValidator.isValid(null), isFalse);
      expect(ReasonValidator.isValid(''), isFalse);
      expect(ReasonValidator.isValid('   '), isFalse);
    });

    test('rejects reasons exceeding 140 characters', () {
      final longReason = 'A' * 141;
      expect(ReasonValidator.isValid(longReason), isFalse);
      final exactReason = 'A' * 140;
      expect(ReasonValidator.isValid(exactReason), isTrue);
    });

    test('rejects reasons mentioning dates or days remaining', () {
      expect(ReasonValidator.isValid('Eat this today!'), isFalse);
      expect(ReasonValidator.isValid('Tomatoes expire tomorrow so use them now.'), isFalse);
      expect(ReasonValidator.isValid('Good for yesterday leftovers.'), isFalse);
      expect(ReasonValidator.isValid('Use within 2 days for best taste.'), isFalse);
      expect(ReasonValidator.isValid('Cook in 3 days.'), isFalse);
      expect(ReasonValidator.isValid('Good for next week meals.'), isFalse);
    });

    test('rejects safety, freshness, and health guarantee claims', () {
      expect(ReasonValidator.isValid('This food is 100% safe to eat.'), isFalse);
      expect(ReasonValidator.isValid('Checks the safety of your produce.'), isFalse);
      expect(ReasonValidator.isValid('Keeps your greens fresh.'), isFalse);
      expect(ReasonValidator.isValid('Guaranteed freshness in every bite.'), isFalse);
      expect(ReasonValidator.isValid('Prevents food from spoiling.'), isFalse);
      expect(ReasonValidator.isValid('Use before it is spoiled.'), isFalse);
      expect(ReasonValidator.isValid('Protects against spoilage.'), isFalse);
      expect(ReasonValidator.isValid('Your eggs are still good to eat.'), isFalse);
      expect(ReasonValidator.isValid('Your chicken is okay to eat.'), isFalse);
      expect(ReasonValidator.isValid('Healthy meal packed with vitamins.'), isFalse);
      expect(ReasonValidator.isValid('Guaranteed no risk dinner.'), isFalse);
    });
  });
}
