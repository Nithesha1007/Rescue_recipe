import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/confetti_celebration.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/pulsing_mic.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/step_indicator.dart';
import '../../../recipes/domain/entities/recipe.dart';
import '../../domain/services/voice_session_controller.dart';
import '../bloc/cooking_bloc.dart';
import '../bloc/cooking_event.dart';
import '../bloc/cooking_state.dart';
import '../widgets/cooking_ingredients_sheet.dart';
import '../widgets/finish_confirmation_sheet.dart';

class CookingPage extends StatelessWidget {
  final Recipe recipe;

  const CookingPage({
    super.key,
    required this.recipe,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<CookingBloc>()..add(CookingStarted(recipe)),
      child: const _CookingView(),
    );
  }
}

class _CookingView extends StatefulWidget {
  const _CookingView();

  @override
  State<_CookingView> createState() => _CookingViewState();
}

class _CookingViewState extends State<_CookingView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WakelockPlus.enable();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final isInBackground = (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive);
    context.read<CookingBloc>().add(AppLifecycleStatusChanged(isInBackground));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CookingBloc, CookingState>(
      listenWhen: (previous, current) =>
          previous.flowStatus != current.flowStatus,
      listener: (context, state) {
        if (state.flowStatus == CookingFlowStatus.confirmingFinish) {
          _showFinishSheet(context, state);
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              state.session?.recipe.title ?? 'Cooking Mode',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.format_list_bulleted_rounded),
                tooltip: 'Ingredients',
                onPressed: state.session == null
                    ? null
                    : () => _showIngredientsSheet(context, state.session!.recipe),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                tooltip: 'Exit cooking',
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          body: SafeArea(
            child: _buildBody(context, state),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, CookingState state) {
    switch (state.flowStatus) {
      case CookingFlowStatus.loading:
      case CookingFlowStatus.initial:
        return const Center(child: LoadingSkeletonList(count: 3));

      case CookingFlowStatus.error:
        return ErrorState(
          message: state.errorMessage ?? 'An error occurred during cooking.',
          retryLabel: 'Retry',
          onRetry: () {
            final session = state.session;
            if (session != null) {
              context.read<CookingBloc>().add(CookingStarted(session.recipe));
            }
          },
        );

      case CookingFlowStatus.finished:
        return _buildFinishedView(context, state);

      case CookingFlowStatus.running:
      case CookingFlowStatus.paused:
      case CookingFlowStatus.confirmingFinish:
        return _buildActiveCookingView(context, state);
    }
  }

  Widget _buildFinishedView(BuildContext context, CookingState state) {
    final theme = Theme.of(context);

    return ConfettiCelebration(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  color: AppColors.limeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 48,
                  color: AppColors.low,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text(
                'Recipe Completed!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontFamily: AppTypography.headingFont,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Great job rescuing food today.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppCard(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStat(
                      context,
                      count: state.rescuedCount,
                      label: 'Rescued',
                      color: AppColors.low,
                    ),
                    _buildStat(
                      context,
                      count: state.totalDeducted,
                      label: 'Deducted',
                      color: AppColors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppButton(
                label: 'Back to Kitchen',
                variant: AppButtonVariant.filled,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStat(
    BuildContext context, {
    required int count,
    required String label,
    required Color color,
  }) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          '$count',
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildActiveCookingView(BuildContext context, CookingState state) {
    final session = state.session;
    if (session == null) {
      return const EmptyState(
        icon: Icons.kitchen_rounded,
        title: 'No active session',
        message: 'Unable to start cooking session.',
      );
    }

    final isLandscape = MediaQuery.orientationOf(context) == Orientation.landscape;

    if (isLandscape) {
      return _buildLandscapeLayout(context, state, session);
    }
    return _buildPortraitLayout(context, state, session);
  }

  Widget _buildPortraitLayout(
    BuildContext context,
    CookingState state,
    dynamic session,
  ) {
    final step = session.recipe.steps[session.currentStepIndex];

    return ContentContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg,
              vertical: AppSpacing.xs,
            ),
            child: StepIndicator(
              current: session.currentStepIndex,
              count: session.totalSteps,
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
              child: _buildFocusCard(context, session, state, step),
            ),
          ),
          _buildControlBar(context, state, session, step),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    CookingState state,
    dynamic session,
  ) {
    final step = session.recipe.steps[session.currentStepIndex];

    return Row(
      children: [
        Expanded(
          flex: 6,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                StepIndicator(
                  current: session.currentStepIndex,
                  count: session.totalSteps,
                ),
                const SizedBox(height: AppSpacing.sm),
                Expanded(child: _buildFocusCard(context, session, state, step)),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: _buildControlBar(context, state, session, step),
        ),
      ],
    );
  }

  Widget _buildFocusCard(
    BuildContext context,
    dynamic session,
    CookingState state,
    dynamic step,
  ) {
    final theme = Theme.of(context);
    final String? tip = step.tip;
    final int? minutes = step.minutes;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Step ${session.currentStepIndex + 1} of ${session.totalSteps}',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded, size: AppSizes.iconSm),
                tooltip: 'Read again',
                onPressed: () {
                  context.read<CookingBloc>().add(const StepRepeatTriggered());
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              if (tip != null && tip.isNotEmpty)
                Chip(
                  avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
                  label: Text('Tip: $tip', style: theme.textTheme.labelSmall),
                  backgroundColor: AppColors.limeSoft,
                ),
              if (minutes != null && minutes > 0)
                ActionChip(
                  avatar: const Icon(Icons.timer_outlined, size: 16),
                  label: Text(
                    state.isTimerActive
                        ? 'Timer: ${_formatTimer(state.timerSecondsRemaining ?? (minutes * 60))}'
                        : 'Start ${minutes}m timer',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: state.isTimerActive ? AppColors.orange : null,
                    ),
                  ),
                  onPressed: () {
                    final bloc = context.read<CookingBloc>();
                    if (state.isTimerActive) {
                      bloc.add(const StopStepTimer());
                    } else {
                      bloc.add(StartStepTimer(minutes * 60));
                    }
                  },
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: SingleChildScrollView(
              child: Text(
                session.currentStepText,
                style: theme.textTheme.titleMedium?.copyWith(
                  height: 1.45,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Widget _buildControlBar(
    BuildContext context,
    CookingState state,
    dynamic session,
    dynamic step,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.lg,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildMicButton(context, state),
          const SizedBox(height: AppSpacing.sm),
          _buildVoiceHintChips(context),
          const SizedBox(height: AppSpacing.sm),
          _buildControlButtons(context, state, session),
        ],
      ),
    );
  }

  Widget _buildVoiceHintChips(BuildContext context) {
    final hints = ['"Next"', '"Back"', '"Repeat"', '"Pause"', '"Tip"', '"Timer"'];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: hints.map((h) {
          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHigh,
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                h,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMicButton(BuildContext context, CookingState state) {
    final micState = switch (state.audioState) {
      AudioSessionState.listening => PulsingMicState.listening,
      AudioSessionState.speaking => PulsingMicState.speaking,
      AudioSessionState.pausedListeningForResume => PulsingMicState.paused,
      _ => state.isPaused ? PulsingMicState.paused : PulsingMicState.idle,
    };

    final hintText = switch (state.audioState) {
      AudioSessionState.listening => 'Listening... say "Next", "Back", "Tip", or "Timer"',
      AudioSessionState.speaking => 'Speaking steps...',
      AudioSessionState.pausedListeningForResume => 'Paused in background',
      _ => state.isPaused ? 'Paused. Tap mic or say "Resume"' : 'Tap mic or speak commands',
    };

    return Column(
      children: [
        PulsingMic(
          state: micState,
          size: 54,
          onTap: () {
            context.read<CookingBloc>().add(const MicToggled());
          },
        ),
        const SizedBox(height: 4),
        Text(
          hintText,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildControlButtons(
    BuildContext context,
    CookingState state,
    dynamic session,
  ) {
    final bloc = context.read<CookingBloc>();

    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            context,
            icon: Icons.arrow_back_rounded,
            label: 'Back',
            enabled: !session.isFirstStep,
            onPressed: () => bloc.add(const StepPreviousTriggered()),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            context,
            icon: state.isPaused ? Icons.play_arrow_rounded : Icons.pause_rounded,
            label: state.isPaused ? 'Resume' : 'Pause',
            enabled: true,
            onPressed: () {
              if (state.isPaused) {
                bloc.add(const CookingResumedTriggered());
              } else {
                bloc.add(const CookingPausedTriggered());
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: _buildActionButton(
            context,
            icon: session.isLastStep ? Icons.check_circle_rounded : Icons.arrow_forward_rounded,
            label: session.isLastStep ? 'Finish' : 'Next',
            enabled: true,
            isPrimary: true,
            onPressed: () {
              if (session.isLastStep) {
                bloc.add(const FinishCookingRequested());
              } else {
                bloc.add(const StepNextTriggered());
              }
            },
          ),
        ),
      ],
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required bool enabled,
    required VoidCallback onPressed,
    bool isPrimary = false,
  }) {
    final theme = Theme.of(context);

    return InkWell(
      onTap: enabled ? onPressed : null,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: Container(
        height: 54,
        decoration: BoxDecoration(
          color: enabled
              ? (isPrimary ? AppColors.orange : theme.colorScheme.surfaceContainerHigh)
              : theme.colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 20,
              color: enabled
                  ? (isPrimary ? AppColors.white : theme.colorScheme.onSurface)
                  : theme.colorScheme.outline,
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: enabled
                      ? (isPrimary ? AppColors.white : theme.colorScheme.onSurface)
                      : theme.colorScheme.outline,
                ),
                maxLines: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showIngredientsSheet(BuildContext context, Recipe recipe) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingIngredientsSheet(recipe: recipe),
    );
  }

  void _showFinishSheet(BuildContext context, CookingState state) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FinishConfirmationSheet(
        proposals: state.deductionProposals,
        onToggle: (id) => context.read<CookingBloc>().add(DeductionProposalToggled(id)),
        onConfirm: () {
          Navigator.of(context).pop();
          context.read<CookingBloc>().add(const ConfirmDeductionsAndFinish());
        },
        onCancel: () => Navigator.of(context).pop(),
      ),
    );
  }
}
