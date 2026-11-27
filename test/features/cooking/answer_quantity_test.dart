import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/cooking/domain/utils/answer_quantity.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';

void main() {
  group('AnswerQuantity', () {
    const testRecipe = Recipe(
      id: 'test_1',
      title: 'Pasta Primavera',
      minutes: 25,
      servings: 2,
      dietTags: {},
      ingredients: [
        RecipeIngredient(name: 'Olive Oil', quantity: 2, unit: 'tbsp'),
        RecipeIngredient(name: 'Garlic Cloves', quantity: 3, unit: 'cloves'),
        RecipeIngredient(name: 'Salt', quantity: null, unit: null),
        RecipeIngredient(name: 'Flour', quantity: 1.5, unit: 'cups'),
      ],
      steps: [
        RecipeStep(text: 'Boil pasta'),
        RecipeStep(text: 'Saute garlic in olive oil'),
        RecipeStep(text: 'Serve hot'),
      ],
    );

    test('answers known ingredient with exact quantity and unit', () {
      final answer = AnswerQuantity.answer(recipe: testRecipe, query: 'olive oil');
      expect(answer, 'You need 2 tbsp of Olive Oil.');
    });

    test('answers ingredient with fractional quantity', () {
      final answer = AnswerQuantity.answer(recipe: testRecipe, query: 'flour');
      expect(answer, 'You need 1 1/2 cups of Flour.');
    });

    test('answers ingredient with null quantity (to taste / as needed)', () {
      final answer = AnswerQuantity.answer(recipe: testRecipe, query: 'salt');
      expect(answer, 'The recipe calls for Salt to taste, or as needed.');
    });

    test('answers absent ingredient gracefully', () {
      final answer = AnswerQuantity.answer(recipe: testRecipe, query: 'paprika');
      expect(answer, "I couldn't find paprika in this recipe.");
    });

    test('answers empty query with prompt', () {
      final answer = AnswerQuantity.answer(recipe: testRecipe, query: '   ');
      expect(answer, 'Which ingredient would you like to know about?');
    });
  });
}
