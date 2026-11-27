import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:rescue_recipe/core/config/app_config.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/recipes/data/datasources/gemini_recipe_datasource.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/repositories/recipe_repository.dart';

void main() {
  group('GeminiRecipeDataSource', () {
    const validConfig = AppConfig(
      geminiApiKey: 'test-api-key',
      geminiModel: 'gemini-2.5-flash',
    );

    final sampleParams = [
      const IngredientCandidateParam(
        name: 'tomato',
        quantity: 2,
        unit: 'pieces',
        useSoon: true,
      ),
      const IngredientCandidateParam(
        name: 'onion',
        quantity: 1,
        unit: 'piece',
        useSoon: false,
      ),
    ];

    test('successfully parses valid JSON response into Recipe list', () async {
      final jsonResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode([
                    {
                      'title': 'Tomato Onion Skillet',
                      'minutes': 15,
                      'servings': 2,
                      'dietTags': ['vegan', 'glutenFree'],
                      'ingredients': [
                        {
                          'name': 'tomato',
                          'quantity': 2,
                          'unit': 'pieces',
                          'isOptional': false,
                          'isPantryStaple': false,
                        },
                        {
                          'name': 'salt',
                          'quantity': 0.5,
                          'unit': 'tsp',
                          'isOptional': false,
                          'isPantryStaple': true,
                        }
                      ],
                      'steps': [
                        {'text': 'Chop the tomatoes into wedges.', 'minutes': 3},
                        {'text': 'Sauté in skillet with salt.', 'minutes': 7}
                      ],
                      'substitutions': [
                        {
                          'missingIngredient': 'onion',
                          'substitute': 'shallot',
                          'note': 'Shallot gives a mild flavor.'
                        }
                      ],
                      'whyRecommended': 'Uses your ripe tomatoes in a quick skillet.'
                    }
                  ])
                }
              ]
            }
          }
        ]
      });

      final mockClient = MockClient((request) async {
        expect(request.headers['x-goog-api-key'], 'test-api-key');
        return http.Response(jsonResponse, 200, headers: {'content-type': 'application/json'});
      });

      final dataSource = GeminiRecipeDataSourceImpl(
        config: validConfig,
        client: mockClient,
      );

      final recipes = await dataSource.generateRecipes(
        ingredients: sampleParams,
        dietPreference: DietTag.none,
      );

      expect(recipes.length, 1);
      expect(recipes.first.title, 'Tomato Onion Skillet');
      expect(recipes.first.minutes, 15);
      expect(recipes.first.dietTags.contains(DietTag.vegan), isTrue);
      expect(recipes.first.ingredients.length, 2);
      expect(recipes.first.steps.length, 2);
      expect(recipes.first.substitutions.length, 1);
    });

    test('drops invalid recipes (e.g. empty steps, minutes > 240)', () async {
      final jsonResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode([
                    {
                      'title': 'Invalid Slow Cook',
                      'minutes': 300, // Invalid: > 240
                      'servings': 2,
                      'dietTags': ['vegan'],
                      'ingredients': [{'name': 'tomato', 'isOptional': false, 'isPantryStaple': false}],
                      'steps': [{'text': 'Cook.'}],
                    },
                    {
                      'title': 'Invalid Empty Steps',
                      'minutes': 20,
                      'servings': 2,
                      'dietTags': ['vegan'],
                      'ingredients': [{'name': 'tomato', 'isOptional': false, 'isPantryStaple': false}],
                      'steps': [], // Invalid: empty steps
                    },
                    {
                      'title': 'Valid Recipe',
                      'minutes': 20,
                      'servings': 2,
                      'dietTags': ['vegan'],
                      'ingredients': [{'name': 'tomato', 'isOptional': false, 'isPantryStaple': false}],
                      'steps': [{'text': 'Cook in pan.'}],
                    }
                  ])
                }
              ]
            }
          }
        ]
      });

      final mockClient = MockClient((request) async {
        return http.Response(jsonResponse, 200);
      });

      final dataSource = GeminiRecipeDataSourceImpl(
        config: validConfig,
        client: mockClient,
      );

      final recipes = await dataSource.generateRecipes(
        ingredients: sampleParams,
        dietPreference: DietTag.none,
      );

      // Only the valid recipe survives
      expect(recipes.length, 1);
      expect(recipes.first.title, 'Valid Recipe');
    });

    test('throws UnexpectedFailure on 401 unauthorized', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Unauthorized"}', 401);
      });

      final dataSource = GeminiRecipeDataSourceImpl(
        config: validConfig,
        client: mockClient,
      );

      expect(
        () => dataSource.generateRecipes(
          ingredients: sampleParams,
          dietPreference: DietTag.none,
        ),
        throwsA(isA<UnexpectedFailure>()),
      );
    });

    test('throws ParsingFailure on malformed JSON response', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"candidates": [{"content": {"parts": [{"text": "Not a JSON"}]}}]}', 200);
      });

      final dataSource = GeminiRecipeDataSourceImpl(
        config: validConfig,
        client: mockClient,
      );

      expect(
        () => dataSource.generateRecipes(
          ingredients: sampleParams,
          dietPreference: DietTag.none,
        ),
        throwsA(isA<ParsingFailure>()),
      );
    });
  });
}
