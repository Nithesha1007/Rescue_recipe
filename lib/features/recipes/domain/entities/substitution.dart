import 'package:equatable/equatable.dart';

class Substitution extends Equatable {
  const Substitution({
    required this.missingIngredient,
    required this.substitute,
    required this.note,
  });

  final String missingIngredient;
  final String substitute;
  final String note;

  @override
  List<Object?> get props => [missingIngredient, substitute, note];
}
