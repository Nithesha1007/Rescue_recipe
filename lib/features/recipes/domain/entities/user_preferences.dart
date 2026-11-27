import 'package:equatable/equatable.dart';

import 'diet_tag.dart';

class UserPreferences extends Equatable {
  const UserPreferences({
    this.dietPreference = DietTag.none,
  });

  final DietTag dietPreference;

  UserPreferences copyWith({
    DietTag? dietPreference,
  }) {
    return UserPreferences(
      dietPreference: dietPreference ?? this.dietPreference,
    );
  }

  @override
  List<Object?> get props => [dietPreference];
}
