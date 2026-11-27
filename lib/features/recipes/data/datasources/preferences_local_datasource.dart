import 'package:hive/hive.dart';

import '../../domain/entities/diet_tag.dart';

abstract class PreferencesLocalDataSource {
  Future<DietTag> getDietPreference();
  Future<void> saveDietPreference(DietTag diet);
}

class PreferencesLocalDataSourceImpl implements PreferencesLocalDataSource {
  PreferencesLocalDataSourceImpl(this._box);

  final Box<String> _box;
  static const String _dietKey = 'diet_preference';

  @override
  Future<DietTag> getDietPreference() async {
    final stored = _box.get(_dietKey, defaultValue: DietTag.none.name);
    return DietTag.fromString(stored);
  }

  @override
  Future<void> saveDietPreference(DietTag diet) async {
    await _box.put(_dietKey, diet.name);
  }
}
