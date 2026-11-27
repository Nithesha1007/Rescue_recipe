import 'package:equatable/equatable.dart';
import '../../../../core/domain/expiry_priority.dart';

enum UsageAction {
  reduced,
  used,
  discarded,
}

class UsageLogEntry extends Equatable {
  final String id;
  final String ingredientName;
  final double? quantity;
  final String? unit;
  final UsageAction action;
  final ExpiryPriority priorityAtUsage;
  final String? recipeId;
  final DateTime timestamp;

  const UsageLogEntry({
    required this.id,
    required this.ingredientName,
    this.quantity,
    this.unit,
    required this.action,
    required this.priorityAtUsage,
    this.recipeId,
    required this.timestamp,
  });

  /// True if using this item rescued food from waste (was Critical, High, or Medium priority).
  bool get wasRescued {
    return (action == UsageAction.used || action == UsageAction.reduced) &&
        (priorityAtUsage == ExpiryPriority.critical ||
            priorityAtUsage == ExpiryPriority.high ||
            priorityAtUsage == ExpiryPriority.medium);
  }

  @override
  List<Object?> get props => [
        id,
        ingredientName,
        quantity,
        unit,
        action,
        priorityAtUsage,
        recipeId,
        timestamp,
      ];
}
