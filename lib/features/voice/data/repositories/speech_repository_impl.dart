import 'dart:async';

import 'package:permission_handler/permission_handler.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../../core/utils/debug_logger.dart';
import '../../domain/repositories/speech_repository.dart';

class SpeechRepositoryImpl implements SpeechRepository {
  SpeechRepositoryImpl({stt.SpeechToText? speechToText})
      : _speech = speechToText ?? stt.SpeechToText();

  final stt.SpeechToText _speech;
  StreamController<SpeechRecognitionUpdate>? _controller;
  bool _initialized = false;
  String? _preferredLocale;

  @override
  bool get isListening => _speech.isListening;

  @override
  Future<bool> initialize() async {
    if (_initialized) return true;
    try {
      _initialized = await _speech.initialize(
        onError: (error) {
          DebugLogger.speech('Engine error: ${error.errorMsg} (permanent: ${error.permanent})');
        },
        onStatus: (status) {
          DebugLogger.speech('Engine status: $status');
          if (status == 'done' || status == 'notListening') {
            _controller?.close();
          }
        },
      );
      DebugLogger.speech('Speech initialized: $_initialized');
      return _initialized;
    } catch (e, st) {
      DebugLogger.error('SPEECH', 'Initialization exception: $e', e, st);
      return false;
    }
  }

  @override
  Future<SpeechPermissionStatus> checkPermission() async {
    final status = await Permission.microphone.status;
    return _mapStatus(status);
  }

  @override
  Future<SpeechPermissionStatus> requestPermission() async {
    final status = await Permission.microphone.request();
    return _mapStatus(status);
  }

  @override
  Future<List<String>> getAvailableLocales() async {
    try {
      if (!_initialized) await initialize();
      final locales = await _speech.locales();
      final ids = locales.map((l) => l.localeId).toList();
      DebugLogger.speech('Available locales count: ${ids.length}');
      return ids;
    } catch (_) {
      return ['en_IN', 'en_US'];
    }
  }

  @override
  Stream<SpeechRecognitionUpdate> startListening({String? localeId}) {
    _preferredLocale = localeId;
    _controller = StreamController<SpeechRecognitionUpdate>.broadcast(
      onCancel: () {
        stop();
      },
    );

    _listenInternal();
    return _controller!.stream;
  }

  void _listenInternal() {
    _speech.listen(
      onResult: (result) {
        _controller?.add(SpeechRecognitionUpdate(
          transcript: result.recognizedWords,
          soundLevel: 0.5,
          isFinal: result.finalResult,
        ));
      },
      onSoundLevelChange: (level) {
        final double normalized = ((level + 2) / 12).clamp(0.0, 1.0);
        _controller?.add(SpeechRecognitionUpdate(
          transcript: _speech.lastRecognizedWords,
          soundLevel: normalized,
          isFinal: false,
        ));
      },
      listenOptions: stt.SpeechListenOptions(
        localeId: _preferredLocale,
        listenMode: stt.ListenMode.dictation,
        cancelOnError: false,
        partialResults: true,
        listenFor: const Duration(seconds: 120),
        pauseFor: const Duration(seconds: 8),
      ),
    );
  }

  @override
  Future<void> stop() async {
    if (_speech.isListening) {
      await _speech.stop();
    }
    _controller?.close();
  }

  @override
  Future<void> cancel() async {
    if (_speech.isListening) {
      await _speech.cancel();
    }
    _controller?.close();
  }

  SpeechPermissionStatus _mapStatus(PermissionStatus status) {
    return switch (status) {
      PermissionStatus.granted || PermissionStatus.limited =>
        SpeechPermissionStatus.granted,
      PermissionStatus.denied => SpeechPermissionStatus.denied,
      PermissionStatus.permanentlyDenied =>
        SpeechPermissionStatus.permanentlyDenied,
      PermissionStatus.restricted => SpeechPermissionStatus.restricted,
      _ => SpeechPermissionStatus.denied,
    };
  }
}
