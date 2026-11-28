import 'package:equatable/equatable.dart';

import '../../../../core/domain/expiry_priority.dart';

enum IngredientStatus {
  active,
  used,
  discarded;

  bool get isActive => this == IngredientStatus.active;
  bool get isUsed => this == IngredientStatus.used;
  bool get isDiscarded => this == IngredientStatus.discarded;
}

enum StorageLocation {
  fridge('Fridge', '❄️'),
  freezer('Freezer', '🧊'),
  pantry('Pantry', '🥫');

  const StorageLocation(this.displayName, this.emoji);
  final String displayName;
  final String emoji;
}

class Ingredient extends Equatable {
  const Ingredient({
    required this.id,
    required this.name,
    this.quantity,
    this.unit,
    this.expiryDate,
    required this.addedAt,
    this.status = IngredientStatus.active,
    this.statusChangedAt,
    this.storage = StorageLocation.pantry,
  });

  final String id;
  /// Normalized lowercase for matching; UI formats display name with capitalization.
  final String name;
  final double? quantity;
  final String? unit;
  /// Calendar date only (no time).
  final DateTime? expiryDate;
  final DateTime addedAt;
  final IngredientStatus status;
  final DateTime? statusChangedAt;
  final StorageLocation storage;

  /// Display name capitalized (e.g. "tomato" -> "Tomato").
  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  /// Formatted quantity label (e.g. "3 pieces", "500 g", or "Quantity not specified").
  String get quantityLabel {
    if (quantity == null) {
      return 'Quantity not specified';
    }
    // Format double to integer if no fraction
    final String qStr = quantity! % 1 == 0
        ? quantity!.toInt().toString()
        : quantity!.toStringAsFixed(1);
    if (unit == null || unit!.trim().isEmpty) {
      return qStr;
    }
    return '$qStr $unit';
  }

  /// Calculates expiry priority given an optional [today] date.
  ExpiryPriority priority({DateTime? today}) =>
      ExpiryPriority.fromDate(expiryDate, today: today);

  /// Calculates calendar days remaining given an optional [today] date.
  int? daysLeft({DateTime? today}) =>
      ExpiryPriority.daysLeft(expiryDate, today: today);

  Ingredient copyWith({
    String? id,
    String? name,
    double? Function()? quantity,
    String? Function()? unit,
    DateTime? Function()? expiryDate,
    DateTime? addedAt,
    IngredientStatus? status,
    DateTime? Function()? statusChangedAt,
    StorageLocation? storage,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity != null ? quantity() : this.quantity,
      unit: unit != null ? unit() : this.unit,
      expiryDate: expiryDate != null ? expiryDate() : this.expiryDate,
      addedAt: addedAt ?? this.addedAt,
      status: status ?? this.status,
      statusChangedAt:
          statusChangedAt != null ? statusChangedAt() : this.statusChangedAt,
      storage: storage ?? this.storage,
    );
  }

  @override
  List<Object?> get props => [
        id,
        name,
        quantity,
        unit,
        expiryDate,
        addedAt,
        status,
        statusChangedAt,
        storage,
      ];
}
