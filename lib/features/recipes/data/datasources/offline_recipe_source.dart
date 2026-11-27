import '../../domain/entities/diet_tag.dart';
import '../../domain/entities/recipe.dart';
import '../../domain/entities/recipe_ingredient.dart';
import '../../domain/entities/recipe_step.dart';
import '../../domain/entities/substitution.dart';

/// Bundled static recipes that require no network access or assets.
/// 12 curated dishes covering South Indian staples, stir-fries, soups, pasta, and quick snacks.
/// Evaluated by the same RescueFirstRanker and IngredientMatcher as Gemini recipes.
class OfflineRecipeSource {
  OfflineRecipeSource._();

  static const List<Recipe> recipes = <Recipe>[
    // 1. Tomato Spinach Scramble (Breakfast / Quick)
    Recipe(
      id: 'offline_1',
      title: 'Tomato Spinach Scramble',
      minutes: 15,
      servings: 2,
      cuisine: 'Continental',
      difficulty: 'Easy',
      tips: ['Cook over medium-low heat for soft, creamy scrambled curds.'],
      dietTags: {
        DietTag.vegetarian,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'spinach', quantity: 100, unit: 'g'),
        RecipeIngredient(name: 'egg', quantity: 3, unit: 'pieces'),
        RecipeIngredient(name: 'butter', quantity: 1, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'black pepper', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Dice the tomatoes and roughly chop the spinach.', minutes: 3, tip: 'Remove excess tomato seeds to prevent a watery scramble.'),
        RecipeStep(text: 'Melt the butter in a non-stick skillet over medium heat.', minutes: 2),
        RecipeStep(text: 'Add the tomatoes and spinach and sauté until wilted.', minutes: 3),
        RecipeStep(text: 'Whisk the eggs in a small bowl with salt and pepper.', minutes: 2),
        RecipeStep(text: 'Pour the eggs into the pan and gently scramble until softly set.', minutes: 5, tip: 'Take off the heat just before fully set, as carryover heat finishes cooking.'),
      ],
      substitutions: [
        Substitution(missingIngredient: 'egg', substitute: 'firm tofu', note: 'Crumble and season with turmeric for a plant-based scramble.'),
        Substitution(missingIngredient: 'butter', substitute: 'olive oil', note: 'Use 1 tablespoon of olive oil or vegetable oil instead.'),
      ],
      source: RecipeSource.offline,
    ),

    // 2. Potato Onion Hash (Breakfast / Snacks)
    Recipe(
      id: 'offline_2',
      title: 'Potato Onion Hash',
      minutes: 25,
      servings: 2,
      cuisine: 'Continental',
      difficulty: 'Easy',
      tips: ['Parboil or microwave diced potatoes for 2 minutes first to speed up crisping.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'potato', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'cooking oil', quantity: 2, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'black pepper', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'paprika', quantity: 0.5, unit: 'tsp', isOptional: true, isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Peel and cut the potatoes into small half-inch cubes.', minutes: 5),
        RecipeStep(text: 'Finely dice the onion.', minutes: 2),
        RecipeStep(text: 'Heat cooking oil in a wide frying pan over medium-high heat.', minutes: 3),
        RecipeStep(text: 'Add potatoes and onions, seasoning evenly with salt and pepper.', minutes: 2),
        RecipeStep(text: 'Cook undisturbed for five minutes to develop a golden crust, then flip and finish until tender.', minutes: 13, tip: 'Resist stirring constantly so the edges get crispy.'),
      ],
      substitutions: [
        Substitution(missingIngredient: 'potato', substitute: 'sweet potato', note: 'Sweet potatoes give a sweeter, caramelized hash flavor.'),
        Substitution(missingIngredient: 'onion', substitute: 'scallions or leeks', note: 'Use 2 green scallions or leek greens sliced thinly.'),
      ],
      source: RecipeSource.offline,
    ),

