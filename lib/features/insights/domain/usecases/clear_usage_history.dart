import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cooking/domain/repositories/usage_log_repository.dart';

class ClearUsageHistory implements UseCase<void, NoParams> {
  final UsageLogRepository _repository;

  ClearUsageHistory(this._repository);

  @override
  FutureEither<void> call(NoParams params) async {
    return _repository.clearHistory();
  }
}
