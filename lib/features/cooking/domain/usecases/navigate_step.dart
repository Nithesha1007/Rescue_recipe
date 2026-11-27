import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/cooking_session.dart';

enum StepNavigationDirection {
  next,
  previous,
  goToStep,
  startOver,
}

class NavigateStepParams {
  final CookingSession session;
  final StepNavigationDirection direction;
  final int? targetStep; // 1-based index if direction is goToStep

  const NavigateStepParams({
    required this.session,
    required this.direction,
    this.targetStep,
  });
}

class NavigateStep implements UseCase<CookingSession, NavigateStepParams> {
  @override
  FutureEither<CookingSession> call(NavigateStepParams params) async {
    final session = params.session;
    final totalSteps = session.totalSteps;

    if (totalSteps == 0) {
      return Right(session);
    }

    int nextIndex = session.currentStepIndex;

    switch (params.direction) {
      case StepNavigationDirection.next:
        if (nextIndex < totalSteps - 1) {
          nextIndex++;
        }
        break;
      case StepNavigationDirection.previous:
        if (nextIndex > 0) {
          nextIndex--;
        }
        break;
      case StepNavigationDirection.goToStep:
        if (params.targetStep != null) {
          final zeroBased = params.targetStep! - 1;
          nextIndex = zeroBased.clamp(0, totalSteps - 1);
        }
        break;
      case StepNavigationDirection.startOver:
        nextIndex = 0;
        break;
    }

    return Right(session.copyWith(currentStepIndex: nextIndex));
  }
}