    // 3. Rustic Tomato Onion Soup (Soup / Continental)
    Recipe(
      id: 'offline_3',
      title: 'Rustic Tomato Onion Soup',
      minutes: 30,
      servings: 3,
      cuisine: 'Continental',
      difficulty: 'Easy',
      tips: ['Add a pinch of sugar if your tomatoes are very tart.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'tomato', quantity: 4, unit: 'pieces'),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'water', quantity: 2, unit: 'cups', isPantryStaple: true),
        RecipeIngredient(name: 'olive oil', quantity: 1, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 1, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'garlic', quantity: 2, unit: 'cloves', isOptional: true),
      ],
      steps: [
        RecipeStep(text: 'Roughly chop the tomatoes and slice the onion.', minutes: 5),
        RecipeStep(text: 'Heat olive oil in a deep pot and cook the onions until soft and translucent.', minutes: 5, tip: 'Slowly softening the onion releases natural sweetness.'),
        RecipeStep(text: 'Add the chopped tomatoes, garlic, salt, and water.', minutes: 3),
        RecipeStep(text: 'Simmer gently over medium heat for fifteen minutes.', minutes: 15),
        RecipeStep(text: 'Ladle directly into bowls for a rustic chunky texture, or blend if preferred.', minutes: 2),
      ],
      substitutions: [
        Substitution(missingIngredient: 'tomato', substitute: 'canned diced tomatoes', note: 'One 400g can of crushed or diced tomatoes works seamlessly.'),
      ],
      source: RecipeSource.offline,
    ),

    // 4. South Indian Tomato Rice (Thakkali Sadam - South Indian)
    Recipe(
      id: 'offline_4',
      title: 'South Indian Tomato Rice',
      minutes: 20,
      servings: 2,
      cuisine: 'South Indian',
      difficulty: 'Easy',
      tips: ['Use leftover chilled rice for separate, fluffy grains.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'rice', quantity: 2, unit: 'cups'),
        RecipeIngredient(name: 'tomato', quantity: 3, unit: 'pieces'),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'mustard seeds', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'curry leaves', quantity: 1, unit: 'sprig', isOptional: true),
        RecipeIngredient(name: 'cooking oil', quantity: 1.5, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'turmeric', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 1, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Chop onions finely and puree or finely dice tomatoes.', minutes: 4),
        RecipeStep(text: 'Heat oil in a pan, crackle mustard seeds and curry leaves.', minutes: 2, tip: 'Wait until the mustard seeds pop fully before adding onions.'),
        RecipeStep(text: 'Add onions and sauté until golden brown.', minutes: 4),
        RecipeStep(text: 'Add tomatoes, turmeric, and salt; cook until oil separates from the masala.', minutes: 6, tip: 'Cooking the tomatoes until mushy concentrates the tangy flavor.'),
        RecipeStep(text: 'Gently fold in cooked rice until every grain is evenly coated.', minutes: 4),
      ],
      substitutions: [
        Substitution(missingIngredient: 'mustard seeds', substitute: 'cumin seeds', note: 'Cumin seeds provide a warm, earthy tempering.'),
      ],
      source: RecipeSource.offline,
    ),

