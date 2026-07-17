import 'package:dio/dio.dart';

import 'failures.dart';

/// Maps a [DioException] to a domain [Failure].
///
/// DRF error bodies come in two shapes:
///  * `{"detail": "Human readable message"}` — auth/permission/generic errors
///  * `{"field": ["msg1", ...], "other_field": ["msg"]}` — validation errors
Failure mapDioError(DioException error) {
  switch (error.type) {
    case DioExceptionType.connectionTimeout:
    case DioExceptionType.sendTimeout:
    case DioExceptionType.receiveTimeout:
    case DioExceptionType.connectionError:
      return const NetworkFailure();
    case DioExceptionType.badResponse:
      return _mapResponse(error.response);
    case DioExceptionType.cancel:
      return const ServerFailure('Request was cancelled.');
    case DioExceptionType.badCertificate:
    case DioExceptionType.transformTimeout:
    case DioExceptionType.unknown:
      return const ServerFailure();
  }
}

Failure _mapResponse(Response<dynamic>? response) {
  final statusCode = response?.statusCode ?? 0;
  final data = response?.data;
  final detail = data is Map<String, dynamic> ? data['detail'] : null;

  if (statusCode == 401 || statusCode == 403) {
    return AuthFailure(detail is String ? detail : 'You are not authorized to do that.');
  }

  if (statusCode == 400 && data is Map<String, dynamic>) {
    if (detail is String) return ValidationFailure(detail, const {});
    final fieldErrors = <String, List<String>>{};
    data.forEach((field, messages) {
      if (messages is List) {
        fieldErrors[field] = messages.map((m) => m.toString()).toList();
      } else if (messages is String) {
        fieldErrors[field] = [messages];
      }
    });
    if (fieldErrors.isNotEmpty) {
      return ValidationFailure(
        fieldErrors.values.first.first,
        fieldErrors,
      );
    }
  }

  return ServerFailure(detail is String ? detail : 'Server error ($statusCode).');
}
