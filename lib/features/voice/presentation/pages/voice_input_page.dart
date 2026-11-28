import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../../../../core/widgets/responsive_builder.dart';
import '../../../../core/widgets/section_header.dart';
import '../../../../core/widgets/voice_orb.dart';
import '../../../ingredients/domain/entities/ingredient.dart';
import '../../../ingredients/presentation/cubit/inventory_cubit.dart';
import '../../../ingredients/presentation/widgets/ingredient_form_sheet.dart';
import '../../../settings/domain/entities/user_preferences.dart';
import '../../../settings/presentation/cubit/settings_cubit.dart';
import '../../domain/entities/extracted_ingredient.dart';
import '../bloc/voice_input_bloc.dart';
import '../bloc/voice_input_event.dart';
import '../bloc/voice_input_state.dart';
import '../widgets/extracted_ingredient_tile.dart';

class VoiceInputPage extends StatefulWidget {
  const VoiceInputPage({super.key});

  @override
  State<VoiceInputPage> createState() => _VoiceInputPageState();
}

class _VoiceInputPageState extends State<VoiceInputPage> {
  late final TextEditingController _transcriptController;
  late final TextEditingController _correctionController;
  String _currentLocale = 'en_IN';
  bool _isConfirming = false;

  Widget _buildLanguageChipRow(BuildContext context) {
    VoiceInputLanguage voiceLang = VoiceInputLanguage.auto;
    try {
      voiceLang = context.watch<SettingsCubit>().state.preferences.voiceInputLanguage;
    } catch (_) {}
    final isAutoAi = voiceLang == VoiceInputLanguage.auto;

    const locales = [
      ('en_IN', 'English (India)'),
      ('ta_IN', 'Tamil (தமிழ்)'),
      ('hi_IN', 'Hindi (हिंदी)'),
    ];

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: isAutoAi ? AppColors.orange.withValues(alpha: 0.15) : Theme.of(context).colorScheme.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            isAutoAi
                ? 'Mode: Auto (AI) - Tamil, Hindi, English, Mixed'
                : 'Mode: Live (On-device speech recognizer)',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isAutoAi ? AppColors.orange : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
          ),
        ),
        const SizedBox(height: 6),
        if (!isAutoAi)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: locales.map((loc) {
                final isSelected = _currentLocale == loc.$1;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 3),
                  child: ChoiceChip(
                    label: Text(loc.$2, style: AppTypography.chipLabel),
                    selected: isSelected,
                    selectedColor: AppColors.orange,
                    onSelected: (val) {
                      if (val) {
                        setState(() => _currentLocale = loc.$1);
                        context.read<VoiceInputBloc>().add(StartListening(
                              localeId: loc.$1,
                              isAutoMode: false,
                            ));
                      }
                    },
                  ),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    final currentState = context.read<VoiceInputBloc>().state;
    final initialText =
        currentState is VoiceInputEditing ? currentState.transcript : '';
    _transcriptController = TextEditingController(text: initialText);
    _correctionController = TextEditingController();
  }

  @override
  void dispose() {
    _transcriptController.dispose();
    _correctionController.dispose();
    super.dispose();
  }

  Future<void> _onEditItem(int index, ExtractedIngredient item) async {
    final ingredient = Ingredient(
      id: index.toString(),
      name: item.name,
      quantity: item.quantity,
      unit: item.unit,
      expiryDate: item.resolvedExpiry,
      addedAt: DateTime.now(),
    );

    final updated = await IngredientFormSheet.show(context, initial: ingredient);
    if (updated != null && mounted) {
      context.read<VoiceInputBloc>().add(EditExtractedItem(
            index: index,
            updatedItem: ExtractedIngredient(
              name: updated.name,
              quantity: updated.quantity,
              unit: updated.unit,
              expiryPhrase: item.expiryPhrase,
              resolvedExpiry: updated.expiryDate,
              expiryUnderstood: true,
            ),
          ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<VoiceInputBloc, VoiceInputState>(
      listener: (context, state) {
        if (state is VoiceInputSaved) {
          context.read<InventoryCubit>().loadIngredients();
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(
              SnackBar(
                content: Text(
                    'Added ${state.count} ${state.count == 1 ? "ingredient" : "ingredients"} to My Kitchen!'),
              ),
            );
          Navigator.of(context).pop();
        } else if (state is VoiceInputEditing) {
          if (_transcriptController.text != state.transcript) {
            _transcriptController.value = TextEditingValue(
              text: state.transcript,
              selection: TextSelection.collapsed(offset: state.transcript.length),
            );
          }
        }
      },
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Voice Rescue'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                context.read<VoiceInputBloc>().add(const CancelVoiceInput());
                Navigator.of(context).pop();
              },
            ),
          ),
          body: SafeArea(
            child: ContentContainer(
              vertical: AppSpacing.md,
              child: _buildBody(context, state),
            ),
          ),
        );
      },
    );
  }

  Widget _buildBody(BuildContext context, VoiceInputState state) {
    if (state is VoiceInputRequestingPermission) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is VoiceInputPermissionDenied) {
      return _buildPermissionDeniedView(context, state.isPermanent);
    }

    if (state is VoiceInputExtracting || state is VoiceInputSaving) {
      return SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionHeader(
              title: state is VoiceInputExtracting
                  ? 'Extracting ingredients...'
                  : 'Saving to kitchen...',
              subtitle: 'Analyzing your food items and expiry phrases.',
            ),
            const SizedBox(height: AppSpacing.xl),
            const LoadingSkeletonList(count: 3),
          ],
        ),
      );
    }

    if (state is VoiceInputConfirming) {
      return _buildConfirmationView(context, state);
    }

    if (state is VoiceInputError) {
      return ErrorState(
        message: state.message,
        retryLabel: 'Try again',
        onRetry: () {
          if (state.transcript.isNotEmpty) {
            _transcriptController.text = state.transcript;
            context
                .read<VoiceInputBloc>()
                .add(TranscriptChanged(state.transcript));
          } else {
            context.read<VoiceInputBloc>().add(const ResetToIdle());
          }
        },
      );
    }

    // Default: Idle, Listening, or Editing
    return _buildVoiceInputView(context, state);
  }

  Widget _buildPermissionDeniedView(BuildContext context, bool isPermanent) {
    return Center(
      child: EmptyState(
        icon: Icons.mic_off_outlined,
        title: 'Microphone permission needed',
        message: isPermanent
            ? 'Microphone access is permanently denied. You can grant access in device settings or type your ingredients below.'
            : 'RescueRecipe uses your microphone to transcribe spoken ingredients. You can also type them directly.',
        actionLabel: isPermanent ? 'Open settings' : 'Grant permission',
        onAction: () async {
          if (isPermanent) {
            await openAppSettings();
          } else {
            if (context.mounted) {
              context.read<VoiceInputBloc>().add(const StartListening());
            }
          }
        },
      ),
    );
  }

  Widget _buildVoiceInputView(BuildContext context, VoiceInputState state) {
    final bool isListening = state is VoiceInputListening;
    final double soundLevel = isListening ? (state).soundLevel : 0.0;
    final String liveTranscript =
        isListening ? (state).transcript : _transcriptController.text;
    final bool hasTranscript = _transcriptController.text.trim().isNotEmpty ||
        (state is VoiceInputEditing && state.transcript.trim().isNotEmpty);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          VoiceOrb(
            active: isListening,
            level: soundLevel,
            semanticLabel: isListening
                ? 'Voice orb recording, sound level ${(soundLevel * 100).toInt()}%'
                : 'Voice orb idle',
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildLanguageChipRow(context),
          const SizedBox(height: AppSpacing.sm),
          Text(
            isListening ? 'Listening...' : 'Tap the microphone to speak',
            style: context.text.titleMedium?.copyWith(
              color: isListening ? AppColors.orange : context.colors.onSurface,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          // Action button (Listen / Stop)
          if (!isListening)
            AppButton(
              label: 'Start speaking',
              icon: Icons.mic,
              variant: AppButtonVariant.filled,
              onPressed: () {
                HapticFeedback.lightImpact();
                final prefs = context.read<SettingsCubit>().state.preferences;
                final isAuto = prefs.voiceInputLanguage == VoiceInputLanguage.auto;
                final locale = prefs.voiceInputLanguage == VoiceInputLanguage.tamil
                    ? 'ta_IN'
                    : (prefs.voiceInputLanguage == VoiceInputLanguage.hindi
                        ? 'hi_IN'
                        : _currentLocale);
                context.read<VoiceInputBloc>().add(StartListening(
                      localeId: locale,
                      isAutoMode: isAuto,
                    ));
              },
            )
          else
            AppButton(
              label: 'Done speaking',
              icon: Icons.stop,
              variant: AppButtonVariant.filled,
              onPressed: () {
                HapticFeedback.lightImpact();
                context.read<VoiceInputBloc>().add(const StopListening());
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Icon(
                      isListening ? Icons.record_voice_over : Icons.edit_note,
                      size: AppSizes.iconSm,
                      color: context.colors.secondary,
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Expanded(
                      child: Text(
                        isListening ? 'Live transcript' : 'Transcript (editable)',
                        style: context.text.labelLarge?.copyWith(
                          color: context.colors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                if (isListening)
                  Text(
                    liveTranscript.isEmpty
                        ? 'Speak your ingredients (e.g. "three tomatoes, two onions, and spinach expiring tomorrow")...'
                        : liveTranscript,
                    style: context.text.bodyLarge?.copyWith(
                      color: liveTranscript.isEmpty
                          ? context.colors.onSurfaceVariant
                          : context.colors.onSurface,
                    ),
                  )
                else
                  TextFormField(
                    controller: _transcriptController,
                    maxLines: 4,
                    decoration: const InputDecoration(
                      hintText:
                          'Type or edit your ingredients here (e.g. "three tomatoes, two onions, spinach")...',
                    ),
                    onChanged: (text) {
                      context
                          .read<VoiceInputBloc>()
                          .add(TranscriptChanged(text));
                    },
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (!isListening && hasTranscript)
            AppButton(
              label: 'Find ingredients',
              icon: Icons.auto_awesome,
              variant: AppButtonVariant.filled,
              expand: true,
              onPressed: () {
                HapticFeedback.mediumImpact();
                context.read<VoiceInputBloc>().add(const SubmitTranscript());
              },
            ),
          const SizedBox(height: AppSpacing.xl),
          const ExpiryDisclaimer(),
        ],
      ),
    );
  }

  Widget _buildConfirmationView(
      BuildContext context, VoiceInputConfirming state) {
    final text = context.text;
    final scheme = context.colors;

    if (state.items.isEmpty) {
      return Center(
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: "I didn't catch any ingredients",
          message:
              'No food ingredients were found in your transcript. Try speaking again or edit your text.',
          actionLabel: 'Try again',
          onAction: () {
            context
                .read<VoiceInputBloc>()
                .add(TranscriptChanged(state.originalTranscript));
          },
        ),
      );
    }

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(
                      header: true,
                      child: Text(
                        'Review ingredients',
                        style: text.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Found ${state.items.length} ${state.items.length == 1 ? "item" : "items"}.',
                      style: text.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.xs,
                ),
                decoration: BoxDecoration(
                  color: scheme.primaryContainer,
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
                child: Text(
                  state.source.label,
                  style: text.labelSmall?.copyWith(
                    color: scheme.onPrimaryContainer,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          for (int i = 0; i < state.items.length; i++) ...[
            ExtractedIngredientTile(
              item: state.items[i],
              onTap: () => _onEditItem(i, state.items[i]),
              onDelete: () {
                HapticFeedback.mediumImpact();
                context.read<VoiceInputBloc>().add(RemoveExtractedItem(i));
              },
            ),
            const SizedBox(height: AppSpacing.md),
          ],
          const SizedBox(height: AppSpacing.lg),
          AppCard(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Need to fix something? Say or type a correction:',
                  style: text.labelMedium?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _correctionController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. "actually I don\'t have onions"',
                          isDense: true,
                        ),
                        onFieldSubmitted: (val) {
                          if (val.trim().isNotEmpty) {
                            context
                                .read<VoiceInputBloc>()
                                .add(ApplyCorrectionText(val.trim()));
                            _correctionController.clear();
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    IconButton(
                      icon: const Icon(Icons.send),
                      color: AppColors.orange,
                      tooltip: 'Apply correction',
                      onPressed: () {
                        final val = _correctionController.text.trim();
                        if (val.isNotEmpty) {
                          context
                              .read<VoiceInputBloc>()
                              .add(ApplyCorrectionText(val));
                          _correctionController.clear();
                        }
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppButton(
            label: 'Add all to My Kitchen',
            icon: Icons.check,
            variant: AppButtonVariant.filled,
            expand: true,
            onPressed: () {
              if (_isConfirming) return;
              _isConfirming = true;
              HapticFeedback.mediumImpact();
              context
                  .read<VoiceInputBloc>()
                  .add(const ConfirmAllIngredients());
            },
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Discard and re-record',
            icon: Icons.refresh,
            variant: AppButtonVariant.text,
            expand: true,
            onPressed: () {
              context.read<VoiceInputBloc>().add(const ResetToIdle());
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const ExpiryDisclaimer(),
        ],
      ),
    );
  }
}
