import 'package:equatable/equatable.dart';
import 'package:fpdart/fpdart.dart';

sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Could not read or save data.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No connection. Working offline.']);
}

class TimeoutFailure extends Failure {
  const TimeoutFailure([super.message = 'The request took too long.']);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Could not understand the response.']);
}

class PermissionFailure extends Failure {
  const PermissionFailure([super.message = 'Permission was denied.']);
}

class ValidationFailure extends Failure {
  const ValidationFailure([super.message = 'Some details are invalid.']);
}

class UnexpectedFailure extends Failure {
  const UnexpectedFailure([super.message = 'Something went wrong.']);
}

typedef FutureEither<T> = Future<Either<Failure, T>>;
