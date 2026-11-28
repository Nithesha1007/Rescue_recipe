import 'package:equatable/equatable.dart';
import '../../../../core/widgets/weekly_bar_chart.dart';
import 'achievement.dart';

class IngredientFrequency extends Equatable {
  final String name;
  final int count;
  final String emoji;
  final String? tip;

  const IngredientFrequency({
    required this.name,
    required this.count,
    required this.emoji,
    this.tip,
  });

  @override
  List<Object?> get props => [name, count, emoji, tip];
}

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
  final int rescuedThisWeek;
  final int rescuedLastWeek;
  final List<bool> streakCalendar28Days;
  final List<IngredientFrequency> topRescuedIngredients;
  final List<IngredientFrequency> wasteWatchList;

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
    this.rescuedThisWeek = 0,
    this.rescuedLastWeek = 0,
    this.streakCalendar28Days = const [],
    this.topRescuedIngredients = const [],
    this.wasteWatchList = const [],
  });

  bool get isEmpty => usedCount == 0 && discardedCount == 0;

  int get itemsUsed => usedCount;
  int get itemsDiscarded => discardedCount;
  int get itemsRescued => rescuedCount;
  List<WeeklyBarChartItem> get weeklyDays => weeklyActivity;

  int get weekOverWeekDiff => rescuedThisWeek - rescuedLastWeek;

  String get levelName {
    if (rescueScore < 100) return 'Seedling';
    if (rescueScore < 250) return 'Sprout';
    if (rescueScore < 500) return 'Home Cook';
    if (rescueScore < 1000) return 'Chef';
    return 'Rescue Hero';
  }

  int get nextLevelScore {
    if (rescueScore < 100) return 100;
    if (rescueScore < 250) return 250;
    if (rescueScore < 500) return 500;
    if (rescueScore < 1000) return 1000;
    return 1000;
  }

  double get levelProgress {
    if (rescueScore < 100) return (rescueScore / 100.0).clamp(0.0, 1.0);
    if (rescueScore < 250) return ((rescueScore - 100) / 150.0).clamp(0.0, 1.0);
    if (rescueScore < 500) return ((rescueScore - 250) / 250.0).clamp(0.0, 1.0);
    if (rescueScore < 1000) return ((rescueScore - 500) / 500.0).clamp(0.0, 1.0);
    return 1.0;
  }

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
        rescuedThisWeek,
        rescuedLastWeek,
        streakCalendar28Days,
        topRescuedIngredients,
        wasteWatchList,
      ];
}
