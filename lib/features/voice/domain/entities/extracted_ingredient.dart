import 'package:equatable/equatable.dart';

import '../../../../core/domain/expiry_priority.dart';

class ExtractedIngredient extends Equatable {
  const ExtractedIngredient({
    required this.name,
    this.spokenName,
    this.quantity,
    this.unit,
    this.expiryPhrase,
    this.resolvedExpiry,
    this.expiryUnderstood = true,
  });

  /// Canonical English lowercase ingredient name.
  final String name;
  /// Original spoken name (e.g. "thakkali", "vengayam").
  final String? spokenName;
  final double? quantity;
  final String? unit;
  /// The user's exact words for expiry (e.g. "tomorrow", "in 3 days", "sometime soon").
  final String? expiryPhrase;
  /// Resolved calendar date (from pure Dart ExpiryDateResolver), null if no phrase or unrecognized.
  final DateTime? resolvedExpiry;
  /// Set to false when an expiryPhrase was provided by the user but could not be parsed.
  final bool expiryUnderstood;

  /// Display name capitalized (e.g. "tomato" -> "Tomato").
  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Formatted quantity label (e.g. "3 pieces", "500 g", or "Quantity not given").
  String get quantityLabel {
    if (quantity == null) {
      return 'Quantity not given';
    }
    final String qStr = quantity! % 1 == 0
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(1);
    if (unit == null || unit!.trim().isEmpty) {
      return qStr;
    }
    return '$qStr $unit';
  }

  ExpiryPriority priority({DateTime? today}) =>
      ExpiryPriority.fromDate(resolvedExpiry, today: today);

  int? daysLeft({DateTime? today}) =>
      ExpiryPriority.daysLeft(resolvedExpiry, today: today);

  ExtractedIngredient copyWith({
    String? name,
    String? spokenName,
    double? Function()? quantity,
    String? Function()? unit,
    String? Function()? expiryPhrase,
    DateTime? Function()? resolvedExpiry,
    bool? expiryUnderstood,
  }) {
    return ExtractedIngredient(
      name: name ?? this.name,
      spokenName: spokenName ?? this.spokenName,
      quantity: quantity != null ? quantity() : this.quantity,
      unit: unit != null ? unit() : this.unit,
      expiryPhrase: expiryPhrase != null ? expiryPhrase() : this.expiryPhrase,
      resolvedExpiry:
          resolvedExpiry != null ? resolvedExpiry() : this.resolvedExpiry,
      expiryUnderstood: expiryUnderstood ?? this.expiryUnderstood,
    );
  }

  @override
  List<Object?> get props => [
        name,
        spokenName,
        quantity,
        unit,
        expiryPhrase,
        resolvedExpiry,
        expiryUnderstood,
      ];
}
