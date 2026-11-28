import 'dart:io';
import 'package:fpdart/fpdart.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../ingredients/domain/utils/expiry_date_resolver.dart';
import '../entities/audio_extraction_result.dart';
import '../../data/datasources/gemini_remote_datasource.dart';

class AudioExtractParams {
  const AudioExtractParams({
    required this.audioFilePath,
    this.mimeType = 'audio/wav',
    this.today,
  });

  final String audioFilePath;
  final String mimeType;
  final DateTime? today;
}

class ExtractIngredientsFromAudio
    implements UseCase<AudioExtractionResult, AudioExtractParams> {
  const ExtractIngredientsFromAudio({
    required this.remoteDataSource,
    required this.config,
  });

  final GeminiRemoteDataSource remoteDataSource;
  final AppConfig config;

  @override
  FutureEither<AudioExtractionResult> call(AudioExtractParams params) async {
    final file = File(params.audioFilePath);
    if (!await file.exists()) {
      return const Left(UnexpectedFailure('Recorded audio file not found.'));
    }

    List<int> bytes;
    try {
      bytes = await file.readAsBytes();
    } catch (e) {
      return Left(UnexpectedFailure('Failed to read audio file: $e'));
    } finally {
      // Safe file cleanup immediately after reading
      try {
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }

    if (!config.hasGeminiKey) {
      return const Left(UnexpectedFailure(
        'Gemini API key is required for Auto (AI) voice transcription.',
      ));
    }

    try {
      final rawResult = await remoteDataSource.extractFromAudio(
        audioBytes: bytes,
        mimeType: params.mimeType,
      );

      // Resolve expiry dates using multi-lingual ExpiryDateResolver
      final resolvedItems = rawResult.ingredients.map((item) {
        if (item.expiryPhrase == null || item.expiryPhrase!.trim().isEmpty) {
          return item.copyWith(
            resolvedExpiry: () => null,
            expiryUnderstood: true,
          );
        }

        final date = ExpiryDateResolver.resolve(
          item.expiryPhrase,
          today: params.today,
        );

        if (date != null) {
          return item.copyWith(
            resolvedExpiry: () => date,
            expiryUnderstood: true,
          );
        } else {
          return item.copyWith(
            resolvedExpiry: () => null,
            expiryUnderstood: false,
          );
        }
      }).toList();

      return Right(AudioExtractionResult(
        transcript: rawResult.transcript,
        detectedLanguage: rawResult.detectedLanguage,
        ingredients: resolvedItems,
      ));
    } catch (e) {
      return Left(UnexpectedFailure('Audio extraction failed: $e'));
    }
  }
}
