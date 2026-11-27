import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class UpdateSettings implements UseCase<void, UserPreferences> {
  final SettingsRepository _repository;

  UpdateSettings(this._repository);

  @override
  FutureEither<void> call(UserPreferences params) {
    return _repository.savePreferences(params);
  }
}
