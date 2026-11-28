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
  static const String _customItemValueKey = 'custom_item_value';
  static const String _notificationsEnabledKey = 'notifications_enabled';
  static const String _notifyHourKey = 'notify_hour';
  static const String _notifyMinuteKey = 'notify_minute';
  static const String _notifyDayBeforeKey = 'notify_day_before';
  static const String _notifyOnExpiryDayKey = 'notify_on_expiry_day';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';
  static const String _voiceInputLanguageKey = 'voice_input_language';
  static const String _guideLanguageKey = 'guide_language';
  static const String _displayNameKey = 'display_name';
  static const String _avatarEmojiKey = 'avatar_emoji';
  static const String _householdSizeKey = 'household_size';
  static const String _defaultServingsKey = 'default_servings';
  static const String _cookingSkillKey = 'cooking_skill';
  static const String _spiceLevelKey = 'spice_level';
  static const String _allergensKey = 'allergens_csv';
  static const String _dislikedKey = 'disliked_csv';
  static const String _preferredCuisinesKey = 'preferred_cuisines_csv';
  static const String _allowAiIllustrationKey = 'allow_ai_illustration';
  static const String _voiceFeedbackEnabledKey = 'voice_feedback_enabled';
  static const String _highContrastKey = 'high_contrast';
  static const String _reduceMotionKey = 'reduce_motion';

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
    final customValStr = _preferencesBox.get(_customItemValueKey);
    final customVal = customValStr != null ? double.tryParse(customValStr) : null;

    final notifEnabled = _preferencesBox.get(_notificationsEnabledKey, defaultValue: 'true') == 'true';
    final notifyHour = int.tryParse(_preferencesBox.get(_notifyHourKey, defaultValue: '9') ?? '9') ?? 9;
    final notifyMinute = int.tryParse(_preferencesBox.get(_notifyMinuteKey, defaultValue: '0') ?? '0') ?? 0;
    final notifyDayBefore = _preferencesBox.get(_notifyDayBeforeKey, defaultValue: 'true') == 'true';
    final notifyOnExpiryDay = _preferencesBox.get(_notifyOnExpiryDayKey, defaultValue: 'true') == 'true';
    final hasOnboarded = _preferencesBox.get(_hasCompletedOnboardingKey, defaultValue: 'false') == 'true';

    final voiceInputLangStr = _preferencesBox.get(_voiceInputLanguageKey, defaultValue: 'auto');
    final voiceInputLanguage = VoiceInputLanguage.values.firstWhere(
      (v) => v.name == voiceInputLangStr,
      orElse: () => VoiceInputLanguage.auto,
    );

    final guideLangStr = _preferencesBox.get(_guideLanguageKey, defaultValue: 'english');
    final guideLanguage = GuideLanguage.values.firstWhere(
      (g) => g.name == guideLangStr,
      orElse: () => GuideLanguage.english,
    );

    final displayName = _preferencesBox.get(_displayNameKey, defaultValue: '') ?? '';
    final avatarEmoji = _preferencesBox.get(_avatarEmojiKey, defaultValue: '🧑‍🍳') ?? '🧑‍🍳';
    final householdSize = int.tryParse(_preferencesBox.get(_householdSizeKey, defaultValue: '2') ?? '2') ?? 2;
    final defaultServings = int.tryParse(_preferencesBox.get(_defaultServingsKey, defaultValue: '2') ?? '2') ?? 2;

    final skillStr = _preferencesBox.get(_cookingSkillKey, defaultValue: 'intermediate');
    final cookingSkill = CookingSkill.values.firstWhere(
      (s) => s.name == skillStr,
      orElse: () => CookingSkill.intermediate,
    );

    final spiceStr = _preferencesBox.get(_spiceLevelKey, defaultValue: 'medium');
    final spiceLevel = SpiceLevel.values.firstWhere(
      (s) => s.name == spiceStr,
      orElse: () => SpiceLevel.medium,
    );

    final allergensRaw = _preferencesBox.get(_allergensKey, defaultValue: '') ?? '';
    final allergens = allergensRaw.isNotEmpty
        ? allergensRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final dislikedRaw = _preferencesBox.get(_dislikedKey, defaultValue: '') ?? '';
    final dislikedIngredients = dislikedRaw.isNotEmpty
        ? dislikedRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final cuisinesRaw = _preferencesBox.get(_preferredCuisinesKey, defaultValue: '') ?? '';
    final preferredCuisines = cuisinesRaw.isNotEmpty
        ? cuisinesRaw.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
        : <String>[];

    final allowAiIllustration = _preferencesBox.get(_allowAiIllustrationKey, defaultValue: 'false') == 'true';
    final voiceFeedbackEnabled = _preferencesBox.get(_voiceFeedbackEnabledKey, defaultValue: 'true') == 'true';
    final highContrast = _preferencesBox.get(_highContrastKey, defaultValue: 'false') == 'true';
    final reduceMotion = _preferencesBox.get(_reduceMotionKey, defaultValue: 'false') == 'true';

    return UserPreferences(
      diet: diet,
      cuisine: cuisine,
      speechLocale: speechLocale,
      speechRate: speechRate.clamp(0.3, 0.8),
      themeMode: themeMode,
      currencySymbol: currency,
      customItemValue: customVal,
      notificationsEnabled: notifEnabled,
      notifyHour: notifyHour,
      notifyMinute: notifyMinute,
      notifyDayBefore: notifyDayBefore,
      notifyOnExpiryDay: notifyOnExpiryDay,
      hasCompletedOnboarding: hasOnboarded,
      voiceInputLanguage: voiceInputLanguage,
      guideLanguage: guideLanguage,
      displayName: displayName,
      avatarEmoji: avatarEmoji,
      householdSize: householdSize,
      defaultServings: defaultServings,
      cookingSkill: cookingSkill,
      spiceLevel: spiceLevel,
      allergens: allergens,
      dislikedIngredients: dislikedIngredients,
      preferredCuisines: preferredCuisines,
      allowAiIllustration: allowAiIllustration,
      voiceFeedbackEnabled: voiceFeedbackEnabled,
      highContrast: highContrast,
      reduceMotion: reduceMotion,
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
    if (preferences.customItemValue != null) {
      await _preferencesBox.put(_customItemValueKey, preferences.customItemValue.toString());
    } else {
      await _preferencesBox.delete(_customItemValueKey);
    }
    await _preferencesBox.put(_notificationsEnabledKey, preferences.notificationsEnabled.toString());
    await _preferencesBox.put(_notifyHourKey, preferences.notifyHour.toString());
    await _preferencesBox.put(_notifyMinuteKey, preferences.notifyMinute.toString());
    await _preferencesBox.put(_notifyDayBeforeKey, preferences.notifyDayBefore.toString());
    await _preferencesBox.put(_notifyOnExpiryDayKey, preferences.notifyOnExpiryDay.toString());
    await _preferencesBox.put(_hasCompletedOnboardingKey, preferences.hasCompletedOnboarding.toString());
    await _preferencesBox.put(_voiceInputLanguageKey, preferences.voiceInputLanguage.name);
    await _preferencesBox.put(_guideLanguageKey, preferences.guideLanguage.name);
    await _preferencesBox.put(_displayNameKey, preferences.displayName);
    await _preferencesBox.put(_avatarEmojiKey, preferences.avatarEmoji);
    await _preferencesBox.put(_householdSizeKey, preferences.householdSize.toString());
    await _preferencesBox.put(_defaultServingsKey, preferences.defaultServings.toString());
    await _preferencesBox.put(_cookingSkillKey, preferences.cookingSkill.name);
    await _preferencesBox.put(_spiceLevelKey, preferences.spiceLevel.name);
    await _preferencesBox.put(_allergensKey, preferences.allergens.join(','));
    await _preferencesBox.put(_dislikedKey, preferences.dislikedIngredients.join(','));
    await _preferencesBox.put(_preferredCuisinesKey, preferences.preferredCuisines.join(','));
    await _preferencesBox.put(_allowAiIllustrationKey, preferences.allowAiIllustration.toString());
    await _preferencesBox.put(_voiceFeedbackEnabledKey, preferences.voiceFeedbackEnabled.toString());
    await _preferencesBox.put(_highContrastKey, preferences.highContrast.toString());
    await _preferencesBox.put(_reduceMotionKey, preferences.reduceMotion.toString());
  }

  @override
  Future<void> clearAll() async {
    await _preferencesBox.clear();
  }
}
