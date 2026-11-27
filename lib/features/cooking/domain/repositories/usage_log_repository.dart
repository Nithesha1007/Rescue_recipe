import '../../../../core/error/failures.dart';
import '../entities/usage_log_entry.dart';

abstract class UsageLogRepository {
  /// Records a single usage log entry.
  FutureEither<void> logUsage(UsageLogEntry entry);

  /// Retrieves all recorded usage logs in reverse chronological order.
  FutureEither<List<UsageLogEntry>> getUsageLogs();

  /// Returns total count of ingredients marked used or reduced with Critical, High, or Medium priority.
  FutureEither<int> getRescuedCount();

  /// Clears all usage logs.
  FutureEither<void> clearHistory();
}
