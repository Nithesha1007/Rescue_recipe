/// Pure Dart transcript accumulator that manages continuous speech recognition streams.
/// Separates finalized segments (`committedText`) from the transient live segment (`partialText`).
class TranscriptAccumulator {
  String _committedText = '';
  String _partialText = '';
  int _consecutiveSilentRestarts = 0;
  int _currentSessionGeneration = 0;

  String get committedText => _committedText;
  String get partialText => _partialText;
  int get consecutiveSilentRestarts => _consecutiveSilentRestarts;
  int get silentRestartCount => _consecutiveSilentRestarts;
  int get currentSessionGeneration => _currentSessionGeneration;
  int get generation => _currentSessionGeneration;

  /// Combined full text representation for display.
  String get fullTranscript {
    final c = _committedText.trim();
    final p = _partialText.trim();
    if (c.isEmpty) return p;
    if (p.isEmpty) return c;
    return '$c $p';
  }

  /// Alias for fullTranscript.
  String get liveTranscript => fullTranscript;

  /// Whether no text has been committed or partially recognized.
  bool get isEmpty => fullTranscript.isEmpty;

  /// Increments session generation to reject late callbacks from older sessions.
  int startNewSession() {
    _currentSessionGeneration++;
    _partialText = '';
    return _currentSessionGeneration;
  }

  /// Increments generation and returns the new value.
  int nextGeneration() => startNewSession();

  /// Handles incoming live transcript from the speech engine.
  void onSpeechResult({
    required String recognizedWords,
    required bool isFinal,
    required int generation,
  }) {
    if (generation != _currentSessionGeneration) return;

    final incoming = recognizedWords.trim();
    if (incoming.isEmpty) return;

    if (isFinal) {
      _consecutiveSilentRestarts = 0;
      if (_committedText.isEmpty) {
        _committedText = incoming;
      } else {
        // Prevent duplicate appending if the engine re-sends identical final text
        if (!_committedText.endsWith(incoming) && !incoming.startsWith(_committedText)) {
          _committedText = '$_committedText $incoming';
        } else if (incoming.startsWith(_committedText)) {
          _committedText = incoming;
        }
      }
      _partialText = '';
    } else {
      _partialText = incoming;
    }
  }

  /// Direct partial update (e.g. for testing or direct feeder).
  void updatePartial(String text) {
    _partialText = text.trim();
  }

  /// Direct commit of a segment (e.g. for testing or simulated streams).
  void commitSegment(String segment) {
    final incoming = segment.trim();
    if (incoming.isEmpty) return;
    _consecutiveSilentRestarts = 0;
    if (_committedText.isEmpty) {
      _committedText = incoming;
    } else {
      if (!_committedText.endsWith(incoming) && !incoming.startsWith(_committedText)) {
        _committedText = '$_committedText $incoming';
      } else if (incoming.startsWith(_committedText)) {
        _committedText = incoming;
      }
    }
    _partialText = '';
  }

  /// Called when the engine stops on its own.
  /// Returns `true` if auto-restart should occur, `false` if 3 consecutive silent restarts exceeded.
  bool onEngineStopped({required int generation}) {
    if (generation != _currentSessionGeneration) return false;

    // If partial had text but wasn't committed, commit it now
    if (_partialText.trim().isNotEmpty) {
      final p = _partialText.trim();
      if (_committedText.isEmpty) {
        _committedText = p;
      } else if (!_committedText.endsWith(p)) {
        _committedText = '$_committedText $p';
      }
      _partialText = '';
      _consecutiveSilentRestarts = 0;
    } else {
      _consecutiveSilentRestarts++;
    }

    return _consecutiveSilentRestarts < 3;
  }

  /// Increments restart counter manually.
  void incrementRestart() {
    _consecutiveSilentRestarts++;
  }

  /// Checks if restart is allowed against a maximum limit.
  bool shouldRestart({int maxSilentRestarts = 3}) {
    return _consecutiveSilentRestarts < maxSilentRestarts;
  }

  /// Called when user edits the text field manually.
  void onUserManualEdit(String newText) {
    _committedText = newText.trim();
    _partialText = '';
    _consecutiveSilentRestarts = 0;
  }

  /// Resets accumulator to blank state.
  void reset() {
    _committedText = '';
    _partialText = '';
    _consecutiveSilentRestarts = 0;
    _currentSessionGeneration++;
  }

  /// Alias for reset.
  void clear() => reset();
}
