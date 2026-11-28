import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/achievement_badge.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/stat_tile.dart';
import '../../../../core/widgets/weekly_bar_chart.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../../shell/presentation/cubit/navigation_cubit.dart';
import '../cubit/insights_cubit.dart';
import '../cubit/insights_state.dart';
import '../../domain/entities/achievement.dart';
import '../../domain/entities/insights_summary.dart';

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  final GlobalKey _shareCardKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    context.read<InsightsCubit>().loadInsights();
  }

  void _showShareModal(BuildContext context, InsightsSummary summary, String currency) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final text = theme.textTheme;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Share Your Impact',
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Inspire your family and friends to reduce food waste!',
                style: text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),

              // Visual Branded Share Card
              RepaintBoundary(
                key: _shareCardKey,
                child: Container(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppColors.forest, AppColors.forestMid],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.lg),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.forest.withValues(alpha: 0.3),
                        blurRadius: 16,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: AppColors.orange,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Icon(Icons.eco_rounded, color: AppColors.white, size: 20),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              const Text(
                                'RescueRecipe',
                                style: AppTypography.shareTitle,
                              ),
                            ],
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppRadius.pill),
                            ),
                            child: Text(
                              summary.levelName,
                              style: AppTypography.shareBadge,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        '${summary.rescuedCount}',
                        style: AppTypography.shareCount,
                      ),
                      const Text(
                        'Ingredients Rescued',
                        style: AppTypography.shareSubtitle,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          Column(
                            children: [
                              Text(
                                '$currency${summary.estimatedMoneySaved.toStringAsFixed(0)}',
                                style: AppTypography.shareStatNum,
                              ),
                              const Text(
                                'Saved',
                                style: AppTypography.shareStatLabel,
                              ),
                            ],
                          ),
                          Container(width: 1, height: 32, color: AppColors.white.withValues(alpha: 0.2)),
                          Column(
                            children: [
                              Text(
                                '${summary.currentStreak} Days',
                                style: AppTypography.shareStatOrange,
                              ),
                              const Text(
                                'Rescue Streak',
                                style: AppTypography.shareStatLabel,
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.md),
                      const Text(
                        'Speak Your Ingredients. Rescue Your Food. Reduce Food Waste.',
                        textAlign: TextAlign.center,
                        style: AppTypography.shareTagline,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),

              AppButton(
                label: 'Share Summary',
                icon: Icons.share_rounded,
                onPressed: () {
                  Navigator.pop(ctx);
                  final textMessage =
                      '🌱 I just rescued ${summary.rescuedCount} food items and saved an estimated $currency${summary.estimatedMoneySaved.toStringAsFixed(0)} with RescueRecipe! Let\'s reduce food waste together.';
                  SharePlus.instance.share(ShareParams(text: textMessage));
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        );
      },
    );
  }

  void _showAchievementDetails(BuildContext context, Achievement achievement) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final theme = Theme.of(ctx);
        final text = theme.textTheme;

        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
          ),
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              CircleAvatar(
                radius: 36,
                backgroundColor: achievement.isUnlocked
                    ? AppColors.orange.withValues(alpha: 0.15)
                    : theme.colorScheme.outlineVariant.withValues(alpha: 0.2),
                child: Icon(
                  _achievementIcon(achievement.id),
                  size: 40,
                  color: achievement.isUnlocked ? AppColors.orange : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                achievement.title,
                style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                achievement.description,
                style: text.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.lg),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(AppRadius.md),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Status', style: text.labelMedium),
                    Text(
                      achievement.isUnlocked ? 'Unlocked 🎉' : 'In Progress (${achievement.progressHint})',
                      style: text.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: achievement.isUnlocked ? AppColors.low : AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Close',
                variant: AppButtonVariant.outlined,
                onPressed: () => Navigator.pop(ctx),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Impact & Insights'),
      ),
      body: SafeArea(
        child: BlocBuilder<InsightsCubit, InsightsState>(
          builder: (context, state) {
            return switch (state.status) {
              InsightsStatus.initial || InsightsStatus.loading =>
                const ContentContainer(
                  child: Padding(
                    padding: EdgeInsets.all(AppSpacing.md),
                    child: LoadingSkeletonList(count: 4),
                  ),
                ),
              InsightsStatus.error => ErrorState(
                  message: state.errorMessage ?? 'Failed to load insights.',
                  onRetry: () => context.read<InsightsCubit>().loadInsights(),
                ),
              InsightsStatus.empty => _buildEmptyState(context),
              InsightsStatus.loaded => _buildLoadedState(context, state),
            };
          },
        ),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: ContentContainer(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  EmptyState(
                    icon: Icons.insights_rounded,
                    title: 'No Activity Logged Yet',
                    message:
                        'Cook rescue recipes or update ingredients to earn points, build streaks, and track real food waste reduction.',
                    actionLabel: 'Go to My Kitchen',
                    onAction: () {
                      context.read<NavigationCubit>().select(NavTab.kitchen);
                    },
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.stars_rounded, color: AppColors.orange),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                'How Rescue Points Work',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          '• Rescuing an expiring item: +10 pts\n• Using any staple item: +2 pts\n• Discarding an item: -3 pts\n• Unlock tiers from Seedling to Rescue Hero!',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(height: 1.5),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadedState(BuildContext context, InsightsState state) {
    final summary = state.summary;
    if (summary == null) return const SizedBox.shrink();

    final currency = context.watch<SettingsCubit>().state.preferences.currencySymbol;
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return ContentContainer(
      child: RefreshIndicator(
        onRefresh: () => context.read<InsightsCubit>().loadInsights(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Hero Summary Card
              _buildHeroSummaryCard(context, summary, currency),
              const SizedBox(height: AppSpacing.md),

              // 2. Core 2x2 Stats Grid
              ResponsiveGrid(
                spacing: AppSpacing.sm,
                children: [
                  StatTile(
                    label: 'Rescued',
                    value: '${summary.rescuedCount}',
                    icon: Icons.eco_rounded,
                  ),
                  StatTile(
                    label: 'Items Used',
                    value: '${summary.usedCount}',
                    icon: Icons.check_circle_outline_rounded,
                  ),
                  StatTile(
                    label: 'Discarded',
                    value: '${summary.discardedCount}',
                    icon: Icons.delete_outline_rounded,
                  ),
                  StatTile(
                    label: 'Saved (Estimated)',
                    value: '$currency${summary.estimatedMoneySaved.toStringAsFixed(0)}',
                    icon: Icons.savings_outlined,
                  ),
                ],
              ),
              if (summary.unpricedRescuedCount > 0) ...[
                const SizedBox(height: 4),
                Text(
                  '* ${summary.unpricedRescuedCount} rescued item(s) had no price estimate and were excluded from the money total.',
                  style: text.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 3. Rescue Score & Level Ring
              _buildScoreAndLevelCard(context, summary),
              const SizedBox(height: AppSpacing.md),

              // 4. 28-Day Streak Calendar
              _buildStreakCalendarCard(context, summary),
              const SizedBox(height: AppSpacing.md),

              // 5. Weekly Activity Chart
              const SectionHeader(
                title: 'Weekly Rescue Activity',
                subtitle: 'Stacked breakdown of items rescued, used, and discarded',
              ),
              const SizedBox(height: AppSpacing.xs),
              AppCard(
                child: WeeklyBarChart(items: summary.weeklyActivity),
              ),
              const SizedBox(height: AppSpacing.md),

              // 6. Top Rescued Ingredients
              if (summary.topRescuedIngredients.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Top Rescued Foods',
                  subtitle: 'Ingredients you saved most often from going to waste',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildTopRescuedCard(context, summary),
                const SizedBox(height: AppSpacing.md),
              ],

              // 7. Waste Watch List
              if (summary.wasteWatchList.isNotEmpty) ...[
                const SectionHeader(
                  title: 'Waste Watch',
                  subtitle: 'Items discarded most often with preservation tips',
                ),
                const SizedBox(height: AppSpacing.xs),
                _buildWasteWatchCard(context, summary),
                const SizedBox(height: AppSpacing.md),
              ],

              // 8. Achievements 2-Column Grid
              const SectionHeader(
                title: 'Illustrative Achievements',
                subtitle: 'Milestones unlocked by consistent food rescue activity',
              ),
              const SizedBox(height: AppSpacing.xs),
              _buildAchievementsGrid(context, summary),
              const SizedBox(height: AppSpacing.md),

              // 9. Financial Savings Estimate Card with Settings Link
              _buildSavingsEstimateCard(context, summary, currency),
              const SizedBox(height: AppSpacing.lg),

              const ExpiryDisclaimer(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeroSummaryCard(BuildContext context, InsightsSummary summary, String currency) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final diff = summary.weekOverWeekDiff;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Weekly Overview',
                  style: text.labelMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.share_outlined, color: AppColors.orange),
                tooltip: 'Share Impact',
                onPressed: () => _showShareModal(context, summary, currency),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'This week you rescued ${summary.rescuedThisWeek} items!',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: diff >= 0
                      ? AppColors.low.withValues(alpha: 0.15)
                      : AppColors.critical.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      diff >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                      size: 14,
                      color: diff >= 0 ? AppColors.low : AppColors.critical,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      diff >= 0 ? '+$diff vs last week' : '$diff vs last week',
                      style: text.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: diff >= 0 ? AppColors.low : AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Keep cooking to preserve ingredients!',
                  style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScoreAndLevelCard(BuildContext context, InsightsSummary summary) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Rescue Score',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Level: ${summary.levelName} (Illustrative)',
                    style: text.bodySmall?.copyWith(
                      color: AppColors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                decoration: BoxDecoration(
                  color: AppColors.orange.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  '${summary.rescueScore} pts',
                  style: text.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: summary.levelProgress,
              minHeight: 8,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            summary.rescueScore >= 1000
                ? 'Maximum tier reached! Master Rescuer.'
                : '${summary.nextLevelScore - summary.rescueScore} points to next rank',
            style: text.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCalendarCard(BuildContext context, InsightsSummary summary) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: [
              Text(
                '28-Day Rescue Streak',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.local_fire_department_rounded, color: AppColors.critical, size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '${summary.currentStreak} Days',
                    style: text.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: AppColors.critical,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Best Streak: ${summary.bestStreak} days (Illustrative)',
            style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),

          // 28 Dots Grid (4 rows x 7 cols)
          LayoutBuilder(
            builder: (context, constraints) {
              final dotSize = (constraints.maxWidth - (6 * 8)) / 7;
              final size = dotSize.clamp(14.0, 24.0);

              return Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: List.generate(
                  summary.streakCalendar28Days.length,
                  (index) {
                    final isActive = summary.streakCalendar28Days[index];
                    return Container(
                      width: size,
                      height: size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? AppColors.low
                            : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                      ),
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            alignment: WrapAlignment.center,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppSpacing.md,
            runSpacing: AppSpacing.xs,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.low),
                  ),
                  const SizedBox(width: 4),
                  Text('Active Rescue Day', style: text.labelSmall),
                ],
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text('No Activity', style: text.labelSmall),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTopRescuedCard(BuildContext context, InsightsSummary summary) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final maxCount = summary.topRescuedIngredients.first.count;

    return AppCard(
      child: Column(
        children: summary.topRescuedIngredients.map((item) {
          final ratio = maxCount > 0 ? (item.count / maxCount).clamp(0.1, 1.0) : 1.0;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              children: [
                Text(item.emoji, style: AppTypography.mediumEmoji),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  flex: 2,
                  child: Text(
                    item.name,
                    style: text.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                    child: LinearProgressIndicator(
                      value: ratio,
                      minHeight: 8,
                      backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.lime),
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  '${item.count}',
                  style: text.labelMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildWasteWatchCard(BuildContext context, InsightsSummary summary) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      child: Column(
        children: summary.wasteWatchList.map((item) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.emoji, style: AppTypography.watchEmoji),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            item.name,
                            style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${item.count} discarded',
                            style: text.labelSmall?.copyWith(color: AppColors.critical),
                          ),
                        ],
                      ),
                      if (item.tip != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          '💡 ${item.tip}',
                          style: text.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildAchievementsGrid(BuildContext context, InsightsSummary summary) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = (constraints.maxWidth - AppSpacing.sm) / 2;

        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: summary.achievements.map((achievement) {
            return SizedBox(
              width: itemWidth,
              child: GestureDetector(
                onTap: () => _showAchievementDetails(context, achievement),
                child: AchievementBadge(
                  title: achievement.title,
                  description: achievement.description,
                  icon: _achievementIcon(achievement.id),
                  isUnlocked: achievement.isUnlocked,
                  progressHint: achievement.isUnlocked ? null : achievement.progressHint,
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSavingsEstimateCard(BuildContext context, InsightsSummary summary, String currency) {
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: AppColors.orange, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Financial Savings Basis',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Estimated savings are calculated using typical ingredient pricing or your customized value per item. Adjust currency and values in Profile settings.',
            style: text.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: 'Adjust Currency & Item Value',
              variant: AppButtonVariant.outlined,
              icon: Icons.tune_rounded,
              onPressed: () {
                context.read<NavigationCubit>().select(NavTab.profile);
              },
            ),
          ),
        ],
      ),
    );
  }

  IconData _achievementIcon(String id) {
    return switch (id) {
      'first_rescue' => Icons.eco_rounded,
      'rescue_rookie' => Icons.workspace_premium_rounded,
      '3_day_streak' => Icons.local_fire_department_rounded,
      '7_day_streak' => Icons.whatshot_rounded,
      'zero_waste_week' => Icons.verified_rounded,
      'voice_chef' => Icons.record_voice_over_rounded,
      'pantry_hero' => Icons.shield_rounded,
      _ => Icons.emoji_events_rounded,
    };
  }
}
