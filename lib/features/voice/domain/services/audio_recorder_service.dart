import 'dart:async';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

import '../../../../core/utils/debug_logger.dart';

abstract class AudioRecorderService {
  Future<bool> hasPermission();
  Future<void> startRecording();
  Future<String?> stopRecording();
  Stream<double> get amplitudeStream;
  bool get isRecording;
  Future<void> cancel();
  Future<void> dispose();
}

class AudioRecorderServiceImpl implements AudioRecorderService {
  AudioRecorderServiceImpl({AudioRecorder? recorder})
      : _recorder = recorder;

  AudioRecorder? _recorder;
  AudioRecorder get _rec => _recorder ??= AudioRecorder();
  final StreamController<double> _amplitudeController =
      StreamController<double>.broadcast();
  Timer? _amplitudeTimer;
  Timer? _silenceTimer;
  Timer? _maxDurationTimer;
  bool _isRecording = false;
  String? _currentPath;

  static const double _silenceThresholdDb = -40.0;
  static const Duration _silenceDuration = Duration(milliseconds: 2500);
  static const Duration _maxDuration = Duration(seconds: 45);

  @override
  bool get isRecording => _isRecording;

  @override
  Stream<double> get amplitudeStream => _amplitudeController.stream;

  @override
  Future<bool> hasPermission() async {
    return await _rec.hasPermission();
  }

  @override
  Future<void> startRecording() async {
    if (_isRecording) return;

    final hasPerm = await hasPermission();
    if (!hasPerm) {
      throw Exception('Microphone permission not granted for audio recording.');
    }

    final tempDir = await getTemporaryDirectory();
    final fileName = 'voice_clip_${DateTime.now().millisecondsSinceEpoch}.wav';
    _currentPath = '${tempDir.path}/$fileName';

    // 16 kHz, mono, PCM16, WAV
    const config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
    );

    await _rec.start(config, path: _currentPath!);
    _isRecording = true;
    DebugLogger.speech('Audio recording started at $_currentPath');

    _startMonitoring();
  }

  void _startMonitoring() {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();

    _maxDurationTimer = Timer(_maxDuration, () async {
      DebugLogger.speech('Max recording duration (45s) reached. Stopping.');
      await stopRecording();
    });

    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 100), (_) async {
      if (!_isRecording) return;
      try {
        final amp = await _rec.getAmplitude();
        // Convert dB (-160 to 0) to normalized 0.0 - 1.0
        final db = amp.current;
        final normalized = ((db + 60.0) / 60.0).clamp(0.0, 1.0);
        _amplitudeController.add(normalized);

        // Silence detection
        if (db < _silenceThresholdDb) {
          _silenceTimer ??= Timer(_silenceDuration, () async {
            DebugLogger.speech('Silence of 2.5s detected. Auto-stopping recorder.');
            await stopRecording();
          });
        } else {
          _silenceTimer?.cancel();
          _silenceTimer = null;
        }
      } catch (_) {}
    });
  }

  @override
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();

    final path = await _rec.stop();
    _isRecording = false;
    DebugLogger.speech('Audio recording stopped. File: $path');
    return path ?? _currentPath;
  }

  @override
  Future<void> cancel() async {
    _amplitudeTimer?.cancel();
    _silenceTimer?.cancel();
    _maxDurationTimer?.cancel();
    if (_isRecording) {
      await _rec.cancel();
      _isRecording = false;
    }
    if (_currentPath != null) {
      try {
        final file = File(_currentPath!);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
      _currentPath = null;
    }
  }

  @override
  Future<void> dispose() async {
    await cancel();
    if (_recorder != null) {
      await _rec.dispose();
    }
    await _amplitudeController.close();
  }
}
