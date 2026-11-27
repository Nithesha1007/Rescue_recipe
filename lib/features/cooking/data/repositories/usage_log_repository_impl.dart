import 'package:fpdart/fpdart.dart';
import 'package:hive/hive.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/usage_log_entry.dart';
import '../../domain/repositories/usage_log_repository.dart';
import '../models/usage_log_model.dart';

class UsageLogRepositoryImpl implements UsageLogRepository {
  final Box<UsageLogModel> _box;

  UsageLogRepositoryImpl(this._box);

  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async {
    try {
      final model = UsageLogModel.fromEntity(entry);
      await _box.put(model.id, model);
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to log usage: $e'));
    }
  }

  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async {
    try {
      final entries = _box.values
          .map((m) => m.toEntity())
          .toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return Right(entries);
    } catch (e) {
      return Left(StorageFailure('Failed to retrieve usage logs: $e'));
    }
  }

  @override
  FutureEither<int> getRescuedCount() async {
    try {
      final count = _box.values
          .map((m) => m.toEntity())
          .where((e) => e.wasRescued)
          .length;
      return Right(count);
    } catch (e) {
      return Left(StorageFailure('Failed to calculate rescued count: $e'));
    }
  }

  @override
  FutureEither<void> clearHistory() async {
    try {
      await _box.clear();
      return const Right(null);
    } catch (e) {
      return Left(StorageFailure('Failed to clear usage logs: $e'));
    }
  }
}
