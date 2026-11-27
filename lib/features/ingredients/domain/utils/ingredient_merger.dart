import '../../../../core/domain/expiry_priority.dart';
import '../entities/ingredient.dart';

/// Pure Dart rules for duplicate merging and inventory sorting.
abstract final class IngredientMerger {
  /// Normalizes a name string (trims, lowercase, simple English plural removal:
  /// tomatoes -> tomato, onions -> onion, potatoes -> potato, carrots -> carrot).
  static String normalizeName(String raw) {
    String s = raw.trim().toLowerCase();
    if (s.endsWith('es')) {
      if (s.endsWith('tomatoes')) return s.replaceFirst('tomatoes', 'tomato');
      if (s.endsWith('potatoes')) return s.replaceFirst('potatoes', 'potato');
      if (s.endsWith('berries')) return s.replaceFirst('berries', 'berry');
      // e.g. radishes -> radish
      if (s.endsWith('shes') || s.endsWith('ches') || s.endsWith('sses')) {
        return s.substring(0, s.length - 2);
      }
    }
    if (s.endsWith('s') && !s.endsWith('ss') && !s.endsWith('is') && !s.endsWith('us')) {
      return s.substring(0, s.length - 1);
    }
    return s;
  }

  /// Checks if two calendar dates represent the same year, month, and day.
  static bool areSameDate(DateTime? a, DateTime? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }

  /// Checks if two units are the same (case-insensitive, trimmed).
  static bool areSameUnit(String? a, String? b) {
    final String? cleanA = a?.trim().toLowerCase();
    final String? cleanB = b?.trim().toLowerCase();
    if ((cleanA == null || cleanA.isEmpty) && (cleanB == null || cleanB.isEmpty)) {
      return true;
    }
    return cleanA == cleanB;
  }

  /// Merges [incoming] list of ingredients into an [existing] list according to rules:
  /// - Same normalized name AND same unit AND same expiry date means quantities add up.
  /// - If name matches but expiry or unit differs, keep as separate items.
  /// - If either quantity is null, the merged quantity is null (never guess).
  static List<Ingredient> merge(
    List<Ingredient> existing,
    List<Ingredient> incoming,
  ) {
    final List<Ingredient> result = List<Ingredient>.from(existing);

    for (final Ingredient newItem in incoming) {
      final String newNorm = normalizeName(newItem.name);
      final int matchIndex = result.indexWhere((item) {
        if (!item.status.isActive) return false;
        final bool nameMatch = normalizeName(item.name) == newNorm;
        final bool unitMatch = areSameUnit(item.unit, newItem.unit);
        final bool dateMatch = areSameDate(item.expiryDate, newItem.expiryDate);
        return nameMatch && unitMatch && dateMatch;
      });

      if (matchIndex >= 0) {
        final Ingredient match = result[matchIndex];
        final double? combinedQty;
        if (match.quantity == null || newItem.quantity == null) {
          combinedQty = null;
        } else {
          combinedQty = match.quantity! + newItem.quantity!;
        }

        result[matchIndex] = match.copyWith(
          quantity: () => combinedQty,
        );
      } else {
        result.add(newItem.copyWith(
          name: newNorm,
        ));
      }
    }

    return result;
  }

  /// Inventory sorting rule:
  /// - Expired first, then Critical, High, Medium, Low, Unknown last.
  /// - Ties sorted by days left (ascending), then name (alphabetical).
  static List<Ingredient> sortInventory(List<Ingredient> items, {DateTime? today}) {
    final List<Ingredient> list = List<Ingredient>.from(items);
    list.sort((a, b) {
      final ExpiryPriority prioA = a.priority(today: today);
      final ExpiryPriority prioB = b.priority(today: today);

      final int prioRankA = _priorityRank(prioA);
      final int prioRankB = _priorityRank(prioB);

      if (prioRankA != prioRankB) {
        return prioRankA.compareTo(prioRankB);
      }

      // Tie-breaker 1: days left (ascending)
      final int? daysA = a.daysLeft(today: today);
      final int? daysB = b.daysLeft(today: today);

      if (daysA != null && daysB != null) {
        if (daysA != daysB) return daysA.compareTo(daysB);
      } else if (daysA != null) {
        return -1;
      } else if (daysB != null) {
        return 1;
      }

      // Tie-breaker 2: name
      return a.name.compareTo(b.name);
    });

    return list;
  }

  static int _priorityRank(ExpiryPriority priority) => switch (priority) {
        ExpiryPriority.expired => 0,
        ExpiryPriority.critical => 1,
        ExpiryPriority.high => 2,
        ExpiryPriority.medium => 3,
        ExpiryPriority.low => 4,
        ExpiryPriority.unknown => 5,
      };
}
