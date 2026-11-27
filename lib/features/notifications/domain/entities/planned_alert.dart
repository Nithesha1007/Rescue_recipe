import 'package:equatable/equatable.dart';

enum AlertType {
  dayBefore,
  onDay,
}

class PlannedAlert extends Equatable {
  final int id;
  final String ingredientId;
  final String ingredientName;
  final AlertType alertType;
  final DateTime scheduledTime;
  final String title;
  final String body;
  final String payload;

  const PlannedAlert({
    required this.id,
    required this.ingredientId,
    required this.ingredientName,
    required this.alertType,
    required this.scheduledTime,
    required this.title,
    required this.body,
    required this.payload,
  });

  @override
  List<Object?> get props => [
        id,
        ingredientId,
        ingredientName,
        alertType,
        scheduledTime,
        title,
        body,
        payload,
      ];
}
