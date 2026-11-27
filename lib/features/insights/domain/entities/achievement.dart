import 'package:equatable/equatable.dart';

class Achievement extends Equatable {
  final String id;
  final String title;
  final String description;
  final bool isUnlocked;
  final int currentProgress;
  final int targetProgress;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.isUnlocked,
    required this.currentProgress,
    required this.targetProgress,
  });

  String get progressHint => '$currentProgress of $targetProgress';

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        isUnlocked,
        currentProgress,
        targetProgress,
      ];
}
