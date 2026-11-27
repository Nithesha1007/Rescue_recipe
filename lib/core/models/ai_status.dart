import 'package:equatable/equatable.dart';

enum AiConnectionState {
  untested,
  ok,
  noKey,
  offline,
  timeout,
  authError,
  quotaExceeded,
  modelNotFound,
  badResponse,
}

class AiStatus extends Equatable {
  final AiConnectionState state;
  final int? lastStatusCode;
  final String? activeModel;
  final DateTime? lastChecked;
  final String? message;

  const AiStatus({
    this.state = AiConnectionState.untested,
    this.lastStatusCode,
    this.activeModel,
    this.lastChecked,
    this.message,
  });

  String get displayLabel {
    switch (state) {
      case AiConnectionState.untested:
        return 'Not tested yet';
      case AiConnectionState.ok:
        return 'Connected (${activeModel ?? "Gemini"})';
      case AiConnectionState.noKey:
        return 'No API key in build';
      case AiConnectionState.offline:
        return 'Offline / No internet';
      case AiConnectionState.timeout:
        return 'Connection timed out';
      case AiConnectionState.authError:
        return 'Invalid API key (401/403)';
      case AiConnectionState.quotaExceeded:
        return 'Rate limit exceeded (429)';
      case AiConnectionState.modelNotFound:
        return 'Model not found (404)';
      case AiConnectionState.badResponse:
        return 'Invalid response format';
    }
  }

  bool get isOperational => state == AiConnectionState.ok;

  @override
  List<Object?> get props => [state, lastStatusCode, activeModel, lastChecked, message];
}
