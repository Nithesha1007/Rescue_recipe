import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/debug_logger.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../entities/recipe.dart';
import '../entities/recipe_step.dart';
import '../entities/substitution.dart';

class TranslatedRecipeContent {
  const TranslatedRecipeContent({
    required this.title,
    this.description,
    required this.steps,
    this.tips = const [],
    this.substitutions = const [],
  });

  final String title;
  final String? description;
  final List<RecipeStep> steps;
  final List<String> tips;
  final List<Substitution> substitutions;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'steps': steps
            .map((s) => {
                  'text': s.text,
                  'minutes': s.minutes,
                  'tip': s.tip,
                })
            .toList(),
        'tips': tips,
        'substitutions': substitutions
            .map((s) => {
                  'missingIngredient': s.missingIngredient,
                  'substitute': s.substitute,
                  'note': s.note,
                })
            .toList(),
      };

  factory TranslatedRecipeContent.fromJson(Map<String, dynamic> json) {
    return TranslatedRecipeContent(
      title: json['title'] as String,
      description: json['description'] as String?,
      steps: (json['steps'] as List<dynamic>)
          .map((item) => RecipeStep(
                text: item['text'] as String,
                minutes: (item['minutes'] as num?)?.toInt(),
                tip: item['tip'] as String?,
              ))
          .toList(),
      tips: (json['tips'] as List<dynamic>?)?.map((t) => t as String).toList() ??
          const [],
      substitutions: (json['substitutions'] as List<dynamic>?)
              ?.map((item) => Substitution(
                    missingIngredient: item['missingIngredient'] as String? ?? '',
                    substitute: item['substitute'] as String? ?? '',
                    note: item['note'] as String? ?? '',
                  ))
              .toList() ??
          const [],
    );
  }
}

class TranslateRecipeContent {
  TranslateRecipeContent({
    required AppConfig config,
    required http.Client client,
  })  : _config = config,
        _client = client;

  final AppConfig _config;
  final http.Client _client;

  // In-memory / runtime cache per recipe id + language
  final Map<String, TranslatedRecipeContent> _translationCache = {};

  static const String _endpointUrl =
      'https://generativelanguage.googleapis.com/v1beta/models/';

  Future<Recipe> execute({
    required Recipe recipe,
    required GuideLanguage targetLanguage,
  }) async {
    // English is the default baseline
    if (targetLanguage == GuideLanguage.english) {
      return recipe;
    }

    final cacheKey = '${recipe.id}_${targetLanguage.name}';
    if (_translationCache.containsKey(cacheKey)) {
      final cached = _translationCache[cacheKey]!;
      return _applyTranslation(recipe, cached);
    }

    if (!_config.hasGeminiKey) {
      DebugLogger.ai('No Gemini key for translation; falling back to English');
      return recipe;
    }

    try {
      final translated = await _callGeminiTranslation(recipe, targetLanguage);
      if (_validateTranslation(recipe, translated)) {
        _translationCache[cacheKey] = translated;
        return _applyTranslation(recipe, translated);
      } else {
        DebugLogger.ai('Translation validation failed; falling back to English');
        return recipe;
      }
    } catch (e) {
      DebugLogger.ai('Translation request failed: $e. Falling back to English');
      return recipe;
    }
  }

  Recipe _applyTranslation(Recipe original, TranslatedRecipeContent translated) {
    return original.copyWith(
      title: translated.title.isNotEmpty ? translated.title : original.title,
      aiReason: translated.description ?? original.aiReason,
      steps: translated.steps.isNotEmpty ? translated.steps : original.steps,
      tips: translated.tips.isNotEmpty ? translated.tips : original.tips,
      substitutions: translated.substitutions.isNotEmpty
          ? translated.substitutions
          : original.substitutions,
    );
  }

