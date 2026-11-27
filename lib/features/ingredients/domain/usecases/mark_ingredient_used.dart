import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cooking/domain/entities/usage_log_entry.dart';
import '../../../cooking/domain/repositories/usage_log_repository.dart';
import '../repositories/ingredient_repository.dart';

class MarkIngredientUsed implements UseCase<void, String> {
  const MarkIngredientUsed(
    this._repository, [
    this._usageLogRepository,
  ]);

  final IngredientRepository _repository;
  final UsageLogRepository? _usageLogRepository;

  @override
  FutureEither<void> call(String id) async {
    final ingredientsResult = await _repository.getActiveIngredients();
    final markResult = await _repository.markUsed(id);

    if (markResult.isRight() && _usageLogRepository != null) {
      ingredientsResult.fold(
        (_) => null,
        (items) {
          final matched = items.where((i) => i.id == id).toList();
          if (matched.isNotEmpty) {
            final item = matched.first;
            _usageLogRepository.logUsage(UsageLogEntry(
              id: '${item.id}_${DateTime.now().millisecondsSinceEpoch}',
              ingredientName: item.name,
              quantity: item.quantity,
              unit: item.unit,
              action: UsageAction.used,
              priorityAtUsage: item.priority(today: DateTime.now()),
              timestamp: DateTime.now(),
            ));
          }
        },
      );
    }

    return markResult;
  }
}

