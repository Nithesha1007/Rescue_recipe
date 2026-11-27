import 'package:equatable/equatable.dart';

enum SpeechPermissionStatus {
  granted,
  denied,
  permanentlyDenied,
  restricted,
}

class SpeechRecognitionUpdate extends Equatable {
  const SpeechRecognitionUpdate({
    required this.transcript,
    required this.soundLevel,
    required this.isFinal,
  });

  final String transcript;
  /// Sound level normalized strictly to 0.0 .. 1.0 for the voice orb.
  final double soundLevel;
  final bool isFinal;

  @override
  List<Object?> get props => [transcript, soundLevel, isFinal];
}

abstract interface class SpeechRepository {
  Future<bool> initialize();
  Future<SpeechPermissionStatus> checkPermission();
  Future<SpeechPermissionStatus> requestPermission();
  Stream<SpeechRecognitionUpdate> startListening({String? localeId});
  Future<List<String>> getAvailableLocales();
  Future<void> stop();
  Future<void> cancel();
  bool get isListening;
}