  bool _validateTranslation(Recipe original, TranslatedRecipeContent translated) {
    // 1. Length checks
    if (translated.steps.length != original.steps.length) {
      DebugLogger.ai(
        'Step count mismatch: expected ${original.steps.length}, got ${translated.steps.length}',
      );
      return false;
    }

    // 2. Digit preservation: every digit sequence in original steps should appear in translated steps
    final digitPattern = RegExp(r'\d+');
    for (int i = 0; i < original.steps.length; i++) {
      final origDigits = digitPattern
          .allMatches(original.steps[i].text)
          .map((m) => m.group(0)!)
          .toSet();
      final transDigits = digitPattern
          .allMatches(translated.steps[i].text)
          .map((m) => m.group(0)!)
          .toSet();

      for (final d in origDigits) {
        if (!transDigits.contains(d)) {
          DebugLogger.ai('Digit $d missing in translated step $i');
          return false;
        }
      }
    }

    // 3. Safety/freshness claims: reject translations containing misleading freshness claims
    final forbiddenPhrases = [
      'guaranteed fresh',
      'guaranteed safe',
      '100% safe',
      'নিরাপদ',
      'முற்றிலும் பாதுகாப்பானது',
      'நிச்சயம் கெடாது',
      'सुरक्षित होने की गारंटी',
      'पूरी तरह सुरक्षित',
    ];

    for (final step in translated.steps) {
      for (final phrase in forbiddenPhrases) {
        if (step.text.toLowerCase().contains(phrase.toLowerCase())) {
          DebugLogger.ai('Forbidden freshness claim found: "$phrase"');
          return false;
        }
      }
    }

    return true;
  }

  Future<TranslatedRecipeContent> _callGeminiTranslation(
    Recipe recipe,
    GuideLanguage targetLanguage,
  ) async {
    final languageName = switch (targetLanguage) {
      GuideLanguage.tamil => 'Tamil (in Tamil script தமிழ்)',
      GuideLanguage.hindi => 'Hindi (in Devanagari script हिंदी)',
      GuideLanguage.tanglish => 'Tanglish (Tamil spoken in Latin/English script)',
      GuideLanguage.english => 'English',
    };

    final prompt = '''
You are a cooking translation engine.
Translate the following recipe content into $languageName.
STRICT RULES:
1. Preserve all Western digits and numbers exactly as numbers (e.g. "5 minutes" -> "5", "180" -> "180").
2. Do not change quantities, cooking times, temperatures, or units.
3. Steps array must have EXACTLY ${recipe.steps.length} elements in identical order.
4. Tips array must have EXACTLY ${recipe.tips.length} elements.
5. Never make any statement claiming ingredients are guaranteed fresh or safe.
6. Return strictly valid JSON adhering to the schema.

Recipe Title: ${recipe.title}
Recipe Description: ${recipe.aiReason ?? ''}
Recipe Steps:
${jsonEncode(recipe.steps.map((s) => {'text': s.text, 'minutes': s.minutes, 'tip': s.tip}).toList())}
Recipe Tips:
${jsonEncode(recipe.tips)}
Recipe Substitutions:
${jsonEncode(recipe.substitutions.map((s) => {'missingIngredient': s.missingIngredient, 'substitute': s.substitute, 'note': s.note}).toList())}
''';

    final payload = {
      'contents': [
        {
          'role': 'user',
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'temperature': 0.1,
        'responseMimeType': 'application/json',
        'responseSchema': {
          'type': 'OBJECT',
          'properties': {
            'title': {'type': 'STRING'},
            'description': {'type': 'STRING'},
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
            'tips': {
              'type': 'ARRAY',
              'items': {'type': 'STRING'}
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
            }
          },
          'required': ['title', 'steps']
        }
      }
    };

    final model = _config.geminiModel;
    final url = Uri.parse('$_endpointUrl$model:generateContent');
    final response = await _client.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        'x-goog-api-key': _config.geminiApiKey,
      },
      body: jsonEncode(payload),
    );

    if (response.statusCode != 200) {
      throw UnexpectedFailure('Translation failed with status: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = data['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw const UnexpectedFailure('No translation candidates returned');
    }

    final text = candidates[0]['content']['parts'][0]['text'] as String;
    final jsonContent = jsonDecode(text) as Map<String, dynamic>;
    return TranslatedRecipeContent.fromJson(jsonContent);
  }
}
