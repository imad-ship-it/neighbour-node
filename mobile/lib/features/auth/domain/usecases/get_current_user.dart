import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class GetCurrentUser implements UseCase<UserEntity, NoParams> {
  const GetCurrentUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(NoParams params) =>
      _repository.getCurrentUser();
}
