import 'package:hive/hive.dart';

import '../models/ingredient_model.dart';

abstract interface class IngredientLocalDataSource {
  Stream<List<IngredientModel>> watchAll();
  List<IngredientModel> getAll();
  IngredientModel? getById(String id);
  Future<void> save(IngredientModel model);
  Future<void> saveAll(List<IngredientModel> models);
  Future<void> delete(String id);
}

class IngredientLocalDataSourceImpl implements IngredientLocalDataSource {
  const IngredientLocalDataSourceImpl(this._box);

  final Box<IngredientModel> _box;

  @override
  Stream<List<IngredientModel>> watchAll() {
    return _box.watch().map((_) => _box.values.toList());
  }

  @override
  List<IngredientModel> getAll() {
    return _box.values.toList();
  }

  @override
  IngredientModel? getById(String id) {
    return _box.get(id);
  }

  @override
  Future<void> save(IngredientModel model) async {
    await _box.put(model.id, model);
  }

  @override
  Future<void> saveAll(List<IngredientModel> models) async {
    final Map<String, IngredientModel> map = {
      for (final m in models) m.id: m,
    };
    await _box.putAll(map);
  }

  @override
  Future<void> delete(String id) async {
    await _box.delete(id);
  }
}
