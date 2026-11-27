import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/voice/data/datasources/offline_ingredient_parser.dart';

void main() {
  group('OfflineIngredientParser', () {
    test('parses official demo sentence correctly', () {
      const sentence =
          'I have three tomatoes, two onions, spinach and two potatoes. My tomatoes expire tomorrow.';

      final items = OfflineIngredientParser.parse(sentence);
      expect(items.length, 4);

      final tomatoes = items.where((i) => i.name == 'tomato');
      expect(tomatoes.isNotEmpty, isTrue);
      expect(tomatoes.first.quantity, 3.0);
      expect(tomatoes.first.expiryPhrase, 'tomorrow');

      final onions = items.where((i) => i.name == 'onion');
      expect(onions.isNotEmpty, isTrue);
      expect(onions.first.quantity, 2.0);

      final spinach = items.where((i) => i.name == 'spinach');
      expect(spinach.isNotEmpty, isTrue);
      expect(spinach.first.quantity, isNull);

      final potatoes = items.where((i) => i.name == 'potato');
      expect(potatoes.isNotEmpty, isTrue);
      expect(potatoes.first.quantity, 2.0);
    });

    test('handles digits, number words and units', () {
      const text = '500 g flour, 2 litres milk and a bunch of carrots';
      final items = OfflineIngredientParser.parse(text);

      expect(items.length, 3);
      expect(items[0].name, 'flour');
      expect(items[0].quantity, 500.0);
      expect(items[0].unit, 'g');

      expect(items[1].name, 'milk');
      expect(items[1].quantity, 2.0);
      expect(items[1].unit, 'litres');

      expect(items[2].name, 'carrot');
      expect(items[2].quantity, 1.0);
      expect(items[2].unit, 'bunch');
    });

    test('sets vague quantities like "some" or "a bit" to null', () {
      const text = 'some cheese, a bit of butter and a handful of nuts';
      final items = OfflineIngredientParser.parse(text);

      expect(items.length, 3);
      expect(items[0].name, 'cheese');
      expect(items[0].quantity, isNull);

      expect(items[1].name, 'butter');
      expect(items[1].quantity, isNull);

      expect(items[2].name, 'nut');
      expect(items[2].quantity, isNull);
    });

    test('extracts inline expiry phrases', () {
      const text = 'bread expiring in 3 days, yoghurt expires friday';
      final items = OfflineIngredientParser.parse(text);

      expect(items.length, 2);
      expect(items[0].name, 'bread');
      expect(items[0].expiryPhrase, 'in 3 days');

      expect(items[1].name, 'yoghurt');
      expect(items[1].expiryPhrase, 'friday');
    });
  });
}
