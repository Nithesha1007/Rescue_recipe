import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rescue_recipe/features/recipes/domain/services/dish_image_resolver.dart';

void main() {
  group('DishImageResolver', () {
    test('returns null when offline or network fails', () async {
      final client = MockClient((request) async {
        throw Exception('Offline socket exception');
      });
      final resolver = DishImageResolver(client: client);
      final url = await resolver.resolvePhotoUrl(title: 'Tomato Soup');
      expect(url, isNull);
    });

    test('returns verified food photo from Wikipedia summary', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
          {
            "type": "standard",
            "title": "Tomato soup",
            "description": "Soup made with tomatoes as the primary ingredient",
            "extract": "Tomato soup is a soup with tomatoes as the primary ingredient. It is a popular dish.",
            "thumbnail": {
              "source": "https://upload.wikimedia.org/wikipedia/commons/thumb/test.jpg"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final resolver = DishImageResolver(client: client);
      final url = await resolver.resolvePhotoUrl(title: 'Tomato Soup');
      expect(url, equals('https://upload.wikimedia.org/wikipedia/commons/thumb/test.jpg'));
    });

    test('rejects disambiguation pages', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
          {
            "type": "disambiguation",
            "title": "Sambar",
            "description": "Disambiguation page",
            "thumbnail": {
              "source": "https://upload.wikimedia.org/wikipedia/commons/thumb/deer.jpg"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final resolver = DishImageResolver(client: client);
      final url = await resolver.resolvePhotoUrl(title: 'Sambar');
      expect(url, isNull);
    });

    test('rejects non-food articles lacking food keywords', () async {
      final client = MockClient((request) async {
        return http.Response(
          '''
          {
            "type": "standard",
            "title": "Apple",
            "description": "Multinational technology company headquartered in Cupertino",
            "extract": "Apple Inc. produces electronics and computers.",
            "thumbnail": {
              "source": "https://upload.wikimedia.org/wikipedia/commons/thumb/logo.png"
            }
          }
          ''',
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final resolver = DishImageResolver(client: client);
      final url = await resolver.resolvePhotoUrl(title: 'Apple Corporation');
      expect(url, isNull);
    });
  });
}
