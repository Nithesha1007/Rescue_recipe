import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../../domain/entities/recipe_step.dart';
import '../../domain/entities/substitution.dart';
import '../../domain/repositories/recipe_repository.dart';

abstract class GeminiRecipeDataSource {
  Future<List<Recipe>> generateRecipes({
    required List<IngredientCandidateParam> ingredients,
    required DietTag dietPreference,
  });
}

class GeminiRecipeDataSourceImpl implements GeminiRecipeDataSource {
  const GeminiRecipeDataSourceImpl({
    required AppConfig config,
    required http.Client client,
  })  : _config = config,
        _client = client;

  final AppConfig _config;
  final http.Client _client;

  static const String _endpointUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';
  static const Duration _timeout = Duration(seconds: 25);

  @override
  Future<List<Recipe>> generateRecipes({
    required List<IngredientCandidateParam> ingredients,
    required DietTag dietPreference,
  }) async {
    if (!_config.hasGeminiKey) {
      throw const UnexpectedFailure('Gemini API key is not configured.');
    }

    final primaryModel = _config.geminiModel;
    final fallbackModel = _config.fallbackModel;

    final payload = _buildPayload(ingredients, dietPreference);
    final headers = {
      'Content-Type': 'application/json',
      'x-goog-api-key': _config.geminiApiKey,
    };

    http.Response response;
    try {
      final url = Uri.parse('$_endpointUrl$primaryModel:generateContent');
      response = await _sendWithRetry(url, headers, payload);

      // If 404 and we have a fallback model, retry with fallback
      if (response.statusCode == 404 && primaryModel != fallbackModel) {
        DebugLogger.ai('Recipe generation model $primaryModel returned 404, retrying with $fallbackModel');
        final fallbackUrl = Uri.parse('$_endpointUrl$fallbackModel:generateContent');
        response = await _sendWithRetry(fallbackUrl, headers, payload);
      }
    } on TimeoutException {
      throw const TimeoutFailure(
        'Gemini recipe generation timed out. Please try again.',
      );
    } on SocketException {
      throw const NetworkFailure(
        'Unable to connect to Gemini. Please check your internet connection.',
      );
    } catch (e) {
      if (e is Failure) rethrow;
      throw UnexpectedFailure('Unexpected network error: $e');
    }

    return _parseResponse(response);
  }

  Future<http.Response> _sendWithRetry(
    Uri url,
    Map<String, String> headers,
    String body,
  ) async {
    try {
      final res = await _client.post(url, headers: headers, body: body).timeout(_timeout);
      if (res.statusCode >= 500 && res.statusCode <= 599) {
        // One retry on 5xx
        return await _client.post(url, headers: headers, body: body).timeout(_timeout);
      }
      return res;
    } on TimeoutException {
      // One retry on timeout
      return await _client.post(url, headers: headers, body: body).timeout(_timeout);
    }
  }

