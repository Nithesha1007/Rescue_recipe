import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_strings.dart';
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
              const SizedBox(height: AppSpacing.md),
              _buildAiDiagnosticsSection(context),
              const SizedBox(height: AppSpacing.md),
              _buildDietAndCuisineSection(context, prefs),
              const SizedBox(height: AppSpacing.md),
              _buildSpeechSection(context, prefs),
              const SizedBox(height: AppSpacing.md),
              _buildAppearanceSection(context, prefs),
              const SizedBox(height: AppSpacing.md),
              _buildCurrencySection(context, prefs),
              const SizedBox(height: AppSpacing.md),
              _buildNotificationsSection(context, prefs),
              const SizedBox(height: AppSpacing.md),
              _buildDataManagementSection(context),
              const SizedBox(height: AppSpacing.md),
              _buildAboutSection(context),
              const SizedBox(height: AppSpacing.md),
              const ExpiryDisclaimer(),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.orange.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.restaurant_menu_rounded,
              color: AppColors.orange,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  AppStrings.appName,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Voice-first AI food rescue',
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
    final theme = Theme.of(context);
    AiStatus status = _testedAiStatus ?? sl<GeminiRemoteDataSource>().lastStatus;

    Color badgeColor;
    switch (status.state) {
      case AiConnectionState.ok:
        badgeColor = AppColors.low;
        break;
      case AiConnectionState.noKey:
      case AiConnectionState.untested:
        badgeColor = theme.colorScheme.onSurfaceVariant;
        break;
      default:
        badgeColor = AppColors.critical;
    }

    return SettingsSection(
      title: 'AI Connection Diagnostics',
      children: [
        SettingsTile(
          icon: Icons.hub_rounded,
          title: 'Gemini Cloud Connection',
          subtitle: status.displayLabel,
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: badgeColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
            child: Text(
              status.state == AiConnectionState.ok ? 'Online' : 'Diagnose',
              style: theme.textTheme.labelSmall?.copyWith(
                color: badgeColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          bottomControl: Row(
            children: [
              AppButton(
                label: _isTestingAi ? 'Testing...' : 'Test AI Connection',
                variant: AppButtonVariant.outlined,
                icon: Icons.network_check_rounded,
                loading: _isTestingAi,
                onPressed: _testAiConnection,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDietAndCuisineSection(BuildContext context, UserPreferences prefs) {
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();

    return SettingsSection(
      title: 'Diet & Cuisine Preferences',
      children: [
        SettingsTile(
          icon: Icons.eco_rounded,
          title: 'Dietary Preference',
          subtitle: 'Filters recipes to match your dietary requirements',
          bottomControl: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: DietTag.values.map((tag) {
                final isSelected = prefs.diet == tag;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
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
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        SettingsTile(
          icon: Icons.ramen_dining_rounded,
          title: 'Cuisine Style',
          subtitle: 'Boosts rankings for your favored regional recipes',
          bottomControl: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: CuisineTag.values.map((cuisine) {
                final isSelected = prefs.cuisine == cuisine;
                return Padding(
                  padding: const EdgeInsets.only(right: AppSpacing.xs),
                  child: ChoiceChip(
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
                  ),
                );
              }).toList(),
            ),
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
          trailing: DropdownButton<String>(
            value: prefs.speechLocale,
            underline: const SizedBox.shrink(),
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
        SettingsTile(
          icon: Icons.speed_rounded,
          title: 'Read Aloud Speed',
          subtitle: 'Pace used when reciting cooking steps',
          bottomControl: Column(
            children: [
              Row(
                children: [
                  Text('Slow', style: theme.textTheme.bodySmall),
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
                  Text('Fast', style: theme.textTheme.bodySmall),
                ],
              ),
              Row(
                children: [
                  AppButton(
                    label: _isTestingSpeech ? 'Speaking...' : 'Test Voice',
                    variant: AppButtonVariant.outlined,
                    icon: Icons.volume_up_rounded,
                    loading: _isTestingSpeech,
                    onPressed: () => _testSpeech(prefs.speechRate),
                  ),
                  const SizedBox(width: AppSpacing.sm),
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
          bottomControl: SizedBox(
            width: double.infinity,
            child: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(
                  value: ThemeMode.system,
                  label: Text('System'),
                  icon: Icon(Icons.brightness_auto_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.light,
                  label: Text('Light'),
                  icon: Icon(Icons.light_mode_rounded),
                ),
                ButtonSegment(
                  value: ThemeMode.dark,
                  label: Text('Dark'),
                  icon: Icon(Icons.dark_mode_rounded),
                ),
              ],
              selected: {prefs.themeMode},
              onSelectionChanged: (selected) {
                cubit.updatePreferences(prefs.copyWith(themeMode: selected.first));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrencySection(BuildContext context, UserPreferences prefs) {
    final theme = Theme.of(context);
    final cubit = context.read<SettingsCubit>();
    const currencies = ['₹', '\$', '€', '£'];

    return SettingsSection(
      title: 'Regional Display',
      children: [
        SettingsTile(
          icon: Icons.currency_exchange_rounded,
          title: 'Currency Symbol',
          subtitle: 'Used for estimated illustrative savings',
          trailing: Wrap(
            spacing: 4,
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
          subtitle: 'Receive notifications before ingredients expire',
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
            subtitle: 'If alerts fail to fire, verify notification permissions.',
            trailing: TextButton(
              onPressed: () => openAppSettings(),
              child: const Text('Open Settings'),
            ),
          ),
        ],
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
          subtitle: 'Load sample ingredients or clear offline database',
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
              '• Savings amounts and streaks are illustrative estimates and game mechanics.',
        ),
      ],
    );
  }
}
