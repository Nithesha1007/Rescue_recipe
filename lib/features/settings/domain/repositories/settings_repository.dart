import '../../../../core/error/failures.dart';
import '../entities/user_preferences.dart';

abstract class SettingsRepository {
  FutureEither<UserPreferences> getPreferences();
  FutureEither<void> savePreferences(UserPreferences preferences);
  FutureEither<void> clearAllData();
}
