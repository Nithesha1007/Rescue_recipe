import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/models/ai_status.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_page_scaffold.dart';
import '../../../../core/widgets/expiry_disclaimer.dart';
import '../../../../core/widgets/settings_tile.dart';
import '../../../cooking/data/services/tts_service.dart';
import '../../../ingredients/data/datasources/demo_ingredients.dart';
import '../../../ingredients/presentation/cubit/inventory_cubit.dart';
import '../../../ingredients/presentation/cubit/inventory_state.dart';
import '../../../insights/presentation/cubit/insights_cubit.dart';
import '../../../insights/domain/entities/insights_summary.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import '../../../voice/data/datasources/gemini_remote_datasource.dart';
import '../../domain/entities/user_preferences.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  bool _isTestingSpeech = false;
  bool _isTestingAi = false;
  AiStatus? _testedAiStatus;
  late final TextEditingController _customValueController;
  final TextEditingController _newDislikeController = TextEditingController();

  static const List<String> _commonAllergens = [
    'Dairy',
    'Gluten',
    'Peanuts',
    'Tree Nuts',
    'Eggs',
    'Soy',
    'Shellfish',
    'Fish',
    'Sesame',
  ];

  static const List<String> _commonCuisines = [
    'South Indian',
    'North Indian',
    'Indo-Chinese',
    'Italian',
    'Continental',
    'Mexican',
    'Mediterranean',
    'Thai',
  ];

  static const List<String> _avatarChoices = [
    '👨‍🍳',
    '👩‍🍳',
    '🧑‍🍳',
    '🥘',
    '🍲',
    '🥑',
    '🍅',
    '🌱',
    '🥗',
    '🍛',
  ];

  @override
  void initState() {
    super.initState();
    final prefs = context.read<SettingsCubit>().state.preferences;
    _customValueController = TextEditingController(
      text: prefs.customItemValue != null ? prefs.customItemValue!.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _customValueController.dispose();
    _newDislikeController.dispose();
    super.dispose();
  }

  Future<void> _testSpeech(double rate) async {
    if (_isTestingSpeech) return;
    setState(() => _isTestingSpeech = true);

    try {
      final tts = sl<TtsService>();
      await tts.setSpeechRate(rate);
      await tts.speak("Hello! This is how I will read recipes for you.");
    } catch (_) {
      // Best effort in test environments
    } finally {
      if (mounted) {
        setState(() => _isTestingSpeech = false);
      }
    }
  }

  Future<void> _testAiConnection() async {
    if (_isTestingAi) return;
    setState(() => _isTestingAi = true);

    try {
      final geminiDs = sl<GeminiRemoteDataSource>();
      final status = await geminiDs.testConnection();
      if (mounted) {
        setState(() => _testedAiStatus = status);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _testedAiStatus = const AiStatus(
            state: AiConnectionState.badResponse,
            message: 'Connection failed',
          );
        });
      }
    } finally {
      if (mounted) {
        setState(() => _isTestingAi = false);
      }
    }
  }

  void _showEditProfileSheet(BuildContext context, UserPreferences prefs) {
    final nameController = TextEditingController(text: prefs.displayName);
    String selectedEmoji = prefs.avatarEmoji;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetCtx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final theme = Theme.of(ctx);
            final text = theme.textTheme;

            return Container(
              padding: EdgeInsets.only(
                left: AppSpacing.lg,
                right: AppSpacing.lg,
                top: AppSpacing.lg,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + AppSpacing.xl,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
              ),
              child: SingleChildScrollView(
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
                      'Edit Profile',
                      style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Center(
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.orange.withValues(alpha: 0.15),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          selectedEmoji,
                          style: AppTypography.heroEmoji,
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Text('Choose Avatar', style: text.labelMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: AppSpacing.sm,
                      runSpacing: AppSpacing.sm,
                      alignment: WrapAlignment.center,
                      children: _avatarChoices.map((emoji) {
                        final isSel = emoji == selectedEmoji;
                        return GestureDetector(
                          onTap: () => setSheetState(() => selectedEmoji = emoji),
                          child: Container(
                            padding: const EdgeInsets.all(AppSpacing.xs),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSel ? AppColors.orange : theme.colorScheme.outlineVariant,
                                width: isSel ? 2 : 1,
                              ),
                              color: isSel ? AppColors.orange.withValues(alpha: 0.1) : null,
                            ),
                            child: Text(emoji, style: AppTypography.pickerEmoji),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    TextField(
                      controller: nameController,
                      decoration: const InputDecoration(
                        labelText: 'Your Name',
                        hintText: 'Enter your name',
                        prefixIcon: Icon(Icons.person_outline_rounded),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    AppButton(
                      label: 'Save Profile',
                      icon: Icons.check_rounded,
                      onPressed: () {
                        final newName = nameController.text.trim();
                        context.read<SettingsCubit>().updatePreferences(prefs.copyWith(
                              displayName: newName.isNotEmpty ? newName : 'Food Rescuer',
                              avatarEmoji: selectedEmoji,
                            ));
                        Navigator.pop(sheetCtx);
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _exportKitchenData(BuildContext context) {
    final inventoryState = context.read<InventoryCubit>().state;
    final prefs = context.read<SettingsCubit>().state.preferences;
    final insights = context.read<InsightsCubit>().state.summary;

    final items = inventoryState is InventoryLoaded
        ? inventoryState.items.map((i) => {
              'id': i.id,
              'name': i.name,
              'quantity': i.quantity,
              'unit': i.unit,
              'expiryDate': i.expiryDate?.toIso8601String(),
              'storage': i.storage.name,
            }).toList()
        : [];

    final payload = {
      'exportedAt': DateTime.now().toIso8601String(),
      'profile': {
        'displayName': prefs.displayName,
        'householdSize': prefs.householdSize,
        'diet': prefs.diet.name,
        'allergens': prefs.allergens,
        'dislikedIngredients': prefs.dislikedIngredients,
        'preferredCuisines': prefs.preferredCuisines,
      },
      'inventory': items,
      'stats': {
        'rescuedCount': insights?.rescuedCount ?? 0,
        'usedCount': insights?.usedCount ?? 0,
        'discardedCount': insights?.discardedCount ?? 0,
        'rescueScore': insights?.rescueScore ?? 0,
        'currentStreak': insights?.currentStreak ?? 0,
      },
    };

    final jsonStr = const JsonEncoder.withIndent('  ').convert(payload);
    SharePlus.instance.share(ShareParams(text: jsonStr));
  }

  double _calculateProfileCompletion(UserPreferences prefs) {
    int total = 6;
    int completed = 0;

    if (prefs.displayName.isNotEmpty && prefs.displayName != 'Food Rescuer') completed++;
    if (prefs.diet != DietTag.none) completed++;
    if (prefs.preferredCuisines.isNotEmpty) completed++;
    if (prefs.allergens.isNotEmpty || prefs.dislikedIngredients.isNotEmpty) completed++;
    if (prefs.householdSize > 0) completed++;
    if (prefs.cookingSkill != CookingSkill.beginner) completed++;

    return (completed / total).clamp(0.2, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Profile & Settings',
      subtitle: 'Customize your food rescue assistant',
      scrollable: true,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final prefs = state.preferences;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildFoodPreferencesSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildHouseholdSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildSpeechSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildAppearanceSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildNotificationsSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildEstimatesSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildAiDiagnosticsSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildDataManagementSection(context),
              const SizedBox(height: AppSpacing.lg),
              _buildAboutSection(context),
              const SizedBox(height: AppSpacing.xl),
              const ExpiryDisclaimer(),
              const SizedBox(height: AppSpacing.xxl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, UserPreferences prefs) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    InsightsSummary? insights;
    try {
      insights = context.watch<InsightsCubit>().state.summary;
    } catch (_) {
      // In case InsightsCubit is not above ProfilePage
    }
    final completion = _calculateProfileCompletion(prefs);
    final levelName = insights?.levelName ?? 'Seedling';

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () => _showEditProfileSheet(context, prefs),
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.orange.withValues(alpha: 0.15),
                    border: Border.all(color: AppColors.orange.withValues(alpha: 0.4), width: 2),
                  ),
                  alignment: Alignment.center,
                  child: Text(prefs.avatarEmoji, style: AppTypography.avatarEmoji),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            prefs.displayName,
                            style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          tooltip: 'Edit Profile',
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => _showEditProfileSheet(context, prefs),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.orange.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        'Level: $levelName (Illustrative)',
                        style: text.labelSmall?.copyWith(
                          color: AppColors.orange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // 3 Quick Stats
          Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(AppRadius.md),
            ),
            child: Row(
              children: [
                Expanded(child: _buildQuickStat(context, '${insights?.rescuedCount ?? 0}', 'Rescued', AppColors.low)),
                Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant),
                Expanded(child: _buildQuickStat(context, '${insights?.currentStreak ?? 0} d', 'Streak', AppColors.orange)),
                Container(width: 1, height: 28, color: theme.colorScheme.outlineVariant),
                Expanded(child: _buildQuickStat(
                  context,
                  '${prefs.currencySymbol}${insights?.estimatedMoneySaved.toStringAsFixed(0) ?? "0"}',
                  'Saved',
                  AppColors.low,
                )),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),

          // Profile completion progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text('Profile Completion', style: text.labelSmall)),
              Text('${(completion * 100).toInt()}%', style: text.labelSmall?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: completion,
              minHeight: 6,
              backgroundColor: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(BuildContext context, String value, String label, Color color) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildFoodPreferencesSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return SettingsSection(
      title: 'Food Preferences & Allergens',
      children: [
        SettingsTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Dietary Restrictions',
          subtitle: 'Filters recipes to match your diet',
          bottomControl: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: DietTag.values.map((tag) {
              final isSelected = prefs.diet == tag;
              return ChoiceChip(
                label: Text(tag.displayName),
                selected: isSelected,
                selectedColor: AppColors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    cubit.updatePreferences(prefs.copyWith(diet: tag));
                  }
                },
              );
            }).toList(),
          ),
        ),
        SettingsTile(
          icon: Icons.warning_amber_rounded,
          title: 'Allergens (Hard Exclusion)',
          subtitle: 'Never suggest recipes containing these allergens',
          bottomControl: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _commonAllergens.map((allergen) {
              final isSelected = prefs.allergens.contains(allergen);
              return FilterChip(
                label: Text(allergen),
                selected: isSelected,
                selectedColor: AppColors.critical.withValues(alpha: 0.2),
                checkmarkColor: AppColors.critical,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.critical : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  final list = List<String>.from(prefs.allergens);
                  if (selected) {
                    list.add(allergen);
                  } else {
                    list.remove(allergen);
                  }
                  cubit.updatePreferences(prefs.copyWith(allergens: list));
                },
              );
            }).toList(),
          ),
        ),
        SettingsTile(
          icon: Icons.thumb_down_outlined,
          title: 'Disliked Ingredients',
          subtitle: 'Exclude recipes with ingredients you dislike',
          bottomControl: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (prefs.dislikedIngredients.isNotEmpty)
                Wrap(
                  spacing: AppSpacing.xs,
                  runSpacing: AppSpacing.xs,
                  children: prefs.dislikedIngredients.map((item) {
                    return Chip(
                      label: Text(item),
                      deleteIcon: const Icon(Icons.close_rounded, size: 16),
                      onDeleted: () {
                        final list = List<String>.from(prefs.dislikedIngredients)..remove(item);
                        cubit.updatePreferences(prefs.copyWith(dislikedIngredients: list));
                      },
                    );
                  }).toList(),
                ),
              const SizedBox(height: AppSpacing.xs),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _newDislikeController,
                      decoration: const InputDecoration(
                        hintText: 'Add an ingredient to avoid',
                        isDense: true,
                      ),
                      onSubmitted: (val) {
                        final trimmed = val.trim();
                        if (trimmed.isNotEmpty && !prefs.dislikedIngredients.contains(trimmed)) {
                          final list = List<String>.from(prefs.dislikedIngredients)..add(trimmed);
                          cubit.updatePreferences(prefs.copyWith(dislikedIngredients: list));
                          _newDislikeController.clear();
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    label: 'Add',
                    variant: AppButtonVariant.tonal,
                    onPressed: () {
                      final trimmed = _newDislikeController.text.trim();
                      if (trimmed.isNotEmpty && !prefs.dislikedIngredients.contains(trimmed)) {
                        final list = List<String>.from(prefs.dislikedIngredients)..add(trimmed);
                        cubit.updatePreferences(prefs.copyWith(dislikedIngredients: list));
                        _newDislikeController.clear();
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
        SettingsTile(
          icon: Icons.ramen_dining_rounded,
          title: 'Preferred Cuisines',
          subtitle: 'Boosts recipe ranking for your regional tastes',
          bottomControl: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: _commonCuisines.map((c) {
              final isSelected = prefs.preferredCuisines.contains(c);
              return FilterChip(
                label: Text(c),
                selected: isSelected,
                selectedColor: AppColors.orange.withValues(alpha: 0.2),
                checkmarkColor: AppColors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.orange : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  final list = List<String>.from(prefs.preferredCuisines);
                  if (selected) {
                    list.add(c);
                  } else {
                    list.remove(c);
                  }
                  cubit.updatePreferences(prefs.copyWith(preferredCuisines: list));
                },
              );
            }).toList(),
          ),
        ),
        SettingsTile(
          icon: Icons.local_fire_department_outlined,
          title: 'Spice Tolerance',
          subtitle: 'Adjusts heat level in AI recipe suggestions',
          bottomControl: SegmentedButton<SpiceLevel>(
            segments: const [
              ButtonSegment(value: SpiceLevel.mild, label: Text('Mild')),
              ButtonSegment(value: SpiceLevel.medium, label: Text('Medium')),
              ButtonSegment(value: SpiceLevel.hot, label: Text('Hot 🔥')),
            ],
            selected: {prefs.spiceLevel},
            onSelectionChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(spiceLevel: val.first));
            },
          ),
        ),
        SettingsTile(
          icon: Icons.outdoor_grill_outlined,
          title: 'Cooking Skill Level',
          subtitle: 'Customizes recipe complexity and step instructions',
          bottomControl: SegmentedButton<CookingSkill>(
            segments: const [
              ButtonSegment(value: CookingSkill.beginner, label: Text('Beginner')),
              ButtonSegment(value: CookingSkill.intermediate, label: Text('Intermediate')),
              ButtonSegment(value: CookingSkill.expert, label: Text('Expert')),
            ],
            selected: {prefs.cookingSkill},
            onSelectionChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(cookingSkill: val.first));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildHouseholdSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);
    final text = theme.textTheme;

    return SettingsSection(
      title: 'Household & Recipe Servings',
      children: [
        SettingsTile(
          icon: Icons.people_outline_rounded,
          title: 'Household Size',
          subtitle: 'Helps estimate meal quantities',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: prefs.householdSize > 1
                    ? () => cubit.updatePreferences(prefs.copyWith(householdSize: prefs.householdSize - 1))
                    : null,
              ),
              Text('${prefs.householdSize}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: prefs.householdSize < 10
                    ? () => cubit.updatePreferences(prefs.copyWith(householdSize: prefs.householdSize + 1))
                    : null,
              ),
            ],
          ),
        ),
        SettingsTile(
          icon: Icons.flatware_rounded,
          title: 'Default Recipe Servings',
          subtitle: 'Recipes scale to this number of portions automatically',
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: prefs.defaultServings > 1
                    ? () => cubit.updatePreferences(prefs.copyWith(defaultServings: prefs.defaultServings - 1))
                    : null,
              ),
              Text('${prefs.defaultServings}', style: text.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: prefs.defaultServings < 10
                    ? () => cubit.updatePreferences(prefs.copyWith(defaultServings: prefs.defaultServings + 1))
                    : null,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: 'Speech & Voice Assistant',
      children: [
        SettingsTile(
          icon: Icons.mic_rounded,
          title: 'Voice Input Mode & Language',
          subtitle: 'Choose between AI audio extraction or live recognizer',
          bottomControl: DropdownButtonHideUnderline(
            child: DropdownButton<VoiceInputLanguage>(
              isExpanded: true,
              isDense: true,
              value: prefs.voiceInputLanguage,
              items: const [
                DropdownMenuItem(
                  value: VoiceInputLanguage.auto,
                  child: Text('Auto (AI) - Tamil, Hindi, English, Mixed'),
                ),
                DropdownMenuItem(
                  value: VoiceInputLanguage.english,
                  child: Text('Live - English (India)'),
                ),
                DropdownMenuItem(
                  value: VoiceInputLanguage.tamil,
                  child: Text('Live - Tamil (தமிழ்)'),
                ),
                DropdownMenuItem(
                  value: VoiceInputLanguage.hindi,
                  child: Text('Live - Hindi (हिंदी)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  cubit.updatePreferences(prefs.copyWith(voiceInputLanguage: val));
                }
              },
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.record_voice_over_rounded,
          title: 'Cooking Guide Language',
          subtitle: 'Language used by the voice guide while cooking',
          bottomControl: DropdownButtonHideUnderline(
            child: DropdownButton<GuideLanguage>(
              isExpanded: true,
              isDense: true,
              value: prefs.guideLanguage,
              items: const [
                DropdownMenuItem(
                  value: GuideLanguage.english,
                  child: Text('English'),
                ),
                DropdownMenuItem(
                  value: GuideLanguage.tamil,
                  child: Text('Tamil (தமிழ்)'),
                ),
                DropdownMenuItem(
                  value: GuideLanguage.hindi,
                  child: Text('Hindi (हिंदी)'),
                ),
                DropdownMenuItem(
                  value: GuideLanguage.tanglish,
                  child: Text('Tanglish (Tamil in English Script)'),
                ),
              ],
              onChanged: (val) {
                if (val != null) {
                  cubit.updatePreferences(prefs.copyWith(guideLanguage: val));
                }
              },
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.volume_up_rounded,
          title: 'Spoken Feedback',
          subtitle: 'Read steps and timer alerts aloud during cooking',
          trailing: Switch(
            value: prefs.voiceFeedbackEnabled,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(voiceFeedbackEnabled: val));
            },
          ),
        ),
        SettingsTile(
          icon: Icons.speed_rounded,
          title: 'Voice Reading Speed',
          subtitle: 'Adjust TTS playback rate (${prefs.speechRate.toStringAsFixed(2)}x)',
          bottomControl: Column(
            children: [
              Slider(
                value: prefs.speechRate,
                min: 0.5,
                max: 1.5,
                divisions: 10,
                activeColor: AppColors.orange,
                onChanged: (val) {
                  cubit.updateSpeechRate(val);
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: AppButton(
                  label: _isTestingSpeech ? 'Reading...' : 'Test Voice',
                  variant: AppButtonVariant.outlined,
                  icon: Icons.play_arrow_rounded,
                  loading: _isTestingSpeech,
                  onPressed: () => _testSpeech(prefs.speechRate),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAppearanceSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: 'Appearance & Accessibility',
      children: [
        SettingsTile(
          icon: Icons.palette_outlined,
          title: 'App Theme',
          subtitle: 'Select light, dark, or system mode',
          bottomControl: SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('System')),
              ButtonSegment(value: ThemeMode.light, label: Text('Light')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
            ],
            selected: {prefs.themeMode},
            onSelectionChanged: (val) {
              cubit.updateThemeMode(val.first);
            },
          ),
        ),
        SettingsTile(
          icon: Icons.contrast_rounded,
          title: 'High Contrast',
          subtitle: 'Enhances border outlines and text contrast',
          trailing: Switch(
            value: prefs.highContrast,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(highContrast: val));
            },
          ),
        ),
        SettingsTile(
          icon: Icons.motion_photos_off_rounded,
          title: 'Reduce Motion',
          subtitle: 'Minimizes celebratory confetti and scale animations',
          trailing: Switch(
            value: prefs.reduceMotion,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(reduceMotion: val));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: 'Expiry Alerts & Reminders',
      children: [
        SettingsTile(
          icon: Icons.notifications_active_outlined,
          title: 'Daily Expiry Notifications',
          subtitle: 'Alerts you about critical and high priority items',
          trailing: Switch(
            value: prefs.notificationsEnabled,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updateNotificationsEnabled(val);
            },
          ),
        ),
        if (prefs.notificationsEnabled) ...[
          SettingsTile(
            title: 'Alert 1 Day Before Expiry',
            trailing: Switch(
              value: prefs.notifyDayBefore,
              activeTrackColor: AppColors.orange,
              onChanged: (val) {
                cubit.updatePreferences(prefs.copyWith(notifyDayBefore: val));
              },
            ),
          ),
          SettingsTile(
            title: 'Alert On Expiry Day',
            trailing: Switch(
              value: prefs.notifyOnExpiryDay,
              activeTrackColor: AppColors.orange,
              onChanged: (val) {
                cubit.updatePreferences(prefs.copyWith(notifyOnExpiryDay: val));
              },
            ),
          ),
          SettingsTile(
            title: 'Device Permissions',
            subtitle: 'If alerts fail to fire, check notification permission in settings.',
            trailing: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildEstimatesSection(BuildContext context, UserPreferences prefs) {
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();
    const currencies = ['₹', '\$', '€', '£', '¥', 'A\$', 'C\$'];

    return SettingsSection(
      title: 'Savings Estimates & Currency',
      children: [
        SettingsTile(
          icon: Icons.currency_exchange_rounded,
          title: 'Currency Symbol',
          subtitle: 'Used for illustrative estimated savings',
          bottomControl: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.xs,
            children: currencies.map((curr) {
              final isSelected = prefs.currencySymbol == curr;
              return ChoiceChip(
                label: Text(curr, style: const TextStyle(fontWeight: FontWeight.bold)),
                selected: isSelected,
                selectedColor: AppColors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : null,
                ),
                onSelected: (selected) {
                  if (selected) {
                    cubit.updatePreferences(prefs.copyWith(currencySymbol: curr));
                  }
                },
              );
            }).toList(),
          ),
        ),
        SettingsTile(
          icon: Icons.price_check_rounded,
          title: 'Average Value per Item',
          subtitle: 'Replaces item price table with a flat estimate (Optional)',
          bottomControl: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _customValueController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    prefixText: '${prefs.currencySymbol} ',
                    hintText: 'Default price table',
                    isDense: true,
                  ),
                  onChanged: (val) {
                    final parsed = double.tryParse(val.trim());
                    cubit.updatePreferences(prefs.copyWith(
                      customItemValue: () => parsed,
                    ));
                  },
                ),
              ),
              if (prefs.customItemValue != null) ...[
                const SizedBox(width: AppSpacing.sm),
                IconButton(
                  icon: const Icon(Icons.clear_rounded),
                  tooltip: 'Reset to default table',
                  onPressed: () {
                    _customValueController.clear();
                    cubit.updatePreferences(prefs.copyWith(
                      customItemValue: () => null,
                    ));
                  },
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAiDiagnosticsSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();
    final geminiDs = sl.isRegistered<GeminiRemoteDataSource>()
        ? sl<GeminiRemoteDataSource>()
        : null;
    final currentStatus = _testedAiStatus ?? geminiDs?.lastStatus ?? const AiStatus(
      state: AiConnectionState.untested,
      message: 'Checking AI status...',
    );

    final (statusColor, statusIcon, statusHeadline) = switch (currentStatus.state) {
      AiConnectionState.ok => (
          AppColors.low,
          Icons.check_circle_rounded,
          'Connected to Gemini (${currentStatus.activeModel ?? "flash"})',
        ),
      AiConnectionState.noKey => (
          AppColors.medium,
          Icons.key_off_rounded,
          'No API key set (Running in offline mode)',
        ),
      AiConnectionState.authError => (
          AppColors.critical,
          Icons.error_outline_rounded,
          'Invalid Gemini API key (401/403)',
        ),
      AiConnectionState.modelNotFound => (
          AppColors.medium,
          Icons.search_off_rounded,
          'Model 404 (Auto-fallback to gemini-flash-latest)',
        ),
      AiConnectionState.quotaExceeded => (
          AppColors.medium,
          Icons.timer_outlined,
          'Gemini rate limited (429 - waiting)',
        ),
      AiConnectionState.offline || AiConnectionState.timeout => (
          AppColors.medium,
          Icons.wifi_off_rounded,
          'Network timeout (Using offline fallback)',
        ),
      AiConnectionState.badResponse => (
          AppColors.critical,
          Icons.warning_amber_rounded,
          'Bad response from AI endpoint',
        ),
      _ => (
          AppColors.unknown,
          Icons.help_outline_rounded,
          'AI status untested',
        ),
    };

    return SettingsSection(
      title: 'AI Connection Diagnostics',
      children: [
        SettingsTile(
          icon: statusIcon,
          title: statusHeadline,
          subtitle: currentStatus.message ??
              (currentStatus.state == AiConnectionState.ok
                  ? 'Voice extraction and recipe inspiration are running at peak speed.'
                  : 'Curated offline recipes and local speech extraction remain fully active.'),
          bottomControl: Align(
            alignment: Alignment.centerLeft,
            child: AppButton(
              label: _isTestingAi ? 'Testing...' : 'Test AI Connection',
              variant: AppButtonVariant.outlined,
              icon: Icons.network_check_rounded,
              loading: _isTestingAi,
              onPressed: _testAiConnection,
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.image_outlined,
          title: 'Generate Dish Illustrations with AI',
          subtitle: 'Experimental Imagen illustration if real photo is not found',
          trailing: Switch(
            value: prefs.allowAiIllustration,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(allowAiIllustration: val));
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDataManagementSection(BuildContext context) {
    return SettingsSection(
      title: 'Data & Privacy',
      children: [
        SettingsTile(
          icon: Icons.storage_rounded,
          title: 'Data Backup & Controls',
          subtitle: 'Export data as JSON, load test inventory, or reset app',
          bottomControl: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Export Data (JSON)',
                variant: AppButtonVariant.outlined,
                icon: Icons.file_upload_outlined,
                onPressed: () => _exportKitchenData(context),
              ),
              AppButton(
                label: 'Load Demo Pantry',
                variant: AppButtonVariant.outlined,
                icon: Icons.download_rounded,
                onPressed: () async {
                  final items = DemoIngredients.load();
                  await context.read<InventoryCubit>().addMany(items);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded ${items.length} demo pantry items.')),
                    );
                  }
                },
              ),
              AppButton(
                label: 'Clear Insights',
                variant: AppButtonVariant.outlined,
                icon: Icons.bar_chart_rounded,
                onPressed: () async {
                  await context.read<InsightsCubit>().clearHistory();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Insights history cleared.')),
                    );
                  }
                },
              ),
              AppButton(
                label: 'Clear All My Data',
                variant: AppButtonVariant.outlined,
                icon: Icons.delete_forever_rounded,
                onPressed: () => _showClearConfirmation(context),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showClearConfirmation(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        title: const Text('Clear All Data?'),
        content: const Text(
          'This will permanently delete all your inventory items, saved recipes, and reset settings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogCtx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.critical,
            ),
            onPressed: () {
              Navigator.of(dialogCtx).pop();
              context.read<SettingsCubit>().clearAll();
              context.read<InventoryCubit>().loadIngredients();
            },
            child: const Text('Delete Everything'),
          ),
        ],
      ),
    );
  }

  Widget _buildAboutSection(BuildContext context) {
    return const SettingsSection(
      title: 'About & Credits',
      children: [
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'RescueRecipe v1.0.0',
          subtitle: 'Speak your ingredients, rescue your food, reduce food waste.\n\n'
              '• Photos provided by Pexels (licensed under Pexels License).\n'
              '• Recipe structure and techniques inspired by TheMealDB & Wikipedia.\n'
              '• AI suggestions are intended for inspiration only and do not guarantee food safety.\n'
              '• Savings amounts and streaks are illustrative estimates and game mechanics.',
        ),
      ],
    );
  }
}
