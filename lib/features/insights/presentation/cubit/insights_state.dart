import 'package:equatable/equatable.dart';
import '../../domain/entities/insights_summary.dart';

enum InsightsStatus {
  initial,
  loading,
  loaded,
  empty,
  error,
}

class InsightsState extends Equatable {
  final InsightsStatus status;
  final InsightsSummary? summary;
  final String? errorMessage;

  const InsightsState({
    this.status = InsightsStatus.initial,
    this.summary,
    this.errorMessage,
  });

  InsightsState copyWith({
    InsightsStatus? status,
    InsightsSummary? summary,
    String? errorMessage,
  }) {
    return InsightsState(
      status: status ?? this.status,
      summary: summary ?? this.summary,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, summary, errorMessage];
}
