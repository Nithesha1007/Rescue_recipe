import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/achievement_badge.dart';
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

class InsightsPage extends StatefulWidget {
  const InsightsPage({super.key});

  @override
  State<InsightsPage> createState() => _InsightsPageState();
}

class _InsightsPageState extends State<InsightsPage> {
  @override
  void initState() {
    super.initState();
    context.read<InsightsCubit>().loadInsights();
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
            child: Center(
              child: EmptyState(
                icon: Icons.insights_rounded,
                title: 'No Activity Logged Yet',
                message:
                    'Use ingredients or cook recipes to start earning Rescue Points, building streaks, and tracking food waste reduction.',
                actionLabel: 'Go to My Kitchen',
                onAction: () {
                  context.read<NavigationCubit>().select(NavTab.kitchen);
                },
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
              // 1. Core Summary Stats Grid
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
                  style: theme.textTheme.labelSmall?.copyWith(
                    fontStyle: FontStyle.italic,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.md),

              // 2. Game Mechanics: Rescue Score & Streaks
              Row(
                children: [
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.orange, size: 20),
                              Text(
                                'Rescue Score',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${summary.rescueScore}',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.orange,
                              ),
                            ),
                          ),
                          Text(
                            'Illustrative Game Score',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppCard(
                      child: Column(
                        children: [
                          Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Icon(Icons.local_fire_department_rounded, color: AppColors.critical, size: 20),
                              Text(
                                'Rescue Streak',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              '${summary.currentStreak} Days',
                              style: theme.textTheme.headlineMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppColors.critical,
                              ),
                            ),
                          ),
                          Text(
                            'Best: ${summary.bestStreak} Days (Illustrative)',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              // 3. Weekly Bar Chart
              WeeklyBarChart(items: summary.weeklyActivity),
              const SizedBox(height: AppSpacing.md),

              // 4. Achievement Badges
              const SectionHeader(
                title: 'Illustrative Achievements',
                subtitle: 'Badges and milestones unlocked by food rescue activity',
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.xs,
                runSpacing: AppSpacing.xs,
                alignment: WrapAlignment.start,
                children: summary.achievements.map((a) {
                  return AchievementBadge(
                    title: a.title,
                    description: a.description,
                    icon: _achievementIcon(a.id),
                    isUnlocked: a.isUnlocked,
                    progressHint: a.isUnlocked ? null : a.progressHint,
                  );
                }).toList(),
              ),
              const SizedBox(height: AppSpacing.lg),
              const ExpiryDisclaimer(),
              const SizedBox(height: AppSpacing.xl),
            ],
          ),
        ),
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
