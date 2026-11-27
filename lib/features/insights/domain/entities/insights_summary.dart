import 'package:equatable/equatable.dart';
import '../../../../core/widgets/weekly_bar_chart.dart';
import 'achievement.dart';

class InsightsSummary extends Equatable {
  final int usedCount;
  final int discardedCount;
  final int rescuedCount;
  final double estimatedMoneySaved;
  final int unpricedRescuedCount;
  final int rescueScore;
  final int currentStreak;
  final int bestStreak;
  final List<WeeklyBarChartItem> weeklyActivity;
  final List<Achievement> achievements;

  const InsightsSummary({
    required this.usedCount,
    required this.discardedCount,
    required this.rescuedCount,
    required this.estimatedMoneySaved,
    required this.unpricedRescuedCount,
    required this.rescueScore,
    required this.currentStreak,
    required this.bestStreak,
    required this.weeklyActivity,
    required this.achievements,
  });

  bool get isEmpty => usedCount == 0 && discardedCount == 0;

  int get itemsUsed => usedCount;
  int get itemsDiscarded => discardedCount;
  int get itemsRescued => rescuedCount;
  List<WeeklyBarChartItem> get weeklyDays => weeklyActivity;

  @override
  List<Object?> get props => [
        usedCount,
        discardedCount,
        rescuedCount,
        estimatedMoneySaved,
        unpricedRescuedCount,
        rescueScore,
        currentStreak,
        bestStreak,
        weeklyActivity,
        achievements,
      ];
}
