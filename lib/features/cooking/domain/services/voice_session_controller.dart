import '../../../settings/domain/entities/user_preferences.dart';
import '../entities/voice_command.dart';

enum AudioSessionState {
  idle,
  speaking,
  listening,
  pausedListeningForResume,
  finished,
  disposed,
}

abstract class VoiceSessionController {
  /// Stream of audio session state updates.
  Stream<AudioSessionState> get stateStream;

  /// Stream of recognized commands parsed from speech.
  Stream<VoiceCommand> get commandStream;

  /// Current audio session state.
  AudioSessionState get currentState;

  /// Active Guide Language.
  GuideLanguage get guideLanguage;

  /// Sets the guide language for TTS and bilingual speech listening.
  void setGuideLanguage(GuideLanguage language);

  /// Speaks [text]. Guarantees listening is stopped before speaking begins,
  /// and completes only when TTS finishes speaking plus a 300ms buffer.
  Future<void> speak(String text);

  /// Starts listening for a voice command.
  Future<void> startListening({bool isPausedContext = false});

  /// Stops both listening and speaking immediately.
  Future<void> stopAll();

  /// Called when the app enters background or loses focus.
  void onAppPaused();

  /// Called when the app resumes focus.
  void onAppResumed();

  /// Disposes resources, streams, and shuts down TTS and speech listeners.
  Future<void> dispose();
}
