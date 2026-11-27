import 'dart:math';
import '../../../../core/widgets/weekly_bar_chart.dart';
import '../../../cooking/domain/entities/usage_log_entry.dart';
import '../entities/achievement.dart';
import '../entities/insights_summary.dart';
import 'price_table.dart';

class InsightsCalculator {
  static InsightsSummary compute({
    required List<UsageLogEntry> entries,
    required DateTime today,
  }) {
    int usedCount = 0;
    int discardedCount = 0;
    int rescuedCount = 0;
    double moneySaved = 0.0;
    int unpricedRescuedCount = 0;

    final normalizedToday = DateTime(today.year, today.month, today.day);

    // Group entries by calendar date
    final Map<DateTime, List<UsageLogEntry>> entriesByDate = {};
    final Set<String> distinctCookedRecipeIds = {};

    for (final e in entries) {
      final dateKey = DateTime(e.timestamp.year, e.timestamp.month, e.timestamp.day);
      entriesByDate.putIfAbsent(dateKey, () => []).add(e);

      if (e.action == UsageAction.used || e.action == UsageAction.reduced) {
        usedCount++;
        if (e.wasRescued) {
          rescuedCount++;
          final priceEst = PriceTable.estimatePrice(
            name: e.ingredientName,
            quantity: e.quantity,
            unit: e.unit,
          );
          if (priceEst != null) {
            moneySaved += priceEst;
          } else {
            unpricedRescuedCount++;
          }
        }
        if (e.recipeId != null && e.recipeId!.isNotEmpty) {
          distinctCookedRecipeIds.add(e.recipeId!);
        }
      } else if (e.action == UsageAction.discarded) {
        discardedCount++;
      }
    }

    // Rescue Score: rescued * 10 + (used - rescued) * 2 - discarded * 3 (never below 0)
    final otherUsed = max(0, usedCount - rescuedCount);
    final rawScore = (rescuedCount * 10) + (otherUsed * 2) - (discardedCount * 3);
    final rescueScore = max(0, rawScore);

    // Streaks calculation
    final (currentStreak, bestStreak) = _calculateStreaks(entriesByDate, normalizedToday);

    // Weekly chart (last 7 calendar days ending today, oldest first)
    final weeklyActivity = _calculateWeeklyActivity(entriesByDate, normalizedToday);

    // Achievements
    final achievements = _calculateAchievements(
      rescuedCount: rescuedCount,
      usedCount: usedCount,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      distinctCookedRecipesCount: distinctCookedRecipeIds.length,
      entriesByDate: entriesByDate,
      normalizedToday: normalizedToday,
    );

    return InsightsSummary(
      usedCount: usedCount,
      discardedCount: discardedCount,
      rescuedCount: rescuedCount,
      estimatedMoneySaved: moneySaved,
      unpricedRescuedCount: unpricedRescuedCount,
      rescueScore: rescueScore,
      currentStreak: currentStreak,
      bestStreak: bestStreak,
      weeklyActivity: weeklyActivity,
      achievements: achievements,
    );
  }

  /// Alias for compute to allow calling calculate(entries, today: ...)
  static InsightsSummary calculate(
    List<UsageLogEntry> entries, {
    DateTime? today,
  }) {
    return compute(
      entries: entries,
      today: today ?? DateTime.now(),
    );
  }

