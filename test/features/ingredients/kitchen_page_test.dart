import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/constants/app_strings.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/ingredients/domain/entities/ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/delete_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/get_active_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_used.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/update_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'package:rescue_recipe/features/ingredients/presentation/pages/kitchen_page.dart';

import 'inventory_cubit_test.dart';

void main() {
  late FakeIngredientRepository fakeRepo;
  late InventoryCubit inventoryCubit;

  setUp(() {
    fakeRepo = FakeIngredientRepository();
    inventoryCubit = InventoryCubit(
      getActiveIngredients: GetActiveIngredients(fakeRepo),
      addIngredient: AddIngredient(fakeRepo),
      addIngredients: AddIngredients(fakeRepo),
      updateIngredient: UpdateIngredient(fakeRepo),
      deleteIngredient: DeleteIngredient(fakeRepo),
      markIngredientUsed: MarkIngredientUsed(fakeRepo),
      markIngredientDiscarded: MarkIngredientDiscarded(fakeRepo),
    );
  });

  tearDown(() {
    inventoryCubit.close();
  });

  Widget buildKitchenApp() {
    return BlocProvider<InventoryCubit>.value(
      value: inventoryCubit,
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const KitchenPage(),
      ),
    );
  }

  testWidgets('KitchenPage displays empty state when no ingredients',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    await tester.pumpWidget(buildKitchenApp());
    await tester.pumpAndSettle();

    expect(find.text('Your kitchen is empty'), findsOneWidget);
    expect(find.text('Add first ingredient'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'KitchenPage does not overflow at 320dp width with text scale 1.5 in loaded state',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final now = DateTime.now();
    await fakeRepo.addIngredient(
      Ingredient(
        id: '1',
        name: 'tomato',
        quantity: 3,
        unit: 'pieces',
        expiryDate: now.add(const Duration(days: 1)),
        addedAt: now,
      ),
    );
    await fakeRepo.addIngredient(
      Ingredient(
        id: '2',
        name: 'spinach leaves from the garden',
        quantity: 200,
        unit: 'grams',
        expiryDate: now,
        addedAt: now,
      ),
    );

    await tester.pumpWidget(buildKitchenApp());
    await tester.pumpAndSettle();

    expect(find.text('Tomato'), findsOneWidget);
    expect(find.text('3 pieces'), findsOneWidget);
    expect(find.text('Spinach leaves from the garden'), findsOneWidget);
    expect(find.text(AppStrings.expiryDisclaimer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
