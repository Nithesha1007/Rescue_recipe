import 'package:fpdart/fpdart.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecase/usecase.dart';

class GetSpeechRate implements UseCase<double, NoParams> {
  const GetSpeechRate();

  @override
  FutureEither<double> call(NoParams params) async {
    return const Right(0.5);
  }
}
