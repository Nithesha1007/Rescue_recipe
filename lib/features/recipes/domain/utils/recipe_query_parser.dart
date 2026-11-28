import 'package:equatable/equatable.dart';
import '../../../settings/domain/entities/cuisine_tag.dart';
import '../../domain/entities/diet_tag.dart';
import '../../../../core/domain/ingredient_vocabulary.dart';

/// Parsed conversational query from user voice speech on the Recipes screen.
class ParsedRecipeQuery extends Equatable {
  final int? maxMinutes;
  final DietTag? diet;
  final CuisineTag? cuisine;
  final String? focusIngredient;
  final String? excludeIngredient;
  final bool reset;

  const ParsedRecipeQuery({
    this.maxMinutes,
    this.diet,
    this.cuisine,
    this.focusIngredient,
    this.excludeIngredient,
    this.reset = false,
  });

  bool get isEmpty =>
      maxMinutes == null &&
      diet == null &&
      cuisine == null &&
      focusIngredient == null &&
      excludeIngredient == null &&
      !reset;

  @override
  List<Object?> get props => [
        maxMinutes,
        diet,
        cuisine,
        focusIngredient,
        excludeIngredient,
        reset,
      ];
}

/// Pure Dart conversational parser that extracts structured recipe filters from speech.
abstract final class RecipeQueryParser {
  static ParsedRecipeQuery parse(String text) {
    final query = text.toLowerCase().trim();
    if (query.isEmpty) return const ParsedRecipeQuery();

    // Check reset commands
    if (query.contains('show everything') ||
        query.contains('reset') ||
        query.contains('clear filter') ||
        query.contains('clear all') ||
        query.contains('all recipes')) {
      return const ParsedRecipeQuery(reset: true);
    }

    int? maxMinutes;
    DietTag? diet;
    CuisineTag? cuisine;
    String? focusIngredient;
    String? excludeIngredient;

    // Time extraction
    if (query.contains('half an hour') || query.contains('30 min') || query.contains('30 minutes')) {
      maxMinutes = 30;
    } else if (query.contains('15 min') || query.contains('15 minutes') || query.contains('quick') || query.contains('fast')) {
      maxMinutes = 15;
    } else if (query.contains('20 min') || query.contains('20 minutes')) {
      maxMinutes = 20;
    } else if (query.contains('45 min') || query.contains('45 minutes')) {
      maxMinutes = 45;
    } else if (query.contains('1 hour') || query.contains('an hour') || query.contains('60 min')) {
      maxMinutes = 60;
    } else {
      final match = RegExp(r'(\d+)\s*(mins?|minutes?)').firstMatch(query);
      if (match != null) {
        maxMinutes = int.tryParse(match.group(1)!);
      }
    }

    // Diet extraction
    if (query.contains('vegan')) {
      diet = DietTag.vegan;
    } else if (query.contains('vegetarian') || query.contains('veg') && !query.contains('non-veg')) {
      diet = DietTag.vegetarian;
    } else if (query.contains('gluten-free') || query.contains('gluten free')) {
      diet = DietTag.glutenFree;
    } else if (query.contains('dairy-free') || query.contains('dairy free')) {
      diet = DietTag.dairyFree;
    } else if (query.contains('egg-free') || query.contains('egg free')) {
      diet = DietTag.eggFree;
    }

    // Cuisine extraction
    if (query.contains('south indian')) {
      cuisine = CuisineTag.southIndian;
    } else if (query.contains('north indian')) {
      cuisine = CuisineTag.northIndian;
    } else if (query.contains('chinese')) {
      cuisine = CuisineTag.chinese;
    } else if (query.contains('continental') || query.contains('italian') || query.contains('pasta')) {
      cuisine = CuisineTag.continental;
    } else if (query.contains('snack') || query.contains('snacks')) {
      cuisine = CuisineTag.snacks;
    }

    // Exclude extraction ("without onions", "no garlic", "exclude tomato")
    final excludeMatch = RegExp(
      r"(?:without|no|exclude|excluding|don't use|dont use)\s+([a-zA-Z\s]+?)(?:$|\b(?:and|or|in|under|with)\b)",
      caseSensitive: false,
    ).firstMatch(query);
    if (excludeMatch != null) {
      final raw = excludeMatch.group(1)!.trim();
      excludeIngredient = IngredientVocabulary.resolve(raw);
    }

    // Focus extraction ("use tomatoes first", "using tomato", "with spinach", "have potatoes")
    final focusMatch = RegExp(
      r"(?:use|using|with|have|need to use)\s+([a-zA-Z\s]+?)(?:\s+(?:first|now|today)|\b(?:$|and|or|in|under)\b)",
      caseSensitive: false,
    ).firstMatch(query);
    if (focusMatch != null && excludeIngredient == null) {
      final raw = focusMatch.group(1)!.trim();
      focusIngredient = IngredientVocabulary.resolve(raw);
    }

    return ParsedRecipeQuery(
      maxMinutes: maxMinutes,
      diet: diet,
      cuisine: cuisine,
      focusIngredient: focusIngredient,
      excludeIngredient: excludeIngredient,
    );
  }
}
