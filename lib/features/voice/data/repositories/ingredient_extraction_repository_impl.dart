import 'package:fpdart/fpdart.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/error/failures.dart';
import '../../domain/entities/extracted_ingredient.dart';
import '../../domain/repositories/ingredient_extraction_repository.dart';
import '../datasources/connectivity_service.dart';
import '../datasources/gemini_remote_datasource.dart';
import '../datasources/offline_ingredient_parser.dart';

class IngredientExtractionRepositoryImpl
    implements IngredientExtractionRepository {
  IngredientExtractionRepositoryImpl({
    required this.remoteDataSource,
    required this.connectivityService,
    required this.config,
  });

  final GeminiRemoteDataSource remoteDataSource;
  final ConnectivityService connectivityService;
  final AppConfig config;

  @override
  FutureEither<ExtractionResult> extract(String transcript) async {
    final bool hasKey = config.hasGeminiKey;
    final bool isOnline = await connectivityService.isConnected;

    // If no key or offline, fall back directly to offline parser
    if (!hasKey || !isOnline) {
      final List<ExtractedIngredient> offlineParsed =
          OfflineIngredientParser.parse(transcript);
      return Right(ExtractionResult(
        items: offlineParsed,
        source: ExtractionSource.offline,
      ));
    }

    try {
      final List<ExtractedIngredient> remoteItems =
          await remoteDataSource.extractIngredients(transcript);
      return Right(ExtractionResult(
        items: remoteItems,
        source: ExtractionSource.gemini,
      ));
    } catch (_) {
      // Automatic fallback to offline parser on any remote error
      final List<ExtractedIngredient> fallbackItems =
          OfflineIngredientParser.parse(transcript);
      return Right(ExtractionResult(
        items: fallbackItems,
        source: ExtractionSource.offline,
      ));
    }
  }
}
