import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../../recipes/domain/entities/diet_tag.dart';
import 'cuisine_tag.dart';

class UserPreferences extends Equatable {
  final DietTag diet;
  final CuisineTag cuisine;
  final String speechLocale;
  final double speechRate;
  final ThemeMode themeMode;
  final String currencySymbol;
  final bool notificationsEnabled;
  final int notifyHour;
  final int notifyMinute;
  final bool notifyDayBefore;
  final bool notifyOnExpiryDay;

  const UserPreferences({
    this.diet = DietTag.none,
    this.cuisine = CuisineTag.any,
    this.speechLocale = 'en_IN',
    this.speechRate = 0.5,
    this.themeMode = ThemeMode.system,
    this.currencySymbol = '₹',
    this.notificationsEnabled = true,
    this.notifyHour = 9,
    this.notifyMinute = 0,
    this.notifyDayBefore = true,
    this.notifyOnExpiryDay = true,
  });

  UserPreferences copyWith({
    DietTag? diet,
    CuisineTag? cuisine,
    String? speechLocale,
    double? speechRate,
    ThemeMode? themeMode,
    String? currencySymbol,
    bool? notificationsEnabled,
    int? notifyHour,
    int? notifyMinute,
    bool? notifyDayBefore,
    bool? notifyOnExpiryDay,
  }) {
    return UserPreferences(
      diet: diet ?? this.diet,
      cuisine: cuisine ?? this.cuisine,
      speechLocale: speechLocale ?? this.speechLocale,
      speechRate: speechRate ?? this.speechRate,
      themeMode: themeMode ?? this.themeMode,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      notifyHour: notifyHour ?? this.notifyHour,
      notifyMinute: notifyMinute ?? this.notifyMinute,
      notifyDayBefore: notifyDayBefore ?? this.notifyDayBefore,
      notifyOnExpiryDay: notifyOnExpiryDay ?? this.notifyOnExpiryDay,
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
        notificationsEnabled,
        notifyHour,
        notifyMinute,
        notifyDayBefore,
        notifyOnExpiryDay,
      ];
}
