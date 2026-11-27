import 'package:flutter_test/flutter_test.dart';
import 'package:rescue_recipe/core/models/ai_status.dart';

void main() {
  group('AiStatus Model Tests', () {
    test('default status is untested', () {
      const status = AiStatus();
      expect(status.state, AiConnectionState.untested);
      expect(status.isOperational, isFalse);
      expect(status.displayLabel, 'Not tested yet');
    });

    test('ok status returns operational and connected label', () {
      final status = AiStatus(
        state: AiConnectionState.ok,
        lastStatusCode: 200,
        activeModel: 'gemini-1.5-flash',
        lastChecked: DateTime.now(),
      );
      expect(status.isOperational, isTrue);
      expect(status.displayLabel, 'Connected (gemini-1.5-flash)');
    });

    test('error statuses return human-readable diagnostic labels', () {
      expect(
        const AiStatus(state: AiConnectionState.noKey).displayLabel,
        'No API key in build',
      );
      expect(
        const AiStatus(state: AiConnectionState.offline).displayLabel,
        'Offline / No internet',
      );
      expect(
        const AiStatus(state: AiConnectionState.timeout).displayLabel,
        'Connection timed out',
      );
      expect(
        const AiStatus(state: AiConnectionState.authError).displayLabel,
        'Invalid API key (401/403)',
      );
      expect(
        const AiStatus(state: AiConnectionState.quotaExceeded).displayLabel,
        'Rate limit exceeded (429)',
      );
      expect(
        const AiStatus(state: AiConnectionState.modelNotFound).displayLabel,
        'Model not found (404)',
      );
      expect(
        const AiStatus(state: AiConnectionState.badResponse).displayLabel,
        'Invalid response format',
      );
    });
  });
}
