import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

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
import '../../../insights/presentation/cubit/insights_cubit.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import '../../../voice/data/datasources/gemini_remote_datasource.dart';
import '../../domain/entities/cuisine_tag.dart';
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

  @override
  Widget build(BuildContext context) {
    return AppPageScaffold(
      title: 'Profile & Settings',
      subtitle: 'Customize your food rescue experience',
      scrollable: true,
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          final prefs = state.preferences;

          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildHeader(context),
              const SizedBox(height: AppSpacing.lg),
              _buildAiDiagnosticsSection(context),
              const SizedBox(height: AppSpacing.lg),
              _buildDietAndCuisineSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildSpeechSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildAppearanceSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildNotificationsSection(context, prefs),
              const SizedBox(height: AppSpacing.lg),
              _buildEstimatesSection(context, prefs),
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

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);

    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: theme.colorScheme.primaryContainer,
            child: const Icon(
              Icons.eco_rounded,
              color: AppColors.orange,
              size: 32,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Food Rescuer',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Voice-first AI kitchen assistant',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAiDiagnosticsSection(BuildContext context) {
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
      ],
    );
  }

  Widget _buildDietAndCuisineSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return SettingsSection(
      title: 'Diet & Cuisine Preferences',
      children: [
        SettingsTile(
          icon: Icons.restaurant_menu_rounded,
          title: 'Dietary Restrictions',
          subtitle: 'Filters out unmatching recipes',
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
          icon: Icons.ramen_dining_rounded,
          title: 'Cuisine Style',
          subtitle: 'Boosts rankings for your favored regional recipes',
          bottomControl: Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: CuisineTag.values.map((cuisine) {
              final isSelected = prefs.cuisine == cuisine;
              return ChoiceChip(
                label: Text(cuisine.displayName),
                selected: isSelected,
                selectedColor: AppColors.orange,
                labelStyle: TextStyle(
                  color: isSelected ? theme.colorScheme.onPrimary : null,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    cubit.updatePreferences(prefs.copyWith(cuisine: cuisine));
                  }
                },
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildSpeechSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();
    final theme = Theme.of(context);

    return SettingsSection(
      title: 'Speech & Voice Assistant',
      children: [
        SettingsTile(
          icon: Icons.language_rounded,
          title: 'Voice Recognition Language',
          subtitle: 'Accent and dialect for continuous voice input',
          bottomControl: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              isDense: true,
              value: prefs.speechLocale,
              items: const [
                DropdownMenuItem(value: 'en_IN', child: Text('English (India)')),
                DropdownMenuItem(value: 'en_US', child: Text('English (US)')),
                DropdownMenuItem(value: 'en_GB', child: Text('English (UK)')),
              ],
              onChanged: (val) {
                if (val != null) {
                  cubit.updatePreferences(prefs.copyWith(speechLocale: val));
                }
              },
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.speed_rounded,
          title: 'Read Aloud Speed',
          subtitle: 'Pace used when reciting cooking steps',
          bottomControl: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Text('Slow', style: theme.textTheme.labelSmall),
                  Expanded(
                    child: Slider(
                      value: prefs.speechRate,
                      min: 0.3,
                      max: 0.8,
                      divisions: 5,
                      label: '${(prefs.speechRate * 2).toStringAsFixed(1)}x',
                      activeColor: AppColors.orange,
                      onChanged: (val) {
                        cubit.updatePreferences(prefs.copyWith(speechRate: val));
                      },
                    ),
                  ),
                  Text('Fast', style: theme.textTheme.labelSmall),
                ],
              ),
              const SizedBox(height: AppSpacing.xs),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  AppButton(
                    label: _isTestingSpeech ? 'Speaking...' : 'Test Voice',
                    variant: AppButtonVariant.outlined,
                    icon: Icons.volume_up_rounded,
                    loading: _isTestingSpeech,
                    onPressed: () => _testSpeech(prefs.speechRate),
                  ),
                  TextButton.icon(
                    icon: const Icon(Icons.settings_voice_rounded, size: AppSizes.iconSm),
                    label: const Text('Voice Settings'),
                    onPressed: () => sl<TtsService>().openVoiceSettings(),
                  ),
                ],
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
      title: 'Appearance',
      children: [
        SettingsTile(
          icon: Icons.palette_rounded,
          title: 'Theme Mode',
          subtitle: 'Choose between system, light, or dark themes',
          bottomControl: LayoutBuilder(
            builder: (context, constraints) {
              return SizedBox(
                width: double.infinity,
                child: SegmentedButton<ThemeMode>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    padding: WidgetStatePropertyAll(
                      EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.system,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('System', maxLines: 1),
                      ),
                      icon: Icon(Icons.brightness_auto_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.light,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Light', maxLines: 1),
                      ),
                      icon: Icon(Icons.light_mode_rounded, size: 18),
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      label: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text('Dark', maxLines: 1),
                      ),
                      icon: Icon(Icons.dark_mode_rounded, size: 18),
                    ),
                  ],
                  selected: {prefs.themeMode},
                  onSelectionChanged: (selected) {
                    cubit.updatePreferences(prefs.copyWith(themeMode: selected.first));
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNotificationsSection(BuildContext context, UserPreferences prefs) {
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: 'Notifications',
      children: [
        SettingsTile(
          icon: Icons.notifications_active_rounded,
          title: 'Daily Expiry Alerts',
          subtitle: 'Receive reminders before ingredients expire',
          trailing: Switch(
            value: prefs.notificationsEnabled,
            activeTrackColor: AppColors.orange,
            onChanged: (val) {
              cubit.updatePreferences(prefs.copyWith(notificationsEnabled: val));
            },
          ),
        ),
        if (prefs.notificationsEnabled) ...[
          SettingsTile(
            icon: Icons.access_time_rounded,
            title: 'Alert Time',
            subtitle: '${prefs.notifyHour.toString().padLeft(2, '0')}:${prefs.notifyMinute.toString().padLeft(2, '0')}',
            trailing: const Icon(Icons.chevron_right_rounded),
            onTap: () async {
              final picked = await showTimePicker(
                context: context,
                initialTime: TimeOfDay(
                  hour: prefs.notifyHour,
                  minute: prefs.notifyMinute,
                ),
              );
              if (picked != null) {
                cubit.updatePreferences(prefs.copyWith(
                  notifyHour: picked.hour,
                  notifyMinute: picked.minute,
                ));
              }
            },
          ),
          SettingsTile(
            title: 'Alert Day Before Expiry',
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
    const currencies = ['₹', '\$', '€', '£'];

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

  Widget _buildDataManagementSection(BuildContext context) {
    return SettingsSection(
      title: 'Data & Storage',
      children: [
        SettingsTile(
          icon: Icons.storage_rounded,
          title: 'Local Data Controls',
          subtitle: 'Manage local Hive database and test data',
          bottomControl: Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              AppButton(
                label: 'Load Demo Data',
                variant: AppButtonVariant.outlined,
                icon: Icons.download_rounded,
                onPressed: () async {
                  final items = DemoIngredients.load();
                  await context.read<InventoryCubit>().addMany(items);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Loaded ${items.length} demo ingredients.')),
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
          'This will permanently delete all your inventory items and reset settings. This action cannot be undone.',
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
      title: 'About RescueRecipe',
      children: [
        SettingsTile(
          icon: Icons.info_outline_rounded,
          title: 'RescueRecipe v1.0.0',
          subtitle: 'Speak your ingredients, rescue your food, reduce food waste.\n\n'
              '• AI suggestions are intended for inspiration only and do not constitute food safety advice.\n'
              '• Savings amounts and streaks are illustrative estimates and game mechanics.\n'
              '• Recipe photos sourced from Wikipedia under Creative Commons.',
        ),
      ],
    );
  }
}
