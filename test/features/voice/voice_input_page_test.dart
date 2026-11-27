import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/theme/app_theme.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/delete_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/get_active_ingredients.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_discarded.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/mark_ingredient_used.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/update_ingredient.dart';
import 'package:rescue_recipe/features/ingredients/presentation/cubit/inventory_cubit.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/ingredient_extraction_repository.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/apply_voice_correction.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/confirm_ingredients.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/extract_ingredients_from_transcript.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_bloc.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_state.dart';
import 'package:rescue_recipe/features/voice/presentation/pages/voice_input_page.dart';

import '../ingredients/inventory_cubit_test.dart';
import 'voice_input_bloc_test.dart';

class _TestVoiceInputBloc extends VoiceInputBloc {
  _TestVoiceInputBloc({
    required super.speechRepository,
    required super.extractIngredients,
    required super.applyVoiceCorrection,
    required super.confirmIngredients,
    required VoiceInputState initialState,
  }) : _state = initialState,
       super();

  final VoiceInputState _state;

  @override
  VoiceInputState get state => _state;
}

void main() {
  late FakeSpeechRepository fakeSpeech;
  late FakeExtractionRepo fakeExtraction;
  late FakeIngredientRepository fakeIngredientRepo;
  late InventoryCubit inventoryCubit;

  setUp(() {
    fakeSpeech = FakeSpeechRepository();
    fakeExtraction = FakeExtractionRepo();
    fakeIngredientRepo = FakeIngredientRepository();

    inventoryCubit = InventoryCubit(
      getActiveIngredients: GetActiveIngredients(fakeIngredientRepo),
      addIngredient: AddIngredient(fakeIngredientRepo),
      addIngredients: AddIngredients(fakeIngredientRepo),
      updateIngredient: UpdateIngredient(fakeIngredientRepo),
      deleteIngredient: DeleteIngredient(fakeIngredientRepo),
      markIngredientUsed: MarkIngredientUsed(fakeIngredientRepo),
      markIngredientDiscarded: MarkIngredientDiscarded(fakeIngredientRepo),
    );
  });

  tearDown(() {
    inventoryCubit.close();
  });

  Widget buildVoiceApp(VoiceInputBloc bloc) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<VoiceInputBloc>.value(value: bloc),
        BlocProvider<InventoryCubit>.value(value: inventoryCubit),
      ],
      child: MaterialApp(
        theme: AppTheme.light(),
        home: const VoiceInputPage(),
      ),
    );
  }

  testWidgets(
      'VoiceInputPage does not overflow in editing state at 320dp width with text scale 1.5',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final bloc = _TestVoiceInputBloc(
      speechRepository: fakeSpeech,
      extractIngredients: ExtractIngredientsFromTranscript(fakeExtraction),
      applyVoiceCorrection: const ApplyVoiceCorrection(),
      confirmIngredients:
          ConfirmIngredients(AddIngredients(fakeIngredientRepo)),
      initialState: const VoiceInputEditing(
        transcript: 'three tomatoes, two onions, and spinach expiring tomorrow',
      ),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(buildVoiceApp(bloc));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Voice Rescue'), findsOneWidget);
    expect(find.text('Transcript (editable)'), findsOneWidget);
    expect(find.text('Find ingredients'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'VoiceInputPage does not overflow in confirmation state at 320dp width with text scale 1.5',
      (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    tester.platformDispatcher.textScaleFactorTestValue = 1.5;
    addTearDown(tester.view.reset);
    addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

    final now = DateTime.now();
    final bloc = _TestVoiceInputBloc(
      speechRepository: fakeSpeech,
      extractIngredients: ExtractIngredientsFromTranscript(fakeExtraction),
      applyVoiceCorrection: const ApplyVoiceCorrection(),
      confirmIngredients:
          ConfirmIngredients(AddIngredients(fakeIngredientRepo)),
      initialState: VoiceInputConfirming(
        items: [
          ExtractedIngredient(
            name: 'tomato',
            quantity: 3,
            unit: 'pieces',
            resolvedExpiry: now.add(const Duration(days: 2)),
          ),
          ExtractedIngredient(
            name: 'spinach',
            quantity: 200,
            unit: 'g',
            resolvedExpiry: now,
          ),
        ],
        source: ExtractionSource.gemini,
        originalTranscript: 'three tomatoes and spinach',
      ),
    );
    addTearDown(bloc.close);

    await tester.pumpWidget(buildVoiceApp(bloc));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Review ingredients'), findsOneWidget);
    expect(find.text('Add all to My Kitchen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
