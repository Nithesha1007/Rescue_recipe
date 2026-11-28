import 'package:equatable/equatable.dart';

class RecipeStep extends Equatable {
  const RecipeStep({
    required this.text,
    this.minutes,
    this.tip,
    this.uses = const <String>[],
  });

  final String text;
  final int? minutes;
  final String? tip;
  final List<String> uses;

  @override
  List<Object?> get props => [text, minutes, tip, uses];
}
