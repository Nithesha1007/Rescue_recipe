import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/clear_usage_history.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/get_insights.dart';
import 'package:rescue_recipe/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:rescue_recipe/features/insights/presentation/cubit/insights_state.dart';

class MockUsageLogRepository implements UsageLogRepository {
  List<UsageLogEntry> entries = [];
  bool failNext = false;

  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async {
    entries.add(entry);
    return const Right(null);
  }

  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async {
    if (failNext) return const Left(StorageFailure('Failed to load'));
    return Right(entries);
  }

  @override
  FutureEither<int> getRescuedCount() async {
    return Right(entries.where((e) => e.wasRescued).length);
  }

  @override
  FutureEither<void> clearHistory() async {
    entries.clear();
    return const Right(null);
  }
}

void main() {
  late MockUsageLogRepository repo;
  late InsightsCubit cubit;

  setUp(() {
    repo = MockUsageLogRepository();
    cubit = InsightsCubit(
      getInsights: GetInsights(repo),
      clearUsageHistory: ClearUsageHistory(repo),
    );
  });

  tearDown(() {
    cubit.close();
  });

  test('initial state is InsightsStatus.initial', () {
    expect(cubit.state.status, equals(InsightsStatus.initial));
  });

  test('loadInsights() emits InsightsStatus.empty when no log entries exist', () async {
    await cubit.loadInsights();
    expect(cubit.state.status, equals(InsightsStatus.empty));
  });

  test('loadInsights() emits InsightsStatus.loaded when entries exist', () async {
    repo.entries = [
      UsageLogEntry(
        id: '1',
        ingredientName: 'Milk',
        quantity: 1,
        unit: 'l',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.critical,
        timestamp: DateTime.now(),
      ),
    ];

    await cubit.loadInsights();
    expect(cubit.state.status, equals(InsightsStatus.loaded));
    expect(cubit.state.summary!.rescuedCount, equals(1));
  });

  test('loadInsights() emits InsightsStatus.error on repository failure', () async {
    repo.failNext = true;
    await cubit.loadInsights();
    expect(cubit.state.status, equals(InsightsStatus.error));
  });

  test('clearHistory() resets to InsightsStatus.empty', () async {
    repo.entries = [
      UsageLogEntry(
        id: '1',
        ingredientName: 'Tomato',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.high,
        timestamp: DateTime.now(),
      ),
    ];
    await cubit.loadInsights();
    expect(cubit.state.status, equals(InsightsStatus.loaded));

    await cubit.clearHistory();
    expect(cubit.state.status, equals(InsightsStatus.empty));
    expect(repo.entries.isEmpty, isTrue);
  });
}
