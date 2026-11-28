import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import 'cuisine_tag.dart';

enum VoiceInputLanguage {
  auto('Auto (AI)', 'auto'),
  english('English', 'en_IN'),
  tamil('Tamil', 'ta_IN'),
  hindi('Hindi', 'hi_IN');

  const VoiceInputLanguage(this.label, this.localeCode);
  final String label;
  final String localeCode;
}

enum GuideLanguage {
  english('English', 'en-IN'),
  tamil('Tamil', 'ta-IN'),
  hindi('Hindi', 'hi-IN'),
  tanglish('Tanglish', 'en-IN'); // Tanglish spoken with Indian English TTS

  const GuideLanguage(this.label, this.ttsLocale);
  final String label;
  final String ttsLocale;
}

enum CookingSkill {
  beginner('Beginner'),
  intermediate('Intermediate'),
  expert('Expert');

  const CookingSkill(this.label);
  final String label;
}

enum SpiceLevel {
  mild('Mild 🌶️'),
  medium('Medium 🌶️🌶️'),
  hot('Hot 🌶️🌶️🌶️');

  const SpiceLevel(this.label);
  final String label;
}

class UserPreferences extends Equatable {
  final DietTag diet;
  final CuisineTag cuisine;
  final String speechLocale;
  final double speechRate;
  final ThemeMode themeMode;
  final String currencySymbol;
  final double? customItemValue;
  final bool notificationsEnabled;
  final int notifyHour;
  final int notifyMinute;
  final bool notifyDayBefore;
  final bool notifyOnExpiryDay;
  final bool hasCompletedOnboarding;
  final VoiceInputLanguage voiceInputLanguage;
  final GuideLanguage guideLanguage;

  // Phase 15 UserProfile additions
  final String displayName;
  final String avatarEmoji;
  final int householdSize;
  final int defaultServings;
  final CookingSkill cookingSkill;
  final SpiceLevel spiceLevel;
  final List<String> allergens;
  final List<String> dislikedIngredients;
  final List<String> preferredCuisines;
  final bool allowAiIllustration;

  const UserPreferences({
    this.diet = DietTag.none,
    this.cuisine = CuisineTag.any,
    this.speechLocale = 'en_IN',
    this.speechRate = 0.5,
    this.themeMode = ThemeMode.system,
    this.currencySymbol = '₹',
    this.customItemValue,
    this.notificationsEnabled = true,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.notifyDayBefore = true,
    this.notifyOnExpiryDay = true,
    this.hasCompletedOnboarding = false,
    this.voiceInputLanguage = VoiceInputLanguage.auto,
    this.guideLanguage = GuideLanguage.english,
    this.displayName = '',
    this.avatarEmoji = '🧑‍🍳',
    this.householdSize = 2,
    this.defaultServings = 2,
    this.cookingSkill = CookingSkill.intermediate,
    this.spiceLevel = SpiceLevel.medium,
    this.allergens = const <String>[],
    this.dislikedIngredients = const <String>[],
    this.preferredCuisines = const <String>[],
    this.allowAiIllustration = false,
    this.voiceFeedbackEnabled = true,
    this.highContrast = false,
    this.reduceMotion = false,
  });

  final bool voiceFeedbackEnabled;
  final bool highContrast;
  final bool reduceMotion;

  UserPreferences copyWith({
    DietTag? diet,
    CuisineTag? cuisine,
    String? speechLocale,
    double? speechRate,
    ThemeMode? themeMode,
    String? currencySymbol,
    double? Function()? customItemValue,
    bool? notificationsEnabled,
    int? notifyHour,
    int? notifyMinute,
    bool? notifyDayBefore,
    bool? notifyOnExpiryDay,
    bool? hasCompletedOnboarding,
    VoiceInputLanguage? voiceInputLanguage,
    GuideLanguage? guideLanguage,
    String? displayName,
    String? avatarEmoji,
    int? householdSize,
    int? defaultServings,
    CookingSkill? cookingSkill,
    SpiceLevel? spiceLevel,
    List<String>? allergens,
    List<String>? dislikedIngredients,
    List<String>? preferredCuisines,
    bool? allowAiIllustration,
    bool? voiceFeedbackEnabled,
    bool? highContrast,
    bool? reduceMotion,
  }) {
    return UserPreferences(
      diet: diet ?? this.diet,
      cuisine: cuisine ?? this.cuisine,
      speechLocale: speechLocale ?? this.speechLocale,
      speechRate: speechRate ?? this.speechRate,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      customItemValue: customItemValue != null ? customItemValue() : this.customItemValue,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      notifyDayBefore: notifyDayBefore ?? this.notifyDayBefore,
      notifyOnExpiryDay: notifyOnExpiryDay ?? this.notifyOnExpiryDay,
      hasCompletedOnboarding: hasCompletedOnboarding ?? this.hasCompletedOnboarding,
      voiceInputLanguage: voiceInputLanguage ?? this.voiceInputLanguage,
      guideLanguage: guideLanguage ?? this.guideLanguage,
      displayName: displayName ?? this.displayName,
      avatarEmoji: avatarEmoji ?? this.avatarEmoji,
      householdSize: householdSize ?? this.householdSize,
      defaultServings: defaultServings ?? this.defaultServings,
      cookingSkill: cookingSkill ?? this.cookingSkill,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      allergens: allergens ?? this.allergens,
      dislikedIngredients: dislikedIngredients ?? this.dislikedIngredients,
      preferredCuisines: preferredCuisines ?? this.preferredCuisines,
      allowAiIllustration: allowAiIllustration ?? this.allowAiIllustration,
      voiceFeedbackEnabled: voiceFeedbackEnabled ?? this.voiceFeedbackEnabled,
      highContrast: highContrast ?? this.highContrast,
      reduceMotion: reduceMotion ?? this.reduceMotion,
    );
  }

  @override
  List<Object?> get props => [
        diet,
        cuisine,
        speechLocale,
        speechRate,
        themeMode,
        currencySymbol,
        customItemValue,
        notificationsEnabled,
        notifyHour,
        notifyMinute,
        notifyDayBefore,
        notifyOnExpiryDay,
        hasCompletedOnboarding,
        voiceInputLanguage,
        guideLanguage,
        displayName,
        avatarEmoji,
        householdSize,
        defaultServings,
        cookingSkill,
        spiceLevel,
        allergens,
        dislikedIngredients,
        preferredCuisines,
        allowAiIllustration,
        voiceFeedbackEnabled,
        highContrast,
        reduceMotion,
      ];
}
