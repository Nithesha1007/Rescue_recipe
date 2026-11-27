import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/repositories/ingredient_repository.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../entities/inventory_deduction.dart';
import '../utils/inventory_deduction_calculator.dart';

class ComputeInventoryDeductionParams {
  final Recipe recipe;
  final DateTime today;

  const ComputeInventoryDeductionParams({
    required this.recipe,
    required this.today,
  });
}

class ComputeInventoryDeduction
    implements UseCase<List<InventoryDeductionProposal>, ComputeInventoryDeductionParams> {
  final IngredientRepository _ingredientRepository;

  ComputeInventoryDeduction(this._ingredientRepository);

  @override
  FutureEither<List<InventoryDeductionProposal>> call(
    ComputeInventoryDeductionParams params,
  ) async {
    final result = await _ingredientRepository.getActiveIngredients();
    return result.fold(
      (failure) => Left(failure),
      (ingredients) {
        final proposals = InventoryDeductionCalculator.compute(
          inventory: ingredients,
          recipe: params.recipe,
          today: params.today,
        );
        return Right(proposals);
      },
    );
  }
}
