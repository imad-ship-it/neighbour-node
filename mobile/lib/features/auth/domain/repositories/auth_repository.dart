import 'package:dartz/dartz.dart';

import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

/// Contract implemented by the data layer. Domain and presentation only ever
/// see this interface — never Dio, tokens, or JSON.
abstract class AuthRepository {
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  });

  /// Restores the session from stored tokens, fetching the profile.
  Future<Either<Failure, UserEntity>> getCurrentUser();

  Future<Either<Failure, Unit>> logout();
}
