part of 'auth_bloc.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => const [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class Authenticated extends AuthState {
  const Authenticated(this.user);

  final UserEntity user;

  @override
  List<Object?> get props => [user];
}

class Unauthenticated extends AuthState {
  const Unauthenticated();
}

class AuthError extends AuthState {
  const AuthError(this.message, {this.fieldErrors = const {}});

  final String message;

  /// DRF per-field validation messages, e.g. `{"email": ["already exists"]}`
  /// — shown under the matching form fields.
  final Map<String, List<String>> fieldErrors;

  String? fieldError(String field) =>
      fieldErrors[field]?.isNotEmpty == true ? fieldErrors[field]!.first : null;

  @override
  List<Object?> get props => [message, fieldErrors];
}
