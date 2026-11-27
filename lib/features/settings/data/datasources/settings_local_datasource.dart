import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import '../../domain/entities/cuisine_tag.dart';
import '../../domain/entities/user_preferences.dart';

abstract class SettingsLocalDataSource {
  Future<UserPreferences> getPreferences();
  Future<void> savePreferences(UserPreferences preferences);
  Future<void> clearAll();
}

class SettingsLocalDataSourceImpl implements SettingsLocalDataSource {
  final Box<String> _preferencesBox;

  static const String _dietKey = 'diet_preference';
  static const String _cuisineKey = 'cuisine_preference';
  static const String _speechLocaleKey = 'speech_locale';
  static const String _speechRateKey = 'speech_rate';
  static const String _themeModeKey = 'theme_mode';
  static const String _currencyKey = 'currency_symbol';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notifyHourKey = 'notify_hour';
  static const String _notifyMinuteKey = 'notify_minute';
  static const String _notifyDayBeforeKey = 'notify_day_before';
  static const String _notifyOnExpiryDayKey = 'notify_on_expiry_day';

  SettingsLocalDataSourceImpl(this._preferencesBox);

  @override
  Future<UserPreferences> getPreferences() async {
    final dietStr = _preferencesBox.get(_dietKey, defaultValue: DietTag.none.name);
    final diet = DietTag.fromString(dietStr);

    final cuisineStr = _preferencesBox.get(_cuisineKey, defaultValue: 'any');
    final cuisine = CuisineTag.fromString(cuisineStr);

    final speechLocale = _preferencesBox.get(_speechLocaleKey, defaultValue: 'en_IN') ?? 'en_IN';

    final speechRateStr = _preferencesBox.get(_speechRateKey);
    final speechRate = speechRateStr != null ? double.tryParse(speechRateStr) ?? 0.5 : 0.5;

    final themeModeStr = _preferencesBox.get(_themeModeKey);
    final themeMode = switch (themeModeStr) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    final currency = _preferencesBox.get(_currencyKey, defaultValue: '₹') ?? '₹';
    final notifEnabled = _preferencesBox.get(_notificationsEnabledKey, defaultValue: 'true') == 'true';
    final notifyHour = int.tryParse(_preferencesBox.get(_notifyHourKey, defaultValue: '9') ?? '9') ?? 9;
    final notifyMinute = int.tryParse(_preferencesBox.get(_notifyMinuteKey, defaultValue: '0') ?? '0') ?? 0;
    final notifyDayBefore = _preferencesBox.get(_notifyDayBeforeKey, defaultValue: 'true') == 'true';
    final notifyOnExpiryDay = _preferencesBox.get(_notifyOnExpiryDayKey, defaultValue: 'true') == 'true';

    return UserPreferences(
      diet: diet,
      cuisine: cuisine,
      speechLocale: speechLocale,
      speechRate: speechRate.clamp(0.3, 0.8),
      themeMode: themeMode,
      currencySymbol: currency,
      notificationsEnabled: notifEnabled,
      notifyHour: notifyHour,
      notifyMinute: notifyMinute,
      notifyDayBefore: notifyDayBefore,
      notifyOnExpiryDay: notifyOnExpiryDay,
    );
  }

  @override
  Future<void> savePreferences(UserPreferences preferences) async {
    await _preferencesBox.put(_dietKey, preferences.diet.name);
    await _preferencesBox.put(_cuisineKey, preferences.cuisine.name);
    await _preferencesBox.put(_speechLocaleKey, preferences.speechLocale);
    await _preferencesBox.put(_speechRateKey, preferences.speechRate.toString());
    await _preferencesBox.put(_themeModeKey, preferences.themeMode.name);
    await _preferencesBox.put(_currencyKey, preferences.currencySymbol);
    await _preferencesBox.put(_notificationsEnabledKey, preferences.notificationsEnabled.toString());
    await _preferencesBox.put(_notifyHourKey, preferences.notifyHour.toString());
    await _preferencesBox.put(_notifyMinuteKey, preferences.notifyMinute.toString());
    await _preferencesBox.put(_notifyDayBeforeKey, preferences.notifyDayBefore.toString());
    await _preferencesBox.put(_notifyOnExpiryDayKey, preferences.notifyOnExpiryDay.toString());
  }

  @override
  Future<void> clearAll() async {
    await _preferencesBox.clear();
  }
}
