import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../domain/usecases/clear_usage_history.dart';
import '../../domain/usecases/get_insights.dart';
import 'insights_state.dart';

class InsightsCubit extends Cubit<InsightsState> {
  final GetInsights _getInsights;
  final ClearUsageHistory? _clearUsageHistory;

  InsightsCubit({
    required GetInsights getInsights,
    ClearUsageHistory? clearUsageHistory,
  })  : _getInsights = getInsights,
        _clearUsageHistory = clearUsageHistory,
        super(const InsightsState());

  Future<void> loadInsights([DateTime? now]) async {
    emit(state.copyWith(status: InsightsStatus.loading));
    final result = await _getInsights(now);
    result.fold(
      (failure) => emit(state.copyWith(
        status: InsightsStatus.error,
        errorMessage: failure.message,
      )),
      (summary) {
        if (summary.isEmpty) {
          emit(state.copyWith(
            status: InsightsStatus.empty,
            summary: summary,
          ));
        } else {
          emit(state.copyWith(
            status: InsightsStatus.loaded,
            summary: summary,
          ));
        }
      },
    );
  }

  Future<void> load([DateTime? now]) => loadInsights(now);

  Future<void> clearHistory() async {
    if (_clearUsageHistory != null) {
      await _clearUsageHistory(const NoParams());
    }
    await loadInsights();
  }
}
