import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/services/video_cooking_helper.dart';

void main() {
  group('VideoCookingHelper', () {
    test('extracts cooking techniques from step instructions', () {
      const step1 = RecipeStep(
        text: 'Finely dice the onion and saute in butter until translucent.',
      );
      const step2 = RecipeStep(
        text: 'Temper mustard seeds, curry leaves, and green chilies.',
      );

      final techniques1 = VideoCookingHelper.extractTechniquesFromStep(step1);
      final techniques2 = VideoCookingHelper.extractTechniquesFromStep(step2);

      expect(techniques1, contains('dice'));
      expect(techniques1, contains('saute'));
      expect(techniques2, contains('temper'));
    });

    test('builds accurate recipe video query fallback', () {
      const recipe = Recipe(
        id: 'r_test',
        title: 'Tomato Onion Rasam',
        minutes: 15,
        servings: 2,
        dietTags: {},
        ingredients: [],
        steps: [],
        substitutions: [],
        source: RecipeSource.offline,
        difficulty: 'Easy',
        tips: [],
        videoSearchQuery: 'how to make traditional rasam recipe',
      );

      final query = VideoCookingHelper.buildVideoQuery(recipe);
      expect(query, 'how to make traditional rasam recipe');

      final recipeWithoutVideoQuery = recipe.copyWith(videoSearchQuery: null);
      final fallbackQuery = VideoCookingHelper.buildVideoQuery(recipeWithoutVideoQuery);
      expect(fallbackQuery, 'how to make Tomato Onion Rasam recipe');
    });

    test('generates technique search query with recipe context', () {
      final query = VideoCookingHelper.buildTechniqueQuery(
        technique: 'temper',
        recipeTitle: 'Tomato Rasam',
      );
      expect(query, 'how to temper Tomato Rasam cooking technique');
    });
  });
}
