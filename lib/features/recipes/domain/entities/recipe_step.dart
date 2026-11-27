import 'package:equatable/equatable.dart';

class RecipeStep extends Equatable {
  const RecipeStep({
    required this.text,
    this.minutes,
    this.tip,
  });

  final String text;
  final int? minutes;
  final String? tip;

  @override
  List<Object?> get props => [text, minutes, tip];
}
