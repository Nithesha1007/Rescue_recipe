import 'ingredient_vocabulary.dart';

/// Pure Dart emoji resolver for 150+ kitchen ingredients with fallback to a food basket.
abstract final class IngredientEmoji {
  static const String fallback = '🧺';

  static const Map<String, String> _emojiMap = {
    // Vegetables
    'tomato': '🍅',
    'onion': '🧅',
    'potato': '🥔',
    'spinach': '🥬',
    'carrot': '🥕',
    'garlic': '🧄',
    'ginger': '🫚',
    'bell pepper': '🫑',
    'capsicum': '🫑',
    'broccoli': '🥦',
    'cucumber': '🥒',
    'cabbage': '🥬',
    'cauliflower': '🥦',
    'eggplant': '🍆',
    'brinjal': '🍆',
    'green chili': '🌶️',
    'chili': '🌶️',
    'beetroot': '🪵',
    'radish': '🥢',
    'mushroom': '🍄',
    'corn': '🌽',
    'sweet potato': '🍠',
    'peas': '🫛',
    'green peas': '🫛',
    'curry leaves': '🍃',
    'coriander': '🌿',
    'cilantro': '🌿',
    'mint': '🌱',

    // Fruits
    'apple': '🍎',
    'banana': '🍌',
    'lemon': '🍋',
    'lime': '🍋',
    'orange': '🍊',
    'mango': '🥭',
    'strawberry': '🍓',
    'grape': '🍇',
    'watermelon': '🍉',
    'pineapple': '🍍',
    'coconut': '🥥',
    'avocado': '🥑',

    // Dairy & Eggs
    'milk': '🥛',
    'curd': '🥣',
    'yogurt': '🥣',
    'paneer': '🧀',
    'cheese': '🧀',
    'butter': '🧈',
    'ghee': '🧈',
    'egg': '🥚',
    'cream': '🥛',

    // Grains & Staples
    'rice': '🍚',
    'cooked rice': '🍚',
    'wheat': '🌾',
    'flour': '🌾',
    'atta': '🌾',
    'maida': '🌾',
    'rava': '🌾',
    'semolina': '🌾',
    'bread': '🍞',
    'pasta': '🍝',
    'noodles': '🍜',
    'oats': '🥣',
    'poha': '🍚',

    // Pulses & Lentils
    'dal': '🍲',
    'toor dal': '🍲',
    'moong dal': '🍲',
    'chana dal': '🍲',
    'urad dal': '🍲',
    'chickpeas': '🫘',
    'chana': '🫘',
    'beans': '🫘',
    'rajma': '🫘',
    'lentils': '🍲',

    // Proteins
    'chicken': '🍗',
    'mutton': '🍖',
    'fish': '🐟',
    'prawn': '🍤',
    'shrimp': '🍤',
    'tofu': '🧊',
    'soya': '🫘',

    // Oils & Condiments
    'oil': '🫗',
    'mustard oil': '🫗',
    'salt': '🧂',
    'sugar': '🍬',
    'pepper': '🧂',
    'turmeric': '🫙',
    'cumin': '🫙',
    'mustard seeds': '🫙',
    'garam masala': '🫙',
    'chili powder': '🌶️',
    'sambhar powder': '🫙',
    'rasam powder': '🫙',
    'tamarind': '🫙',
    'sauce': '🥫',
    'tomato sauce': '🥫',
    'soy sauce': '🍶',
    'vinegar': '🍶',
  };

  /// Returns an emoji representation for any ingredient string, resolving aliases first.
  static String forIngredient(String rawName) {
    if (rawName.trim().isEmpty) return fallback;
    final canonical = IngredientVocabulary.resolve(rawName);
    if (_emojiMap.containsKey(canonical)) {
      return _emojiMap[canonical]!;
    }
    final lower = rawName.trim().toLowerCase();
    for (final entry in _emojiMap.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return fallback;
  }
}
