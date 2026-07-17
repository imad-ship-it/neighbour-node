import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';

import '../../../../core/errors/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class RegisterUser implements UseCase<UserEntity, RegisterParams> {
  const RegisterUser(this._repository);

  final AuthRepository _repository;

  @override
  Future<Either<Failure, UserEntity>> call(RegisterParams params) =>
      _repository.register(
        email: params.email,
        password: params.password,
        displayName: params.displayName,
      );
}

class RegisterParams extends Equatable {
  const RegisterParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  final String email;
  final String password;
  final String displayName;

  @override
  List<Object?> get props => [email, password, displayName];
}
