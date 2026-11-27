import 'package:equatable/equatable.dart';

import '../../domain/entities/diet_tag.dart';

abstract class RecipesEvent extends Equatable {
  const RecipesEvent();

  @override
  List<Object?> get props => [];
}

class LoadRecipes extends RecipesEvent {
  const LoadRecipes({
    this.forceRefresh = false,
  });

  final bool forceRefresh;

  @override
  List<Object?> get props => [forceRefresh];
}

class RefreshRecipes extends RecipesEvent {
  const RefreshRecipes();
}

class ChangeDiet extends RecipesEvent {
  const ChangeDiet(this.diet);

  final DietTag diet;

  @override
  List<Object?> get props => [diet];
}
