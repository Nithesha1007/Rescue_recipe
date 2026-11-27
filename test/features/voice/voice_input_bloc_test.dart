import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fpdart/fpdart.dart';
import 'package:rescue_recipe/core/error/failures.dart';
import 'package:rescue_recipe/features/ingredients/domain/usecases/add_ingredients.dart';
import 'package:rescue_recipe/features/voice/domain/entities/extracted_ingredient.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/ingredient_extraction_repository.dart';
import 'package:rescue_recipe/features/voice/domain/repositories/speech_repository.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/apply_voice_correction.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/confirm_ingredients.dart';
import 'package:rescue_recipe/features/voice/domain/usecases/extract_ingredients_from_transcript.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_bloc.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_event.dart';
import 'package:rescue_recipe/features/voice/presentation/bloc/voice_input_state.dart';

import '../ingredients/inventory_cubit_test.dart';

class FakeSpeechRepository implements SpeechRepository {
  SpeechPermissionStatus permissionStatus = SpeechPermissionStatus.granted;
  bool isInitialized = true;
  bool listening = false;
  final StreamController<SpeechRecognitionUpdate> controller =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  @override
  bool get isListening => listening;

  @override
  Future<bool> initialize() async => isInitialized;

  @override
  Future<SpeechPermissionStatus> checkPermission() async => permissionStatus;

  @override
  Future<SpeechPermissionStatus> requestPermission() async => permissionStatus;

  @override
  Stream<SpeechRecognitionUpdate> startListening({String? localeId}) {
    listening = true;
    return controller.stream;
  }

  @override
  Future<List<String>> getAvailableLocales() async => ['en_IN', 'en_US'];

  @override
  Future<void> stop() async {
    listening = false;
  }

  @override
  Future<void> cancel() async {
    listening = false;
  }
}

class FakeExtractionRepo implements IngredientExtractionRepository {
  @override
  FutureEither<ExtractionResult> extract(String transcript) async {
    return const Right(ExtractionResult(
      items: [
        ExtractedIngredient(name: 'tomato', quantity: 3),
        ExtractedIngredient(name: 'onion', quantity: 2),
      ],
      source: ExtractionSource.gemini,
    ));
  }
}

void main() {
  group('VoiceInputBloc', () {
    late FakeSpeechRepository speechRepo;
    late FakeExtractionRepo extractionRepo;
    late FakeIngredientRepository ingredientRepo;
    late VoiceInputBloc bloc;

    setUp(() {
      speechRepo = FakeSpeechRepository();
      extractionRepo = FakeExtractionRepo();
      ingredientRepo = FakeIngredientRepository();

      bloc = VoiceInputBloc(
        speechRepository: speechRepo,
        extractIngredients: ExtractIngredientsFromTranscript(extractionRepo),
        applyVoiceCorrection: const ApplyVoiceCorrection(),
        confirmIngredients: ConfirmIngredients(AddIngredients(ingredientRepo)),
      );
    });

    tearDown(() {
      bloc.close();
    });

    test('initial state is VoiceInputIdle', () {
      expect(bloc.state, const VoiceInputIdle());
    });

    test('emits PermissionDenied when microphone access is denied', () async {
      speechRepo.permissionStatus = SpeechPermissionStatus.denied;

      bloc.add(const StartListening());
      await pumpEventQueue();

      expect(
        bloc.state,
        const VoiceInputPermissionDenied(isPermanent: false),
      );
    });

    test('emits PermissionDenied permanent when permanently denied', () async {
      speechRepo.permissionStatus = SpeechPermissionStatus.permanentlyDenied;

      bloc.add(const StartListening());
      await pumpEventQueue();

      expect(
        bloc.state,
        const VoiceInputPermissionDenied(isPermanent: true),
      );
    });

    test('listening -> updates -> stop transitions to VoiceInputEditing',
        () async {
      bloc.add(const StartListening());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceInputListening>());

      speechRepo.controller.add(const SpeechRecognitionUpdate(
        transcript: 'three tomatoes',
        soundLevel: 0.6,
        isFinal: false,
      ));
      await pumpEventQueue();

      final listeningState = bloc.state as VoiceInputListening;
      expect(listeningState.transcript, 'three tomatoes');
      expect(listeningState.soundLevel, 0.6);

      bloc.add(const StopListening());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceInputEditing>());
      final editingState = bloc.state as VoiceInputEditing;
      expect(editingState.transcript, 'three tomatoes');
    });

    test('submit transcript extracts ingredients and confirms', () async {
      bloc.add(const TranscriptChanged('three tomatoes and two onions'));
      await pumpEventQueue();

      bloc.add(const SubmitTranscript());
      await pumpEventQueue();

      expect(bloc.state, isA<VoiceInputConfirming>());
      final confirming = bloc.state as VoiceInputConfirming;
      expect(confirming.items.length, 2);
      expect(confirming.source, ExtractionSource.gemini);
    });

    test('apply voice correction modifies confirming items', () async {
      bloc.add(const TranscriptChanged('three tomatoes and two onions'));
      await pumpEventQueue();
      bloc.add(const SubmitTranscript());
      await pumpEventQueue();

      bloc.add(const ApplyCorrectionText("actually I don't have onions"));
      await pumpEventQueue();

      final confirming = bloc.state as VoiceInputConfirming;
      expect(confirming.items.length, 1);
      expect(confirming.items[0].name, 'tomato');
    });

    test('cancel releases microphone and returns to idle', () async {
      bloc.add(const StartListening());
      await pumpEventQueue();
      expect(speechRepo.isListening, isTrue);

      bloc.add(const CancelVoiceInput());
      await pumpEventQueue();

      expect(speechRepo.isListening, isFalse);
      expect(bloc.state, const VoiceInputIdle());
    });
  });
}
