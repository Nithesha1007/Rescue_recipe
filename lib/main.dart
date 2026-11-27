import 'dart:ui';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';
import 'core/di/injection.dart';
import 'core/theme/app_theme.dart';
import 'core/utils/app_logger.dart';
import 'features/cooking/data/models/usage_log_model.dart';
import 'features/ingredients/data/models/ingredient_model.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Edge-to-edge transparent system navigation and status bar
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  // Global uncaught Flutter framework error handler
  FlutterError.onError = (FlutterErrorDetails details) {
    AppLogger.error(
      'Uncaught Flutter framework error: ${details.exceptionAsString()}',
      details.exception,
      details.stack,
    );
  };

  // Global uncaught platform / async dispatcher error handler
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    AppLogger.error(
      'Uncaught asynchronous error: $error',
      error,
      stack,
    );
    return true;
  };

  // Release-safe widget build error fallback
  if (kReleaseMode) {
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return const Material(
        color: AppColors.cream,
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  color: AppColors.orange,
                  size: AppSizes.iconLg,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.ink,
                  ),
                ),
                SizedBox(height: AppSpacing.xs),
                Text(
                  'The screen encountered an unexpected error. Please restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    };
  }

  await Hive.initFlutter();
  Hive.registerAdapter(IngredientModelAdapter());
  Hive.registerAdapter(UsageLogModelAdapter());
  await Hive.openBox<IngredientModel>('ingredients');
  await Hive.openBox<String>('preferences');
  await Hive.openBox<UsageLogModel>('usage_log');
  await configureDependencies();
  runApp(const RescueRecipeApp());
}
