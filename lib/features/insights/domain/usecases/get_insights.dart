import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../cooking/domain/repositories/usage_log_repository.dart';
import '../entities/insights_summary.dart';
import '../utils/insights_calculator.dart';

class GetInsights implements UseCase<InsightsSummary, DateTime?> {
  final UsageLogRepository _repository;

  GetInsights(this._repository);

  @override
  FutureEither<InsightsSummary> call([DateTime? today]) async {
    final result = await _repository.getUsageLogs();
    return result.fold(
      (failure) => Left(failure),
      (entries) {
        final summary = InsightsCalculator.compute(
          entries: entries,
          today: today ?? DateTime.now(),
        );
        return Right(summary);
      },
    );
  }
}