  String _buildPayload(
    List<IngredientCandidateParam> ingredients,
    DietTag dietPreference,
  ) {
    const systemInstruction =
        'You are an expert chef in a food waste reduction app. Generate 6 to 8 realistic, delicious recipes based ONLY on the provided ingredient list plus standard pantry staples (salt, black pepper, water, cooking oil, basic spices, sugar). '
        'Ingredients marked with "useSoon": true are priority items nearing expiry—give strong preference to recipes that use them. '
        'Provide exact, realistic quantities for every ingredient so users know how much to use. '
        'Each step MUST be a single, short, clear sentence suitable for reading aloud, and may include an optional concise cooking tip. '
        'Do NOT mention expiry dates, days left, safety, healthiness, or food freshness in titles, steps, or whyRecommended. '
        'Provide an honest array of dietTags (e.g. vegetarian, vegan, eggFree, dairyFree, glutenFree, nonVegetarian). '
        'Include dish-level tips (e.g., storage advice, serving suggestions) and assign appropriate cuisine category (e.g. South Indian, North Indian, Continental, Chinese-style, Quick snacks). '
        'Output MUST be a JSON array of recipe objects adhering strictly to the schema.';

    final userContent = jsonEncode({
      'availableIngredients': ingredients.map((i) => i.toJson()).toList(),
      'dietPreference': dietPreference.displayName,
    });

    final requestBody = {
      'system_instruction': {
        'parts': [
          {'text': systemInstruction}
        ]
      },
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': 'Generate 6 to 8 recipes for the following ingredients:\n$userContent'}
          ]
        }
      ],
      'generationConfig': {
        'responseMimeType': 'application/json',
        'temperature': 0.4,
        'responseSchema': {
          'type': 'ARRAY',
          'items': {
            'type': 'OBJECT',
            'properties': {
              'title': {'type': 'STRING'},
              'minutes': {'type': 'INTEGER'},
              'servings': {'type': 'INTEGER'},
              'difficulty': {'type': 'STRING'},
              'cuisine': {'type': 'STRING'},
              'tips': {
                'type': 'ARRAY',
                'items': {'type': 'STRING'}
              },
              'dietTags': {
                'type': 'ARRAY',
                'items': {'type': 'STRING'}
              },
              'ingredients': {
                'type': 'ARRAY',
                'items': {
                  'type': 'OBJECT',
                  'properties': {
                    'name': {'type': 'STRING'},
                    'quantity': {'type': 'NUMBER'},
                    'unit': {'type': 'STRING'},
                    'isOptional': {'type': 'BOOLEAN'},
                    'isPantryStaple': {'type': 'BOOLEAN'}
                  },
                  'required': ['name', 'isOptional', 'isPantryStaple']
                }
              },
              'steps': {
                'type': 'ARRAY',
                'items': {
                  'type': 'OBJECT',
                  'properties': {
                    'text': {'type': 'STRING'},
                    'minutes': {'type': 'INTEGER'},
                    'tip': {'type': 'STRING'}
                  },
                  'required': ['text']
                }
              },
              'substitutions': {
                'type': 'ARRAY',
                'items': {
                  'type': 'OBJECT',
                  'properties': {
                    'missingIngredient': {'type': 'STRING'},
                    'substitute': {'type': 'STRING'},
                    'note': {'type': 'STRING'}
                  },
                  'required': ['missingIngredient', 'substitute', 'note']
                }
              },
              'whyRecommended': {'type': 'STRING'}
            },
            'required': [
              'title',
              'minutes',
              'servings',
              'dietTags',
              'ingredients',
              'steps'
            ]
          }
        }
      }
    };

    return jsonEncode(requestBody);
  }

  List<Recipe> _parseResponse(http.Response response) {
    if (response.statusCode == 401 || response.statusCode == 403) {
      throw const UnexpectedFailure(
        'Gemini API key is invalid or unauthorized. Please verify your API key.',
      );
    }

    if (response.statusCode < 200 || response.statusCode > 299) {
      throw UnexpectedFailure(
        'Gemini server returned error (${response.statusCode}).',
      );
    }

    try {
      final Map<String, dynamic> body =
          jsonDecode(response.body) as Map<String, dynamic>;
      final candidates = body['candidates'] as List<dynamic>?;
      if (candidates == null || candidates.isEmpty) {
        throw const ParsingFailure('Gemini returned empty candidates list.');
      }

      final content = candidates.first['content'] as Map<String, dynamic>?;
      final parts = content?['parts'] as List<dynamic>?;
      final text = parts?.first['text'] as String?;
      if (text == null || text.trim().isEmpty) {
        throw const ParsingFailure('Gemini returned empty recipe text.');
      }

      final dynamic jsonResult = jsonDecode(text);
      if (jsonResult is! List) {
        throw const ParsingFailure('Expected a JSON array of recipes.');
      }

      final List<Recipe> recipes = <Recipe>[];

      for (int i = 0; i < jsonResult.length; i++) {
        final item = jsonResult[i];
        if (item is! Map<String, dynamic>) continue;

        final title = (item['title'] as String?)?.trim();
        final minutes = item['minutes'] as num?;
        final servings = item['servings'] as num?;
        final difficulty = (item['difficulty'] as String?)?.trim() ?? 'Easy';
        final cuisine = (item['cuisine'] as String?)?.trim();
        final rawTips = item['tips'] as List<dynamic>?;
        final rawDietTags = item['dietTags'] as List<dynamic>?;
        final rawIngredients = item['ingredients'] as List<dynamic>?;
        final rawSteps = item['steps'] as List<dynamic>?;
        final rawSubs = item['substitutions'] as List<dynamic>?;
        final whyRecommended = (item['whyRecommended'] as String?)?.trim();

        if (title == null || title.isEmpty) continue;
        if (minutes == null || minutes < 1 || minutes > 240) continue;
        if (rawSteps == null || rawSteps.isEmpty || rawSteps.length > 25) continue;
        if (rawIngredients == null || rawIngredients.isEmpty) continue;

        final Set<DietTag> dietTags = <DietTag>{};
        if (rawDietTags != null) {
          for (final dt in rawDietTags) {
            final tag = DietTag.fromString(dt.toString());
            if (tag != DietTag.none) {
              dietTags.add(tag);
            }
          }
        }

        final List<RecipeIngredient> ingredients = <RecipeIngredient>[];
        for (final ing in rawIngredients) {
          if (ing is! Map<String, dynamic>) continue;
          final name = (ing['name'] as String?)?.trim();
          if (name == null || name.isEmpty) continue;

          final qty = ing['quantity'] as num?;
          final unit = (ing['unit'] as String?)?.trim();
          final isOptional = ing['isOptional'] == true;
          final isPantryStaple = ing['isPantryStaple'] == true;

          ingredients.add(RecipeIngredient(
            name: name,
            quantity: qty?.toDouble(),
            unit: unit?.isEmpty == true ? null : unit,
            isOptional: isOptional,
            isPantryStaple: isPantryStaple,
          ));
        }

        if (ingredients.isEmpty) continue;

        final List<RecipeStep> steps = <RecipeStep>[];
        for (final st in rawSteps) {
          if (st is! Map<String, dynamic>) continue;
          final stepText = (st['text'] as String?)?.trim();
          if (stepText == null || stepText.isEmpty) continue;
          final stepMinutes = st['minutes'] as num?;
          final stepTip = (st['tip'] as String?)?.trim();

          steps.add(RecipeStep(
            text: stepText,
            minutes: stepMinutes?.toInt(),
            tip: stepTip?.isNotEmpty == true ? stepTip : null,
          ));
        }

        if (steps.isEmpty) continue;

        final List<String> tips = <String>[];
        if (rawTips != null) {
          for (final t in rawTips) {
            final str = t?.toString().trim();
            if (str != null && str.isNotEmpty) {
              tips.add(str);
            }
          }
        }

        final List<Substitution> substitutions = <Substitution>[];
        if (rawSubs != null) {
          for (final sub in rawSubs) {
            if (sub is! Map<String, dynamic>) continue;
            final missing = (sub['missingIngredient'] as String?)?.trim() ?? '';
            final substitute = (sub['substitute'] as String?)?.trim() ?? '';
            final note = (sub['note'] as String?)?.trim() ?? '';
            if (missing.isNotEmpty && substitute.isNotEmpty) {
              substitutions.add(Substitution(
                missingIngredient: missing,
                substitute: substitute,
                note: note,
              ));
            }
          }
        }

        recipes.add(Recipe(
          id: 'gemini_${DateTime.now().millisecondsSinceEpoch}_$i',
          title: title,
          minutes: minutes.toInt(),
          servings: (servings ?? 2).toInt(),
          difficulty: difficulty,
          cuisine: cuisine,
          tips: tips,
          dietTags: dietTags,
          ingredients: ingredients,
          steps: steps,
          substitutions: substitutions,
          aiReason: whyRecommended,
          source: RecipeSource.gemini,
        ));
      }

      if (recipes.isEmpty) {
        throw const ParsingFailure(
          'Gemini returned recipes but none passed strict schema validation.',
        );
      }

      return recipes;
    } catch (e) {
      if (e is Failure) rethrow;
      throw ParsingFailure('Failed to parse Gemini recipe output: $e');
    }
  }
}
