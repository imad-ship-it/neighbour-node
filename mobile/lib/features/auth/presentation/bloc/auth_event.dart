part of 'auth_bloc.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => const [];
}

/// Fired once from the splash screen: restore session from stored tokens.
class AppStarted extends AuthEvent {
  const AppStarted();
}

class LoginSubmitted extends AuthEvent {
  const LoginSubmitted({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class RegisterSubmitted extends AuthEvent {
  const RegisterSubmitted({
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

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
