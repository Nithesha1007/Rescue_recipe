import 'package:equatable/equatable.dart';
import '../../../recipes/domain/entities/recipe.dart';

enum CookingStatus {
  running,
  paused,
  finished,
}

class CookingSession extends Equatable {
  final Recipe recipe;
  final int currentStepIndex;
  final CookingStatus status;
  final DateTime startedAt;

  const CookingSession({
    required this.recipe,
    this.currentStepIndex = 0,
    this.status = CookingStatus.running,
    required this.startedAt,
  });

  int get totalSteps => recipe.steps.length;

  bool get isFirstStep => currentStepIndex == 0;

  bool get isLastStep => currentStepIndex >= totalSteps - 1;

  String get currentStepText {
    if (recipe.steps.isEmpty) return '';
    final index = currentStepIndex.clamp(0, recipe.steps.length - 1);
    return recipe.steps[index].text;
  }

  CookingSession copyWith({
    Recipe? recipe,
    int? currentStepIndex,
    CookingStatus? status,
    DateTime? startedAt,
  }) {
    return CookingSession(
      recipe: recipe ?? this.recipe,
      currentStepIndex: currentStepIndex ?? this.currentStepIndex,
      status: status ?? this.status,
      startedAt: startedAt ?? this.startedAt,
    );
  }

  @override
  List<Object?> get props => [recipe, currentStepIndex, status, startedAt];
}
