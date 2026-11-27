import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../entities/user_preferences.dart';
import '../repositories/settings_repository.dart';

class GetSettings implements UseCase<UserPreferences, NoParams> {
  final SettingsRepository _repository;

  GetSettings(this._repository);

  @override
  FutureEither<UserPreferences> call(NoParams params) {
    return _repository.getPreferences();
  }
}
