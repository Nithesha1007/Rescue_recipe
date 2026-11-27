import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../entities/cooking_session.dart';

class StartCookingParams {
  final Recipe recipe;

  const StartCookingParams(this.recipe);
}

class StartCooking implements UseCase<CookingSession, StartCookingParams> {
  @override
  FutureEither<CookingSession> call(StartCookingParams params) async {
    final session = CookingSession(
      recipe: params.recipe,
      currentStepIndex: 0,
      status: CookingStatus.running,
      startedAt: DateTime.now(),
    );
    return Right(session);
  }
}
