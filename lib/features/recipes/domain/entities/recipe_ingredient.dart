import 'package:equatable/equatable.dart';

class RecipeIngredient extends Equatable {
  const RecipeIngredient({
    required this.name,
    this.quantity,
    this.unit,
    this.isOptional = false,
    this.isPantryStaple = false,
  });

  final String name;
  final double? quantity;
  final String? unit;
  final bool isOptional;
  final bool isPantryStaple;

  String get displayName {
    if (name.isEmpty) return '';
    return name[0].toUpperCase() + name.substring(1);
  }

  String get displayAmount {
    if (quantity == null) return unit ?? '';
    final formattedQty =
        quantity! % 1 == 0 ? quantity!.toInt().toString() : quantity!.toString();
    if (unit == null || unit!.isEmpty) return formattedQty;
    return '$formattedQty $unit';
  }

  @override
  List<Object?> get props => [name, quantity, unit, isOptional, isPantryStaple];
}
