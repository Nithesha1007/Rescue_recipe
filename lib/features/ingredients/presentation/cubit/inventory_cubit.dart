import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/usecase/usecase.dart';
import '../../../notifications/domain/usecases/sync_expiry_alerts.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/usecases/add_ingredient.dart';
import '../../domain/usecases/add_ingredients.dart';
import '../../domain/usecases/delete_ingredient.dart';
import '../../domain/usecases/get_active_ingredients.dart';
import '../../domain/usecases/mark_ingredient_discarded.dart';
import '../../domain/usecases/mark_ingredient_used.dart';
import '../../domain/usecases/update_ingredient.dart';
import 'inventory_state.dart';

class InventoryCubit extends Cubit<InventoryState> {
  InventoryCubit({
    required GetActiveIngredients getActiveIngredients,
    required AddIngredient addIngredient,
    required AddIngredients addIngredients,
    required UpdateIngredient updateIngredient,
    required DeleteIngredient deleteIngredient,
    required MarkIngredientUsed markIngredientUsed,
    required MarkIngredientDiscarded markIngredientDiscarded,
    SyncExpiryAlerts? syncExpiryAlerts,
  })  : _getActiveIngredients = getActiveIngredients,
        _addIngredient = addIngredient,
        _addIngredients = addIngredients,
        _updateIngredient = updateIngredient,
        _deleteIngredient = deleteIngredient,
        _markIngredientUsed = markIngredientUsed,
        _markIngredientDiscarded = markIngredientDiscarded,
        _syncExpiryAlerts = syncExpiryAlerts,
        super(const InventoryInitial());

  final GetActiveIngredients _getActiveIngredients;
  final AddIngredient _addIngredient;
  final AddIngredients _addIngredients;
  final UpdateIngredient _updateIngredient;
  final DeleteIngredient _deleteIngredient;
  final MarkIngredientUsed _markIngredientUsed;
  final MarkIngredientDiscarded _markIngredientDiscarded;
  final SyncExpiryAlerts? _syncExpiryAlerts;

  Future<void> _triggerAlertSync() async {
    if (_syncExpiryAlerts != null) {
      await _syncExpiryAlerts(const NoParams());
    }
  }

  Future<void> loadIngredients() async {
    emit(const InventoryLoading());
    final result = await _getActiveIngredients(const NoParams());
    result.fold(
      (failure) => emit(InventoryError(failure.message)),
      (items) {
        if (items.isEmpty) {
          emit(const InventoryEmpty());
        } else {
          emit(InventoryLoaded(items));
        }
      },
    );
  }

  Future<void> add(Ingredient ingredient) async {
    final result = await _addIngredient(ingredient);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> addMany(List<Ingredient> ingredients) async {
    final result = await _addIngredients(ingredients);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> update(Ingredient ingredient) async {
    final result = await _updateIngredient(ingredient);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> delete(String id) async {
    final result = await _deleteIngredient(id);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> restore(Ingredient ingredient) async {
    final result = await _updateIngredient(ingredient);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> markUsed(String id) async {
    final result = await _markIngredientUsed(id);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }

  Future<void> markDiscarded(String id) async {
    final result = await _markIngredientDiscarded(id);
    await result.fold(
      (failure) async => emit(InventoryError(failure.message)),
      (_) async {
        await loadIngredients();
        await _triggerAlertSync();
      },
    );
  }
}
