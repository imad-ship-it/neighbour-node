import 'package:dio/dio.dart';
import 'package:dartz/dartz.dart';

import '../../../../core/errors/error_mapper.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl(this._remote);

  final AuthRemoteDataSource _remote;

  @override
  Future<Either<Failure, UserEntity>> register({
    required String email,
    required String password,
    required String displayName,
  }) =>
      _guard(() async {
        final user = await _remote.register(
          email: email,
          password: password,
          displayName: displayName,
        );
        return user.toEntity();
      });

  @override
  Future<Either<Failure, UserEntity>> login({
    required String email,
    required String password,
  }) =>
      _guard(() async {
        final user = await _remote.login(email: email, password: password);
        return user.toEntity();
      });

  @override
  Future<Either<Failure, UserEntity>> getCurrentUser() async {
    // No stored session -> unauthenticated without a network round-trip.
    if (!await _remote.hasSession()) {
      return const Left(AuthFailure('Not signed in.'));
    }
    return _guard(() async => (await _remote.getMe()).toEntity());
  }

  @override
  Future<Either<Failure, Unit>> logout() async {
    await _remote.logout();
    return const Right(unit);
  }

  Future<Either<Failure, T>> _guard<T>(Future<T> Function() run) async {
    try {
      return Right(await run());
    } on DioException catch (e) {
      return Left(mapDioError(e));
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
