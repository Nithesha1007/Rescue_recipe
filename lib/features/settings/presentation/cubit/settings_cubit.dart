import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/usecase/usecase.dart';
import '../../../notifications/domain/usecases/request_notification_permission.dart';
import '../../../notifications/domain/usecases/sync_expiry_alerts.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/usecases/clear_all_data.dart';
import '../../domain/usecases/get_settings.dart';
import '../../domain/usecases/update_settings.dart';
import 'settings_state.dart';

class SettingsCubit extends Cubit<SettingsState> {
  final GetSettings _getSettings;
  final UpdateSettings _updateSettings;
  final ClearAllData _clearAllData;
  final RequestNotificationPermission? _requestNotificationPermission;
  final SyncExpiryAlerts? _syncExpiryAlerts;

  SettingsCubit({
    required GetSettings getSettings,
    required UpdateSettings updateSettings,
    required ClearAllData clearAllData,
    RequestNotificationPermission? requestNotificationPermission,
    SyncExpiryAlerts? syncExpiryAlerts,
  })  : _getSettings = getSettings,
        _updateSettings = updateSettings,
        _clearAllData = clearAllData,
        _requestNotificationPermission = requestNotificationPermission,
        _syncExpiryAlerts = syncExpiryAlerts,
        super(const SettingsState()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    final result = await _getSettings(const NoParams());
    result.fold(
      (failure) => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (preferences) => emit(state.copyWith(
        status: SettingsStatus.loaded,
        preferences: preferences,
      )),
    );
  }

  Future<void> load() => loadSettings();

  Future<void> updatePreferences(UserPreferences preferences) async {
    emit(state.copyWith(preferences: preferences));
    final result = await _updateSettings(preferences);
    await result.fold(
      (failure) async => emit(state.copyWith(
        status: SettingsStatus.error,
        errorMessage: failure.message,
      )),
      (_) async {
        if (_syncExpiryAlerts != null) {
          await _syncExpiryAlerts(const NoParams());
        }
      },
    );
  }

  Future<void> updateDiet(DietTag diet) =>
      updatePreferences(state.preferences.copyWith(diet: diet));

  Future<void> updateThemeMode(ThemeMode mode) =>
      updatePreferences(state.preferences.copyWith(themeMode: mode));

  Future<void> updateSpeechRate(double rate) =>
      updatePreferences(state.preferences.copyWith(speechRate: rate));

  Future<void> updateCurrency(String symbol) =>
      updatePreferences(state.preferences.copyWith(currencySymbol: symbol));

  Future<void> updateNotificationsEnabled(bool enabled) async {
    if (enabled && _requestNotificationPermission != null) {
      final res = await _requestNotificationPermission(const NoParams());
      final granted = res.getOrElse((_) => false);
      if (!granted) {
        // Permission denied by user
        return;
      }
    }
    await updatePreferences(state.preferences.copyWith(notificationsEnabled: enabled));
  }

  Future<void> updateNotifyDayBefore(bool enabled) =>
      updatePreferences(state.preferences.copyWith(notifyDayBefore: enabled));

  Future<void> updateNotifyOnExpiryDay(bool enabled) =>
      updatePreferences(state.preferences.copyWith(notifyOnExpiryDay: enabled));

  Future<void> updateNotifyTime(int hour, int minute) =>
      updatePreferences(state.preferences.copyWith(
        notifyHour: hour,
        notifyMinute: minute,
      ));

  Future<void> clearAll() async {
    emit(state.copyWith(status: SettingsStatus.loading));
    await _clearAllData(const NoParams());
    await loadSettings();
  }
}
