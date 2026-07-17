import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/token_storage.dart';
import '../models/user_model.dart';

/// Talks HTTP + owns token persistence. Throws [DioException] upward — the
/// repository translates those into [Failure]s.
abstract class AuthRemoteDataSource {
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  });

  Future<UserModel> login({required String email, required String password});

  Future<UserModel> getMe();

  Future<void> logout();

  Future<bool> hasSession();
}

class AuthRemoteDataSourceImpl implements AuthRemoteDataSource {
  AuthRemoteDataSourceImpl({
    required Dio client,
    required TokenStorage tokenStorage,
  })  : _dio = client,
        _tokens = tokenStorage;

  final Dio _dio;
  final TokenStorage _tokens;

  @override
  Future<UserModel> register({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.register,
      data: {
        'email': email,
        'password': password,
        'display_name': displayName,
      },
    );
    final data = response.data!;
    await _tokens.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return UserModel.fromJson(data['user'] as Map<String, dynamic>);
  }

  @override
  Future<UserModel> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      ApiConstants.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data!;
    await _tokens.saveTokens(
      access: data['access'] as String,
      refresh: data['refresh'] as String,
    );
    return getMe();
  }

  @override
  Future<UserModel> getMe() async {
    final response = await _dio.get<Map<String, dynamic>>(ApiConstants.me);
    return UserModel.fromJson(response.data!);
  }

  @override
  Future<void> logout() => _tokens.clear();

  @override
  Future<bool> hasSession() async => await _tokens.refreshToken != null;
}
