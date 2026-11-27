import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/glass_card.dart';
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
            child: switch (state.flowStatus) {
              CookingFlowStatus.loading => const Center(
                  child: LoadingSkeleton(width: 240, height: 180),
                ),
              CookingFlowStatus.error => ErrorState(
                  message: state.errorMessage ?? 'An unexpected error occurred.',
                  onRetry: () => Navigator.of(context).pop(),
                ),
              CookingFlowStatus.finished => _buildFinishedView(context, state),
              _ => _buildActiveCookingView(context, state),
            },
          ),
        );
      },
    );
  }

  Widget _buildFinishedView(BuildContext context, CookingState state) {
    final theme = Theme.of(context);

    return ContentContainer(
      child: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                size: 72,
                color: AppColors.lime,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Bon Appetit!',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'You completed ${state.session?.recipe.title ?? 'the recipe'}.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpacing.md),
              AppCard(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildStat(
                          context,
                          count: state.rescuedCount,
                          label: 'Rescued Items',
                          color: AppColors.lime,
                        ),
                        Container(
                          width: 1,
                          height: 40,
                          color: theme.dividerColor,
                        ),
                        _buildStat(
                          context,
                          count: state.totalDeducted,
                          label: 'Inventory Used',
                          color: AppColors.orange,
                        ),
                      ],
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

    final isLandscape =
        MediaQuery.orientationOf(context) == Orientation.landscape;

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
    return ContentContainer(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.xs,
            ),
            child: StepIndicator(
              current: session.currentStepIndex,
              count: session.totalSteps,
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: AppSpacing.xs),
                  _buildFocusCard(context, session),
                  const SizedBox(height: AppSpacing.sm),
                  if (state.spokenFeedback != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                      child: GlassCard(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.record_voice_over_rounded,
                              size: AppSizes.iconSm,
                              color: AppColors.orange,
                            ),
                            const SizedBox(width: AppSpacing.xs),
                            Expanded(
                              child: Text(
                                state.spokenFeedback!,
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const ExpiryDisclaimer(),
                ],
              ),
            ),
          ),
          _buildControlBar(context, state, session),
        ],
      ),
    );
  }

  Widget _buildLandscapeLayout(
    BuildContext context,
    CookingState state,
    dynamic session,
  ) {
    return Row(
      children: [
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              children: [
                StepIndicator(
                  current: session.currentStepIndex,
                  count: session.totalSteps,
                ),
                const SizedBox(height: AppSpacing.sm),
                _buildFocusCard(context, session),
                const SizedBox(height: AppSpacing.xs),
                const ExpiryDisclaimer(),
              ],
            ),
          ),
        ),
        Expanded(
          flex: 4,
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).dividerColor.withValues(alpha: 0.1),
                ),
              ),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildMicButton(context, state),
                const SizedBox(height: AppSpacing.sm),
                _buildControlButtons(context, state, session),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFocusCard(BuildContext context, dynamic session) {
    final theme = Theme.of(context);
    final stepNum = session.currentStepIndex + 1;
    final totalSteps = session.totalSteps;

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'STEP $stepNum OF $totalSteps',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: AppColors.orange,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.volume_up_rounded),
                iconSize: AppSizes.iconSm,
                tooltip: 'Read step aloud',
                onPressed: () {
                  context.read<CookingBloc>().add(const StepRepeatTriggered());
                },
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            session.currentStepText,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildControlBar(
    BuildContext context,
    CookingState state,
    dynamic session,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
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
          const SizedBox(height: AppSpacing.xs),
          _buildControlButtons(context, state, session),
        ],
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
      AudioSessionState.listening => 'Listening... say "Next", "Repeat", or "Pause"',
      AudioSessionState.speaking => 'Speaking...',
      AudioSessionState.pausedListeningForResume => 'Paused in background',
      _ => state.isPaused
          ? 'Paused. Tap mic or say "Resume"'
          : 'Tap mic or say a command',
    };

    return Column(
      children: [
        PulsingMic(
          state: micState,
          size: 58,
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
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Expanded(
          child: AppButton(
            label: 'Back',
            variant: AppButtonVariant.outlined,
            icon: Icons.skip_previous_rounded,
            onPressed: session.isFirstStep
                ? null
                : () => bloc.add(const StepPreviousTriggered()),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppButton(
            label: state.isPaused ? 'Resume' : 'Pause',
            variant: AppButtonVariant.text,
            icon: state.isPaused
                ? Icons.play_arrow_rounded
                : Icons.pause_rounded,
            onPressed: () {
              if (state.isPaused) {
                bloc.add(const CookingResumedTriggered());
              } else {
                bloc.add(const CookingPausedTriggered());
              }
            },
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        Expanded(
          child: AppButton(
            label: session.isLastStep ? 'Finish' : 'Next',
            variant: AppButtonVariant.filled,
            icon: session.isLastStep
                ? Icons.check_rounded
                : Icons.skip_next_rounded,
            onPressed: () => bloc.add(const StepNextTriggered()),
          ),
        ),
      ],
    );
  }

  bool _isFinishing = false;

  void _showIngredientsSheet(BuildContext context, Recipe recipe) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CookingIngredientsSheet(recipe: recipe),
    );
  }

  void _showFinishSheet(BuildContext context, CookingState state) {
    final bloc = context.read<CookingBloc>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => FinishConfirmationSheet(
        proposals: state.deductionProposals,
        onToggle: (id) => bloc.add(DeductionProposalToggled(id)),
        onConfirm: () {
          if (_isFinishing) return;
          _isFinishing = true;
          Navigator.of(context).pop();
          bloc.add(const ConfirmDeductionsAndFinish());
        },
        onCancel: () {
          Navigator.of(context).pop();
        },
      ),
    );
  }
}