  static (int current, int best) _calculateStreaks(
    Map<DateTime, List<UsageLogEntry>> entriesByDate,
    DateTime today,
  ) {
    if (entriesByDate.isEmpty) return (0, 0);

    // Helper: checks if a day has at least one used item
    bool hasUsage(DateTime day) {
      final list = entriesByDate[day];
      if (list == null) return false;
      return list.any((e) => e.action == UsageAction.used || e.action == UsageAction.reduced);
    }

    // 1. Current streak:
    // Starts either today (if usage today) or yesterday (if no usage yet today)
    int current = 0;
    DateTime checkDay = today;

    if (!hasUsage(checkDay)) {
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    while (hasUsage(checkDay)) {
      current++;
      checkDay = checkDay.subtract(const Duration(days: 1));
    }

    // 2. Best streak:
    // Sort all dates with usage in ascending order and find the longest consecutive day run
    final usageDates = entriesByDate.keys.where(hasUsage).toList()..sort();

    int best = 0;
    int currentRun = 0;
    DateTime? prevDate;

    for (final date in usageDates) {
      if (prevDate == null) {
        currentRun = 1;
      } else {
        final diff = date.difference(prevDate).inDays;
        if (diff == 1) {
          currentRun++;
        } else if (diff > 1) {
          currentRun = 1;
        }
      }
      if (currentRun > best) {
        best = currentRun;
      }
      prevDate = date;
    }

    if (current > best) best = current;

    return (current, best);
  }

  static List<WeeklyBarChartItem> _calculateWeeklyActivity(
    Map<DateTime, List<UsageLogEntry>> entriesByDate,
    DateTime today,
  ) {
    const weekdayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final result = <WeeklyBarChartItem>[];

    // 7 days ending today, oldest first: today - 6 to today
    for (int i = 6; i >= 0; i--) {
      final date = today.subtract(Duration(days: i));
      final entries = entriesByDate[date] ?? [];

      int rescued = 0;
      int used = 0;
      int discarded = 0;

      for (final e in entries) {
        if (e.action == UsageAction.used || e.action == UsageAction.reduced) {
          if (e.wasRescued) {
            rescued++;
          } else {
            used++;
          }
        } else if (e.action == UsageAction.discarded) {
          discarded++;
        }
      }

      result.add(WeeklyBarChartItem(
        dayLabel: weekdayLabels[date.weekday - 1],
        rescuedCount: rescued,
        usedCount: used,
        discardedCount: discarded,
        date: date,
      ));
    }

    return result;
  }

  static List<Achievement> _calculateAchievements({
    required int rescuedCount,
    required int usedCount,
    required int currentStreak,
    required int bestStreak,
    required int distinctCookedRecipesCount,
    required Map<DateTime, List<UsageLogEntry>> entriesByDate,
    required DateTime normalizedToday,
  }) {
    // Zero waste week check: past 7 days has at least 1 usage and 0 discards
    bool zeroWasteWeek = false;
    int weekUsed = 0;
    int weekDiscarded = 0;
    for (int i = 0; i < 7; i++) {
      final d = normalizedToday.subtract(Duration(days: i));
      final list = entriesByDate[d] ?? [];
      for (final e in list) {
        if (e.action == UsageAction.used || e.action == UsageAction.reduced) {
          weekUsed++;
        } else if (e.action == UsageAction.discarded) {
          weekDiscarded++;
        }
      }
    }
    if (weekUsed > 0 && weekDiscarded == 0) {
      zeroWasteWeek = true;
    }

    return [
      Achievement(
        id: 'first_rescue',
        title: 'First Rescue',
        description: 'Rescued your first high-risk ingredient.',
        isUnlocked: rescuedCount >= 1,
        currentProgress: min(1, rescuedCount),
        targetProgress: 1,
      ),
      Achievement(
        id: 'rescue_rookie',
        title: 'Rescue Rookie',
        description: 'Rescued 5 expiring items from going to waste.',
        isUnlocked: rescuedCount >= 5,
        currentProgress: min(5, rescuedCount),
        targetProgress: 5,
      ),
      Achievement(
        id: 'streak_3',
        title: '3-Day Rescue Streak',
        description: 'Rescued food for 3 consecutive days.',
        isUnlocked: bestStreak >= 3,
        currentProgress: min(3, bestStreak),
        targetProgress: 3,
      ),
      Achievement(
        id: 'streak_7',
        title: 'Week-Long Warrior',
        description: 'Rescued food for 7 consecutive days.',
        isUnlocked: bestStreak >= 7,
        currentProgress: min(7, bestStreak),
        targetProgress: 7,
      ),
      Achievement(
        id: 'zero_waste_week',
        title: 'Zero Waste Week',
        description: 'Zero food items discarded over a 7-day period.',
        isUnlocked: zeroWasteWeek,
        currentProgress: zeroWasteWeek ? 1 : 0,
        targetProgress: 1,
      ),
      Achievement(
        id: 'voice_chef',
        title: 'Voice Chef',
        description: 'Completed 3 recipes using guided cooking voice control.',
        isUnlocked: distinctCookedRecipesCount >= 3,
        currentProgress: min(3, distinctCookedRecipesCount),
        targetProgress: 3,
      ),
      Achievement(
        id: 'pantry_hero',
        title: 'Pantry Hero',
        description: 'Rescued 20 or more food items.',
        isUnlocked: rescuedCount >= 20,
        currentProgress: min(20, rescuedCount),
        targetProgress: 20,
      ),
    ];
  }
}
