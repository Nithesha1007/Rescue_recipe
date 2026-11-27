import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/voice/data/datasources/offline_ingredient_parser.dart';

void main() {
  group('OfflineIngredientParser Segmenter Tests', () {
    test('segments glued unpunctuated English sentence: "pasta tomato garlic salt"', () {
      final items = OfflineIngredientParser.parse('pasta tomato garlic salt');
      final names = items.map((i) => i.name).toList();

      expect(names, contains('pasta'));
      expect(names, contains('tomato'));
      expect(names, contains('garlic'));
      expect(names, contains('salt'));
      expect(items.length, 4);
    });

    test('segments multi-lingual Tanglish sentence: "vengayam tomato rice chicken"', () {
      final items = OfflineIngredientParser.parse('vengayam tomato rice chicken');
      final names = items.map((i) => i.name).toList();

      expect(names, contains('onion')); // vengayam canonicalized
      expect(names, contains('tomato'));
      expect(names, contains('rice'));
      expect(names, contains('chicken'));
      expect(items.length, 4);
    });

    test('parses complex sentence with quantities, units, and expiry phrases: '
        '"I have three tomatoes two onions spinach and two potatoes my tomatoes expire tomorrow"', () {
      final items = OfflineIngredientParser.parse(
        'I have three tomatoes two onions spinach and two potatoes my tomatoes expire tomorrow',
      );
      final names = items.map((i) => i.name).toList();

      expect(names, contains('tomato'));
      expect(names, contains('onion'));
      expect(names, contains('spinach'));
      expect(names, contains('potato'));

      final tomato = items.firstWhere((i) => i.name == 'tomato');
      expect(tomato.quantity, 3.0);

      final onion = items.firstWhere((i) => i.name == 'onion');
      expect(onion.quantity, 2.0);

      final potato = items.firstWhere((i) => i.name == 'potato');
      expect(potato.quantity, 2.0);
    });

    test('segments Tamil-only ingredient sequence: "thakkali vengayam urulai"', () {
      final items = OfflineIngredientParser.parse('thakkali vengayam urulai');
      final names = items.map((i) => i.name).toList();

      expect(names, contains('tomato')); // thakkali
      expect(names, contains('onion')); // vengayam
      expect(names, contains('potato')); // urulai
      expect(items.length, 3);
    });

    test('correctly preserves spokenName when canonicalizing', () {
      final items = OfflineIngredientParser.parse('two vengayam and thakkali');
      final onion = items.firstWhere((i) => i.name == 'onion');
      expect(onion.spokenName, 'vengayam');
      expect(onion.quantity, 2.0);

      final tomato = items.firstWhere((i) => i.name == 'tomato');
      expect(tomato.spokenName, 'thakkali');
    });
  });
}
