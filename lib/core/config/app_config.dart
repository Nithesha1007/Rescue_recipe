/// Build-time configuration. The API key is never hardcoded.
///
/// Run with:
///   flutter run --dart-define-from-file=env.json
/// or:
///   flutter run --dart-define=GEMINI_API_KEY=your_key
class AppConfig {
  const AppConfig({
    required this.geminiApiKey,
    required this.geminiModel,
    this.fallbackModel = 'gemini-flash-latest',
  });

  factory AppConfig.fromEnvironment() => const AppConfig(
        geminiApiKey: String.fromEnvironment('GEMINI_API_KEY'),
        geminiModel: String.fromEnvironment(
          'GEMINI_MODEL',
          defaultValue: 'gemini-1.5-flash',
        ),
        fallbackModel: String.fromEnvironment(
          'GEMINI_FALLBACK_MODEL',
          defaultValue: 'gemini-flash-latest',
        ),
      );

  final String geminiApiKey;
  final String geminiModel;
  final String fallbackModel;

  bool get hasGeminiKey => geminiApiKey.isNotEmpty;
}
