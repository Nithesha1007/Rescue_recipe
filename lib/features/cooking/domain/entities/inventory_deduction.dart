import 'package:equatable/equatable.dart';
import '../../../../core/domain/expiry_priority.dart';

enum DeductionAction {
  reduce,
  markUsed,
}

class InventoryDeductionProposal extends Equatable {
  final String ingredientId;
  final String ingredientName;
  final double currentQuantity;
  final double? deductQuantity;
  final double? remainingQuantity;
  final String unit;
  final DeductionAction action;
  final ExpiryPriority priority;
  final bool isConfirmed;

  const InventoryDeductionProposal({
    required this.ingredientId,
    required this.ingredientName,
    required this.currentQuantity,
    this.deductQuantity,
    this.remainingQuantity,
    required this.unit,
    required this.action,
    required this.priority,
    this.isConfirmed = true,
  });

  InventoryDeductionProposal copyWith({
    String? ingredientId,
    String? ingredientName,
    double? currentQuantity,
    double? deductQuantity,
    double? remainingQuantity,
    String? unit,
    DeductionAction? action,
    ExpiryPriority? priority,
    bool? isConfirmed,
  }) {
    return InventoryDeductionProposal(
      ingredientId: ingredientId ?? this.ingredientId,
      ingredientName: ingredientName ?? this.ingredientName,
      currentQuantity: currentQuantity ?? this.currentQuantity,
      deductQuantity: deductQuantity ?? this.deductQuantity,
      remainingQuantity: remainingQuantity ?? this.remainingQuantity,
      unit: unit ?? this.unit,
      action: action ?? this.action,
      priority: priority ?? this.priority,
      isConfirmed: isConfirmed ?? this.isConfirmed,
    );
  }

  @override
  List<Object?> get props => [
        ingredientId,
        ingredientName,
        currentQuantity,
        deductQuantity,
        remainingQuantity,
        unit,
        action,
        priority,
        isConfirmed,
      ];
}
