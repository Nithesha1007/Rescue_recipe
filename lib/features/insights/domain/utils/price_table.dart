class PriceTable {
  // Approximate bundled prices in INR per standard unit:
  // kg for solids, l for liquids, piece for items counted individually
  static const Map<String, (double price, String baseUnit)> prices = {
    'tomato': (40.0, 'kg'),
    'tomatoes': (40.0, 'kg'),
    'potato': (30.0, 'kg'),
    'potatoes': (30.0, 'kg'),
    'onion': (35.0, 'kg'),
    'onions': (35.0, 'kg'),
    'spinach': (30.0, 'kg'),
    'milk': (60.0, 'l'),
    'egg': (7.0, 'piece'),
    'eggs': (7.0, 'piece'),
    'cheese': (400.0, 'kg'),
    'paneer': (360.0, 'kg'),
    'carrot': (50.0, 'kg'),
    'carrots': (50.0, 'kg'),
    'apple': (120.0, 'kg'),
    'apples': (120.0, 'kg'),
    'banana': (50.0, 'kg'),
    'bananas': (5.0, 'piece'),
    'bread': (45.0, 'piece'),
    'cucumber': (30.0, 'kg'),
    'bell pepper': (80.0, 'kg'),
    'capsicum': (80.0, 'kg'),
    'yogurt': (70.0, 'kg'),
    'curd': (70.0, 'kg'),
    'chicken': (240.0, 'kg'),
    'garlic': (200.0, 'kg'),
    'ginger': (150.0, 'kg'),
    'rice': (60.0, 'kg'),
    'flour': (40.0, 'kg'),
  };

  /// Estimates value of an ingredient. Returns null if unknown or units incompatible.
  static double? estimatePrice({
    required String name,
    required double? quantity,
    required String? unit,
  }) {
    if (quantity == null || quantity <= 0) return null;

    final normName = name.trim().toLowerCase();
    final entry = prices[normName];
    if (entry == null) return null;

    final basePrice = entry.$1;
    final baseUnit = entry.$2;
    final u = unit?.trim().toLowerCase() ?? '';

    // Convert unit to baseUnit
    final convertedQty = _convert(quantity, u, baseUnit);
    if (convertedQty == null) return null;

    return convertedQty * basePrice;
  }

  static double? _convert(double qty, String fromUnit, String baseUnit) {
    if (fromUnit == baseUnit) return qty;

    if (baseUnit == 'kg') {
      if (fromUnit == 'g' || fromUnit == 'gram' || fromUnit == 'grams') {
        return qty / 1000.0;
      }
      if (fromUnit == 'kg' || fromUnit == 'kgs' || fromUnit == 'kilogram') {
        return qty;
      }
    } else if (baseUnit == 'l') {
      if (fromUnit == 'ml' || fromUnit == 'milliliter' || fromUnit == 'milliliters') {
        return qty / 1000.0;
      }
      if (fromUnit == 'l' || fromUnit == 'liter' || fromUnit == 'liters') {
        return qty;
      }
    } else if (baseUnit == 'piece') {
      if (fromUnit == 'piece' ||
          fromUnit == 'pieces' ||
          fromUnit == 'item' ||
          fromUnit == 'items' ||
          fromUnit == '' ||
          fromUnit == 'eggs' ||
          fromUnit == 'egg') {
        return qty;
      }
    }

    return null;
  }
}
