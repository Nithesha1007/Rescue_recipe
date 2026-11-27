import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';
import 'package:rescue_recipe/features/voice/domain/utils/voice_correction.dart';

void main() {
  group('VoiceCorrection', () {
    final initialList = [
      const ExtractedIngredient(name: 'tomato', quantity: 3, unit: 'pieces'),
      const ExtractedIngredient(name: 'onion', quantity: 2, unit: 'pieces'),
      const ExtractedIngredient(name: 'spinach', quantity: null),
      const ExtractedIngredient(name: 'potato', quantity: 2, unit: 'pieces'),
    ];

    test('removes item with "actually I don\'t have onions"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        "actually I don't have onions",
      );

      expect(updated.length, 3);
      expect(updated.any((i) => i.name == 'onion'), isFalse);
    });

    test('removes item with "remove the spinach"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        'remove the spinach',
      );

      expect(updated.length, 3);
      expect(updated.any((i) => i.name == 'spinach'), isFalse);
    });

    test('removes item with "no potatoes"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        'no potatoes',
      );

      expect(updated.length, 3);
      expect(updated.any((i) => i.name == 'potato'), isFalse);
    });

    test('removes item with "I don\'t have any tomatoes"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        "I don't have any tomatoes",
      );

      expect(updated.length, 3);
      expect(updated.any((i) => i.name == 'tomato'), isFalse);
    });

    test('updates quantity with "actually two tomatoes"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        'actually two tomatoes',
      );

      expect(updated.length, 4);
      final tomato = updated.firstWhere((i) => i.name == 'tomato');
      expect(tomato.quantity, 2.0);
    });

    test('updates quantity with "make it three onions"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        'make it three onions',
      );

      expect(updated.length, 4);
      final onion = updated.firstWhere((i) => i.name == 'onion');
      expect(onion.quantity, 3.0);
    });

    test('updates quantity with "change tomatoes to 5"', () {
      final updated = VoiceCorrection.apply(
        initialList,
        'change tomatoes to 5',
      );

      expect(updated.length, 4);
      final tomato = updated.firstWhere((i) => i.name == 'tomato');
      expect(tomato.quantity, 5.0);
    });
  });
}
