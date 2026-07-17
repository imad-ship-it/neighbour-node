import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:pretty_dio_logger/pretty_dio_logger.dart';

import '../constants/api_constants.dart';
import 'auth_interceptor.dart';
import 'session_manager.dart';
import 'token_storage.dart';

/// Owns the app's single configured [Dio] instance. Data-layer datasources
/// receive this via GetIt — nothing else builds its own Dio.
class ApiClient {
  ApiClient({
    required TokenStorage tokenStorage,
    required SessionManager sessionManager,
  }) {
    final options = BaseOptions(
      baseUrl: ApiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    );

    dio = Dio(options);
    dio.interceptors.add(
      AuthInterceptor(
        tokenStorage: tokenStorage,
        sessionManager: sessionManager,
        plainDio: Dio(options),
      ),
    );
    if (kDebugMode) {
      dio.interceptors.add(
        PrettyDioLogger(requestBody: true, responseBody: true, compact: true),
      );
    }
  }

  late final Dio dio;
}
