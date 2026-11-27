import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ingredient.dart';
import '../../domain/repositories/ingredient_repository.dart';
import '../../domain/utils/ingredient_merger.dart';
import '../datasources/ingredient_local_datasource.dart';
import '../models/ingredient_model.dart';

class IngredientRepositoryImpl implements IngredientRepository {
  const IngredientRepositoryImpl(this._localDataSource);

  final IngredientLocalDataSource _localDataSource;

  @override
  Stream<List<Ingredient>> watchActiveIngredients() {
    return _localDataSource.watchAll().map((models) {
      final List<Ingredient> entities = models
          .map((m) => m.toEntity())
          .where((i) => i.status.isActive)
          .toList();
      return IngredientMerger.sortInventory(entities);
    });
  }

  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async {
    try {
      final List<IngredientModel> models = _localDataSource.getAll();
      final List<Ingredient> entities = models
          .map((m) => m.toEntity())
          .where((i) => i.status.isActive)
          .toList();
      final List<Ingredient> sorted = IngredientMerger.sortInventory(entities);
      return Right(sorted);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<Ingredient?> getIngredientById(String id) async {
    try {
      final IngredientModel? model = _localDataSource.getById(id);
      return Right(model?.toEntity());
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async {
    try {
      // Use merging rules for the new item
      final List<Ingredient> current = _localDataSource
          .getAll()
          .map((m) => m.toEntity())
          .toList();
      final List<Ingredient> merged =
          IngredientMerger.merge(current, [ingredient]);
      final List<IngredientModel> models =
          merged.map(IngredientModel.fromEntity).toList();
      await _localDataSource.saveAll(models);
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> addIngredients(List<Ingredient> ingredients) async {
    try {
      final List<Ingredient> current = _localDataSource
          .getAll()
          .map((m) => m.toEntity())
          .toList();
      final List<Ingredient> merged =
          IngredientMerger.merge(current, ingredients);
      final List<IngredientModel> models =
          merged.map(IngredientModel.fromEntity).toList();
      await _localDataSource.saveAll(models);
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async {
    try {
      final IngredientModel model = IngredientModel.fromEntity(ingredient);
      await _localDataSource.save(model);
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> deleteIngredient(String id) async {
    try {
      await _localDataSource.delete(id);
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> markUsed(String id) async {
    try {
      final IngredientModel? existing = _localDataSource.getById(id);
      if (existing == null) {
        return const Left(StorageFailure('Ingredient not found.'));
      }
      final Ingredient updated = existing.toEntity().copyWith(
            status: IngredientStatus.used,
            statusChangedAt: () => DateTime.now(),
          );
      await _localDataSource.save(IngredientModel.fromEntity(updated));
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }

  @override
  FutureEither<void> markDiscarded(String id) async {
    try {
      final IngredientModel? existing = _localDataSource.getById(id);
      if (existing == null) {
        return const Left(StorageFailure('Ingredient not found.'));
      }
      final Ingredient updated = existing.toEntity().copyWith(
            status: IngredientStatus.discarded,
            statusChangedAt: () => DateTime.now(),
          );
      await _localDataSource.save(IngredientModel.fromEntity(updated));
      return const Right(null);
    } catch (e) {
      return const Left(StorageFailure());
    }
  }
}
