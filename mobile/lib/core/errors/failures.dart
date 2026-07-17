import 'package:equatable/equatable.dart';

/// Base failure crossing layer boundaries as `Either<Failure, T>` (dartz).
sealed class Failure extends Equatable {
  const Failure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

/// Backend reached but returned an unexpected error (5xx, malformed body...).
class ServerFailure extends Failure {
  const ServerFailure([super.message = 'Something went wrong on the server.']);
}

/// No connectivity / timeout — the request never completed.
class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Check your internet connection and try again.']);
}

/// Authentication problem: bad credentials, expired/invalid session (401/403).
class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Your session has expired. Please log in again.']);
}

/// DRF validation error (400) with per-field messages, e.g.
/// `{"email": ["A user with this email already exists."]}`.
class ValidationFailure extends Failure {
  const ValidationFailure(super.message, this.fieldErrors);

  final Map<String, List<String>> fieldErrors;

  /// First message for [field], or null — convenient for form field errors.
  String? operator [](String field) =>
      fieldErrors[field]?.isNotEmpty == true ? fieldErrors[field]!.first : null;

  @override
  List<Object?> get props => [message, fieldErrors];
}
