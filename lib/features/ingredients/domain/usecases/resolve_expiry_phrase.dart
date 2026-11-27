import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';
import '../utils/expiry_date_resolver.dart';

class ResolveExpiryParams extends Equatable {
  const ResolveExpiryParams({required this.phrase, this.today});

  final String phrase;
  final DateTime? today;

  @override
  List<Object?> get props => [phrase, today];
}

class ResolveExpiryPhrase implements UseCase<DateTime?, ResolveExpiryParams> {
  const ResolveExpiryPhrase();

  @override
  FutureEither<DateTime?> call(ResolveExpiryParams params) async {
    final DateTime? resolved =
        ExpiryDateResolver.resolve(params.phrase, today: params.today);
    return Right(resolved);
  }
}
