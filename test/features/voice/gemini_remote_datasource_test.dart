import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rescue_recipe/core/config/app_config.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/voice/data/datasources/gemini_remote_datasource.dart';

void main() {
  group('GeminiRemoteDataSource', () {
    const config = AppConfig(
      geminiApiKey: 'test-api-key',
      geminiModel: 'gemini-2.5-flash',
    );

    test('extracts valid JSON with ingredients and expiry phrases', () async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode([
                    {
                      'name': 'tomatoes',
                      'quantity': 3,
                      'unit': 'pieces',
                      'expiryPhrase': 'tomorrow'
                    },
                    {
                      'name': 'spinach',
                      'quantity': null,
                      'unit': null,
                      'expiryPhrase': null
                    }
                  ])
                }
              ]
            }
          }
        ]
      };

      final client = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-api-key');
        expect(request.headers['Content-Type'], 'application/json');
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);
      final items = await dataSource.extractIngredients('test transcript');

      expect(items.length, 2);
      expect(items[0].name, 'tomatoes');
      expect(items[0].quantity, 3.0);
      expect(items[0].expiryPhrase, 'tomorrow');
      expect(items[1].name, 'spinach');
      expect(items[1].quantity, isNull);
    });

    test('throws ParsingFailure on malformed JSON text', () async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': 'not valid json'}
              ]
            }
          }
        ]
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);

      expect(
        () => dataSource.extractIngredients('test'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('throws ParsingFailure when response is not a list', () async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': jsonEncode({'message': 'something'})}
              ]
            }
          }
        ]
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);

      expect(
        () => dataSource.extractIngredients('test'),
        throwsA(isA<ParsingFailure>()),
      );
    });

    test('ignores items with blank names and clamps negative quantities',
        () async {
      final fakeResponse = {
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode([
                    {'name': '', 'quantity': 5},
                    {'name': '  ', 'quantity': 2},
                    {'name': 'potatoes', 'quantity': -4},
                    {'name': 'carrots', 'quantity': 9999999}
                  ])
                }
              ]
            }
          }
        ]
      };

      final client = MockClient((request) async {
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);
      final items = await dataSource.extractIngredients('test');

      expect(items.length, 2);
      expect(items[0].name, 'potatoes');
      expect(items[0].quantity, isNull); // Clamped negative
      expect(items[1].name, 'carrots');
      expect(items[1].quantity, isNull); // Clamped > 10000
    });

    test('maps 401/403 to UnexpectedFailure with clear message', () async {
      final client = MockClient((request) async {
        return http.Response('Unauthorized', 401);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);

      expect(
        () => dataSource.extractIngredients('test'),
        throwsA(isA<UnexpectedFailure>().having(
          (e) => e.message,
          'message',
          contains('API key error'),
        )),
      );
    });

    test('retries on 500 error once and succeeds', () async {
      int attempts = 0;
      final client = MockClient((request) async {
        attempts++;
        if (attempts == 1) {
          return http.Response('Internal Error', 500);
        }
        final fakeResponse = {
          'candidates': [
            {
              'content': {
                'parts': [
                  {
                    'text': jsonEncode([
                      {'name': 'onions', 'quantity': 2}
                    ])
                  }
                ]
              }
            }
          ]
        };
        return http.Response(jsonEncode(fakeResponse), 200);
      });

      final dataSource =
          GeminiRemoteDataSourceImpl(config: config, client: client);
      final items = await dataSource.extractIngredients('test');

      expect(attempts, 2);
      expect(items.length, 1);
      expect(items[0].name, 'onions');
    });
  });
}
