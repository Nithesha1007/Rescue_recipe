import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/domain/expiry_priority.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/cooking/domain/entities/usage_log_entry.dart';
import 'package:rescue_recipe/features/cooking/domain/repositories/usage_log_repository.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/repositories/ingredient_repository.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/clear_usage_history.dart';
import 'package:rescue_recipe/features/insights/domain/usecases/get_insights.dart';
import 'package:rescue_recipe/features/insights/presentation/cubit/insights_cubit.dart';
import 'package:rescue_recipe/features/insights/presentation/pages/insights_page.dart';
import 'package:rescue_recipe/features/settings/domain/entities/user_preferences.dart';
import 'package:rescue_recipe/features/settings/domain/repositories/settings_repository.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/clear_all_data.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/get_settings.dart';
import 'package:rescue_recipe/features/settings/domain/usecases/update_settings.dart';
import 'package:rescue_recipe/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:rescue_recipe/features/shell/presentation/cubit/navigation_cubit.dart';

class MockUsageLogRepository implements UsageLogRepository {
  List<UsageLogEntry> entries = [];

  @override
  FutureEither<void> logUsage(UsageLogEntry entry) async {
    entries.add(entry);
    return const Right(null);
  }

  @override
  FutureEither<List<UsageLogEntry>> getUsageLogs() async => Right(entries);

  @override
  FutureEither<int> getRescuedCount() async =>
      Right(entries.where((e) => e.wasRescued).length);

  @override
  FutureEither<void> clearHistory() async {
    entries.clear();
    return const Right(null);
  }
}

class MockSettingsRepository implements SettingsRepository {
  UserPreferences preferences = const UserPreferences();

  @override
  FutureEither<UserPreferences> getPreferences() async => Right(preferences);

  @override
  FutureEither<void> savePreferences(UserPreferences prefs) async {
    preferences = prefs;
    return const Right(null);
  }

  @override
  FutureEither<void> clearAllData() async {
    preferences = const UserPreferences();
    return const Right(null);
  }
}

class _DummyIngredientRepository implements IngredientRepository {
  @override
  Stream<List<Ingredient>> watchActiveIngredients() => Stream.value([]);
  @override
  FutureEither<List<Ingredient>> getActiveIngredients() async => const Right([]);
  @override
  FutureEither<Ingredient?> getIngredientById(String id) async => const Right(null);
  @override
  FutureEither<void> addIngredient(Ingredient ingredient) async => const Right(null);
  @override
  FutureEither<void> addIngredients(List<Ingredient> ingredients) async => const Right(null);
  @override
  FutureEither<void> updateIngredient(Ingredient ingredient) async => const Right(null);
  @override
  FutureEither<void> deleteIngredient(String id) async => const Right(null);
  @override
  FutureEither<void> markUsed(String id) async => const Right(null);
  @override
  FutureEither<void> markDiscarded(String id) async => const Right(null);
}

void main() {
  late MockUsageLogRepository repo;
  late MockSettingsRepository settingsRepo;

  setUp(() {
    repo = MockUsageLogRepository();
    settingsRepo = MockSettingsRepository();
  });

  Widget buildTestWidget() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<NavigationCubit>(
          create: (_) => NavigationCubit(),
        ),
        BlocProvider<SettingsCubit>(
          create: (_) => SettingsCubit(
            getSettings: GetSettings(settingsRepo),
            updateSettings: UpdateSettings(settingsRepo),
            clearAllData: ClearAllData(
              settingsRepository: settingsRepo,
              ingredientRepository: _DummyIngredientRepository(),
            ),
          ),
        ),
        BlocProvider<InsightsCubit>(
          create: (_) => InsightsCubit(
            getInsights: GetInsights(repo),
            clearUsageHistory: ClearUsageHistory(repo),
          )..loadInsights(),
        ),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const InsightsPage(),
      ),
    );
  }

  testWidgets('renders empty state when no history exists', (tester) async {
    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('No Activity Logged Yet'), findsOneWidget);
  });

  testWidgets('renders insights summary, charts, and badges when entries exist',
      (tester) async {
    repo.entries = [
      UsageLogEntry(
        id: '1',
        ingredientName: 'Milk',
        quantity: 1,
        unit: 'l',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.critical,
        timestamp: DateTime.now(),
      ),
      UsageLogEntry(
        id: '2',
        ingredientName: 'Tomato',
        quantity: 2,
        unit: 'piece',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.high,
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(find.text('Rescued'), findsWidgets);
    expect(find.text('Rescue Score'), findsOneWidget);
    expect(find.text('Illustrative Achievements'), findsOneWidget);

    // Verify Weekly Chart can toggle to Table View
    expect(find.text('Show as table'), findsOneWidget);
    await tester.tap(find.text('Show as table'));
    await tester.pumpAndSettle();

    expect(find.text('Show as chart'), findsOneWidget);
  });

  testWidgets('renders cleanly without overflow at 320dp width', (tester) async {
    tester.view.physicalSize = const Size(320 * 2, 640 * 2);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    repo.entries = [
      UsageLogEntry(
        id: '1',
        ingredientName: 'Milk',
        quantity: 1,
        unit: 'l',
        action: UsageAction.used,
        priorityAtUsage: ExpiryPriority.critical,
        timestamp: DateTime.now(),
      ),
    ];

    await tester.pumpWidget(buildTestWidget());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}
