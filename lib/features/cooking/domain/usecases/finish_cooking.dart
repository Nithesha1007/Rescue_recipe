import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/repositories/ingredient_repository.dart';
import '../entities/inventory_deduction.dart';
import '../entities/usage_log_entry.dart';
import '../repositories/usage_log_repository.dart';

class FinishCookingParams {
  final String recipeId;
  final List<InventoryDeductionProposal> confirmedProposals;
  final DateTime timestamp;

  const FinishCookingParams({
    required this.recipeId,
    required this.confirmedProposals,
    required this.timestamp,
  });
}

class FinishCookingResult {
  final int rescuedCount;
  final int totalDeducted;

  const FinishCookingResult({
    required this.rescuedCount,
    required this.totalDeducted,
  });
}

class FinishCooking implements UseCase<FinishCookingResult, FinishCookingParams> {
  final IngredientRepository _ingredientRepository;
  final UsageLogRepository _usageLogRepository;

  FinishCooking(this._ingredientRepository, this._usageLogRepository);

  @override
  FutureEither<FinishCookingResult> call(FinishCookingParams params) async {
    int rescuedCount = 0;
    int totalDeducted = 0;

    for (final proposal in params.confirmedProposals) {
      if (!proposal.isConfirmed) continue;

      if (proposal.action == DeductionAction.markUsed) {
        final markResult = await _ingredientRepository.markUsed(proposal.ingredientId);
        if (markResult.isLeft()) {
          return Left(markResult.getLeft().toNullable()!);
        }

        final logEntry = UsageLogEntry(
          id: '${proposal.ingredientId}_${params.timestamp.millisecondsSinceEpoch}',
          ingredientName: proposal.ingredientName,
          quantity: proposal.currentQuantity,
          unit: proposal.unit,
          action: UsageAction.used,
          priorityAtUsage: proposal.priority,
          recipeId: params.recipeId,
          timestamp: params.timestamp,
        );
        await _usageLogRepository.logUsage(logEntry);
        if (logEntry.wasRescued) rescuedCount++;
        totalDeducted++;
      } else if (proposal.action == DeductionAction.reduce && proposal.remainingQuantity != null) {
        final currentIngredientsResult = await _ingredientRepository.getActiveIngredients();
        if (currentIngredientsResult.isRight()) {
          final items = currentIngredientsResult.getOrElse((_) => []);
          final matchingItem = items.where((i) => i.id == proposal.ingredientId).toList();
          if (matchingItem.isNotEmpty) {
            final updatedItem = matchingItem.first.copyWith(
              quantity: () => proposal.remainingQuantity,
            );
            final updateResult = await _ingredientRepository.updateIngredient(updatedItem);
            if (updateResult.isLeft()) {
              return Left(updateResult.getLeft().toNullable()!);
            }

            final logEntry = UsageLogEntry(
              id: '${proposal.ingredientId}_${params.timestamp.millisecondsSinceEpoch}',
              ingredientName: proposal.ingredientName,
              quantity: proposal.deductQuantity,
              unit: proposal.unit,
              action: UsageAction.reduced,
              priorityAtUsage: proposal.priority,
              recipeId: params.recipeId,
              timestamp: params.timestamp,
            );
            await _usageLogRepository.logUsage(logEntry);
            if (logEntry.wasRescued) rescuedCount++;
            totalDeducted++;
          }
        }
      }
    }

    return Right(FinishCookingResult(
      rescuedCount: rescuedCount,
      totalDeducted: totalDeducted,
    ));
  }
}
