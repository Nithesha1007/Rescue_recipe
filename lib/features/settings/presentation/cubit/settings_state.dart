import 'package:equatable/equatable.dart';
import '../../domain/entities/user_preferences.dart';

enum SettingsStatus {
  initial,
  loading,
  loaded,
  error,
}

class SettingsState extends Equatable {
  final SettingsStatus status;
  final UserPreferences preferences;
  final String? errorMessage;

  const SettingsState({
    this.status = SettingsStatus.initial,
    this.preferences = const UserPreferences(),
    this.errorMessage,
  });

  SettingsState copyWith({
    SettingsStatus? status,
    UserPreferences? preferences,
    String? errorMessage,
  }) {
    return SettingsState(
      status: status ?? this.status,
      preferences: preferences ?? this.preferences,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [status, preferences, errorMessage];
}
