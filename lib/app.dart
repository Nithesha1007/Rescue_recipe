import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/constants/app_strings.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'features/insights/presentation/cubit/insights_cubit.dart';
import 'features/notifications/domain/services/notification_scheduler.dart';
import 'features/recipes/presentation/bloc/recipes_bloc.dart';
import 'features/recipes/presentation/bloc/recipes_event.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';
import 'features/shell/presentation/cubit/navigation_cubit.dart';
import 'features/shell/presentation/pages/app_shell.dart';



import 'features/voice/presentation/bloc/voice_input_bloc.dart';

class RescueRecipeApp extends StatefulWidget {
  const RescueRecipeApp({super.key});

  @override
  State<RescueRecipeApp> createState() => _RescueRecipeAppState();
}

class _RescueRecipeAppState extends State<RescueRecipeApp> {
  @override
  void initState() {
    super.initState();
    _initNotifications();
  }

  Future<void> _initNotifications() async {
    if (sl.isRegistered<NotificationScheduler>()) {
      await sl<NotificationScheduler>().init(
        onSelectNotification: (payload) {
          if (sl.isRegistered<NavigationCubit>()) {
            sl<NavigationCubit>().select(NavTab.kitchen);
          }
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(
          create: (_) => sl<NavigationCubit>(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => sl<SettingsCubit>()..loadSettings(),
        ),
        BlocProvider<InventoryCubit>(
          create: (_) => sl<InventoryCubit>()..loadIngredients(),
        ),
        BlocProvider<VoiceInputBloc>(
          create: (_) => sl<VoiceInputBloc>(),
        ),
        BlocProvider<RecipesBloc>(
          create: (_) => sl<RecipesBloc>()..add(const LoadRecipes()),
        ),
        BlocProvider<InsightsCubit>(
          create: (_) => sl<InsightsCubit>()..loadInsights(),
        ),
      ],
      child: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, settingsState) {
          final themeMode = settingsState.status == SettingsStatus.loaded
              ? settingsState.preferences.themeMode
              : ThemeMode.system;

          return MaterialApp(
            title: AppStrings.appName,
            debugShowCheckedModeBanner: false,
            theme: AppTheme.light(),
            darkTheme: AppTheme.dark(),
            themeMode: themeMode,
            home: const AppShell(),
          );
        },
      ),
    );
  }
}
