import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/delete_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/get_active_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_used.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/update_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_state.dart';

class FakeIngredientRepository implements IngredientRepository {
  final List<Ingredient> _items = [];
  bool shouldFail = false;

  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async {
    if (shouldFail) return const Left(StorageFailure('Failed to load'));
    return Right(_items.where((i) => i.status.isActive).toList());
  }

  @override
  FutureEither<Ingredient?> getIngredientById(String id) async {
    final matches = _items.where((i) => i.id == id);
    return Right(matches.isEmpty ? null : matches.first);
  }

  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async {
    _items.add(ingredient);
    return const Right(null);
  }

  @override
  FutureEither<void> addIngredients(List<Ingredient> ingredients) async {
    _items.addAll(ingredients);
    return const Right(null);
  }

  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async {
    final index = _items.indexWhere((i) => i.id == ingredient.id);
    if (index >= 0) {
      _items[index] = ingredient;
    } else {
      _items.add(ingredient);
    }
    return const Right(null);
  }

  @override
  FutureEither<void> deleteIngredient(String id) async {
    _items.removeWhere((i) => i.id == id);
    return const Right(null);
  }

  @override
  FutureEither<void> markUsed(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] = _items[index].copyWith(status: IngredientStatus.used);
    }
    return const Right(null);
  }

  @override
  FutureEither<void> markDiscarded(String id) async {
    final index = _items.indexWhere((i) => i.id == id);
    if (index >= 0) {
      _items[index] =
          _items[index].copyWith(status: IngredientStatus.discarded);
    }
    return const Right(null);
  }

  @override
  Stream<List<Ingredient>> watchActiveIngredients() {
    return Stream.value(_items.where((i) => i.status.isActive).toList());
  }
}

void main() {
  group('InventoryCubit', () {
    late FakeIngredientRepository fakeRepo;
    late InventoryCubit cubit;

    setUp(() {
      fakeRepo = FakeIngredientRepository();
      cubit = InventoryCubit(
        getActiveIngredients: GetActiveIngredients(fakeRepo),
        addIngredient: AddIngredient(fakeRepo),
        addIngredients: AddIngredients(fakeRepo),
        updateIngredient: UpdateIngredient(fakeRepo),
        deleteIngredient: DeleteIngredient(fakeRepo),
        markIngredientUsed: MarkIngredientUsed(fakeRepo),
        markIngredientDiscarded: MarkIngredientDiscarded(fakeRepo),
      );
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is InventoryInitial', () {
      expect(cubit.state, const InventoryInitial());
    });

    test('loadIngredients emits Empty when repo has no items', () async {
      await cubit.loadIngredients();
      expect(cubit.state, const InventoryEmpty());
    });

    test('loadIngredients emits Loaded when repo has items', () async {
      final item = Ingredient(
        id: '1',
        name: 'tomato',
        addedAt: DateTime.now(),
      );
      await fakeRepo.addIngredient(item);
      await cubit.loadIngredients();

      expect(cubit.state, isA<InventoryLoaded>());
      final loaded = cubit.state as InventoryLoaded;
      expect(loaded.items.length, 1);
    });

    test('loadIngredients emits Error when repository fails', () async {
      fakeRepo.shouldFail = true;
      await cubit.loadIngredients();

      expect(cubit.state, isA<InventoryError>());
    });

    test('delete with restore (undo) works properly', () async {
      final item = Ingredient(
        id: '1',
        name: 'tomato',
        addedAt: DateTime.now(),
      );
      await fakeRepo.addIngredient(item);
      await cubit.loadIngredients();
      expect((cubit.state as InventoryLoaded).items.length, 1);

      final deleteFuture = cubit.delete('1');
      await deleteFuture;
      expect(cubit.state, const InventoryEmpty());

      // Undo / restore
      final restoreFuture = cubit.restore(item);
      await restoreFuture;
      expect(cubit.state, isA<InventoryLoaded>());
      expect((cubit.state as InventoryLoaded).items.length, 1);
    });
  });
}
