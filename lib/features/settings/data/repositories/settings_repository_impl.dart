import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_local_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsLocalDataSource _localDataSource;

  SettingsRepositoryImpl(this._localDataSource);

  @override
  FutureEither<UserPreferences> getPreferences() async {
    try {
      final prefs = await _localDataSource.getPreferences();
      return Right(prefs);
    } catch (e) {
      return Left(StorageFailure('Failed to load settings: $e'));
    }
  }

  @override
  FutureEither<void> savePreferences(UserPreferences preferences) async {
    try {
      await _localDataSource.savePreferences(preferences);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to save settings: $e'));
    }
  }

  @override
  FutureEither<void> clearAllData() async {
    try {
      await _localDataSource.clearAll();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to clear settings: $e'));
    }
  }
}
