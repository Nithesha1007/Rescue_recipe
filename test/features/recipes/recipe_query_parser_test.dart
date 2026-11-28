import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/features/recipes/domain/entities/diet_tag.dart';
import 'package:rescue_recipe/features/recipes/domain/utils/recipe_query_parser.dart';
import 'package:rescue_recipe/features/settings/domain/entities/cuisine_tag.dart';

void main() {
  group('RecipeQueryParser', () {
    test('parses empty or blank queries to empty query', () {
      expect(RecipeQueryParser.parse('').isEmpty, isTrue);
      expect(RecipeQueryParser.parse('   ').isEmpty, isTrue);
    });

    test('parses reset keywords', () {
      expect(RecipeQueryParser.parse('show everything').reset, isTrue);
      expect(RecipeQueryParser.parse('reset filters').reset, isTrue);
      expect(RecipeQueryParser.parse('clear all').reset, isTrue);
      expect(RecipeQueryParser.parse('all recipes').reset, isTrue);
    });

    test('parses explicit minutes and relative times', () {
      expect(RecipeQueryParser.parse('15 min dinner').maxMinutes, equals(15));
      expect(RecipeQueryParser.parse('quick snacks').maxMinutes, equals(15));
      expect(RecipeQueryParser.parse('recipes under 20 mins').maxMinutes, equals(20));
      expect(RecipeQueryParser.parse('ready in half an hour').maxMinutes, equals(30));
      expect(RecipeQueryParser.parse('in 45 minutes').maxMinutes, equals(45));
      expect(RecipeQueryParser.parse('under 1 hour').maxMinutes, equals(60));
    });

    test('parses dietary requirements', () {
      expect(RecipeQueryParser.parse('quick vegan lunch').diet, equals(DietTag.vegan));
      expect(RecipeQueryParser.parse('vegetarian curry').diet, equals(DietTag.vegetarian));
      expect(RecipeQueryParser.parse('gluten free pasta').diet, equals(DietTag.glutenFree));
      expect(RecipeQueryParser.parse('dairy-free soup').diet, equals(DietTag.dairyFree));
      expect(RecipeQueryParser.parse('egg-free breakfast').diet, equals(DietTag.eggFree));
    });

    test('parses cuisines', () {
      expect(RecipeQueryParser.parse('south indian breakfast').cuisine, equals(CuisineTag.southIndian));
      expect(RecipeQueryParser.parse('north indian curry').cuisine, equals(CuisineTag.northIndian));
      expect(RecipeQueryParser.parse('chinese noodles').cuisine, equals(CuisineTag.chinese));
      expect(RecipeQueryParser.parse('italian pasta').cuisine, equals(CuisineTag.continental));
      expect(RecipeQueryParser.parse('evening snacks').cuisine, equals(CuisineTag.snacks));
    });

    test('parses excluded ingredients', () {
      expect(RecipeQueryParser.parse('without onions').excludeIngredient, equals('onion'));
      expect(RecipeQueryParser.parse('no garlic').excludeIngredient, equals('garlic'));
      expect(RecipeQueryParser.parse("don't use tomato").excludeIngredient, equals('tomato'));
      expect(RecipeQueryParser.parse('exclude chili').excludeIngredient, equals('chili'));
    });

    test('parses focused ingredients', () {
      expect(RecipeQueryParser.parse('use tomatoes first').focusIngredient, equals('tomato'));
      expect(RecipeQueryParser.parse('using spinach today').focusIngredient, equals('spinach'));
      expect(RecipeQueryParser.parse('with potatoes').focusIngredient, equals('potato'));
      expect(RecipeQueryParser.parse('have paneer').focusIngredient, equals('paneer'));
    });

    test('parses composite complex conversational phrases', () {
      final q1 = RecipeQueryParser.parse('quick south indian breakfast without onions');
      expect(q1.maxMinutes, equals(15));
      expect(q1.cuisine, equals(CuisineTag.southIndian));
      expect(q1.excludeIngredient, equals('onion'));

      final q2 = RecipeQueryParser.parse('vegetarian curry under 30 mins with paneer');
      expect(q2.diet, equals(DietTag.vegetarian));
      expect(q2.maxMinutes, equals(30));
      expect(q2.focusIngredient, equals('paneer'));
    });
  });
}
