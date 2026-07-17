import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint, kDebugMode;

import '../constants/api_constants.dart';
import 'session_manager.dart';
import 'token_storage.dart';

/// Attaches the Bearer access token to outgoing requests and transparently
/// refreshes it once on 401.
///
/// Extends [QueuedInterceptor] so concurrent 401s are handled one at a time —
/// only the first triggers a refresh; the rest see the new token when their
/// turn comes.
class AuthInterceptor extends QueuedInterceptor {
  AuthInterceptor({
    required TokenStorage tokenStorage,
    required SessionManager sessionManager,
    required Dio plainDio,
  })  : _tokens = tokenStorage,
        _session = sessionManager,
        _refreshDio = plainDio;

  final TokenStorage _tokens;
  final SessionManager _session;

  /// Bare Dio (no interceptors) — used for the refresh call and the retry so
  /// a failing refresh can never recurse back into this interceptor.
  final Dio _refreshDio;

  static const _retriedFlag = 'auth_retried';

  static const _publicPaths = {
    ApiConstants.login,
    ApiConstants.register,
    ApiConstants.refresh,
  };

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    if (!_publicPaths.contains(options.path)) {
      final access = await _tokens.accessToken;
      if (access != null) {
        options.headers['Authorization'] = 'Bearer $access';
      }
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;
    final is401 = err.response?.statusCode == 401;
    final isPublic = _publicPaths.contains(options.path);
    final alreadyRetried = options.extra[_retriedFlag] == true;

    if (!is401 || isPublic || alreadyRetried) {
      return handler.next(err);
    }

    final refresh = await _tokens.refreshToken;
    if (refresh == null) {
      _session.notifyLoggedOut();
      return handler.next(err);
    }

    if (kDebugMode) {
      debugPrint(
        '[AuthInterceptor] 401 on ${options.path} — refreshing access token',
      );
    }
    try {
      final response = await _refreshDio.post<Map<String, dynamic>>(
        ApiConstants.refresh,
        data: {'refresh': refresh},
      );
      final newAccess = response.data?['access'] as String?;
      if (newAccess == null) throw StateError('No access token in refresh response');
      await _tokens.saveTokens(
        access: newAccess,
        // SimpleJWT rotation (ROTATE_REFRESH_TOKENS) also returns a new refresh.
        refresh: response.data?['refresh'] as String?,
      );

      options.extra[_retriedFlag] = true;
      options.headers['Authorization'] = 'Bearer $newAccess';
      final retried = await _refreshDio.fetch<dynamic>(options);
      if (kDebugMode) {
        debugPrint(
          '[AuthInterceptor] token refreshed, ${options.path} retried OK',
        );
      }
      return handler.resolve(retried);
    } on DioException catch (retryError) {
      if (retryError.requestOptions.path == ApiConstants.refresh) {
        // Refresh token itself rejected -> session is over.
        await _tokens.clear();
        _session.notifyLoggedOut();
        return handler.next(err);
      }
      // Refresh worked but the retry failed: surface the retry's real error.
      return handler.next(retryError);
    } catch (_) {
      await _tokens.clear();
      _session.notifyLoggedOut();
      return handler.next(err);
    }
  }
}
