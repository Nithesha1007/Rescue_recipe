import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/diet_tag.dart';
import '../../domain/usecases/generate_recipes.dart';
import '../../domain/usecases/update_diet_preference.dart';
import 'recipes_event.dart';
import 'recipes_state.dart';

class RecipesBloc extends Bloc<RecipesEvent, RecipesState> {
  RecipesBloc({
    required GenerateRecipes generateRecipes,
    required UpdateDietPreference updateDietPreference,
  })  : _generateRecipes = generateRecipes,
        _updateDietPreference = updateDietPreference,
        super(const RecipesInitial()) {
    on<LoadRecipes>(_onLoadRecipes);
    on<RefreshRecipes>(_onRefreshRecipes);
    on<ChangeDiet>(_onChangeDiet);
  }

  final GenerateRecipes _generateRecipes;
  final UpdateDietPreference _updateDietPreference;
  DietTag _currentDiet = DietTag.none;

  Future<void> _onLoadRecipes(
    LoadRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    emit(const RecipesLoading());

    final result = await _generateRecipes(GenerateRecipesParams(
      dietPreference: _currentDiet,
      forceRefresh: event.forceRefresh,
    ));

    result.fold(
      (failure) => emit(RecipesError(message: failure.message)),
      (data) {
        _currentDiet = data.dietPreference;
        if (data.rankedRecipes.isEmpty) {
          emit(RecipesNoMatches(
            dietPreference: data.dietPreference,
            reason: _currentDiet != DietTag.none
                ? 'No recipes match your active ingredients with the "${_currentDiet.displayName}" diet filter. Try switching diet or adding more ingredients.'
                : 'No recipes could be formed from your current ingredients. Try adding more items to your kitchen.',
          ));
        } else {
          emit(RecipesLoaded(
            recipes: data.rankedRecipes,
            source: data.source,
            dietPreference: data.dietPreference,
          ));
        }
      },
    );
  }

  Future<void> _onRefreshRecipes(
    RefreshRecipes event,
    Emitter<RecipesState> emit,
  ) async {
    add(const LoadRecipes(forceRefresh: true));
  }

  Future<void> _onChangeDiet(
    ChangeDiet event,
    Emitter<RecipesState> emit,
  ) async {
    _currentDiet = event.diet;
    await _updateDietPreference(UpdateDietPreferenceParams(event.diet));
    add(const LoadRecipes(forceRefresh: false));
  }
}