    // 5. Quick Pepper Rasam (South Indian)
    Recipe(
      id: 'offline_5',
      title: 'Quick Pepper Rasam',
      minutes: 15,
      servings: 3,
      cuisine: 'South Indian',
      difficulty: 'Easy',
      tips: ['Do not boil rasam for too long after adding tempering; turn off once it begins to froth.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'garlic', quantity: 4, unit: 'cloves'),
        RecipeIngredient(name: 'black pepper', quantity: 1, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'cumin seeds', quantity: 1, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'coriander', quantity: 2, unit: 'tbsp', isOptional: true),
        RecipeIngredient(name: 'water', quantity: 3, unit: 'cups', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 1, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Crush the garlic, cumin seeds, and black pepper coarsely using a mortar or grinder.', minutes: 3, tip: 'Coarse crushing brings out intense aroma without making the rasam cloudy.'),
        RecipeStep(text: 'Mash the tomatoes into water with salt and turmeric in a vessel.', minutes: 3),
        RecipeStep(text: 'Add the crushed pepper-garlic mixture and bring to a gentle simmer.', minutes: 5),
        RecipeStep(text: 'Turn off heat as soon as frothy foam appears on top, then garnish with fresh coriander.', minutes: 4),
      ],
      substitutions: [
        Substitution(missingIngredient: 'tomato', substitute: 'lemon juice', note: 'Add 2 tablespoons of fresh lemon juice at the end for lemon rasam.'),
      ],
      source: RecipeSource.offline,
    ),

    // 6. Onion Tomato Chutney (South Indian / Quick)
    Recipe(
      id: 'offline_6',
      title: 'Quick Onion Tomato Chutney',
      minutes: 15,
      servings: 4,
      cuisine: 'South Indian',
      difficulty: 'Easy',
      tips: ['Pairs perfectly with dosa, idli, upma, or toasted bread.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'onion', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'tomato', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'red chili', quantity: 2, unit: 'pieces', isOptional: true),
        RecipeIngredient(name: 'garlic', quantity: 2, unit: 'cloves'),
        RecipeIngredient(name: 'cooking oil', quantity: 1, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.75, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Roughly chop onions, tomatoes, and garlic.', minutes: 3),
        RecipeStep(text: 'Heat oil in a skillet and sauté garlic, red chilies, and onions until soft.', minutes: 5),
        RecipeStep(text: 'Add tomatoes and salt, cooking until soft and pulpy.', minutes: 4, tip: 'Ensure tomatoes lose their raw edge for sweet and tangy balance.'),
        RecipeStep(text: 'Cool for 3 minutes and blend into a smooth or textured chutney.', minutes: 3),
      ],
      substitutions: [
        Substitution(missingIngredient: 'red chili', substitute: 'black pepper or chili powder', note: 'Use 0.5 tsp of chili powder or crushed black pepper for heat.'),
      ],
      source: RecipeSource.offline,
    ),

    // 7. Spiced Potato Poriyal (South Indian / Stir-fry)
    Recipe(
      id: 'offline_7',
      title: 'Spiced Potato Poriyal',
      minutes: 20,
      servings: 2,
      cuisine: 'South Indian',
      difficulty: 'Easy',
      tips: ['Cook in a cast-iron skillet for extra golden roasted bits.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'potato', quantity: 3, unit: 'pieces'),
        RecipeIngredient(name: 'mustard seeds', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'curry leaves', quantity: 1, unit: 'sprig', isOptional: true),
        RecipeIngredient(name: 'turmeric', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'chili powder', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'cooking oil', quantity: 1.5, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.75, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Boil or steam potatoes until tender, then peel and dice into bite-sized cubes.', minutes: 8, tip: 'Do not overcook or the potatoes will turn to mash during stir-frying.'),
        RecipeStep(text: 'Heat oil in a pan, sputter mustard seeds and curry leaves.', minutes: 2),
        RecipeStep(text: 'Add the potatoes, turmeric, chili powder, and salt.', minutes: 2),
        RecipeStep(text: 'Roast over medium heat for eight minutes, tossing occasionally for crispy edges.', minutes: 8),
      ],
      substitutions: [
        Substitution(missingIngredient: 'potato', substitute: 'carrot or cabbage', note: 'Carrot and cabbage stir-fry well with the same tempering.'),
      ],
      source: RecipeSource.offline,
    ),

    // 8. Homestyle Vegetable Upma (South Indian / Breakfast)
    Recipe(
      id: 'offline_8',
      title: 'Homestyle Vegetable Upma',
      minutes: 20,
      servings: 2,
      cuisine: 'South Indian',
      difficulty: 'Easy',
      tips: ['Dry-roast semolina (rava) over low flame until fragrant before adding to boiling water.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
      },
      ingredients: [
        RecipeIngredient(name: 'semolina', quantity: 1, unit: 'cup'),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'carrot', quantity: 1, unit: 'piece', isOptional: true),
        RecipeIngredient(name: 'ginger', quantity: 1, unit: 'tsp'),
        RecipeIngredient(name: 'green chili', quantity: 1, unit: 'piece', isOptional: true),
        RecipeIngredient(name: 'mustard seeds', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'cooking oil', quantity: 1.5, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'water', quantity: 2.5, unit: 'cups', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 1, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Finely chop the onion, carrot, ginger, and chili.', minutes: 4),
        RecipeStep(text: 'Heat oil in a pan, temper with mustard seeds, then sauté onions, ginger, and vegetables until soft.', minutes: 4),
        RecipeStep(text: 'Add water and salt, bringing the mixture to a rolling boil.', minutes: 4, tip: 'Water must be boiling vigorously so the semolina cooks evenly without lumps.'),
        RecipeStep(text: 'Gradually pour semolina in a steady stream while whisking continuously.', minutes: 3),
        RecipeStep(text: 'Cover with a lid on low heat for five minutes to steam and fluff.', minutes: 5),
      ],
      substitutions: [
        Substitution(missingIngredient: 'semolina', substitute: 'oats or broken wheat', note: 'Rolled oats make a quick, wholesome upma with the same vegetables.'),
      ],
      source: RecipeSource.offline,
    ),

    // 9. Garlic Olive Oil Pasta (Aglio e Olio - Continental)
    Recipe(
      id: 'offline_9',
      title: 'Garlic Olive Oil Pasta',
      minutes: 15,
      servings: 2,
      cuisine: 'Continental',
      difficulty: 'Easy',
      tips: ['Save half a cup of starchy pasta water to emulsify the garlic oil into a silky sauce.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
      },
      ingredients: [
        RecipeIngredient(name: 'pasta', quantity: 200, unit: 'g'),
        RecipeIngredient(name: 'garlic', quantity: 4, unit: 'cloves'),
        RecipeIngredient(name: 'olive oil', quantity: 3, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'chili flakes', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 1, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'black pepper', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Boil pasta in salted water until al dente, reserving 1/2 cup pasta cooking water before draining.', minutes: 8),
        RecipeStep(text: 'Thinly slice garlic cloves.', minutes: 2),
        RecipeStep(text: 'In a wide skillet, warm olive oil over gentle heat and sauté garlic slices until pale gold.', minutes: 3, tip: 'Do not burn garlic or it turns bitter; remove from heat if browning too fast.'),
        RecipeStep(text: 'Add chili flakes, drained pasta, and a splash of reserved pasta water.', minutes: 1),
        RecipeStep(text: 'Toss vigorously for one minute until the pasta is coated in a glistening sauce.', minutes: 1),
      ],
      substitutions: [
        Substitution(missingIngredient: 'olive oil', substitute: 'butter', note: 'Butter creates a rich garlic butter noodles variation.'),
      ],
      source: RecipeSource.offline,
    ),

    // 10. Quick Vegetable Stir-Fry Rice (Chinese-style)
    Recipe(
      id: 'offline_10',
      title: 'Quick Vegetable Stir-Fry Rice',
      minutes: 20,
      servings: 2,
      cuisine: 'Chinese-style',
      difficulty: 'Easy',
      tips: ['Stir-fry on high heat in a wide pan so veggies remain crisp and tender.'],
      dietTags: {
        DietTag.vegan,
        DietTag.vegetarian,
        DietTag.dairyFree,
        DietTag.eggFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'rice', quantity: 2, unit: 'cups'),
        RecipeIngredient(name: 'carrot', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'cabbage', quantity: 100, unit: 'g', isOptional: true),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'garlic', quantity: 2, unit: 'cloves'),
        RecipeIngredient(name: 'soy sauce', quantity: 1, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'cooking oil', quantity: 1.5, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'black pepper', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Thinly shred cabbage, dice carrots, and mince garlic and onions.', minutes: 5),
        RecipeStep(text: 'Heat cooking oil on high heat in a wok or skillet.', minutes: 2),
        RecipeStep(text: 'Add garlic and onions, tossing rapidly for one minute.', minutes: 1),
        RecipeStep(text: 'Add cabbage and carrots, stir-frying vigorously for three minutes.', minutes: 3, tip: 'Keep tossing so vegetables blister without releasing moisture.'),
        RecipeStep(text: 'Add cooked rice, soy sauce, and black pepper, tossing together until piping hot.', minutes: 4),
      ],
      substitutions: [
        Substitution(missingIngredient: 'soy sauce', substitute: 'salt and a squeeze of lemon', note: 'Salt and lemon deliver clean seasoning without soy.'),
      ],
      source: RecipeSource.offline,
    ),

    // 11. Spiced Paneer Bhurji (North Indian)
    Recipe(
      id: 'offline_11',
      title: 'Spiced Paneer Bhurji',
      minutes: 15,
      servings: 2,
      cuisine: 'North Indian',
      difficulty: 'Easy',
      tips: ['Crumble paneer softly with fingers instead of grating to preserve a rich texture.'],
      dietTags: {
        DietTag.vegetarian,
        DietTag.glutenFree,
        DietTag.eggFree,
      },
      ingredients: [
        RecipeIngredient(name: 'paneer', quantity: 150, unit: 'g'),
        RecipeIngredient(name: 'onion', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'tomato', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'green chili', quantity: 1, unit: 'piece', isOptional: true),
        RecipeIngredient(name: 'turmeric', quantity: 0.25, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'cumin seeds', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'butter', quantity: 1, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Chop onion and tomato finely, and crumble paneer into uneven chunks.', minutes: 4),
        RecipeStep(text: 'Melt butter in a pan, crackle cumin seeds, then sauté onions until light golden.', minutes: 4),
        RecipeStep(text: 'Add tomatoes, chili, turmeric, and salt, cooking until soft and juicy.', minutes: 3),
        RecipeStep(text: 'Toss in crumbled paneer and cook for just two minutes until warmed through.', minutes: 2, tip: 'Do not overcook paneer or it will turn chewy and rubbery.'),
        RecipeStep(text: 'Remove from heat immediately and serve hot with rotis or bread.', minutes: 2),
      ],
      substitutions: [
        Substitution(missingIngredient: 'paneer', substitute: 'firm tofu', note: 'Crumbled tofu makes a delicious 100% plant-based bhurji.'),
      ],
      source: RecipeSource.offline,
    ),

    // 12. Quick Masala Egg Roast (South Indian / Quick snacks)
    Recipe(
      id: 'offline_12',
      title: 'Quick Masala Egg Roast',
      minutes: 20,
      servings: 2,
      cuisine: 'Quick snacks',
      difficulty: 'Easy',
      tips: ['Make shallow slits on boiled eggs so spices penetrate deep into the whites.'],
      dietTags: {
        DietTag.dairyFree,
        DietTag.glutenFree,
      },
      ingredients: [
        RecipeIngredient(name: 'egg', quantity: 3, unit: 'pieces'),
        RecipeIngredient(name: 'onion', quantity: 2, unit: 'pieces'),
        RecipeIngredient(name: 'tomato', quantity: 1, unit: 'piece'),
        RecipeIngredient(name: 'chili powder', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'black pepper', quantity: 0.5, unit: 'tsp', isPantryStaple: true),
        RecipeIngredient(name: 'curry leaves', quantity: 1, unit: 'sprig', isOptional: true),
        RecipeIngredient(name: 'cooking oil', quantity: 1.5, unit: 'tbsp', isPantryStaple: true),
        RecipeIngredient(name: 'salt', quantity: 0.75, unit: 'tsp', isPantryStaple: true),
      ],
      steps: [
        RecipeStep(text: 'Hard-boil the eggs for nine minutes, then peel and slice in halves or score with shallow slits.', minutes: 10),
        RecipeStep(text: 'Finely slice the onions and chop the tomato.', minutes: 3),
        RecipeStep(text: 'Heat oil in a pan, add curry leaves, and sauté onions until deep golden caramel brown.', minutes: 4, tip: 'Caramelizing onions deepens the sweet-savory flavor of the roast.'),
        RecipeStep(text: 'Add tomatoes, chili powder, black pepper, and salt, cooking into a thick masala paste.', minutes: 2),
        RecipeStep(text: 'Gently add the boiled eggs, spooning the rich onion masala over them for two minutes.', minutes: 1),
      ],
      substitutions: [
        Substitution(missingIngredient: 'egg', substitute: 'boiled baby potatoes or mushrooms', note: 'Baby potatoes or halved button mushrooms absorb this masala wonderfully.'),
      ],
      source: RecipeSource.offline,
    ),
  ];
}
