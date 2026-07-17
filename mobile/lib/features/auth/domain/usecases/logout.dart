import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../repositories/auth_repository.dart';

class Logout implements UseCase<Unit, NoParams> {
  const Logout(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, Unit>> call(NoParams params) => _repository.logout();
}
