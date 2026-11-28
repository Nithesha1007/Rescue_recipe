import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_ingredient.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/recipe_step.dart';
import 'package:rescue_recipe/features/recipes/domain/services/step_ingredient_linker.dart';

void main() {
  group('StepIngredientLinker', () {
    const ingTomatoes = RecipeIngredient(
      name: 'tomato',
      quantity: 2,
      unit: 'pcs',
      isOptional: false,
    );
    const ingOnion = RecipeIngredient(
      name: 'onion',
      quantity: 1,
      unit: 'pcs',
      isOptional: false,
    );
    const ingGarlic = RecipeIngredient(
      name: 'garlic',
      quantity: 4,
      unit: 'cloves',
      isOptional: false,
    );

    final allIngredients = [ingTomatoes, ingOnion, ingGarlic];

    test('links ingredients via explicit uses list', () {
      const step = RecipeStep(
        text: 'Finely chop the vegetables for the base.',
        minutes: 3,
        uses: ['tomato', 'onion'],
      );

      final linked = StepIngredientLinker.linkIngredientsForStep(
        step: step,
        recipeIngredients: allIngredients,
      );

      expect(linked.length, 2);
      expect(linked, contains(ingTomatoes));
      expect(linked, contains(ingOnion));
      expect(linked, isNot(contains(ingGarlic)));
    });

    test('links ingredients via natural text scanning with plurals and aliases', () {
      const step = RecipeStep(
        text: 'Add the chopped onions and minced garlic to the heated pan.',
        minutes: 4,
        uses: [],
      );

      final linked = StepIngredientLinker.linkIngredientsForStep(
        step: step,
        recipeIngredients: allIngredients,
      );

      expect(linked.length, 2);
      expect(linked, contains(ingOnion));
      expect(linked, contains(ingGarlic));
      expect(linked, isNot(contains(ingTomatoes)));
    });

    test('formats chip labels cleanly with amount and unit', () {
      expect(StepIngredientLinker.formatChipLabel(ingTomatoes), 'Tomato 2 pcs');
      expect(StepIngredientLinker.formatChipLabel(ingGarlic), 'Garlic 4 cloves');

      const noAmount = RecipeIngredient(name: 'salt', quantity: null, unit: null);
      expect(StepIngredientLinker.formatChipLabel(noAmount), 'Salt (as needed)');
    });

    test('recites linked ingredients naturally before step instruction', () {
      const step = RecipeStep(
        text: 'Heat oil and saute until golden.',
        minutes: 2,
        uses: ['onion'],
      );

      final spoken = StepIngredientLinker.buildSpokenStepText(
        step: step,
        recipeIngredients: allIngredients,
      );

      expect(spoken, contains('Using 1 pcs Onion.'));
      expect(spoken, contains('Heat oil and saute until golden.'));
    });
  });
}
